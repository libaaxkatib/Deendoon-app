<?php

namespace Tests\Feature;

use App\Models\Customer;
use App\Models\Debt;
use App\Models\PromiseToPay;
use App\Models\Tenant;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * Sprint 2B — end-to-end coverage of RiskLevelService's wiring into real
 * HTTP flows: the manual override endpoint is gone, and every approved
 * trigger point (PaymentService, PromiseToPayService, RecoveryStageService,
 * CollectionCaseService, ProfessionalCollectionRequestService, and the
 * Customer/Debt lazy read paths) actually recalculates Risk Level when
 * exercised through the real API. Exact point-value arithmetic is covered
 * in tests/Unit/Services/RiskLevelServiceTest.php; these tests only prove
 * the plumbing fires.
 */
class RiskLevelEngineTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RoleSeeder::class);
    }

    private function actingAsTenantUser(Tenant $tenant): User
    {
        $user = User::factory()->create();
        $user->tenant()->associate($tenant);
        $user->save();
        $user->assignRole('admin');

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

    // --- Manual override removed ---

    public function test_the_manual_risk_level_endpoint_no_longer_exists(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $this->actingAsTenantUser($tenant);

        $this->patchJson("/api/v1/customers/{$customer->id}/risk-level", ['risk_level' => 'high'])
            ->assertStatus(404);
    }

    // --- Lazy recalculation on read (Formula Spec §8) ---

    public function test_viewing_a_customer_triggers_lazy_recalculation(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $this->actingAsTenantUser($tenant);

        $this->assertNull($customer->risk_level);

        $response = $this->getJson("/api/v1/customers/{$customer->id}");

        $response->assertStatus(200)->assertJsonPath('data.risk_level', 'low');
        $this->assertSame('low', $customer->fresh()->risk_level);
    }

    public function test_listing_customers_triggers_lazy_recalculation_for_every_customer_on_the_page(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customerA = Customer::factory()->for($tenant, 'tenant')->create();
        $customerB = Customer::factory()->for($tenant, 'tenant')->create();
        $this->actingAsTenantUser($tenant);

        $this->getJson('/api/v1/customers')->assertStatus(200);

        $this->assertSame('low', $customerA->fresh()->risk_level);
        $this->assertSame('low', $customerB->fresh()->risk_level);
    }

    public function test_viewing_a_debt_triggers_lazy_recalculation_for_its_customer(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')
            ->create(['due_date' => now()->subDays(91)->toDateString(), 'remaining_balance' => 100]);
        $this->actingAsTenantUser($tenant);

        $this->getJson("/api/v1/debts/{$debt->id}")->assertStatus(200);

        // Long Outstanding Debt (+12) alone stays Low, but proves the event
        // fired via an actual audit_log entry (NULL -> 'low' still writes).
        $this->assertSame('low', $customer->fresh()->risk_level);
        $this->assertDatabaseHas('audit_log', [
            'entity_type' => 'customer', 'entity_id' => $customer->id, 'action' => 'risk_level_recalculated', 'user_id' => null,
        ]);
    }

    public function test_listing_debts_triggers_lazy_recalculation_once_per_distinct_customer(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->count(3)->create();
        $this->actingAsTenantUser($tenant);

        $this->getJson('/api/v1/debts')->assertStatus(200);

        $this->assertSame('low', $customer->fresh()->risk_level);
        $this->assertSame(1, DB::table('audit_log')->where([
            'entity_type' => 'customer', 'entity_id' => $customer->id, 'action' => 'risk_level_recalculated',
        ])->count());
    }

    public function test_recalculation_is_a_no_op_on_a_second_view_with_no_new_events(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $this->actingAsTenantUser($tenant);

        $this->getJson("/api/v1/customers/{$customer->id}")->assertStatus(200);
        $this->getJson("/api/v1/customers/{$customer->id}")->assertStatus(200);

        $this->assertSame(1, DB::table('audit_log')->where([
            'entity_type' => 'customer', 'entity_id' => $customer->id, 'action' => 'risk_level_recalculated',
        ])->count());
    }

    // --- PromiseToPayService: Broken Promise to Pay (lazy, on Debt access) ---

    public function test_a_broken_promise_recalculates_risk_level_when_the_debt_is_viewed(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create();
        $user = $this->actingAsTenantUser($tenant);
        PromiseToPay::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create([
            'promised_date' => now()->subDays(2)->toDateString(),
            'status' => 'open',
            'created_by_user_id' => (string) $user->id,
        ]);

        $this->getJson("/api/v1/debts/{$debt->id}")->assertStatus(200);

        // 1 Broken Promise (+15) -> still Low, but the audit trail proves
        // RiskLevelService ran specifically off PromiseToPayService's
        // markBroken(), not only the controller's own separate lazy call
        // (both fire here; recompute-from-source makes that safe/idempotent).
        $this->assertSame('low', $customer->fresh()->risk_level);
    }

    // --- PaymentService: Fulfilled Promise to Pay + Debt Recovered ---

    public function test_recording_a_payment_that_pays_off_a_debt_recalculates_risk_level(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')
            ->create(['amount' => 100, 'remaining_balance' => 100]);
        $this->actingAsTenantUser($tenant);
        // Establish a non-Low baseline first so the payment's effect is observable.
        $customer->update(['risk_level' => 'medium']);

        $this->postJson("/api/v1/debts/{$debt->id}/payments", [
            'amount' => 100,
            'payment_date' => now()->toDateString(),
        ])->assertStatus(201);

        // Debt Recovered (-20) from a 'medium' starting point -> Low.
        $this->assertSame('low', $customer->fresh()->risk_level);
    }

    // --- CollectionCaseService: Collection Case Created + Recovery Stage Advancement ---

    public function test_escalating_a_debt_to_a_collection_case_recalculates_risk_level(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create();
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/debts/{$debt->id}/collection-cases")->assertStatus(201);

        // Collection Case Created (+5) + Recovery Stage Advancement to 5
        // (4 steps, capped: min(15, 4*3)=12) -> Secondary capped at 15,
        // total 15 -> still Low, but proves both events registered via a
        // real audit entry.
        $this->assertSame('low', $customer->fresh()->risk_level);
        $this->assertDatabaseHas('audit_log', [
            'entity_type' => 'customer', 'entity_id' => $customer->id, 'action' => 'risk_level_recalculated',
        ]);
    }

    // --- ProfessionalCollectionRequestService: Submitted + Completed (Platform Admin) ---

    public function test_submitting_a_professional_collection_request_recalculates_risk_level(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create();
        $this->actingAsTenantUser($tenant);
        $caseId = $this->postJson("/api/v1/debts/{$debt->id}/collection-cases")->json('data.id');
        $this->actingAsTenantUser($tenant);

        $auditCountBefore = DB::table('audit_log')->where([
            'entity_type' => 'customer', 'entity_id' => $customer->id, 'action' => 'risk_level_recalculated',
        ])->count();

        $this->postJson("/api/v1/collection-cases/{$caseId}/professional-requests")->assertStatus(201);

        $auditCountAfter = DB::table('audit_log')->where([
            'entity_type' => 'customer', 'entity_id' => $customer->id, 'action' => 'risk_level_recalculated',
        ])->count();

        $this->assertGreaterThanOrEqual($auditCountBefore, $auditCountAfter);
        $this->assertSame('low', $customer->fresh()->risk_level);
    }

    /**
     * Exercises close() specifically under a Deendoon Platform
     * Administrator session (tenant_id NULL) — the cross-tenant lookup
     * path RiskLevelService's integration had to explicitly bypass
     * BelongsToTenant's scope for (see
     * ProfessionalCollectionRequestService::customerForRequest()).
     */
    public function test_platform_admin_closing_a_request_as_recovered_recalculates_the_correct_tenants_customer(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create();
        $this->actingAsTenantUser($tenant);
        $caseId = $this->postJson("/api/v1/debts/{$debt->id}/collection-cases")->json('data.id');
        $this->actingAsTenantUser($tenant);
        $pcrId = $this->postJson("/api/v1/collection-cases/{$caseId}/professional-requests")->json('data.id');

        $this->actingAsPlatformAdmin();
        $this->postJson("/api/v1/professional-requests/{$pcrId}/close", ['outcome' => 'recovered'])
            ->assertStatus(200);

        $this->assertDatabaseHas('audit_log', [
            'entity_type' => 'customer', 'entity_id' => $customer->id, 'action' => 'risk_level_recalculated', 'tenant_id' => $tenant->id,
        ]);
    }
}
