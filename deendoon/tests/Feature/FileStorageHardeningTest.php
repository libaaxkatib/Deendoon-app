<?php

namespace Tests\Feature;

use App\Exceptions\FileStorageException;
use App\Models\Customer;
use App\Models\Debt;
use App\Models\Tenant;
use App\Models\User;
use App\Services\AdminSettingsService;
use App\Services\DocumentService;
use Barryvdh\DomPDF\Facade\Pdf;
use Barryvdh\DomPDF\PDF as PdfWrapper;
use Database\Seeders\RoleSeeder;
use Database\Seeders\SubscriptionPlanSeeder;
use Illuminate\Filesystem\FilesystemAdapter;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Mockery;
use PHPUnit\Framework\Attributes\DataProvider;
use RuntimeException;
use Tests\TestCase;

/**
 * R2 Step 1b hardening. Read-only endpoints that include the company logo
 * in storage usage must survive an unreachable file disk, while the upload
 * gate stays strict; unreadable or empty source files must never produce an
 * empty stored object or a database row. Fakes and mocks only — no real
 * bucket is contacted.
 */
class FileStorageHardeningTest extends TestCase
{
    use RefreshDatabase;

    private const SECRET = 'SECRET-ENDPOINT-abc.r2.cloudflarestorage.com refused the connection';

