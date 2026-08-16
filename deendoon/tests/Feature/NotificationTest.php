<?php

namespace Tests\Feature;

use App\Models\Customer;
use App\Models\Debt;
use App\Models\Notification;
use App\Models\PromiseToPay;
use App\Models\ReferenceData;
use App\Models\SystemSetting;
use App\Models\Tenant;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Database\Seeders\SubscriptionPlanSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class NotificationTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RoleSeeder::class);
        // Backend Completion Roadmap (Phase 4.2): document generation
        // (which several "document_available" notification tests trigger)
        // now fails closed without a resolvable plan.
        $this->seed(SubscriptionPlanSeeder::class);
        Storage::fake('local');
    }

    private function actingAsTenantUser(Tenant $tenant, string $role = 'admin'): User
    {
        $user = User::factory()->create();
        $user->tenant()->associate($tenant);
        $user->save();
        $user->assignRole($role);

        $token = $user->createToken('test')->plainTextToken;
        $this->withHeader('Authorization', 'Bearer '.$token);

        return $user;
    }

    private function actingAsPlatformAdmin(): User
    {
        $admin = User::factory()->create();
        $admin->assignRole('deendoon_platform_administrator');

        Sanctum::actingAs($admin, ['*']);

        return $admin;
    }

    private function makeDebt(Tenant $tenant, array $attributes = []): Debt
    {
        $customer = Customer::factory()->for($tenant, 'tenant')->create(['credit_limit' => 5000]);

        return Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create($attributes);
    }

    /**
     * @return array<string, mixed>
     */
    private function submitPcrPayload(Tenant $tenant): array
    {
        ReferenceData::factory()->for($tenant, 'tenant')->create(['category' => 'transfer_reason', 'value_label' => 'Non-payment']);
        ReferenceData::factory()->for($tenant, 'tenant')->create(['category' => 'requested_service', 'value_label' => 'Field Visit']);

        return ['reasons' => ['Non-payment'], 'services' => ['Field Visit'], 'declaration_accepted' => true];
    }

    // --- Generation (FR-058) ---

    public function test_recording_a_payment_creates_a_payment_received_notification(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant, ['amount' => 1000, 'remaining_balance' => 1000]);
        $user = $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/debts/{$debt->id}/payments", ['amount' => 400, 'payment_date' => now()->toDateString()])->assertStatus(201);

        $this->assertDatabaseHas('notifications', [
            'recipient_user_id' => (string) $user->id, 'type' => 'payment_received', 'related_entity_type' => 'payment',
        ]);
    }

    public function test_recording_a_payment_creates_a_document_available_notification_for_the_receipt(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant, ['amount' => 1000, 'remaining_balance' => 1000]);
        $user = $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/debts/{$debt->id}/payments", ['amount' => 400, 'payment_date' => now()->toDateString()])->assertStatus(201);

        $this->assertDatabaseHas('notifications', [
            'recipient_user_id' => (string) $user->id, 'type' => 'document_available', 'related_entity_type' => 'receipt',
        ]);
    }

    public function test_generating_a_demand_letter_creates_a_document_available_notification(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $user = $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/debts/{$debt->id}/demand-letters", ['template_type' => 'first_reminder'])->assertStatus(201);

        $this->assertDatabaseHas('notifications', [
            'recipient_user_id' => (string) $user->id, 'type' => 'document_available', 'related_entity_type' => 'demand_letter',
        ]);
    }

    public function test_generating_a_statement_creates_a_document_available_notification(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $user = $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/customers/{$customer->id}/statements")->assertStatus(201);

        $this->assertDatabaseHas('notifications', [
            'recipient_user_id' => (string) $user->id, 'type' => 'document_available', 'related_entity_type' => 'statement',
        ]);
    }

    public function test_logging_a_manual_reminder_creates_a_reminder_sent_notification(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $user = $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/debts/{$debt->id}/reminders/call", [])->assertStatus(200);

        $this->assertDatabaseHas('notifications', [
            'recipient_user_id' => (string) $user->id, 'type' => 'reminder_sent', 'related_entity_type' => 'debt', 'related_entity_id' => $debt->id,
        ]);
    }

    public function test_exceeding_credit_limit_notifies_every_admin_user_in_the_tenant(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $admin = $this->actingAsTenantUser($tenant, 'admin');
        $secondAdmin = User::factory()->create();
        $secondAdmin->tenant()->associate($tenant);
        $secondAdmin->save();
        $secondAdmin->assignRole('admin');

        $customer = Customer::factory()->for($tenant, 'tenant')->create(['credit_limit' => 500]);

        // Debt creation triggers CustomerBalanceService::recalculate(),
        // which dispatches CreditLimitReached once outstanding exceeds the
        // limit (BRL-023).
        $this->postJson("/api/v1/customers/{$customer->id}/debts", [
            'amount' => 1000, 'due_date' => now()->addDays(10)->toDateString(),
        ])->assertStatus(201);

        $this->assertDatabaseHas('notifications', ['recipient_user_id' => (string) $admin->id, 'type' => 'credit_limit_reached']);
        $this->assertDatabaseHas('notifications', ['recipient_user_id' => (string) $secondAdmin->id, 'type' => 'credit_limit_reached']);
    }

    public function test_transitioning_a_professional_collection_request_status_notifies_the_submitting_tenant_user(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $submitter = $this->actingAsTenantUser($tenant);
        $caseId = $this->postJson("/api/v1/debts/{$debt->id}/collection-cases")->json('data.id');
        $pcrId = $this->postJson("/api/v1/collection-cases/{$caseId}/professional-requests", $this->submitPcrPayload($tenant))->json('data.id');

        $this->actingAsPlatformAdmin();
        $this->patchJson("/api/v1/professional-requests/{$pcrId}/status", ['status' => 'under_review'])->assertStatus(200);

        $this->assertDatabaseHas('notifications', [
            'recipient_user_id' => (string) $submitter->id, 'type' => 'professional_collection_request_update', 'related_entity_id' => $pcrId,
        ]);
    }

    public function test_platform_admin_posting_a_message_notifies_the_submitting_tenant_user(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $submitter = $this->actingAsTenantUser($tenant);
        $caseId = $this->postJson("/api/v1/debts/{$debt->id}/collection-cases")->json('data.id');
        $pcrId = $this->postJson("/api/v1/collection-cases/{$caseId}/professional-requests", $this->submitPcrPayload($tenant))->json('data.id');

        $this->actingAsPlatformAdmin();
        $this->postJson("/api/v1/professional-requests/{$pcrId}/messages", ['content' => 'Reviewing now.'])->assertStatus(201);

        $this->assertDatabaseHas('notifications', [
            'recipient_user_id' => (string) $submitter->id, 'type' => 'professional_collection_request_update',
        ]);
    }

    public function test_tenant_user_posting_a_message_does_not_notify_the_platform_administrator(): void
    {
        // Documents a known, schema-level gap: notifications.tenant_id is
        // NOT NULL and the Platform Administrator has none, so this
        // direction cannot be represented — no exception should be thrown,
        // and simply no notification is created for this action.
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);
        $caseId = $this->postJson("/api/v1/debts/{$debt->id}/collection-cases")->json('data.id');
        $pcrId = $this->postJson("/api/v1/collection-cases/{$caseId}/professional-requests", $this->submitPcrPayload($tenant))->json('data.id');

        $countBefore = Notification::count();

        $this->postJson("/api/v1/professional-requests/{$pcrId}/messages", ['content' => 'Please review.'])->assertStatus(201);

        $this->assertSame($countBefore, Notification::count());
    }

    public function test_promise_to_pay_due_notification_is_created_only_once(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $creator = $this->actingAsTenantUser($tenant);
        $promise = PromiseToPay::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create([
            'promised_date' => now()->toDateString(),
            'status' => 'open',
            'created_by_user_id' => (string) $creator->id,
        ]);

        $this->getJson("/api/v1/debts/{$debt->id}")->assertStatus(200);
        $this->getJson("/api/v1/debts/{$debt->id}")->assertStatus(200);
        $this->getJson("/api/v1/debts/{$debt->id}")->assertStatus(200);

        $count = Notification::where('type', 'promise_to_pay_due')->where('related_entity_id', $promise->id)->count();
        $this->assertSame(1, $count);
        $this->assertDatabaseHas('notifications', ['recipient_user_id' => (string) $creator->id, 'type' => 'promise_to_pay_due']);
    }

    // --- Read/Unread (FR-059) ---

    public function test_admin_can_mark_a_notification_as_read(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $user = $this->actingAsTenantUser($tenant);
        $notification = Notification::factory()->for($tenant, 'tenant')->create(['recipient_user_id' => (string) $user->id]);

        $response = $this->patchJson("/api/v1/notifications/{$notification->id}/read");

        $response->assertStatus(200)->assertJsonPath('data.read_at', fn ($value) => $value !== null);
        $this->assertNotNull($notification->fresh()->read_at);
    }

    public function test_admin_can_mark_all_notifications_as_read(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $user = $this->actingAsTenantUser($tenant);
        $first = Notification::factory()->for($tenant, 'tenant')->create(['recipient_user_id' => (string) $user->id]);
        $second = Notification::factory()->for($tenant, 'tenant')->create(['recipient_user_id' => (string) $user->id]);

        $this->patchJson('/api/v1/notifications/mark-all-read')->assertStatus(200);

        $this->assertNotNull($first->fresh()->read_at);
        $this->assertNotNull($second->fresh()->read_at);
    }

    public function test_marking_read_does_not_remove_the_notification_from_history(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $user = $this->actingAsTenantUser($tenant);
        $notification = Notification::factory()->for($tenant, 'tenant')->create(['recipient_user_id' => (string) $user->id]);

        $this->patchJson("/api/v1/notifications/{$notification->id}/read")->assertStatus(200);

        $response = $this->getJson('/api/v1/notifications/history');
        $ids = collect($response->json('data.notifications'))->pluck('id');
        $this->assertTrue($ids->contains($notification->id));
    }

    // --- Filter (FR-060) ---

    public function test_notifications_can_be_filtered_by_type(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $user = $this->actingAsTenantUser($tenant);
        Notification::factory()->for($tenant, 'tenant')->create(['recipient_user_id' => (string) $user->id, 'type' => 'payment_received']);
        Notification::factory()->for($tenant, 'tenant')->create(['recipient_user_id' => (string) $user->id, 'type' => 'document_available']);

        $response = $this->getJson('/api/v1/notifications?type=payment_received');

        $types = collect($response->json('data.notifications'))->pluck('type');
        $this->assertSame(['payment_received'], $types->unique()->values()->all());
    }

    // --- History (FR-061) ---

    public function test_notification_history_includes_already_read_notifications(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $user = $this->actingAsTenantUser($tenant);
        $notification = Notification::factory()->for($tenant, 'tenant')->create(['recipient_user_id' => (string) $user->id, 'read_at' => now()]);

        $response = $this->getJson('/api/v1/notifications/history');

        $ids = collect($response->json('data.notifications'))->pluck('id');
        $this->assertTrue($ids->contains($notification->id));
    }

    // --- Authentication / Authorization / Isolation ---

    public function test_unauthenticated_requests_are_rejected(): void
    {
        $this->getJson('/api/v1/notifications')->assertStatus(401);
        $this->patchJson('/api/v1/notifications/mark-all-read')->assertStatus(401);
    }

    public function test_a_user_cannot_mark_another_users_notification_as_read(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $owner = User::factory()->create();
        $owner->tenant()->associate($tenant);
        $owner->save();
        $notification = Notification::factory()->for($tenant, 'tenant')->create(['recipient_user_id' => (string) $owner->id]);

        $this->actingAsTenantUser($tenant);
        $this->patchJson("/api/v1/notifications/{$notification->id}/read")->assertStatus(404);
    }

    public function test_notifications_are_scoped_to_the_recipient(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $userA = $this->actingAsTenantUser($tenant);
        $userB = User::factory()->create();
        $userB->tenant()->associate($tenant);
        $userB->save();

        Notification::factory()->for($tenant, 'tenant')->create(['recipient_user_id' => (string) $userA->id]);
        Notification::factory()->for($tenant, 'tenant')->create(['recipient_user_id' => (string) $userB->id]);

        $response = $this->getJson('/api/v1/notifications');

        $this->assertCount(1, $response->json('data.notifications'));
    }

    // --- Notification preferences (Module 9) ---

    public function test_reminder_notification_is_suppressed_when_reminder_preference_is_disabled(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $user = $this->actingAsTenantUser($tenant);
        SystemSetting::factory()->for($tenant, 'tenant')->create(['notification_settings' => ['reminder_enabled' => false]]);

        $this->postJson("/api/v1/debts/{$debt->id}/reminders/call", [])->assertStatus(200);

        $this->assertDatabaseMissing('notifications', [
            'recipient_user_id' => (string) $user->id, 'type' => 'reminder_sent',
        ]);
    }

    public function test_payment_notification_is_suppressed_when_payment_preference_is_disabled(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant, ['amount' => 1000, 'remaining_balance' => 1000]);
        $user = $this->actingAsTenantUser($tenant);
        SystemSetting::factory()->for($tenant, 'tenant')->create(['notification_settings' => ['payment_enabled' => false]]);

        $this->postJson("/api/v1/debts/{$debt->id}/payments", ['amount' => 400, 'payment_date' => now()->toDateString()])->assertStatus(201);

        $this->assertDatabaseMissing('notifications', [
            'recipient_user_id' => (string) $user->id, 'type' => 'payment_received',
        ]);
        // The receipt's document_available notification is a different,
        // always-on type — unaffected by the payment_enabled toggle.
        $this->assertDatabaseHas('notifications', [
            'recipient_user_id' => (string) $user->id, 'type' => 'document_available', 'related_entity_type' => 'receipt',
        ]);
    }

    public function test_reminder_notification_is_created_when_notification_settings_column_is_null(): void
    {
        // Fail-open: a tenant that saved Settings before this module shipped
        // (or has never touched Settings at all) must not silently stop
        // receiving reminder/payment notifications.
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $user = $this->actingAsTenantUser($tenant);
        SystemSetting::factory()->for($tenant, 'tenant')->create(['notification_settings' => null]);

        $this->postJson("/api/v1/debts/{$debt->id}/reminders/call", [])->assertStatus(200);

        $this->assertDatabaseHas('notifications', [
            'recipient_user_id' => (string) $user->id, 'type' => 'reminder_sent',
        ]);
    }

    public function test_credit_limit_reached_notification_is_unaffected_by_disabled_preferences(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $admin = $this->actingAsTenantUser($tenant, 'admin');
        SystemSetting::factory()->for($tenant, 'tenant')->create([
            'notification_settings' => ['reminder_enabled' => false, 'payment_enabled' => false],
        ]);
        $customer = Customer::factory()->for($tenant, 'tenant')->create(['credit_limit' => 500]);

        $this->postJson("/api/v1/customers/{$customer->id}/debts", [
            'amount' => 1000, 'due_date' => now()->addDays(10)->toDateString(),
        ])->assertStatus(201);

        $this->assertDatabaseHas('notifications', ['recipient_user_id' => (string) $admin->id, 'type' => 'credit_limit_reached']);
    }

    // --- Delete (Module 9) ---

    public function test_admin_can_delete_their_own_notification(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $user = $this->actingAsTenantUser($tenant);
        $notification = Notification::factory()->for($tenant, 'tenant')->create(['recipient_user_id' => (string) $user->id]);

        $this->deleteJson("/api/v1/notifications/{$notification->id}")->assertStatus(200);

        $this->assertDatabaseMissing('notifications', ['id' => $notification->id]);
    }

    public function test_a_user_cannot_delete_another_users_notification(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $owner = User::factory()->create();
        $owner->tenant()->associate($tenant);
        $owner->save();
        $notification = Notification::factory()->for($tenant, 'tenant')->create(['recipient_user_id' => (string) $owner->id]);

        $this->actingAsTenantUser($tenant);
        $this->deleteJson("/api/v1/notifications/{$notification->id}")->assertStatus(404);

        $this->assertDatabaseHas('notifications', ['id' => $notification->id]);
    }

    public function test_deleting_a_notification_removes_it_from_the_list(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $user = $this->actingAsTenantUser($tenant);
        $notification = Notification::factory()->for($tenant, 'tenant')->create(['recipient_user_id' => (string) $user->id]);

        $this->deleteJson("/api/v1/notifications/{$notification->id}")->assertStatus(200);

        $response = $this->getJson('/api/v1/notifications');
        $ids = collect($response->json('data.notifications'))->pluck('id');
        $this->assertFalse($ids->contains($notification->id));
    }

    // --- Admin Announcement content (Module 9) ---

    public function test_admin_announcement_notification_includes_title_and_message(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $user = $this->actingAsTenantUser($tenant);
        Notification::factory()->for($tenant, 'tenant')->create([
            'recipient_user_id' => (string) $user->id,
            'type' => 'admin_announcement',
            'title' => 'Scheduled maintenance',
            'message' => 'The platform will be briefly unavailable tonight.',
            'related_entity_type' => 'announcement',
        ]);

        $response = $this->getJson('/api/v1/notifications');

        $notification = collect($response->json('data.notifications'))->firstWhere('type', 'admin_announcement');
        $this->assertSame('Scheduled maintenance', $notification['title']);
        $this->assertSame('The platform will be briefly unavailable tonight.', $notification['message']);
    }
}
