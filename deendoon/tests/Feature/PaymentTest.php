<?php

namespace Tests\Feature;

use App\Models\AuditLog;
use App\Models\Customer;
use App\Models\Debt;
use App\Models\PromiseToPay;
use App\Models\Tenant;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Database\Seeders\SubscriptionPlanSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PaymentTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RoleSeeder::class);
        // Backend Completion Roadmap (Phase 4.2): payment recording
        // triggers automatic receipt generation, which now fails closed
        // without a resolvable plan.
        $this->seed(SubscriptionPlanSeeder::class);
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
        $customer = Customer::factory()->for($tenant, 'tenant')->create(['credit_limit' => 5000]);

        return Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create($attributes);
    }

    // --- Recording ---

    public function test_admin_can_record_a_partial_payment(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant, ['amount' => 1000, 'remaining_balance' => 1000]);
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson("/api/v1/debts/{$debt->id}/payments", [
            'amount' => 400,
            'payment_date' => now()->toDateString(),
            'payment_method' => 'cash',
            'reference_notes' => 'First installment',
        ]);

        $response->assertStatus(201)
            ->assertJson(['success' => true])
            ->assertJsonPath('data.amount', '400.00')
            ->assertJsonPath('data.payment_method', 'cash');

        $this->assertDatabaseHas('payments', ['debt_id' => $debt->id, 'amount' => 400]);
    }

    public function test_payment_recording_requires_amount_and_payment_date(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/debts/{$debt->id}/payments", [])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['amount', 'payment_date']);
    }

    public function test_payment_amount_must_be_positive(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/debts/{$debt->id}/payments", [
            'amount' => -50,
            'payment_date' => now()->toDateString(),
        ])->assertStatus(422)->assertJsonValidationErrors(['amount']);
    }

    public function test_payment_against_an_archived_debt_is_rejected(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $debt->delete();
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/debts/{$debt->id}/payments", [
            'amount' => 100,
            'payment_date' => now()->toDateString(),
        ])->assertStatus(404);
    }

    // --- Debt Status effects (BRL-039) ---

    public function test_partial_payment_sets_debt_status_to_partial_paid(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant, ['amount' => 1000, 'remaining_balance' => 1000, 'debt_status' => 'pending']);
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/debts/{$debt->id}/payments", [
            'amount' => 300, 'payment_date' => now()->toDateString(),
        ])->assertStatus(201);

        $debt->refresh();
        $this->assertSame('partial_paid', $debt->debt_status);
        $this->assertSame('700.00', $debt->remaining_balance);
    }

    public function test_full_payment_sets_debt_status_to_paid(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant, ['amount' => 1000, 'remaining_balance' => 1000, 'debt_status' => 'pending']);
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/debts/{$debt->id}/payments", [
            'amount' => 1000, 'payment_date' => now()->toDateString(),
        ])->assertStatus(201);

        $debt->refresh();
        $this->assertSame('paid', $debt->debt_status);
        $this->assertSame('0.00', $debt->remaining_balance);
    }

    public function test_cumulative_partial_payments_eventually_reach_paid(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant, ['amount' => 1000, 'remaining_balance' => 1000]);
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/debts/{$debt->id}/payments", ['amount' => 400, 'payment_date' => now()->toDateString()])->assertStatus(201);
        $this->assertSame('partial_paid', $debt->fresh()->debt_status);

        $this->postJson("/api/v1/debts/{$debt->id}/payments", ['amount' => 600, 'payment_date' => now()->toDateString()])->assertStatus(201);
        $this->assertSame('paid', $debt->fresh()->debt_status);
        $this->assertSame('0.00', $debt->fresh()->remaining_balance);
    }

    public function test_overpayment_is_rejected_and_remaining_balance_is_left_untouched(): void
    {
        // Business Owner Backend Completion (pre-Phase 5), DD-016
        // Product Owner-approved decision: overpayment is rejected, not
        // accepted-and-capped or accepted-and-left-negative.
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant, ['amount' => 1000, 'remaining_balance' => 1000, 'debt_status' => 'pending']);
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson("/api/v1/debts/{$debt->id}/payments", [
            'amount' => 1500, 'payment_date' => now()->toDateString(),
        ]);

        $response->assertStatus(422)->assertJson(['success' => false]);
        $debt->refresh();
        $this->assertSame('pending', $debt->debt_status);
        $this->assertSame('1000.00', $debt->remaining_balance);
        $this->assertDatabaseMissing('payments', ['debt_id' => $debt->id]);
    }

    public function test_a_payment_exactly_equal_to_the_remaining_balance_is_accepted(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant, ['amount' => 1000, 'remaining_balance' => 1000, 'debt_status' => 'pending']);
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/debts/{$debt->id}/payments", [
            'amount' => 1000, 'payment_date' => now()->toDateString(),
        ])->assertStatus(201);

        $this->assertSame('0.00', $debt->fresh()->remaining_balance);
    }

    public function test_payment_against_a_paid_debt_is_rejected(): void
    {
        // DD-017 Product Owner-approved decision.
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant, ['amount' => 1000, 'remaining_balance' => 0, 'debt_status' => 'paid']);
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson("/api/v1/debts/{$debt->id}/payments", [
            'amount' => 50, 'payment_date' => now()->toDateString(),
        ]);

        $response->assertStatus(422)->assertJson(['success' => false]);
        $this->assertDatabaseMissing('payments', ['debt_id' => $debt->id]);
    }

    public function test_payment_against_a_cancelled_debt_is_rejected_even_with_a_stale_positive_remaining_balance(): void
    {
        // Cancelling/writing off a Debt does not zero its remaining_balance
        // (DebtController::updateStatus() never touches that field) — the
        // terminal-status check must catch this independently of the
        // amount-vs-remaining_balance check, which alone would not.
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant, ['amount' => 1000, 'remaining_balance' => 1000, 'debt_status' => 'cancelled']);
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/debts/{$debt->id}/payments", [
            'amount' => 100, 'payment_date' => now()->toDateString(),
        ])->assertStatus(422);
    }

    public function test_payment_against_a_written_off_debt_is_rejected(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant, ['amount' => 1000, 'remaining_balance' => 1000, 'debt_status' => 'written_off']);
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/debts/{$debt->id}/payments", [
            'amount' => 100, 'payment_date' => now()->toDateString(),
        ])->assertStatus(422);
    }

    public function test_status_changed_audit_event_is_not_duplicated_when_status_does_not_transition(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant, ['amount' => 1000, 'remaining_balance' => 1000]);
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/debts/{$debt->id}/payments", ['amount' => 300, 'payment_date' => now()->toDateString()])->assertStatus(201);
        $this->postJson("/api/v1/debts/{$debt->id}/payments", ['amount' => 200, 'payment_date' => now()->toDateString()])->assertStatus(201);

        $this->assertSame('partial_paid', $debt->fresh()->debt_status);
        $this->assertSame(1, AuditLog::where('entity_id', $debt->id)->where('action', 'status_changed')->count());
    }

    // --- Customer Balance integration (FR-036) ---

    public function test_payment_recalculates_customer_outstanding_balance(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create(['credit_limit' => 5000, 'outstanding_balance' => 1000]);
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create(['amount' => 1000, 'remaining_balance' => 1000]);
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/debts/{$debt->id}/payments", ['amount' => 400, 'payment_date' => now()->toDateString()])->assertStatus(201);

        $this->assertSame('600.00', $customer->fresh()->outstanding_balance);
    }

    // --- Recovery Stage integration (BRL-031 Stage 6) ---

    public function test_full_payment_advances_recovery_stage_to_6(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant, ['amount' => 1000, 'remaining_balance' => 1000, 'recovery_stage' => 3]);
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/debts/{$debt->id}/payments", ['amount' => 1000, 'payment_date' => now()->toDateString()])->assertStatus(201);

        $this->assertSame(6, $debt->fresh()->recovery_stage);
    }

    public function test_partial_payment_does_not_advance_recovery_stage(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant, ['amount' => 1000, 'remaining_balance' => 1000, 'recovery_stage' => 3]);
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/debts/{$debt->id}/payments", ['amount' => 400, 'payment_date' => now()->toDateString()])->assertStatus(201);

        $this->assertSame(3, $debt->fresh()->recovery_stage);
    }

    // --- Audit Logging / Follow-up History (FR-034, FR-038) ---

    public function test_payment_records_payment_added_and_receipt_generated_audit_events(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant, ['amount' => 1000, 'remaining_balance' => 1000]);
        $user = $this->actingAsTenantUser($tenant);

        $paymentId = $this->postJson("/api/v1/debts/{$debt->id}/payments", [
            'amount' => 400, 'payment_date' => now()->toDateString(),
        ])->json('data.id');

        $this->assertDatabaseHas('audit_log', [
            'entity_type' => 'debt', 'entity_id' => $debt->id, 'action' => 'payment_added', 'user_id' => (string) $user->id,
        ]);
        $this->assertDatabaseHas('audit_log', [
            'entity_type' => 'payment', 'entity_id' => $paymentId, 'action' => 'receipt_generated',
        ]);
    }

    public function test_payment_records_a_followup_history_entry(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant, ['amount' => 1000, 'remaining_balance' => 1000]);
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/debts/{$debt->id}/payments", ['amount' => 400, 'payment_date' => now()->toDateString()])->assertStatus(201);

        $this->assertDatabaseHas('follow_up_history', ['debt_id' => $debt->id, 'action_type' => 'payment_recorded']);
    }

    // --- Promise to Pay fulfillment (BRL-032) ---

    public function test_a_qualifying_payment_on_or_before_the_promised_date_fulfills_an_open_promise(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant, ['amount' => 1000, 'remaining_balance' => 1000]);
        $promise = PromiseToPay::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create([
            'promised_date' => now()->addDays(3)->toDateString(),
            'status' => 'open',
        ]);
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/debts/{$debt->id}/payments", [
            'amount' => 100, 'payment_date' => now()->toDateString(),
        ])->assertStatus(201);

        $this->assertSame('fulfilled', $promise->fresh()->status);
        $this->assertNotNull($promise->fresh()->resolved_at);
        $this->assertDatabaseHas('follow_up_history', ['debt_id' => $debt->id, 'action_type' => 'promise_fulfilled']);
    }

    public function test_a_payment_recorded_after_the_promised_date_does_not_fulfill_the_promise(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant, ['amount' => 1000, 'remaining_balance' => 1000]);
        $promise = PromiseToPay::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create([
            'promised_date' => now()->subDays(1)->toDateString(),
            'status' => 'open',
        ]);
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/debts/{$debt->id}/payments", [
            'amount' => 100, 'payment_date' => now()->toDateString(),
        ])->assertStatus(201);

        $this->assertSame('open', $promise->fresh()->status);
    }

    // --- Payment History (FR-035) ---

    public function test_debt_level_payment_history_lists_payments_in_reverse_chronological_order(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant, ['amount' => 1000, 'remaining_balance' => 1000]);
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/debts/{$debt->id}/payments", ['amount' => 100, 'payment_date' => now()->subDays(5)->toDateString()])->assertStatus(201);
        $this->postJson("/api/v1/debts/{$debt->id}/payments", ['amount' => 200, 'payment_date' => now()->toDateString()])->assertStatus(201);

        $response = $this->getJson("/api/v1/debts/{$debt->id}/payments");

        $response->assertStatus(200);
        $amounts = collect($response->json('data'))->pluck('amount');
        $this->assertSame(['200.00', '100.00'], $amounts->all());
    }

    public function test_customer_level_payment_history_aggregates_across_debts(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create(['credit_limit' => 5000]);
        $debtA = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create(['amount' => 500, 'remaining_balance' => 500]);
        $debtB = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create(['amount' => 800, 'remaining_balance' => 800]);
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/debts/{$debtA->id}/payments", ['amount' => 100, 'payment_date' => now()->toDateString()])->assertStatus(201);
        $this->postJson("/api/v1/debts/{$debtB->id}/payments", ['amount' => 200, 'payment_date' => now()->toDateString()])->assertStatus(201);

        $response = $this->getJson("/api/v1/customers/{$customer->id}/payments");

        $response->assertStatus(200);
        $this->assertCount(2, $response->json('data'));
    }

    // --- Timeline integration (FR-024) ---

    public function test_timeline_shows_payment_stage_completed_after_a_payment(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant, ['amount' => 1000, 'remaining_balance' => 1000]);
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/debts/{$debt->id}/payments", ['amount' => 400, 'payment_date' => now()->toDateString()])->assertStatus(201);

        $response = $this->getJson("/api/v1/debts/{$debt->id}/timeline");

        $stages = collect($response->json('data.stages'));
        $this->assertSame('completed', $stages->firstWhere('event', 'payment')['status']);
    }

    public function test_timeline_shows_recovered_stage_completed_once_the_debt_is_fully_paid(): void
    {
        // Bug fix (Transfer Case to Deendoon Recovery Team review): the
        // "recovered" stage previously hardcoded 'pending' unconditionally,
        // regardless of the Debt's actual status.
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant, ['amount' => 1000, 'remaining_balance' => 1000]);
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/debts/{$debt->id}/payments", ['amount' => 1000, 'payment_date' => now()->toDateString()])->assertStatus(201);

        $response = $this->getJson("/api/v1/debts/{$debt->id}/timeline");

        $stages = collect($response->json('data.stages'));
        $recovered = $stages->firstWhere('event', 'recovered');
        $this->assertSame('completed', $recovered['status']);
        $this->assertNotNull($recovered['occurred_at']);
    }

    public function test_timeline_recovered_stage_stays_pending_for_a_partially_paid_debt(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant, ['amount' => 1000, 'remaining_balance' => 1000]);
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/debts/{$debt->id}/payments", ['amount' => 400, 'payment_date' => now()->toDateString()])->assertStatus(201);

        $response = $this->getJson("/api/v1/debts/{$debt->id}/timeline");

        $stages = collect($response->json('data.stages'));
        $recovered = $stages->firstWhere('event', 'recovered');
        $this->assertSame('pending', $recovered['status']);
        $this->assertNull($recovered['occurred_at']);
    }

    // --- Authentication / Authorization / Tenant isolation ---

    public function test_unauthenticated_requests_are_rejected(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);

        $this->postJson("/api/v1/debts/{$debt->id}/payments", ['amount' => 100, 'payment_date' => now()->toDateString()])->assertStatus(401);
        $this->getJson("/api/v1/debts/{$debt->id}/payments")->assertStatus(401);
    }

    public function test_user_without_admin_role_cannot_record_or_view_payments(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant, null);

        $this->postJson("/api/v1/debts/{$debt->id}/payments", [
            'amount' => 100, 'payment_date' => now()->toDateString(),
        ])->assertStatus(403);
        $this->getJson("/api/v1/debts/{$debt->id}/payments")->assertStatus(403);
    }

    public function test_payment_history_respects_tenant_isolation(): void
    {
        $tenantA = Tenant::create(['business_name' => 'Tenant A']);
        $tenantB = Tenant::create(['business_name' => 'Tenant B']);
        $debtB = $this->makeDebt($tenantB);

        $this->actingAsTenantUser($tenantA);

        $this->getJson("/api/v1/debts/{$debtB->id}/payments")->assertStatus(404);
        $this->postJson("/api/v1/debts/{$debtB->id}/payments", [
            'amount' => 100, 'payment_date' => now()->toDateString(),
        ])->assertStatus(404);
    }
}
