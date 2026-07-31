<?php

namespace Tests\Feature;

use App\Events\PromiseBroken;
use App\Models\Customer;
use App\Models\Debt;
use App\Models\PromiseToPay;
use App\Models\Tenant;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Event;
use Tests\TestCase;

class RecoveryWorkflowTest extends TestCase
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

    // --- Follow-up History ---

    public function test_admin_can_view_followup_history(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/debts/{$debt->id}/reminders/call", ['details' => 'No answer']);

        $response = $this->getJson("/api/v1/debts/{$debt->id}/followup-history");

        $response->assertStatus(200);
        $this->assertSame('call_logged', $response->json('data.0.action_type'));
    }

    public function test_followup_history_returns_404_for_another_tenants_debt(): void
    {
        $tenantA = Tenant::create(['business_name' => 'Tenant A']);
        $tenantB = Tenant::create(['business_name' => 'Tenant B']);
        $debtB = $this->makeDebt($tenantB);

        $this->actingAsTenantUser($tenantA);

        $this->getJson("/api/v1/debts/{$debtB->id}/followup-history")->assertStatus(404);
    }

    // --- Manual Reminder (WhatsApp / SMS / Call) ---

    public function test_admin_can_send_a_manual_whatsapp_reminder(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson("/api/v1/debts/{$debt->id}/reminders/whatsapp", ['details' => 'Reminder sent']);

        $response->assertStatus(200)->assertJson(['success' => true]);
        $this->assertDatabaseHas('follow_up_history', ['debt_id' => $debt->id, 'action_type' => 'manual_whatsapp']);
        $this->assertDatabaseHas('audit_log', ['entity_id' => $debt->id, 'action' => 'reminder_sent']);
    }

    public function test_admin_can_send_a_manual_sms_reminder(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/debts/{$debt->id}/reminders/sms", [])->assertStatus(200);

        $this->assertDatabaseHas('follow_up_history', ['debt_id' => $debt->id, 'action_type' => 'manual_sms']);
    }

    public function test_a_call_with_no_outcome_is_still_recorded(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/debts/{$debt->id}/reminders/call", [])->assertStatus(200);

        $this->assertDatabaseHas('follow_up_history', [
            'debt_id' => $debt->id,
            'action_type' => 'call_logged',
            'details' => null,
        ]);
    }

    public function test_reminder_sent_while_overdue_advances_recovery_stage_to_2(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant, ['debt_status' => 'overdue', 'recovery_stage' => 1]);
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/debts/{$debt->id}/reminders/whatsapp", [])->assertStatus(200);

        $this->assertSame(2, $debt->fresh()->recovery_stage);
    }

    public function test_reminder_sent_while_not_overdue_does_not_advance_stage(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant, ['debt_status' => 'pending', 'recovery_stage' => 1]);
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/debts/{$debt->id}/reminders/whatsapp", [])->assertStatus(200);

        $this->assertSame(1, $debt->fresh()->recovery_stage);
    }

    public function test_logging_a_call_advances_recovery_stage_to_3(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant, ['recovery_stage' => 1]);
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/debts/{$debt->id}/reminders/call", [])->assertStatus(200);

        $this->assertSame(3, $debt->fresh()->recovery_stage);
    }

    // --- Promise to Pay ---

    public function test_admin_can_record_a_promise_to_pay(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson("/api/v1/debts/{$debt->id}/promise-to-pay", [
            'promised_date' => now()->addDays(7)->toDateString(),
        ]);

        $response->assertStatus(201)->assertJsonPath('data.status', 'open');
        $this->assertDatabaseHas('promises_to_pay', ['debt_id' => $debt->id, 'status' => 'open']);
        $this->assertDatabaseHas('follow_up_history', ['debt_id' => $debt->id, 'action_type' => 'promise_recorded']);
        $this->assertDatabaseHas('audit_log', ['entity_type' => 'promise_to_pay', 'action' => 'created']);
    }

    public function test_promise_to_pay_rejects_a_past_date(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/debts/{$debt->id}/promise-to-pay", [
            'promised_date' => now()->subDays(1)->toDateString(),
        ])->assertStatus(422)->assertJsonValidationErrors(['promised_date']);
    }

    public function test_promise_to_pay_requires_a_date(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/debts/{$debt->id}/promise-to-pay", [])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['promised_date']);
    }

    // --- Promise Broken (lazy transition + event + stage advancement) ---

    public function test_an_open_promise_past_its_date_transitions_to_broken_when_the_debt_is_viewed(): void
    {
        Event::fake([PromiseBroken::class]);

        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $promise = PromiseToPay::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create([
            'promised_date' => now()->subDays(2)->toDateString(),
            'status' => 'open',
        ]);
        $this->actingAsTenantUser($tenant);

        $response = $this->getJson("/api/v1/debts/{$debt->id}");

        $response->assertStatus(200);
        $this->assertSame('broken', $promise->fresh()->status);
        $this->assertNotNull($promise->fresh()->resolved_at);

        Event::assertDispatched(
            PromiseBroken::class,
            fn (PromiseBroken $event): bool => $event->promise->is($promise),
        );
    }

    public function test_broken_promise_records_followup_history_and_audit_entries(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $promise = PromiseToPay::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create([
            'promised_date' => now()->subDays(2)->toDateString(),
            'status' => 'open',
        ]);
        $this->actingAsTenantUser($tenant);

        $this->getJson("/api/v1/debts/{$debt->id}")->assertStatus(200);

        $this->assertDatabaseHas('follow_up_history', ['debt_id' => $debt->id, 'action_type' => 'promise_broken']);
        $this->assertDatabaseHas('audit_log', ['entity_type' => 'promise_to_pay', 'entity_id' => $promise->id, 'action' => 'status_changed']);
    }

    public function test_broken_promise_advances_recovery_stage_to_4(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant, ['recovery_stage' => 1]);
        PromiseToPay::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create([
            'promised_date' => now()->subDays(2)->toDateString(),
            'status' => 'open',
        ]);
        $this->actingAsTenantUser($tenant);

        $this->getJson("/api/v1/debts/{$debt->id}")->assertStatus(200);

        $this->assertSame(4, $debt->fresh()->recovery_stage);
    }

    public function test_broken_promise_does_not_downgrade_a_later_recovery_stage(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant, ['recovery_stage' => 5]);
        PromiseToPay::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create([
            'promised_date' => now()->subDays(2)->toDateString(),
            'status' => 'open',
        ]);
        $this->actingAsTenantUser($tenant);

        $this->getJson("/api/v1/debts/{$debt->id}")->assertStatus(200);

        $this->assertSame(5, $debt->fresh()->recovery_stage);
    }

    public function test_a_promise_not_yet_due_is_unaffected(): void
    {
        Event::fake([PromiseBroken::class]);

        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $promise = PromiseToPay::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create([
            'promised_date' => now()->addDays(5)->toDateString(),
            'status' => 'open',
        ]);
        $this->actingAsTenantUser($tenant);

        $this->getJson("/api/v1/debts/{$debt->id}")->assertStatus(200);

        $this->assertSame('open', $promise->fresh()->status);
        Event::assertNotDispatched(PromiseBroken::class);
    }

    // --- Timeline (now sourced from follow_up_history) ---

    public function test_timeline_shows_whatsapp_reminder_completed_after_sending_one(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/debts/{$debt->id}/reminders/whatsapp", [])->assertStatus(200);

        $response = $this->getJson("/api/v1/debts/{$debt->id}/timeline");

        $stages = collect($response->json('data.stages'));
        $this->assertSame('completed', $stages->firstWhere('event', 'whatsapp_reminder')['status']);
        $this->assertSame('pending', $stages->firstWhere('event', 'sms_reminder')['status']);
    }

    public function test_timeline_shows_promise_to_pay_completed_after_recording_one(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/debts/{$debt->id}/promise-to-pay", [
            'promised_date' => now()->addDays(7)->toDateString(),
        ])->assertStatus(201);

        $response = $this->getJson("/api/v1/debts/{$debt->id}/timeline");

        $stages = collect($response->json('data.stages'));
        $this->assertSame('completed', $stages->firstWhere('event', 'promise_to_pay')['status']);
        $this->assertSame('pending', $stages->firstWhere('event', 'payment')['status']);
    }

    // --- Authentication / Authorization / Tenant isolation ---

    public function test_unauthenticated_requests_are_rejected(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);

        $this->getJson("/api/v1/debts/{$debt->id}/followup-history")->assertStatus(401);
        $this->postJson("/api/v1/debts/{$debt->id}/reminders/call", [])->assertStatus(401);
        $this->postJson("/api/v1/debts/{$debt->id}/promise-to-pay", [])->assertStatus(401);
    }

    public function test_user_without_admin_role_cannot_use_recovery_workflow_endpoints(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant, null);

        $this->postJson("/api/v1/debts/{$debt->id}/reminders/whatsapp", [])->assertStatus(403);
        $this->postJson("/api/v1/debts/{$debt->id}/promise-to-pay", [
            'promised_date' => now()->addDays(1)->toDateString(),
        ])->assertStatus(403);
    }

    public function test_reminder_actions_respect_tenant_isolation(): void
    {
        $tenantA = Tenant::create(['business_name' => 'Tenant A']);
        $tenantB = Tenant::create(['business_name' => 'Tenant B']);
        $debtB = $this->makeDebt($tenantB);

        $this->actingAsTenantUser($tenantA);

        $this->postJson("/api/v1/debts/{$debtB->id}/reminders/whatsapp", [])->assertStatus(404);
        $this->postJson("/api/v1/debts/{$debtB->id}/promise-to-pay", [
            'promised_date' => now()->addDays(1)->toDateString(),
        ])->assertStatus(404);
    }
}
