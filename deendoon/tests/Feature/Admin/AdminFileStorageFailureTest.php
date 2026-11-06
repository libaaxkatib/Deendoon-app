<?php

namespace Tests\Feature\Admin;

use App\Exceptions\FileStorageException;
use App\Models\CollectionCase;
use App\Models\Customer;
use App\Models\Debt;
use App\Models\ProfessionalCollectionRequest;
use App\Models\SupportTicket;
use App\Models\Tenant;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Database\Seeders\SubscriptionPlanSeeder;
use Illuminate\Filesystem\FilesystemAdapter;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Exceptions;
use Illuminate\Support\Facades\Storage;
use Mockery;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\TestCase;

/**
 * Admin Panel uploads when file storage is unavailable: the platform
 * administrator is sent back to the page with a plain message — never a
 * bare 500 page, and never a path, bucket or endpoint — and nothing is
 * saved. The failure is still reported for the log.
 */
class AdminFileStorageFailureTest extends TestCase
{
    use RefreshDatabase;

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

    private function platformAdmin(): User
    {
        $admin = User::factory()->create();
        $admin->assignRole('deendoon_platform_administrator');

        return $admin;
    }

    /**
     * A disk whose writes fail with a driver message that must never reach
     * the page.
     */
    private function failingWrites(string $disk): void
    {
        config(['filesystems.app_files_disk' => $disk]);
        $failing = Mockery::mock(FilesystemAdapter::class);
        $failing->shouldReceive('fileExists')->andReturn(false);
        $failing->shouldReceive('put')->andThrow(new \RuntimeException('SECRET-BUCKET at https://abc.r2.cloudflarestorage.com failed'));
        Storage::set($disk, $failing);
    }

    private function openTicket(): SupportTicket
    {
        $tenant = Tenant::factory()->create();
        $owner = User::factory()->create();
        $owner->tenant()->associate($tenant);
        $owner->save();

        return SupportTicket::factory()->create(['tenant_id' => $tenant->id, 'submitted_by_user_id' => $owner->id, 'status' => 'open']);
    }

    private function assignedRequest(): ProfessionalCollectionRequest
    {
        $tenant = Tenant::factory()->create();
        $owner = User::factory()->create();
        $owner->tenant()->associate($tenant);
        $owner->save();
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create();
        $case = CollectionCase::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create();

        return ProfessionalCollectionRequest::factory()->create([
            'tenant_id' => $tenant->id,
            'collection_case_id' => $case->id,
            'status' => 'assigned',
            'submitted_by_user_id' => $owner->id,
        ]);
    }

    private function assertSafeMessage(string $body): void
    {
        $this->assertStringNotContainsString('SECRET-BUCKET', $body);
        $this->assertStringNotContainsString('r2.cloudflarestorage.com', $body);
        $this->assertStringNotContainsString('documents/', $body);
    }

    #[DataProvider('disks')]
    public function test_a_failed_ticket_attachment_upload_redirects_back_with_a_clear_message(string $disk): void
    {
        Exceptions::fake();
        $this->failingWrites($disk);
        $ticket = $this->openTicket();
        $showUrl = route('admin.support-tickets.show', $ticket);

        $response = $this->actingAs($this->platformAdmin())
            ->from($showUrl)
            ->post(route('admin.support-tickets.attachments.store', $ticket), [
                'file' => UploadedFile::fake()->create('evidence.pdf', 100, 'application/pdf'),
            ]);

        $response->assertRedirect($showUrl);
        $response->assertSessionHasErrors(['file' => 'The attachment was not saved. '.FileStorageException::USER_MESSAGE]);
        $this->assertSafeMessage(json_encode(session('errors')->getBag('default')->all()));
        $this->assertDatabaseCount('support_ticket_attachments', 0);
        Exceptions::assertReported(FileStorageException::class);
    }

    public function test_the_message_is_shown_on_the_ticket_page_after_the_redirect(): void
    {
        $this->failingWrites('local');
        $ticket = $this->openTicket();
        $showUrl = route('admin.support-tickets.show', $ticket);

        $page = $this->actingAs($this->platformAdmin())
            ->from($showUrl)
            ->followingRedirects()
            ->post(route('admin.support-tickets.attachments.store', $ticket), [
                'file' => UploadedFile::fake()->create('evidence.pdf', 100, 'application/pdf'),
            ]);

        $page->assertOk()->assertSee('The attachment was not saved. '.FileStorageException::USER_MESSAGE);
        $this->assertSafeMessage($page->getContent());
    }

    #[DataProvider('disks')]
    public function test_a_failed_professional_collection_attachment_upload_redirects_back_with_a_clear_message(string $disk): void
    {
        Exceptions::fake();
        $this->failingWrites($disk);
        $pcr = $this->assignedRequest();
        $showUrl = route('admin.professional-collection.show', $pcr);

        $response = $this->actingAs($this->platformAdmin())
            ->from($showUrl)
            ->post(route('admin.professional-collection.attachments.store', $pcr), [
                'file' => UploadedFile::fake()->create('evidence.pdf', 100, 'application/pdf'),
            ]);

        $response->assertRedirect($showUrl);
        $response->assertSessionHasErrors(['file' => 'The attachment was not saved. '.FileStorageException::USER_MESSAGE]);
        $this->assertSafeMessage(json_encode(session('errors')->getBag('default')->all()));
        $this->assertDatabaseCount('professional_collection_request_attachments', 0);
        Exceptions::assertReported(FileStorageException::class);
    }

    #[DataProvider('disks')]
    public function test_a_timeline_event_with_a_failed_attachment_records_nothing(string $disk): void
    {
        Exceptions::fake();
        $this->failingWrites($disk);
        $pcr = $this->assignedRequest();
        $showUrl = route('admin.professional-collection.show', $pcr);

        $response = $this->actingAs($this->platformAdmin())
            ->from($showUrl)
            ->post(route('admin.professional-collection.timeline', $pcr), [
                'event_type' => 'telephone_collection',
                'notes' => 'Called the debtor.',
                'attachments' => [UploadedFile::fake()->create('call-note.pdf', 100, 'application/pdf')],
            ]);

        $response->assertRedirect($showUrl);
        $response->assertSessionHasErrors(['attachments' => 'The timeline event was not recorded. '.FileStorageException::USER_MESSAGE]);
        $this->assertSafeMessage(json_encode(session('errors')->getBag('default')->all()));
        $this->assertDatabaseCount('professional_collection_timeline_events', 0);
        $this->assertDatabaseCount('professional_collection_request_attachments', 0);
        Exceptions::assertReported(FileStorageException::class);
    }

    public function test_a_successful_admin_upload_is_unchanged(): void
    {
        $ticket = $this->openTicket();

        $this->actingAs($this->platformAdmin())
            ->post(route('admin.support-tickets.attachments.store', $ticket), [
                'file' => UploadedFile::fake()->create('evidence.pdf', 100, 'application/pdf'),
            ])
            ->assertRedirect(route('admin.support-tickets.show', $ticket))
            ->assertSessionHas('status', 'Attachment uploaded.');

        $this->assertDatabaseCount('support_ticket_attachments', 1);
    }
}
