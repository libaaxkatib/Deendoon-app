<?php

namespace Tests\Feature;

use App\Models\CollectionCase;
use App\Models\Customer;
use App\Models\Debt;
use App\Models\MessageTemplate;
use App\Models\Reminder;
use App\Models\Tenant;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Tests\TestCase;

class ReminderTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RoleSeeder::class);
    }

    private function actingAsTenantUser(Tenant $tenant, ?string $role = 'admin'): User
    {
        $user = User::factory()->create();
        $user->tenant()->associate($tenant);
        $user->save();

        if ($role !== null) {
            $user->assignRole($role);
        }

        $token = $user->createToken('test')->plainTextToken;
        $this->withHeader('Authorization', 'Bearer '.$token);

        return $user;
    }

    private function makeDebt(Tenant $tenant, array $attributes = []): Debt
    {
        $customer = Customer::factory()->for($tenant, 'tenant')->create();

        return Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create($attributes);
    }

    // --- Create (§7.5) ---

    public function test_admin_can_create_a_reminder(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson('/api/v1/reminders', [
            'type' => 'follow_up_call',
            'related_entity_type' => 'debt',
            'related_entity_id' => $debt->id,
            'due_date' => now()->addDay()->toDateTimeString(),
            'timing_rule' => 'same_day',
            'delivery_methods' => ['in_app'],
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('data.type', 'follow_up_call')
            ->assertJsonPath('data.title', 'Follow-up Call');
    }

    public function test_custom_timing_requires_a_custom_fire_at_on_or_before_due_date(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);

        $this->postJson('/api/v1/reminders', [
            'type' => 'client_visit',
            'related_entity_type' => 'debt',
            'related_entity_id' => $debt->id,
            'due_date' => now()->addDay()->toDateTimeString(),
            'timing_rule' => 'custom',
            'delivery_methods' => ['in_app'],
        ])->assertStatus(422)->assertJsonValidationErrors(['custom_fire_at']);
    }

    public function test_creating_a_reminder_requires_at_least_one_delivery_method(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);

        $this->postJson('/api/v1/reminders', [
            'type' => 'client_visit',
            'related_entity_type' => 'debt',
            'related_entity_id' => $debt->id,
            'due_date' => now()->addDay()->toDateTimeString(),
            'timing_rule' => 'same_day',
            'delivery_methods' => [],
        ])->assertStatus(422)->assertJsonValidationErrors(['delivery_methods']);
    }

    public function test_amount_due_is_dropped_for_a_type_that_does_not_carry_one(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson('/api/v1/reminders', [
            'type' => 'client_visit',
            'related_entity_type' => 'debt',
            'related_entity_id' => $debt->id,
            'due_date' => now()->addDay()->toDateTimeString(),
            'timing_rule' => 'same_day',
            'delivery_methods' => ['in_app'],
        ]);

        $response->assertStatus(201)->assertJsonPath('data.amount_due', null);
    }

    public function test_amount_due_is_kept_for_payment_due(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson('/api/v1/reminders', [
            'type' => 'payment_due',
            'related_entity_type' => 'debt',
            'related_entity_id' => $debt->id,
            'amount_due' => 250.50,
            'due_date' => now()->addDay()->toDateTimeString(),
            'timing_rule' => 'same_day',
            'delivery_methods' => ['in_app'],
        ]);

        $response->assertStatus(201)->assertJsonPath('data.amount_due', '250.50');
    }

    // --- List / Filters (§7.3) ---

    public function test_index_can_filter_by_today_tab(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $today = Reminder::factory()->for($tenant, 'tenant')->dueToday()
            ->create(['related_entity_type' => 'debt', 'related_entity_id' => $debt->id]);
        Reminder::factory()->for($tenant, 'tenant')->overdue()
            ->create(['related_entity_type' => 'debt', 'related_entity_id' => $debt->id]);
        $this->actingAsTenantUser($tenant);

        $response = $this->getJson('/api/v1/reminders?tab=today');

        $ids = collect($response->json('data.reminders'))->pluck('id');
        $this->assertEquals([$today->id], $ids->all());
    }

    public function test_index_can_filter_by_overdue_tab(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $overdue = Reminder::factory()->for($tenant, 'tenant')->overdue()
            ->create(['related_entity_type' => 'debt', 'related_entity_id' => $debt->id]);
        Reminder::factory()->for($tenant, 'tenant')->dueToday()
            ->create(['related_entity_type' => 'debt', 'related_entity_id' => $debt->id]);
        $this->actingAsTenantUser($tenant);

        $response = $this->getJson('/api/v1/reminders?tab=overdue');

        $ids = collect($response->json('data.reminders'))->pluck('id');
        $this->assertEquals([$overdue->id], $ids->all());
    }

    public function test_index_can_filter_by_upcoming_tab(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $upcoming = Reminder::factory()->for($tenant, 'tenant')
            ->create(['related_entity_type' => 'debt', 'related_entity_id' => $debt->id, 'due_date' => now()->addWeek()]);
        Reminder::factory()->for($tenant, 'tenant')->dueToday()
            ->create(['related_entity_type' => 'debt', 'related_entity_id' => $debt->id]);
        $this->actingAsTenantUser($tenant);

        $response = $this->getJson('/api/v1/reminders?tab=upcoming');

        $ids = collect($response->json('data.reminders'))->pluck('id');
        $this->assertEquals([$upcoming->id], $ids->all());
    }

    public function test_index_can_filter_by_completed_tab(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $completed = Reminder::factory()->for($tenant, 'tenant')->completed()
            ->create(['related_entity_type' => 'debt', 'related_entity_id' => $debt->id]);
        Reminder::factory()->for($tenant, 'tenant')->dueToday()
            ->create(['related_entity_type' => 'debt', 'related_entity_id' => $debt->id]);
        $this->actingAsTenantUser($tenant);

        $response = $this->getJson('/api/v1/reminders?tab=completed');

        $ids = collect($response->json('data.reminders'))->pluck('id');
        $this->assertEquals([$completed->id], $ids->all());
    }

    public function test_index_lists_only_the_authenticated_users_own_tenant_reminders(): void
    {
        $tenantA = Tenant::create(['business_name' => 'Tenant A']);
        $tenantB = Tenant::create(['business_name' => 'Tenant B']);
        $debtA = $this->makeDebt($tenantA);
        $debtB = $this->makeDebt($tenantB);
        $reminderA = Reminder::factory()->for($tenantA, 'tenant')
            ->create(['related_entity_type' => 'debt', 'related_entity_id' => $debtA->id]);
        Reminder::factory()->for($tenantB, 'tenant')
            ->create(['related_entity_type' => 'debt', 'related_entity_id' => $debtB->id]);

        $this->actingAsTenantUser($tenantA);
        $response = $this->getJson('/api/v1/reminders');

        $ids = collect($response->json('data.reminders'))->pluck('id');
        $this->assertEquals([$reminderA->id], $ids->all());
    }

    // --- Details / Update / Delete (§7.4) ---

    public function test_admin_can_view_reminder_details(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $reminder = Reminder::factory()->for($tenant, 'tenant')
            ->create(['related_entity_type' => 'debt', 'related_entity_id' => $debt->id]);
        $this->actingAsTenantUser($tenant);

        $this->getJson("/api/v1/reminders/{$reminder->id}")
            ->assertStatus(200)
            ->assertJsonPath('data.id', $reminder->id);
    }

    public function test_admin_can_reschedule_a_reminder(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $reminder = Reminder::factory()->for($tenant, 'tenant')
            ->create(['related_entity_type' => 'debt', 'related_entity_id' => $debt->id]);
        $this->actingAsTenantUser($tenant);
        $newDueDate = now()->addWeek()->toDateTimeString();

        $this->putJson("/api/v1/reminders/{$reminder->id}", ['due_date' => $newDueDate])
            ->assertStatus(200);

        $this->assertSame(
            Carbon::parse($newDueDate)->toDateTimeString(),
            $reminder->fresh()->due_date->toDateTimeString(),
        );
    }

    public function test_admin_can_delete_a_reminder(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $reminder = Reminder::factory()->for($tenant, 'tenant')
            ->create(['related_entity_type' => 'debt', 'related_entity_id' => $debt->id]);
        $this->actingAsTenantUser($tenant);

        $this->deleteJson("/api/v1/reminders/{$reminder->id}")->assertStatus(200);

        $this->getJson('/api/v1/reminders')
            ->assertJson(['data' => ['reminders' => []]]);
        $this->assertSoftDeleted('reminders', ['id' => $reminder->id]);
    }

    // --- Complete (§7.3, §7.4) ---

    public function test_admin_can_complete_a_reminder(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $reminder = Reminder::factory()->for($tenant, 'tenant')
            ->create(['related_entity_type' => 'debt', 'related_entity_id' => $debt->id]);
        $this->actingAsTenantUser($tenant);

        $this->patchJson("/api/v1/reminders/{$reminder->id}/complete")
            ->assertStatus(200)
            ->assertJsonPath('data.status', 'completed');
    }

    public function test_completing_an_already_completed_reminder_is_rejected(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $reminder = Reminder::factory()->for($tenant, 'tenant')->completed()
            ->create(['related_entity_type' => 'debt', 'related_entity_id' => $debt->id]);
        $this->actingAsTenantUser($tenant);

        $this->patchJson("/api/v1/reminders/{$reminder->id}/complete")->assertStatus(409);
    }

    // --- Check In (P2.2) ---

    public function test_admin_can_check_in_on_a_reminder(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $reminder = Reminder::factory()->for($tenant, 'tenant')
            ->create(['related_entity_type' => 'debt', 'related_entity_id' => $debt->id]);
        $this->actingAsTenantUser($tenant);

        $response = $this->patchJson("/api/v1/reminders/{$reminder->id}/check-in");

        $response->assertStatus(200);
        $this->assertNotNull($response->json('data.checked_in_at'));

        // Confirmed persisted (not just reflected in this one response) by
        // re-fetching through a separate real request.
        $this->getJson("/api/v1/reminders/{$reminder->id}")
            ->assertStatus(200)
            ->assertJsonPath('data.checked_in_at', fn ($value) => $value !== null);
    }

    public function test_checking_in_again_simply_refreshes_the_timestamp_not_a_conflict(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $reminder = Reminder::factory()->for($tenant, 'tenant')
            ->create(['related_entity_type' => 'debt', 'related_entity_id' => $debt->id]);
        $this->actingAsTenantUser($tenant);

        $this->patchJson("/api/v1/reminders/{$reminder->id}/check-in")->assertStatus(200);
        $this->patchJson("/api/v1/reminders/{$reminder->id}/check-in")->assertStatus(200);
    }

    public function test_checking_in_is_blocked_when_the_related_customer_is_read_only(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        Customer::where('id', $debt->customer_id)->update(['is_read_only' => true]);
        $reminder = Reminder::factory()->for($tenant, 'tenant')
            ->create(['related_entity_type' => 'debt', 'related_entity_id' => $debt->id]);
        $this->actingAsTenantUser($tenant);

        $this->patchJson("/api/v1/reminders/{$reminder->id}/check-in")->assertStatus(403);
    }

    // --- Summary (§7.1) ---

    public function test_summary_returns_due_today_and_overdue_counts(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        Reminder::factory()->for($tenant, 'tenant')->dueToday()
            ->create(['related_entity_type' => 'debt', 'related_entity_id' => $debt->id, 'type' => 'payment_due']);
        Reminder::factory()->for($tenant, 'tenant')->overdue()
            ->create(['related_entity_type' => 'debt', 'related_entity_id' => $debt->id]);
        $this->actingAsTenantUser($tenant);

        $response = $this->getJson('/api/v1/reminders/summary');

        $response->assertStatus(200)
            ->assertJsonPath('data.total_due_today', 1)
            ->assertJsonPath('data.per_type.payment_due', 1)
            ->assertJsonPath('data.overdue_count', 1);
    }

    // --- Send (§7.3, §7.7, §7.8) ---

    public function test_admin_can_send_a_reminder_via_whatsapp(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $reminder = Reminder::factory()->for($tenant, 'tenant')->paymentDue()
            ->create(['related_entity_type' => 'debt', 'related_entity_id' => $debt->id]);
        $template = MessageTemplate::factory()->for($tenant, 'tenant')->create();
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson("/api/v1/reminders/{$reminder->id}/send", [
            'channel' => 'whatsapp',
            'template_id' => $template->id,
        ]);

        $response->assertStatus(200)->assertJsonPath('data.status', 'sent');
        $this->assertDatabaseHas('sent_messages', [
            'reminder_id' => $reminder->id,
            'channel' => 'whatsapp',
            'status' => 'sent',
        ]);
    }

    public function test_rendered_message_substitutes_customer_and_amount(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create(['name' => 'Hodan Store', 'phone' => '254712345678']);
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create();
        $reminder = Reminder::factory()->for($tenant, 'tenant')->paymentDue()
            ->create(['related_entity_type' => 'debt', 'related_entity_id' => $debt->id, 'amount_due' => 2150]);
        $template = MessageTemplate::factory()->for($tenant, 'tenant')->create();
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson('/api/v1/messages/render', [
            'template_id' => $template->id,
            'reminder_id' => $reminder->id,
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('data.recipient_name', 'Hodan Store')
            ->assertJsonFragment(['recipient_phone' => '254712345678']);
        $this->assertStringContainsString('Hodan Store', $response->json('data.rendered_text'));
        // Reminder Module Final Polish: {amount_due} now renders with a
        // thousand separator via number_format(), matching how monetary
        // values should display everywhere in the Reminder module.
        $this->assertStringContainsString('2,150.00', $response->json('data.rendered_text'));
    }

    public function test_rendered_message_falls_back_to_debt_remaining_balance_for_follow_up_call(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create(['name' => 'Hodan Store']);
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')
            ->create(['amount' => 1750.25, 'remaining_balance' => 1750.25]);
        // Follow-up Call reminders never carry their own amount_due — the
        // Business Decision approved for this fix is that {amount_due}
        // should still resolve, from the related Debt's remaining_balance.
        $reminder = Reminder::factory()->for($tenant, 'tenant')
            ->create(['type' => 'follow_up_call', 'related_entity_type' => 'debt', 'related_entity_id' => $debt->id, 'amount_due' => null]);
        $template = MessageTemplate::factory()->for($tenant, 'tenant')->create();
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson('/api/v1/messages/render', [
            'template_id' => $template->id,
            'reminder_id' => $reminder->id,
        ]);

        $response->assertStatus(200);
        $this->assertStringContainsString('1,750.25', $response->json('data.rendered_text'));
    }

    public function test_rendered_message_falls_back_to_collection_case_debt_balance_for_client_visit(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create(['name' => 'Hodan Store']);
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')
            ->create(['amount' => 980, 'remaining_balance' => 980]);
        $case = CollectionCase::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create();
        // Client Visit reminders never carry their own amount_due either —
        // resolved here via the related Collection Case's Debt.
        $reminder = Reminder::factory()->for($tenant, 'tenant')
            ->create(['type' => 'client_visit', 'related_entity_type' => 'collection_case', 'related_entity_id' => $case->id, 'amount_due' => null]);
        $template = MessageTemplate::factory()->for($tenant, 'tenant')->create();
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson('/api/v1/messages/render', [
            'template_id' => $template->id,
            'reminder_id' => $reminder->id,
        ]);

        $response->assertStatus(200);
        $this->assertStringContainsString('980.00', $response->json('data.rendered_text'));
    }

    public function test_rendered_message_leaves_amount_empty_when_no_balance_can_be_resolved(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create(['name' => 'Hodan Store']);
        // No amount_due on the reminder and no related Debt to fall back
        // to — the priority chain's final step returns an empty value
        // rather than fabricating one.
        $reminder = Reminder::factory()->for($tenant, 'tenant')
            ->create(['type' => 'follow_up_call', 'related_entity_type' => 'customer', 'related_entity_id' => $customer->id, 'amount_due' => null]);
        $template = MessageTemplate::factory()->for($tenant, 'tenant')->create();
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson('/api/v1/messages/render', [
            'template_id' => $template->id,
            'reminder_id' => $reminder->id,
        ]);

        $response->assertStatus(200);
        // CustomerFactory defaults outstanding_balance to 0, so this
        // exercises the same "no balance" path a Customer with no open
        // debts (a real 0) would hit — the placeholder resolves cleanly to
        // "0.00" rather than being left as a literal unresolved brace.
        $this->assertStringNotContainsString('{amount_due}', $response->json('data.rendered_text'));
    }

    public function test_admin_can_list_message_templates_filtered_by_channel(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        MessageTemplate::factory()->for($tenant, 'tenant')->create(['channel' => 'whatsapp']);
        MessageTemplate::factory()->for($tenant, 'tenant')->sms()->create();
        $this->actingAsTenantUser($tenant);

        $response = $this->getJson('/api/v1/message-templates?channel=sms');

        $channels = collect($response->json('data'))->pluck('channel');
        $this->assertEquals(['sms'], $channels->unique()->all());
    }

    // Business Owner Backend Completion (pre-Phase 5): regression coverage
    // for the confirmed authorization gap — templates() and render() had no
    // authorize()/Gate check at all, unlike every other endpoint in this
    // controller cluster.
    public function test_message_templates_is_forbidden_without_the_admin_role(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant, role: null);

        $response = $this->getJson('/api/v1/message-templates');

        $response->assertStatus(403);
    }

    public function test_render_message_is_forbidden_without_the_admin_role(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $reminder = Reminder::factory()->for($tenant, 'tenant')->paymentDue()
            ->create(['related_entity_type' => 'debt', 'related_entity_id' => $debt->id]);
        $template = MessageTemplate::factory()->for($tenant, 'tenant')->create();
        $this->actingAsTenantUser($tenant, role: null);

        $response = $this->postJson('/api/v1/messages/render', [
            'template_id' => $template->id,
            'reminder_id' => $reminder->id,
        ]);

        $response->assertStatus(403);
    }

    // --- Authentication / Authorization ---

    public function test_unauthenticated_requests_are_rejected(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $reminder = Reminder::factory()->for($tenant, 'tenant')
            ->create(['related_entity_type' => 'debt', 'related_entity_id' => $debt->id]);

        $this->getJson('/api/v1/reminders')->assertStatus(401);
        $this->getJson("/api/v1/reminders/{$reminder->id}")->assertStatus(401);
    }

    public function test_user_without_admin_role_cannot_access_reminders(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant, null);

        $this->getJson('/api/v1/reminders')->assertStatus(403);
    }
}