    /**
     * @return array<string, array{0: string}>
     */
    public static function disks(): array
    {
        return ['local disk' => ['local'], 'r2 disk' => ['r2']];
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

    private function actingAsTenantAdmin(Tenant $tenant): User
    {
        $user = User::factory()->create();
        $user->tenant()->associate($tenant);
        $user->save();
        $user->assignRole('admin');
        Sanctum::actingAs($user, ['*']);

        return $user;
    }

    /**
     * A disk that cannot be reached: every existence check throws, and a
     * write must never be attempted.
     */
    private function unreachable(string $disk): void
    {
        $mock = Mockery::mock(FilesystemAdapter::class);
        $mock->shouldReceive('fileExists')->andThrow(new RuntimeException(self::SECRET));
        $mock->shouldNotReceive('put');
        Storage::set($disk, $mock);
    }

    private function tenantWithLogo(): Tenant
    {
        return Tenant::create(['business_name' => 'Acme Co', 'logo_path' => 'branding/acme/logo.png']);
    }

    // --- M3: read-only endpoints survive an outage ---

    #[DataProvider('disks')]
    public function test_storage_usage_and_subscription_endpoints_survive_an_unreachable_disk(string $disk): void
    {
        $this->useDisk($disk);
        $tenant = $this->tenantWithLogo();
        $this->actingAsTenantAdmin($tenant);
        Log::spy();
        $this->unreachable($disk);

        $usage = $this->getJson('/api/v1/documents/storage-usage')->assertStatus(200);
        $this->assertSame(0, $usage->json('data.used_bytes'));

        foreach (['/api/v1/subscription', '/api/v1/subscription/storage'] as $uri) {
            $response = $this->getJson($uri)->assertStatus(200);
            $this->assertStringNotContainsString('SECRET-ENDPOINT', $response->getContent());
        }

        $this->assertStringNotContainsString('SECRET-ENDPOINT', $usage->getContent());
        Log::shouldHaveReceived('warning')
            ->withArgs(fn (string $message, array $context) => ($context['tenant_id'] ?? null) === $tenant->id
                && ($context['exception'] ?? null) === RuntimeException::class)
            ->atLeast()->once();
    }

    #[DataProvider('disks')]
    public function test_a_healthy_disk_still_counts_the_logo_in_usage(string $disk): void
    {
        $this->useDisk($disk);
        $tenant = $this->tenantWithLogo();
        $this->actingAsTenantAdmin($tenant);
        Storage::disk($disk)->put('branding/acme/logo.png', str_repeat('a', 1234));

        $this->getJson('/api/v1/documents/storage-usage')
            ->assertStatus(200)
            ->assertJsonPath('data.used_bytes', 1234);
    }

    #[DataProvider('disks')]
    public function test_the_upload_gate_stays_strict_during_an_outage(string $disk): void
    {
        $this->useDisk($disk);
        $tenant = $this->tenantWithLogo();
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $this->actingAsTenantAdmin($tenant);
        $this->unreachable($disk);

        $response = $this->post("/api/v1/customers/{$customer->id}/attachments", [
            'file' => UploadedFile::fake()->create('id-card.pdf', 100, 'application/pdf'),
        ])->assertStatus(503)->assertJsonPath('message', FileStorageException::USER_MESSAGE);

        $this->assertStringNotContainsString('SECRET-ENDPOINT', $response->getContent());
        $this->assertDatabaseCount('customer_attachments', 0);
    }

    #[DataProvider('disks')]
    public function test_an_unmeasurable_logo_refuses_the_upload_instead_of_under_counting_usage(string $disk): void
    {
        // Only the logo-size read fails; writing would succeed. A lenient
        // gate would treat the logo as 0 bytes and accept the upload, so a
        // 503 here proves the gate itself is strict, independent of the
        // write failing.
        $this->useDisk($disk);
        $tenant = $this->tenantWithLogo();
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $this->actingAsTenantAdmin($tenant);

        $mock = Mockery::mock(FilesystemAdapter::class);
        $mock->shouldReceive('fileExists')->with('branding/acme/logo.png')->andThrow(new RuntimeException(self::SECRET));
        $mock->shouldReceive('fileExists')->andReturn(false);
        $mock->shouldNotReceive('put');
        Storage::set($disk, $mock);

        $this->post("/api/v1/customers/{$customer->id}/attachments", [
            'file' => UploadedFile::fake()->create('id-card.pdf', 100, 'application/pdf'),
        ])->assertStatus(503);

        $this->assertDatabaseCount('customer_attachments', 0);
    }

    #[DataProvider('disks')]
    public function test_usage_is_lenient_for_readers_and_strict_for_the_gate_at_service_level(string $disk): void
    {
        $this->useDisk($disk);
        $tenant = $this->tenantWithLogo();
        $this->unreachable($disk);
        $documents = app(DocumentService::class);

        $this->assertSame(0, $documents->storageUsage($tenant)['used_bytes']);

        $this->expectException(FileStorageException::class);
        $documents->storageUsage($tenant, failOnStorageError: true);
    }

    // --- L2: unreadable or empty sources never become stored objects ---

    #[DataProvider('disks')]
    public function test_an_unreadable_upload_stores_nothing(string $disk): void
    {
        $this->useDisk($disk);
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $unreadable = new UploadedFile('/nonexistent/dir/missing.pdf', 'missing.pdf', 'application/pdf', UPLOAD_ERR_NO_TMP_DIR, true);

        try {
            app(DocumentService::class)->storeUploadedFile($unreadable, $tenant, 'debt_attachments');
            $this->fail('Expected a FileStorageException.');
        } catch (FileStorageException) {
            // expected
        }

        $this->assertCount(0, Storage::disk($disk)->allFiles(), 'An empty object was stored for an unreadable upload.');
    }

    #[DataProvider('disks')]
    public function test_an_unreadable_logo_changes_nothing(string $disk): void
    {
        $this->useDisk($disk);
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $actor = User::factory()->create();
        $logo = Mockery::mock(UploadedFile::class);
        $logo->shouldReceive('extension')->andReturn('png');
        $logo->shouldReceive('getRealPath')->andReturn(false);

        try {
            app(AdminSettingsService::class)->updateCompanyProfile($tenant, ['business_name' => 'Renamed Co'], $logo, $actor);
            $this->fail('Expected a FileStorageException.');
        } catch (FileStorageException) {
            // expected
        }

        $this->assertCount(0, Storage::disk($disk)->allFiles());
        $this->assertNull($tenant->fresh()->logo_path);
    }

    #[DataProvider('disks')]
    public function test_a_pdf_that_renders_to_nothing_stores_no_object_and_no_document_row(string $disk): void
    {
        $this->useDisk($disk);
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create(['credit_limit' => 5000]);
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create();
        $this->actingAsTenantAdmin($tenant);

        // The wrapper's output() is typed `string` and casts a dompdf
        // failure (null) to '', so '' is what a failed render looks like.
        // The mock must be the real wrapper class: loadView() is typed to
        // return it, and a plain mock would 500 for the wrong reason.
        $rendered = Mockery::mock(PdfWrapper::class);
        $rendered->shouldReceive('output')->once()->andReturn('');
        Pdf::shouldReceive('loadView')->once()->andReturn($rendered);

        $this->postJson("/api/v1/debts/{$debt->id}/demand-letters", ['template_type' => 'first_reminder'])
            ->assertStatus(500);

        $this->assertDatabaseCount('demand_letters', 0);
        $this->assertCount(0, Storage::disk($disk)->allFiles());
    }
}
