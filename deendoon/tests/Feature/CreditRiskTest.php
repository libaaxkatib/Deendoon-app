<?php

namespace Tests\Feature;

use App\Events\CreditLimitReached;
use App\Models\Customer;
use App\Models\Tenant;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Event;
use Tests\TestCase;

class CreditRiskTest extends TestCase
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

    // --- Credit Score (read-only, FR-026 display aspect) ---

    public function test_admin_can_view_credit_score(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $this->actingAsTenantUser($tenant);

        $response = $this->getJson("/api/v1/customers/{$customer->id}/credit-score");

        $response->assertStatus(200)
            ->assertJsonPath('data.customer_id', $customer->id)
            ->assertJsonPath('data.credit_score', null)
            ->assertJsonPath('data.credit_score_band', null);
    }

    public function test_credit_score_is_null_for_a_customer_with_no_scoring_history(): void
    {
        // No scoring engine exists (DD-008/DD-009 unresolved; Modules 5/6
        // don't exist), so a Customer's credit_score genuinely stays NULL
        // rather than any invented baseline.
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();

        $this->assertNull($customer->credit_score);
        $this->assertNull($customer->credit_score_band);
    }

    public function test_credit_score_returns_404_for_another_tenants_customer(): void
    {
        $tenantA = Tenant::create(['business_name' => 'Tenant A']);
        $tenantB = Tenant::create(['business_name' => 'Tenant B']);
        $customerB = Customer::factory()->for($tenantB, 'tenant')->create();

        $this->actingAsTenantUser($tenantA);

        $this->getJson("/api/v1/customers/{$customerB->id}/credit-score")->assertStatus(404);
    }

    // --- Risk Level (FR-027) ---
    //
    // Manual Risk Level assignment (PATCH /customers/{customer}/risk-level,
    // UpdateRiskLevelRequest, CustomerPolicy::updateRiskLevel()) was removed
    // in Sprint 2B: Risk Level is now exclusively system-calculated by
    // RiskLevelService. See tests/Unit/Services/RiskLevelServiceTest.php
    // and tests/Feature/RiskLevelEngineTest.php for its coverage.

    public function test_risk_level_does_not_affect_credit_score_or_customer_status(): void
    {
        // BRL-006: Risk Level, Credit Score, Customer Status are
        // independently maintained.
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create(['customer_status' => 'active']);
        $this->actingAsTenantUser($tenant);

        $this->getJson("/api/v1/customers/{$customer->id}")->assertStatus(200);

        $fresh = $customer->fresh();
        $this->assertSame('active', $fresh->customer_status);
        $this->assertNull($fresh->credit_score);
    }

    public function test_manual_risk_level_endpoint_no_longer_exists(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $this->actingAsTenantUser($tenant);

        $this->patchJson("/api/v1/customers/{$customer->id}/risk-level", ['risk_level' => 'low'])
            ->assertStatus(404);
    }

    // --- Credit Limit Reached trigger (FR-028, trigger only — no Module 10) ---

    public function test_credit_limit_reached_event_fires_when_debt_creation_pushes_balance_to_the_limit(): void
    {
        Event::fake([CreditLimitReached::class]);

        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create(['credit_limit' => 500]);
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/customers/{$customer->id}/debts", [
            'amount' => 500,
            'due_date' => now()->addDays(10)->toDateString(),
        ])->assertStatus(201);

        Event::assertDispatched(
            CreditLimitReached::class,
            fn (CreditLimitReached $event): bool => $event->customer->is($customer),
        );
    }

    public function test_credit_limit_reached_event_does_not_fire_when_balance_stays_under_the_limit(): void
    {
        Event::fake([CreditLimitReached::class]);

        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create(['credit_limit' => 5000]);
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/customers/{$customer->id}/debts", [
            'amount' => 100,
            'due_date' => now()->addDays(10)->toDateString(),
        ])->assertStatus(201);

        Event::assertNotDispatched(CreditLimitReached::class);
    }

    public function test_credit_limit_reached_event_fires_again_on_a_repeated_qualifying_recalculation(): void
    {
        // DD-011 (re-trigger/suppression policy) is unresolved — this
        // documents the deliberate no-suppression behavior rather than
        // inventing a de-duplication rule.
        Event::fake([CreditLimitReached::class]);

        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create(['credit_limit' => 100]);
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/customers/{$customer->id}/debts", [
            'amount' => 100, 'due_date' => now()->addDays(10)->toDateString(),
        ])->assertStatus(201);
        $this->postJson("/api/v1/customers/{$customer->id}/debts", [
            'amount' => 50, 'due_date' => now()->addDays(10)->toDateString(),
        ])->assertStatus(201);

        Event::assertDispatchedTimes(CreditLimitReached::class, 2);
    }

    // --- Authentication / Authorization ---

    public function test_unauthenticated_requests_are_rejected(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();

        $this->getJson("/api/v1/customers/{$customer->id}/credit-score")->assertStatus(401);
    }

    public function test_user_without_admin_role_cannot_access_credit_risk_endpoints(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $this->actingAsTenantUser($tenant, null);

        $this->getJson("/api/v1/customers/{$customer->id}/credit-score")->assertStatus(403);
    }
}
