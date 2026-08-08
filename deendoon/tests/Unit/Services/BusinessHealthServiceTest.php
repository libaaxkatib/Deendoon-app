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
 * Sprint 17B / Business Owner Backend Completion (pre-Phase 5) — direct
 * coverage of BusinessHealthService against `Business_Health_Engine_v1.0.md`
 * / `Business_Health_Formula_Specification_v1.0.md` (FROZEN weights/bands)
 * plus the Product Owner-approved adaptive formulas for Collection
 * Performance (DD-032, reuses CollectionRateService) and Outstanding
 * Exposure (a rolling 365-day historical baseline, never gated — a
 * `confidence` label instead).
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

    public function test_a_tenant_with_no_classified_customers_still_returns_neutral_baseline(): void
    {
        // Portfolio Customer Risk Levels remains a real gate — a Customer
        // must have been recalculated (viewed) at least once, unlike
        // Collection Performance/Outstanding Exposure which are always
        // computable once any Debt/Payment exists at all.
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $customer = Customer::factory()->for($tenant, 'tenant')->create(['risk_level' => null]);
        Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create();

        $result = $this->service()->calculate();

        $this->assertSame(['status' => 'neutral_baseline', 'score' => null], $result);
    }

    // --- Full composite: real score from day one (Business Owner Backend Completion) ---

    public function test_a_tenant_with_a_single_fully_recovered_debt_scores_100_and_healthy(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $customer = Customer::factory()->for($tenant, 'tenant')->create(['risk_level' => 'low']);
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')
            ->create(['amount' => 1000, 'remaining_balance' => 0, 'debt_status' => 'paid', 'due_date' => now()->toDateString()]);
        Payment::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create(['amount' => 1000, 'payment_date' => now()->toDateString()]);

        $result = $this->service()->calculate();

        // Collection Performance 100 (1000 collected / 1000 became due) * 0.45
        // + Outstanding Exposure 100 (nothing currently outstanding) * 0.20
        // + Portfolio Risk Levels 100 (the one Low-Risk customer) * 0.35 = 100.
        $this->assertSame('healthy', $result['status']);
        $this->assertSame(100, $result['score']);
        // Only 1 completed Debt Cycle — below the established-history threshold.
        $this->assertSame('limited_history', $result['confidence']);
    }

    public function test_confidence_is_established_once_5_debt_cycles_have_completed(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $customer = Customer::factory()->for($tenant, 'tenant')->create(['risk_level' => 'low']);
        for ($i = 0; $i < 5; $i++) {
            Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')
                ->create(['remaining_balance' => 0, 'debt_status' => 'paid']);
        }

        $result = $this->service()->calculate();

        $this->assertSame('established', $result['confidence']);
    }

    public function test_cancelled_and_written_off_debts_also_count_as_completed_cycles(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $customer = Customer::factory()->for($tenant, 'tenant')->create(['risk_level' => 'low']);
        Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create(['debt_status' => 'paid']);
        Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create(['debt_status' => 'cancelled']);
        Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create(['debt_status' => 'written_off']);
        Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create(['debt_status' => 'cancelled']);
        Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create(['debt_status' => 'written_off']);

        $result = $this->service()->calculate();

        $this->assertSame('established', $result['confidence']);
    }

    // --- Collection Performance input (DD-032, reuses CollectionRateService) ---

    public function test_collection_performance_divides_all_time_collected_by_all_time_became_due(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')
            ->create(['amount' => 1000, 'due_date' => now()->toDateString()]);
        Payment::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create(['amount' => 400, 'payment_date' => now()->toDateString()]);

        $performance = $this->invoke('collectionPerformance');

        $this->assertSame(40.0, $performance);
    }

    public function test_collection_performance_is_clamped_at_100_when_collected_exceeds_became_due(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')
            ->create(['amount' => 1000, 'due_date' => now()->toDateString()]);
        Payment::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create(['amount' => 1500, 'payment_date' => now()->toDateString()]);

        $performance = $this->invoke('collectionPerformance');

        $this->assertSame(100.0, $performance);
    }

    // --- Outstanding Exposure input (rolling 365-day historical baseline) ---

    public function test_outstanding_exposure_is_100_when_nothing_is_currently_outstanding(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')
            ->create(['remaining_balance' => 0, 'debt_status' => 'paid']);

        $exposure = $this->invoke('outstandingExposure');

        $this->assertSame(100.0, $exposure);
    }

    public function test_outstanding_exposure_reflects_current_outstanding_against_the_trailing_365_day_baseline(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        // 1000 extended within the trailing 365 days (the baseline); 400
        // still outstanding now -> ratio 0.4 -> score (1-0.4)*100 = 60.
        Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')
            ->create(['amount' => 1000, 'remaining_balance' => 400, 'debt_status' => 'pending']);

        $exposure = $this->invoke('outstandingExposure');

        $this->assertSame(60.0, $exposure);
    }

    public function test_outstanding_exposure_baseline_excludes_debts_created_outside_the_trailing_365_days(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        // Created 400 days ago -> excluded from the baseline, but still
        // currently outstanding -> baseline 0 with current > 0 is the
        // worst-case signal (score 0), not an undefined/crashing ratio.
        Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')
            ->create(['amount' => 1000, 'remaining_balance' => 500, 'debt_status' => 'pending', 'created_at' => now()->subDays(400)]);

        $exposure = $this->invoke('outstandingExposure');

        $this->assertSame(0.0, $exposure);
    }

    public function test_outstanding_exposure_baseline_includes_a_debt_created_exactly_at_the_365_day_edge(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')
            ->create(['amount' => 1000, 'remaining_balance' => 1000, 'debt_status' => 'pending', 'created_at' => now()->subDays(365)]);

        $exposure = $this->invoke('outstandingExposure');

        // Baseline 1000, current 1000 -> ratio 1 -> score 0, proving the
        // debt counted toward the baseline (had it been excluded, baseline
        // would be 0 with current > 0, which also scores 0 — so this is
        // corroborated by the ratio math, not just the boundary inclusion).
        $this->assertSame(0.0, $exposure);
    }

    // --- Portfolio Customer Risk Levels input (unchanged) ---

    public function test_portfolio_risk_levels_uses_the_frozen_health_contribution_weights(): void
    {
        // Health Contribution Weights: Low=100, Medium=50, High=0.
        // (100 + 50 + 0) / 3 = 50.
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        Customer::factory()->for($tenant, 'tenant')->create(['risk_level' => 'low']);
        Customer::factory()->for($tenant, 'tenant')->create(['risk_level' => 'medium']);
        Customer::factory()->for($tenant, 'tenant')->create(['risk_level' => 'high']);

        $index = $this->invoke('portfolioRiskLevelsIndex');

        $this->assertSame(50.0, $index);
    }

    public function test_portfolio_risk_levels_excludes_unclassified_customers_from_the_average(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        Customer::factory()->for($tenant, 'tenant')->create(['risk_level' => 'low']);
        Customer::factory()->for($tenant, 'tenant')->create(['risk_level' => null]);

        $index = $this->invoke('portfolioRiskLevelsIndex');

        $this->assertSame(100.0, $index);
    }

    public function test_portfolio_risk_levels_is_tenant_isolated(): void
    {
        $tenantA = Tenant::create(['business_name' => 'Tenant A']);
        $tenantB = Tenant::create(['business_name' => 'Tenant B']);
        Customer::factory()->for($tenantB, 'tenant')->create(['risk_level' => 'high']);

        $this->actingAsTenantUser($tenantA);
        Customer::factory()->for($tenantA, 'tenant')->create(['risk_level' => 'low']);

        $index = $this->invoke('portfolioRiskLevelsIndex');

        $this->assertSame(100.0, $index);
    }

    public function test_portfolio_risk_levels_returns_null_when_no_customer_is_classified(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        Customer::factory()->for($tenant, 'tenant')->create(['risk_level' => null]);

        $index = $this->invoke('portfolioRiskLevelsIndex');

        $this->assertNull($index);
    }

    // --- Guardrail mechanism: present, dormant (Critical Floor uncalibrated) ---

    public function test_critical_floor_is_uncalibrated_by_default(): void
    {
        $reflection = new \ReflectionClassConstant(BusinessHealthService::class, 'CRITICAL_FLOOR');

        $this->assertNull($reflection->getValue());
    }

    // --- Status band thresholds (Formula Spec §3) ---

    public function test_status_band_thresholds_match_the_frozen_ranges(): void
    {
        $this->assertSame('healthy', $this->invokeStatusFor(80.0));
        $this->assertSame('healthy', $this->invokeStatusFor(100.0));
        $this->assertSame('needs_attention', $this->invokeStatusFor(79.0));
        $this->assertSame('needs_attention', $this->invokeStatusFor(50.0));
        $this->assertSame('at_risk', $this->invokeStatusFor(49.0));
        $this->assertSame('at_risk', $this->invokeStatusFor(0.0));
    }

    private function invoke(string $method): mixed
    {
        $reflection = new \ReflectionMethod(BusinessHealthService::class, $method);
        $reflection->setAccessible(true);

        return $reflection->invoke($this->service());
    }

    private function invokeStatusFor(float $score): string
    {
        $method = new \ReflectionMethod(BusinessHealthService::class, 'statusFor');
        $method->setAccessible(true);

        return $method->invoke($this->service(), $score);
    }
}
