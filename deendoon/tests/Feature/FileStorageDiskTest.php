<?php

namespace Tests\Feature;

use App\Models\Customer;
use App\Models\Debt;
use App\Models\DemandLetter;
use App\Models\SupportTicket;
use App\Models\SupportTicketAttachment;
use App\Models\Tenant;
use App\Models\User;
use App\Services\Admin\AdminDashboardService;
use App\Services\AuditLogService;
use Database\Seeders\RoleSeeder;
use Database\Seeders\SubscriptionPlanSeeder;
use Illuminate\Filesystem\FilesystemAdapter;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Testing\TestResponse;
use Laravel\Sanctum\Sanctum;
use Mockery;
use PHPUnit\Framework\Attributes\DataProvider;
use RuntimeException;
use Tests\TestCase;

/**
 * Tenant files live on whichever disk `filesystems.app_files_disk`
 * (`APP_FILES_DISK`) names — "local" by default, "r2" for Cloudflare R2.
 * Every behaviour is asserted against BOTH disks, using fakes only: a real
 * R2 bucket is never contacted. Covers disk selection, failed writes (no
 * database row), rollback cleanup, missing files (404, not 500), the
 * authorization / cross-tenant rules on downloads, and the dashboard's
 * file-storage health check.
 */
class FileStorageDiskTest extends TestCase
{
    use RefreshDatabase;

