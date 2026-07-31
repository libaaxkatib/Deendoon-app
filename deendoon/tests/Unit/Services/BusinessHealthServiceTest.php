<?php

namespace Tests\Unit\Services;

use App\Models\Customer;
use App\Models\Debt;
use App\Models\Payment;
use App\Models\Tenant;
use App\Models\User;
use App\Services\BusinessHealthService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * Sprint 17B — direct coverage of BusinessHealthService against
 * `Business_Health_Engine_v1.0.md` / `Business_Health_Formula_
 * Specification_v1.0.md` (FROZEN). Two of the three inputs (Collection
 * Performance, Outstanding Exposure) are currently unresolved (DD-032;
 * the Outstanding Exposure normalization formula and Sufficient
 * Historical Activity threshold), so the dominant, most important
 * behavior under test is that the engine correctly reports Neutral
 * Baseline rather than silently computing a partial or invented score —
 * this is the frozen spec's own instruction (§1: "the whole card, not a
 * partial substitution"), not a limitation of this test suite.
 */
class BusinessHealthServiceTest extends TestCase
{
    use RefreshDatabase;

    private function service(): BusinessHealthService
    {
        return app(BusinessHealthService::class);
    }

    private function actingAsTenantUser(Tenant $tenant): User
    {
        $user = User::factory()->create();
        $user->tenant()->associate($tenant);
        $user->save();

        Sanctum::actingAs($user);

        return $user;
    }

    // --- Neutral Baseline: no recorded activity at all ---

    public function test_a_tenant_with_no_debts_or_payments_returns_neutral_baseline(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $result = $this->service()->calculate();

        $this->assertSame(['status' => 'neutral_baseline', 'score' => null], $result);
    }

    // --- Neutral Baseline: Collection Performance / Outstanding Exposure unresolved (DD-032, etc.) ---

    public function test_a_tenant_with_real_debts_and_classified_customers_still_returns_neutral_baseline_today(): void
    {
        // Deliberately the most important test in this suite: proves the
        // engine does NOT silently compute a score from 1 of 3 inputs.
        // Portfolio Customer Risk Levels alone is fully resolvable, but
        // Collection Performance (DD-032) and Outstanding Exposure (no
        // normalization formula defined) are not — per Formula Spec §1
        // this must leave the *entire* composite in Neutral Baseline, not
        // a partial/best-effort score.
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $customer = Customer::factory()->for($tenant, 'tenant')->create(['risk_level' => 'low']);
        Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create();

        $result = $this->service()->calculate();

        $this->assertSame(['status' => 'neutral_baseline', 'score' => null], $result);
    }

    public function test_a_tenant_with_a_recorded_payment_but_no_debt_still_returns_neutral_baseline_today(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create();
        Payment::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create();

        $result = $this->service()->calculate();

        $this->assertSame(['status' => 'neutral_baseline', 'score' => null], $result);
    }

    // --- Portfolio Customer Risk Levels input (the one fully-resolvable input) ---

    public function test_portfolio_risk_levels_uses_the_frozen_health_contribution_weights(): void
    {
        // Health Contribution Weights: Low=100, Medium=50, High=0.
        // (100 + 50 + 0) / 3 = 50 — verified via reflection since the
        // composite itself cannot surface this value while Collection
        // Performance/Outstanding Exposure remain unresolved.
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        Customer::factory()->for($tenant, 'tenant')->create(['risk_level' => 'low']);
        Customer::factory()->for($tenant, 'tenant')->create(['risk_level' => 'medium']);
        Customer::factory()->for($tenant, 'tenant')->create(['risk_level' => 'high']);

        $index = $this->invokePortfolioRiskLevelsIndex();

        $this->assertSame(50.0, $index);
    }

    public function test_portfolio_risk_levels_excludes_unclassified_customers_from_the_average(): void
    {
        // 1 Low (100) + 1 unclassified (excluded) = average of 100, not
        // (100 + 0) / 2 = 50 — an unclassified customer has nothing
        // defined to average in, mirroring riskDistribution()'s existing
        // exclusion of unclassified customers from its percentage base.
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        Customer::factory()->for($tenant, 'tenant')->create(['risk_level' => 'low']);
        Customer::factory()->for($tenant, 'tenant')->create(['risk_level' => null]);

        $index = $this->invokePortfolioRiskLevelsIndex();

        $this->assertSame(100.0, $index);
    }

    public function test_portfolio_risk_levels_is_tenant_isolated(): void
    {
        $tenantA = Tenant::create(['business_name' => 'Tenant A']);
        $tenantB = Tenant::create(['business_name' => 'Tenant B']);
        Customer::factory()->for($tenantB, 'tenant')->create(['risk_level' => 'high']);

        $this->actingAsTenantUser($tenantA);
        Customer::factory()->for($tenantA, 'tenant')->create(['risk_level' => 'low']);

        $index = $this->invokePortfolioRiskLevelsIndex();

        // Only Tenant A's single Low-Risk customer (100), not blended
        // with Tenant B's High-Risk customer.
        $this->assertSame(100.0, $index);
    }

    public function test_portfolio_risk_levels_returns_null_when_no_customer_is_classified(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        Customer::factory()->for($tenant, 'tenant')->create(['risk_level' => null]);

        $index = $this->invokePortfolioRiskLevelsIndex();

        $this->assertNull($index);
    }

    // --- Guardrail mechanism: present, dormant (Critical Floor uncalibrated) ---

    public function test_critical_floor_is_uncalibrated_by_default(): void
    {
        $reflection = new \ReflectionClassConstant(BusinessHealthService::class, 'CRITICAL_FLOOR');

        $this->assertNull($reflection->getValue());
    }

    // --- Status band thresholds (Formula Spec §3, exercised via reflection since Guardrail/weights currently gate the public entry point) ---

    public function test_status_band_thresholds_match_the_frozen_ranges(): void
    {
        $this->assertSame('healthy', $this->invokeStatusFor(80.0));
        $this->assertSame('healthy', $this->invokeStatusFor(100.0));
        $this->assertSame('needs_attention', $this->invokeStatusFor(79.0));
        $this->assertSame('needs_attention', $this->invokeStatusFor(50.0));
        $this->assertSame('at_risk', $this->invokeStatusFor(49.0));
        $this->assertSame('at_risk', $this->invokeStatusFor(0.0));
    }

    private function invokePortfolioRiskLevelsIndex(): ?float
    {
        $method = new \ReflectionMethod(BusinessHealthService::class, 'portfolioRiskLevelsIndex');
        $method->setAccessible(true);

        return $method->invoke($this->service());
    }

    private function invokeStatusFor(float $score): string
    {
        $method = new \ReflectionMethod(BusinessHealthService::class, 'statusFor');
        $method->setAccessible(true);

        return $method->invoke($this->service(), $score);
    }
}
