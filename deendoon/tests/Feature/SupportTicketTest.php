<?php

namespace Tests\Feature;

use App\Models\SupportTicket;
use App\Models\Tenant;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Database\Seeders\SubscriptionPlanSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * Module 7 — Support & Tickets, Business Owner-facing API. Mirrors
 * ProfessionalCollectionRequestTest's Sanctum::actingAs() convention —
 * this module also needs genuine mid-test identity switches (Business
 * Owner creates, Platform Administrator replies/closes, within the same
 * test).
 */
class SupportTicketTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RoleSeeder::class);
        $this->seed(SubscriptionPlanSeeder::class);
        Storage::fake('local');
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

    private function actingAsPlatformAdmin(): User
    {
        $admin = User::factory()->create();
        $admin->assignRole('deendoon_platform_administrator');

        Sanctum::actingAs($admin, ['*']);

        return $admin;
    }

    /**
     * @return array<string, mixed>
     */
    private function ticketPayload(array $overrides = []): array
    {
        return array_merge([
            'subject' => 'Cannot generate demand letter',
            'description' => 'The demand letter PDF fails to download.',
            'priority' => 'high',
            'category' => 'technical_issue',
        ], $overrides);
    }

    // --- Creation ---

    public function test_business_owner_can_create_a_ticket(): void
    {
        $tenant = Tenant::factory()->create();
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson('/api/v1/support-tickets', $this->ticketPayload());

        $response->assertStatus(201)
            ->assertJsonPath('data.subject', 'Cannot generate demand letter')
            ->assertJsonPath('data.status', 'open')
            ->assertJsonPath('data.priority', 'high')
            ->assertJsonPath('data.category', 'technical_issue')
            ->assertJsonPath('data.reference_number', 'SUP-000001');
    }

    public function test_reference_numbers_increment_per_tenant(): void
    {
        $tenant = Tenant::factory()->create();
        $this->actingAsTenantUser($tenant);

        $this->postJson('/api/v1/support-tickets', $this->ticketPayload());
        $second = $this->postJson('/api/v1/support-tickets', $this->ticketPayload());

        $second->assertJsonPath('data.reference_number', 'SUP-000002');
    }

    public function test_platform_administrator_cannot_create_a_ticket(): void
    {
        $this->actingAsPlatformAdmin();

        $this->postJson('/api/v1/support-tickets', $this->ticketPayload())->assertForbidden();
    }

    public function test_creating_a_ticket_requires_subject_description_priority_and_category(): void
    {
        $tenant = Tenant::factory()->create();
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson('/api/v1/support-tickets', []);

        $response->assertStatus(422)->assertJsonValidationErrors(['subject', 'description', 'priority', 'category']);
    }

    public function test_priority_must_be_one_of_the_approved_values(): void
    {
        $tenant = Tenant::factory()->create();
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson('/api/v1/support-tickets', $this->ticketPayload(['priority' => 'critical']));

        $response->assertStatus(422)->assertJsonValidationErrors(['priority']);
    }

    public function test_category_must_be_one_of_the_approved_values(): void
    {
        $tenant = Tenant::factory()->create();
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson('/api/v1/support-tickets', $this->ticketPayload(['category' => 'random']));

        $response->assertStatus(422)->assertJsonValidationErrors(['category']);
    }

    public function test_creating_a_ticket_notifies_the_submitting_business_owner(): void
    {
        $tenant = Tenant::factory()->create();
        $user = $this->actingAsTenantUser($tenant);

        $ticketId = $this->postJson('/api/v1/support-tickets', $this->ticketPayload())->json('data.id');

        $this->assertDatabaseHas('notifications', [
            'recipient_user_id' => (string) $user->id,
            'type' => 'support_ticket_created',
            'related_entity_type' => 'support_ticket',
            'related_entity_id' => $ticketId,
            'tenant_id' => $tenant->id,
        ]);
    }

    // --- Visibility / tenant isolation ---

    public function test_business_owner_can_view_own_tickets(): void
    {
        $tenant = Tenant::factory()->create();
        $this->actingAsTenantUser($tenant);
        $this->postJson('/api/v1/support-tickets', $this->ticketPayload());
        $this->postJson('/api/v1/support-tickets', $this->ticketPayload(['subject' => 'Second issue']));

        $response = $this->getJson('/api/v1/support-tickets');

        $response->assertOk();
        $this->assertCount(2, $response->json('data.tickets'));
    }

    public function test_business_owner_cannot_view_another_tenants_ticket(): void
    {
        $tenantA = Tenant::factory()->create();
        $this->actingAsTenantUser($tenantA);
        $ticketId = $this->postJson('/api/v1/support-tickets', $this->ticketPayload())->json('data.id');

        $tenantB = Tenant::factory()->create();
        $this->actingAsTenantUser($tenantB);

        $this->getJson("/api/v1/support-tickets/{$ticketId}")->assertNotFound();
    }

    public function test_business_owner_cannot_see_another_tenants_ticket_in_their_index(): void
    {
        $tenantA = Tenant::factory()->create();
        $this->actingAsTenantUser($tenantA);
        $this->postJson('/api/v1/support-tickets', $this->ticketPayload());

        $tenantB = Tenant::factory()->create();
        $this->actingAsTenantUser($tenantB);

        $response = $this->getJson('/api/v1/support-tickets');

        $this->assertCount(0, $response->json('data.tickets'));
    }

    public function test_platform_administrator_sees_tickets_across_every_tenant(): void
    {
        $tenantA = Tenant::factory()->create();
        $this->actingAsTenantUser($tenantA);
        $this->postJson('/api/v1/support-tickets', $this->ticketPayload());

        $tenantB = Tenant::factory()->create();
        $this->actingAsTenantUser($tenantB);
        $this->postJson('/api/v1/support-tickets', $this->ticketPayload());

        $this->actingAsPlatformAdmin();

        $response = $this->getJson('/api/v1/support-tickets');

        $this->assertCount(2, $response->json('data.tickets'));
    }

    public function test_guest_cannot_access_support_tickets(): void
    {
        $this->getJson('/api/v1/support-tickets')->assertUnauthorized();
    }

    // --- Conversation ---

    public function test_business_owner_can_reply_to_their_own_ticket(): void
    {
        $tenant = Tenant::factory()->create();
        $this->actingAsTenantUser($tenant);
        $ticketId = $this->postJson('/api/v1/support-tickets', $this->ticketPayload())->json('data.id');

        $response = $this->postJson("/api/v1/support-tickets/{$ticketId}/messages", ['content' => 'Any update?']);

        $response->assertStatus(201)->assertJsonPath('data.content', 'Any update?');
    }

    public function test_platform_administrator_can_reply_and_the_business_owner_is_notified(): void
    {
        $tenant = Tenant::factory()->create();
        $owner = $this->actingAsTenantUser($tenant);
        $ticketId = $this->postJson('/api/v1/support-tickets', $this->ticketPayload())->json('data.id');

        $this->actingAsPlatformAdmin();
        $this->postJson("/api/v1/support-tickets/{$ticketId}/messages", ['content' => 'We are looking into this.'])
            ->assertStatus(201);

        $this->assertDatabaseHas('notifications', [
            'recipient_user_id' => (string) $owner->id,
            'type' => 'support_ticket_replied',
            'related_entity_type' => 'support_ticket',
            'related_entity_id' => $ticketId,
        ]);
    }

    public function test_business_owner_replying_to_their_own_ticket_does_not_self_notify(): void
    {
        $tenant = Tenant::factory()->create();
        $owner = $this->actingAsTenantUser($tenant);
        $ticketId = $this->postJson('/api/v1/support-tickets', $this->ticketPayload())->json('data.id');

        $this->postJson("/api/v1/support-tickets/{$ticketId}/messages", ['content' => 'Adding more detail.']);

        $this->assertDatabaseMissing('notifications', [
            'recipient_user_id' => (string) $owner->id,
            'type' => 'support_ticket_replied',
        ]);
    }

    public function test_replying_to_another_tenants_ticket_is_rejected(): void
    {
        $tenantA = Tenant::factory()->create();
        $this->actingAsTenantUser($tenantA);
        $ticketId = $this->postJson('/api/v1/support-tickets', $this->ticketPayload())->json('data.id');

        $tenantB = Tenant::factory()->create();
        $this->actingAsTenantUser($tenantB);

        $this->postJson("/api/v1/support-tickets/{$ticketId}/messages", ['content' => 'Not mine.'])->assertNotFound();
    }

    // --- Status workflow ---

    public function test_platform_administrator_can_transition_status_through_the_approved_sequence(): void
    {
        $tenant = Tenant::factory()->create();
        $this->actingAsTenantUser($tenant);
        $ticketId = $this->postJson('/api/v1/support-tickets', $this->ticketPayload())->json('data.id');

        $this->actingAsPlatformAdmin();
        $response = $this->patchJson("/api/v1/support-tickets/{$ticketId}/status", ['status' => 'in_progress']);

        $response->assertOk()->assertJsonPath('data.status', 'in_progress');
    }

    public function test_business_owner_cannot_change_status(): void
    {
        $tenant = Tenant::factory()->create();
        $this->actingAsTenantUser($tenant);
        $ticketId = $this->postJson('/api/v1/support-tickets', $this->ticketPayload())->json('data.id');

        $this->patchJson("/api/v1/support-tickets/{$ticketId}/status", ['status' => 'in_progress'])->assertForbidden();
    }

    public function test_an_invalid_status_transition_is_rejected(): void
    {
        $tenant = Tenant::factory()->create();
        $this->actingAsTenantUser($tenant);
        $ticketId = $this->postJson('/api/v1/support-tickets', $this->ticketPayload())->json('data.id');

        $this->actingAsPlatformAdmin();
        $response = $this->patchJson("/api/v1/support-tickets/{$ticketId}/status", ['status' => 'resolved']);

        $response->assertStatus(409);
        $this->assertSame('open', SupportTicket::find($ticketId)->status);
    }

    public function test_status_change_notifies_the_business_owner(): void
    {
        $tenant = Tenant::factory()->create();
        $owner = $this->actingAsTenantUser($tenant);
        $ticketId = $this->postJson('/api/v1/support-tickets', $this->ticketPayload())->json('data.id');

        $this->actingAsPlatformAdmin();
        $this->patchJson("/api/v1/support-tickets/{$ticketId}/status", ['status' => 'in_progress']);

        $this->assertDatabaseHas('notifications', [
            'recipient_user_id' => (string) $owner->id,
            'type' => 'support_ticket_status_changed',
            'related_entity_id' => $ticketId,
        ]);
    }

    // --- Close / Reopen ---

    public function test_platform_administrator_can_close_a_ticket(): void
    {
        $tenant = Tenant::factory()->create();
        $owner = $this->actingAsTenantUser($tenant);
        $ticketId = $this->postJson('/api/v1/support-tickets', $this->ticketPayload())->json('data.id');

        $this->actingAsPlatformAdmin();
        $response = $this->postJson("/api/v1/support-tickets/{$ticketId}/close");

        $response->assertOk()->assertJsonPath('data.status', 'closed');
        $this->assertNotNull(SupportTicket::find($ticketId)->closed_at);
        $this->assertDatabaseHas('notifications', [
            'recipient_user_id' => (string) $owner->id,
            'type' => 'support_ticket_closed',
        ]);
    }

    public function test_business_owner_cannot_close_a_ticket(): void
    {
        $tenant = Tenant::factory()->create();
        $this->actingAsTenantUser($tenant);
        $ticketId = $this->postJson('/api/v1/support-tickets', $this->ticketPayload())->json('data.id');

        $this->postJson("/api/v1/support-tickets/{$ticketId}/close")->assertForbidden();
    }

    public function test_closing_an_already_closed_ticket_is_rejected(): void
    {
        $tenant = Tenant::factory()->create();
        $this->actingAsTenantUser($tenant);
        $ticketId = $this->postJson('/api/v1/support-tickets', $this->ticketPayload())->json('data.id');

        $this->actingAsPlatformAdmin();
        $this->postJson("/api/v1/support-tickets/{$ticketId}/close");
        $response = $this->postJson("/api/v1/support-tickets/{$ticketId}/close");

        $response->assertStatus(409);
    }

    public function test_platform_administrator_can_reopen_a_closed_ticket(): void
    {
        $tenant = Tenant::factory()->create();
        $owner = $this->actingAsTenantUser($tenant);
        $ticketId = $this->postJson('/api/v1/support-tickets', $this->ticketPayload())->json('data.id');

        $this->actingAsPlatformAdmin();
        $this->postJson("/api/v1/support-tickets/{$ticketId}/close");
        $response = $this->postJson("/api/v1/support-tickets/{$ticketId}/reopen");

        $response->assertOk()->assertJsonPath('data.status', 'open');
        $ticket = SupportTicket::find($ticketId);
        $this->assertNull($ticket->closed_at);
        $this->assertNotNull($ticket->reopened_at);
        $this->assertDatabaseHas('notifications', [
            'recipient_user_id' => (string) $owner->id,
            'type' => 'support_ticket_reopened',
        ]);
    }

    public function test_business_owner_cannot_reopen_a_ticket(): void
    {
        $tenant = Tenant::factory()->create();
        $this->actingAsTenantUser($tenant);
        $ticketId = $this->postJson('/api/v1/support-tickets', $this->ticketPayload())->json('data.id');

        $this->actingAsPlatformAdmin();
        $this->postJson("/api/v1/support-tickets/{$ticketId}/close");
        Sanctum::actingAs(User::where('tenant_id', $tenant->id)->firstOrFail(), ['*']);

        $this->postJson("/api/v1/support-tickets/{$ticketId}/reopen")->assertForbidden();
    }

    public function test_reopening_an_open_ticket_is_rejected(): void
    {
        $tenant = Tenant::factory()->create();
        $this->actingAsTenantUser($tenant);
        $ticketId = $this->postJson('/api/v1/support-tickets', $this->ticketPayload())->json('data.id');

        $this->actingAsPlatformAdmin();
        $response = $this->postJson("/api/v1/support-tickets/{$ticketId}/reopen");

        $response->assertStatus(409);
    }

    public function test_replies_are_rejected_on_a_closed_ticket(): void
    {
        $tenant = Tenant::factory()->create();
        $this->actingAsTenantUser($tenant);
        $ticketId = $this->postJson('/api/v1/support-tickets', $this->ticketPayload())->json('data.id');

        $this->actingAsPlatformAdmin();
        $this->postJson("/api/v1/support-tickets/{$ticketId}/close");

        $response = $this->postJson("/api/v1/support-tickets/{$ticketId}/messages", ['content' => 'Too late']);

        $response->assertStatus(409);
    }

    // --- Attachments ---

    public function test_business_owner_can_upload_an_allowed_attachment(): void
    {
        $tenant = Tenant::factory()->create();
        $this->actingAsTenantUser($tenant);
        $ticketId = $this->postJson('/api/v1/support-tickets', $this->ticketPayload())->json('data.id');

        $response = $this->postJson("/api/v1/support-tickets/{$ticketId}/attachments", [
            'file' => UploadedFile::fake()->create('screenshot.pdf', 100, 'application/pdf'),
        ]);

        $response->assertStatus(201)->assertJsonPath('data.original_filename', 'screenshot.pdf');
    }

    public function test_uploading_a_disallowed_file_type_is_rejected(): void
    {
        $tenant = Tenant::factory()->create();
        $this->actingAsTenantUser($tenant);
        $ticketId = $this->postJson('/api/v1/support-tickets', $this->ticketPayload())->json('data.id');

        $response = $this->postJson("/api/v1/support-tickets/{$ticketId}/attachments", [
            'file' => UploadedFile::fake()->create('script.exe', 100, 'application/x-msdownload'),
        ]);

        $response->assertStatus(422)->assertJsonValidationErrors(['file']);
    }

    public function test_platform_administrator_can_upload_an_attachment(): void
    {
        $tenant = Tenant::factory()->create();
        $this->actingAsTenantUser($tenant);
        $ticketId = $this->postJson('/api/v1/support-tickets', $this->ticketPayload())->json('data.id');

        $this->actingAsPlatformAdmin();
        $response = $this->postJson("/api/v1/support-tickets/{$ticketId}/attachments", [
            'file' => UploadedFile::fake()->create('log.pdf', 100, 'application/pdf'),
        ]);

        $response->assertStatus(201);
    }

    public function test_attachments_are_rejected_on_a_closed_ticket(): void
    {
        $tenant = Tenant::factory()->create();
        $this->actingAsTenantUser($tenant);
        $ticketId = $this->postJson('/api/v1/support-tickets', $this->ticketPayload())->json('data.id');

        $this->actingAsPlatformAdmin();
        $this->postJson("/api/v1/support-tickets/{$ticketId}/close");

        $response = $this->postJson("/api/v1/support-tickets/{$ticketId}/attachments", [
            'file' => UploadedFile::fake()->create('late.pdf', 100, 'application/pdf'),
        ]);

        $response->assertStatus(409);
    }

    public function test_uploading_an_attachment_to_another_tenants_ticket_is_rejected(): void
    {
        $tenantA = Tenant::factory()->create();
        $this->actingAsTenantUser($tenantA);
        $ticketId = $this->postJson('/api/v1/support-tickets', $this->ticketPayload())->json('data.id');

        $tenantB = Tenant::factory()->create();
        $this->actingAsTenantUser($tenantB);

        $response = $this->postJson("/api/v1/support-tickets/{$ticketId}/attachments", [
            'file' => UploadedFile::fake()->create('notmine.pdf', 100, 'application/pdf'),
        ]);

        $response->assertStatus(404);
    }

    // --- Attachment deletion (Mobile Fix #4A) ---

    public function test_the_business_owner_can_delete_their_own_attachment(): void
    {
        $tenant = Tenant::factory()->create();
        $this->actingAsTenantUser($tenant);
        $ticketId = $this->postJson('/api/v1/support-tickets', $this->ticketPayload())->json('data.id');
        $attachmentId = $this->postJson("/api/v1/support-tickets/{$ticketId}/attachments", [
            'file' => UploadedFile::fake()->create('screenshot.pdf', 100, 'application/pdf'),
        ])->json('data.id');

        $this->deleteJson("/api/v1/support-tickets/{$ticketId}/attachments/{$attachmentId}")->assertStatus(200);

        $this->assertDatabaseMissing('support_ticket_attachments', ['id' => $attachmentId]);
        $this->assertDatabaseHas('audit_log', [
            'action' => 'deleted', 'entity_type' => 'support_ticket_attachment', 'entity_id' => $attachmentId,
        ]);
    }

    public function test_the_platform_administrator_can_delete_their_own_attachment(): void
    {
        $tenant = Tenant::factory()->create();
        $this->actingAsTenantUser($tenant);
        $ticketId = $this->postJson('/api/v1/support-tickets', $this->ticketPayload())->json('data.id');

        $this->actingAsPlatformAdmin();
        $attachmentId = $this->postJson("/api/v1/support-tickets/{$ticketId}/attachments", [
            'file' => UploadedFile::fake()->create('log.pdf', 100, 'application/pdf'),
        ])->json('data.id');

        $this->deleteJson("/api/v1/support-tickets/{$ticketId}/attachments/{$attachmentId}")->assertStatus(200);

        $this->assertDatabaseMissing('support_ticket_attachments', ['id' => $attachmentId]);
    }

    public function test_the_business_owner_cannot_delete_an_attachment_uploaded_by_the_platform_administrator(): void
    {
        $tenant = Tenant::factory()->create();
        $owner = $this->actingAsTenantUser($tenant);
        $ticketId = $this->postJson('/api/v1/support-tickets', $this->ticketPayload())->json('data.id');

        $this->actingAsPlatformAdmin();
        $attachmentId = $this->postJson("/api/v1/support-tickets/{$ticketId}/attachments", [
            'file' => UploadedFile::fake()->create('log.pdf', 100, 'application/pdf'),
        ])->json('data.id');

        Sanctum::actingAs($owner, ['*']);

        $this->deleteJson("/api/v1/support-tickets/{$ticketId}/attachments/{$attachmentId}")->assertStatus(403);
        $this->assertDatabaseHas('support_ticket_attachments', ['id' => $attachmentId]);
    }

    public function test_the_platform_administrator_cannot_delete_an_attachment_uploaded_by_the_business_owner(): void
    {
        $tenant = Tenant::factory()->create();
        $this->actingAsTenantUser($tenant);
        $ticketId = $this->postJson('/api/v1/support-tickets', $this->ticketPayload())->json('data.id');
        $attachmentId = $this->postJson("/api/v1/support-tickets/{$ticketId}/attachments", [
            'file' => UploadedFile::fake()->create('screenshot.pdf', 100, 'application/pdf'),
        ])->json('data.id');

        $this->actingAsPlatformAdmin();

        $this->deleteJson("/api/v1/support-tickets/{$ticketId}/attachments/{$attachmentId}")->assertStatus(403);
        $this->assertDatabaseHas('support_ticket_attachments', ['id' => $attachmentId]);
    }

    public function test_an_attachment_cannot_be_deleted_once_the_ticket_is_closed(): void
    {
        $tenant = Tenant::factory()->create();
        $this->actingAsTenantUser($tenant);
        $ticketId = $this->postJson('/api/v1/support-tickets', $this->ticketPayload())->json('data.id');
        $attachmentId = $this->postJson("/api/v1/support-tickets/{$ticketId}/attachments", [
            'file' => UploadedFile::fake()->create('screenshot.pdf', 100, 'application/pdf'),
        ])->json('data.id');

        $this->actingAsPlatformAdmin();
        $this->postJson("/api/v1/support-tickets/{$ticketId}/close");

        $this->deleteJson("/api/v1/support-tickets/{$ticketId}/attachments/{$attachmentId}")->assertStatus(403);
        $this->assertDatabaseHas('support_ticket_attachments', ['id' => $attachmentId]);
    }

    public function test_deleting_an_attachment_on_another_tenants_ticket_is_rejected(): void
    {
        $tenantA = Tenant::factory()->create();
        $this->actingAsTenantUser($tenantA);
        $ticketId = $this->postJson('/api/v1/support-tickets', $this->ticketPayload())->json('data.id');
        $attachmentId = $this->postJson("/api/v1/support-tickets/{$ticketId}/attachments", [
            'file' => UploadedFile::fake()->create('screenshot.pdf', 100, 'application/pdf'),
        ])->json('data.id');

        $tenantB = Tenant::factory()->create();
        $this->actingAsTenantUser($tenantB);

        $this->deleteJson("/api/v1/support-tickets/{$ticketId}/attachments/{$attachmentId}")->assertStatus(404);
    }
}