    /**
     * @return array<string, array{0: string, 1: string}>
     */
    public static function disks(): array
    {
        return [
            'local disk' => ['local', 'r2'],
            'r2 disk' => ['r2', 'local'],
        ];
    }

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RoleSeeder::class);
        $this->seed(SubscriptionPlanSeeder::class);
        Storage::fake('local');
        Storage::fake('r2');
    }

    private function useDisk(string $disk): void
    {
        config(['filesystems.app_files_disk' => $disk]);
    }

    private function actingAsTenantUser(Tenant $tenant, ?string $role = 'admin'): User
    {
        $user = User::factory()->create();
        $user->tenant()->associate($tenant);
        $user->save();

        if ($role !== null) {
            $user->assignRole($role);
        }

        Sanctum::actingAs($user, ['*']);

        return $user;
    }

    private function makeCustomer(Tenant $tenant): Customer
    {
        return Customer::factory()->for($tenant, 'tenant')->create();
    }

    private function makeDebt(Tenant $tenant): Debt
    {
        $customer = Customer::factory()->for($tenant, 'tenant')->create(['credit_limit' => 5000]);

        return Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create();
    }

    /**
     * Replaces the disk with one whose writes fail, standing in for a full
     * disk or an unreachable bucket.
     */
    private function failWritesOn(string $disk): void
    {
        $failing = Mockery::mock(FilesystemAdapter::class);
        $failing->shouldReceive('fileExists')->andReturn(false);
        $failing->shouldReceive('put')->andReturn(false);
        Storage::set($disk, $failing);
    }

    private function uploadCustomerAttachment(Customer $customer): TestResponse
    {
        return $this->post("/api/v1/customers/{$customer->id}/attachments", [
            'file' => UploadedFile::fake()->create('id-card.pdf', 100, 'application/pdf'),
        ]);
    }

    // --- Disk selection: uploads, generated documents, logos ---

    #[DataProvider('disks')]
    public function test_an_attachment_is_stored_on_the_selected_disk_only(string $disk, string $other): void
    {
        $this->useDisk($disk);
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->makeCustomer($tenant);
        $this->actingAsTenantUser($tenant);

        $response = $this->uploadCustomerAttachment($customer)->assertStatus(201);

        $this->assertCount(1, Storage::disk($disk)->allFiles("documents/{$tenant->id}/customer_attachments"));
        $this->assertCount(0, Storage::disk($other)->allFiles());
        $this->assertDatabaseHas('customer_attachments', ['id' => $response->json('data.id')]);
    }

    public function test_the_local_disk_is_used_when_the_setting_is_absent(): void
    {
        config(['filesystems.app_files_disk' => null]);
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->makeCustomer($tenant);
        $this->actingAsTenantUser($tenant);

        $this->uploadCustomerAttachment($customer)->assertStatus(201);

        $this->assertCount(1, Storage::disk('local')->allFiles());
        $this->assertCount(0, Storage::disk('r2')->allFiles());
    }

    #[DataProvider('disks')]
    public function test_a_generated_document_is_stored_and_downloaded_from_the_selected_disk(string $disk, string $other): void
    {
        $this->useDisk($disk);
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);

        $letterId = $this->postJson("/api/v1/debts/{$debt->id}/demand-letters", ['template_type' => 'first_reminder'])
            ->assertStatus(201)
            ->json('data.id');

        $this->assertCount(1, Storage::disk($disk)->allFiles());
        $this->assertCount(0, Storage::disk($other)->allFiles());

        $response = $this->get("/api/v1/documents/{$letterId}/download")->assertStatus(200);
        $this->assertSame('application/pdf', $response->headers->get('content-type'));
        $this->assertDatabaseHas('document_events', ['document_id' => $letterId, 'event_type' => 'downloaded']);
    }

    #[DataProvider('disks')]
    public function test_the_company_logo_is_stored_on_the_selected_disk_and_counted_in_storage_usage(string $disk, string $other): void
    {
        $this->useDisk($disk);
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $this->post('/api/v1/admin/settings/company-profile', [
            '_method' => 'PUT',
            'business_name' => 'Acme Trading Co',
            'logo' => UploadedFile::fake()->image('logo.png'),
        ])->assertStatus(200);

        Storage::disk($disk)->assertExists("branding/{$tenant->id}/logo.png");
        Storage::disk($other)->assertMissing("branding/{$tenant->id}/logo.png");
        $this->assertGreaterThan(0, $this->getJson('/api/v1/documents/storage-usage')->json('data.used_bytes'));
    }

    // --- Failed writes: no database row ---

    #[DataProvider('disks')]
    public function test_a_failed_write_returns_503_and_saves_no_database_row(string $disk): void
    {
        $this->useDisk($disk);
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->makeCustomer($tenant);
        $this->actingAsTenantUser($tenant);
        $this->failWritesOn($disk);

        $this->uploadCustomerAttachment($customer)
            ->assertStatus(503)
            ->assertJsonPath('success', false)
            ->assertJsonPath('message', 'File storage is temporarily unavailable. Please try again.');

        $this->assertDatabaseCount('customer_attachments', 0);
    }

    #[DataProvider('disks')]
    public function test_a_failed_pdf_write_saves_no_document_row(string $disk): void
    {
        $this->useDisk($disk);
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);
        $this->failWritesOn($disk);

        $this->postJson("/api/v1/debts/{$debt->id}/demand-letters", ['template_type' => 'first_reminder'])
            ->assertStatus(503);

        $this->assertDatabaseCount('demand_letters', 0);
    }

    // --- Rollback cleanup ---

    #[DataProvider('disks')]
    public function test_the_stored_object_is_removed_when_the_database_transaction_rolls_back(string $disk): void
    {
        $this->useDisk($disk);
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->makeCustomer($tenant);
        $this->actingAsTenantUser($tenant);
        $this->mock(AuditLogService::class, fn ($mock) => $mock->shouldReceive('record')->andThrow(new RuntimeException('audit write failed')));

        $this->uploadCustomerAttachment($customer)->assertStatus(500);

        $this->assertDatabaseCount('customer_attachments', 0);
        $this->assertCount(0, Storage::disk($disk)->allFiles(), 'The uploaded object was left behind after the rollback.');
    }

    // --- Delete ---

    #[DataProvider('disks')]
    public function test_deleting_an_attachment_removes_the_object_from_the_selected_disk(string $disk): void
    {
        $this->useDisk($disk);
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->makeCustomer($tenant);
        $this->actingAsTenantUser($tenant);
        $attachmentId = $this->uploadCustomerAttachment($customer)->json('data.id');
        $this->assertCount(1, Storage::disk($disk)->allFiles());

        $this->deleteJson("/api/v1/customers/{$customer->id}/attachments/{$attachmentId}")->assertStatus(200);

        $this->assertCount(0, Storage::disk($disk)->allFiles());
        $this->assertDatabaseMissing('customer_attachments', ['id' => $attachmentId]);
    }

    // --- Missing files: 404, not 500 ---

    #[DataProvider('disks')]
    public function test_downloading_a_document_whose_file_is_gone_returns_404_and_records_nothing(string $disk): void
    {
        $this->useDisk($disk);
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);
        $letterId = $this->postJson("/api/v1/debts/{$debt->id}/demand-letters", ['template_type' => 'first_reminder'])->json('data.id');
        Storage::disk($disk)->delete(DemandLetter::findOrFail($letterId)->file_path);

        $this->get("/api/v1/documents/{$letterId}/download")->assertStatus(404);

        $this->assertDatabaseMissing('document_events', ['document_id' => $letterId, 'event_type' => 'downloaded']);
    }

    #[DataProvider('disks')]
    public function test_downloading_a_ticket_attachment_whose_file_is_gone_returns_404(string $disk): void
    {
        $this->useDisk($disk);
        $tenant = Tenant::factory()->create();
        $this->actingAsTenantUser($tenant);
        $ticketId = $this->postJson('/api/v1/support-tickets', [
            'subject' => 'Cannot generate demand letter',
            'description' => 'The demand letter PDF fails to download.',
            'priority' => 'high',
            'category' => 'technical_issue',
        ])->json('data.id');
        $attachmentId = $this->postJson("/api/v1/support-tickets/{$ticketId}/attachments", [
            'file' => UploadedFile::fake()->create('screenshot.pdf', 100, 'application/pdf'),
        ])->json('data.id');

        $this->get("/api/v1/support-tickets/{$ticketId}/attachments/{$attachmentId}/download")->assertStatus(200);

        Storage::disk($disk)->delete(SupportTicketAttachment::findOrFail($attachmentId)->file_path);

        $this->get("/api/v1/support-tickets/{$ticketId}/attachments/{$attachmentId}/download")->assertStatus(404);
    }

    #[DataProvider('disks')]
    public function test_an_unreachable_disk_is_a_503_not_a_404_on_download(string $disk): void
    {
        $this->useDisk($disk);
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);
        $letterId = $this->postJson("/api/v1/debts/{$debt->id}/demand-letters", ['template_type' => 'first_reminder'])->json('data.id');

        $unreachable = Mockery::mock(FilesystemAdapter::class);
        $unreachable->shouldReceive('fileExists')->andThrow(new RuntimeException('bucket unreachable'));
        Storage::set($disk, $unreachable);

        $this->getJson("/api/v1/documents/{$letterId}/download")->assertStatus(503);
    }

    // --- Authorization and tenant isolation on downloads ---

    #[DataProvider('disks')]
    public function test_another_tenants_document_cannot_be_downloaded(string $disk): void
    {
        $this->useDisk($disk);
        $tenantA = Tenant::create(['business_name' => 'Tenant A']);
        $tenantB = Tenant::create(['business_name' => 'Tenant B']);
        $debtB = $this->makeDebt($tenantB);
        $letterB = DemandLetter::factory()->for($tenantB, 'tenant')->for($debtB, 'debt')->create();
        Storage::disk($disk)->put($letterB->file_path, 'tenant B pdf');
        $this->actingAsTenantUser($tenantA);

        $this->get("/api/v1/documents/{$letterB->id}/download")->assertStatus(404);

        $this->assertDatabaseMissing('document_events', ['document_id' => $letterB->id, 'event_type' => 'downloaded']);
    }

    #[DataProvider('disks')]
    public function test_a_user_without_the_admin_role_cannot_download_a_document_that_exists(string $disk): void
    {
        $this->useDisk($disk);
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);
        $letterId = $this->postJson("/api/v1/debts/{$debt->id}/demand-letters", ['template_type' => 'first_reminder'])->json('data.id');

        $this->actingAsTenantUser($tenant, null);

        $this->get("/api/v1/documents/{$letterId}/download")->assertStatus(403);
    }

    #[DataProvider('disks')]
    public function test_downloads_require_authentication(string $disk): void
    {
        $this->useDisk($disk);
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $letter = DemandLetter::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create();
        Storage::disk($disk)->put($letter->file_path, 'pdf');

        $this->getJson("/api/v1/documents/{$letter->id}/download")->assertStatus(401);
    }

    #[DataProvider('disks')]
    public function test_another_tenants_ticket_attachment_cannot_be_downloaded(string $disk): void
    {
        $this->useDisk($disk);
        $tenantA = Tenant::factory()->create();
        $tenantB = Tenant::factory()->create();
        $ownerB = User::factory()->create();
        $ownerB->tenant()->associate($tenantB);
        $ownerB->save();
        $ticketB = SupportTicket::factory()->create(['tenant_id' => $tenantB->id, 'submitted_by_user_id' => $ownerB->id]);
        $attachmentB = SupportTicketAttachment::factory()->create([
            'support_ticket_id' => $ticketB->id,
            'uploaded_by_user_id' => $ownerB->id,
        ]);
        Storage::disk($disk)->put($attachmentB->file_path, 'tenant B file');
        $this->actingAsTenantUser($tenantA);

        $this->get("/api/v1/support-tickets/{$ticketB->id}/attachments/{$attachmentB->id}/download")->assertStatus(404);
    }

    // --- Dashboard file-storage health ---

    #[DataProvider('disks')]
    public function test_the_dashboard_reports_file_storage_operational_for_a_healthy_disk(string $disk): void
    {
        $this->useDisk($disk);

        $this->assertTrue($this->fileStorageHealth());
    }

    public function test_the_dashboard_reports_a_reachable_object_store_as_operational_even_when_the_bucket_is_empty(): void
    {
        $this->useDisk('r2');
        $store = Mockery::mock(FilesystemAdapter::class);
        $store->shouldReceive('fileExists')->with('.deendoon-health-probe')->andReturn(false);
        Storage::set('r2', $store);

        $this->assertTrue($this->fileStorageHealth());
    }

    public function test_the_dashboard_reports_an_unreachable_object_store_as_down(): void
    {
        $this->useDisk('r2');
        $store = Mockery::mock(FilesystemAdapter::class);
        $store->shouldReceive('fileExists')->andThrow(new RuntimeException('403 Forbidden'));
        Storage::set('r2', $store);

        $this->assertFalse($this->fileStorageHealth());
    }

    public function test_the_dashboard_reports_a_missing_local_root_as_down(): void
    {
        $this->useDisk('local');
        $local = Mockery::mock(FilesystemAdapter::class);
        $local->shouldReceive('exists')->with('')->andReturn(false);
        Storage::set('local', $local);

        $this->assertFalse($this->fileStorageHealth());
    }

    private function fileStorageHealth(): bool
    {
        $entry = collect(app(AdminDashboardService::class)->systemHealth())->firstWhere('name', 'File Storage');

        return $entry['operational'];
    }
}
