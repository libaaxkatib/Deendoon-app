<?php

namespace Tests\Unit\Services;

use App\Models\SubscriptionPlan;
use App\Models\Tenant;
use App\Models\TenantSubscription;
use App\Services\SubscriptionService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Backend Completion Roadmap, Phase 3.2 — direct coverage of
 * SubscriptionService. Read-only only: no test here writes subscription
 * state through the service, matching its own read-only contract.
 */
class SubscriptionServiceTest extends TestCase
{
    use RefreshDatabase;

    private function service(): SubscriptionService
    {
        return app(SubscriptionService::class);
    }

    private function tenant(): Tenant
    {
        return Tenant::create(['business_name' => 'Acme Co']);
    }

    // --- No subscription record at all, and no Free Plan seeded either ---
    // (a data-availability gap, not the normal case — see the fallback
    // tests below for the Product Owner-approved "treat as Free Plan"
    // behavior once a Free plan row actually exists.)

    public function test_a_tenant_with_no_subscription_record_has_no_current_subscription(): void
    {
        $tenant = $this->tenant();

        $this->assertNull($this->service()->currentSubscription($tenant));
    }

    public function test_a_tenant_with_no_subscription_record_and_no_free_plan_seeded_has_no_current_plan(): void
    {
        $tenant = $this->tenant();

        $this->assertNull($this->service()->currentPlan($tenant));
        $this->assertNull($this->service()->customerLimit($tenant));
        $this->assertNull($this->service()->storageLimit($tenant));
    }

    public function test_a_tenant_with_no_subscription_record_has_null_status(): void
    {
        // Unaffected by the Free Plan fallback: status() reports on the
        // subscription record's own lifecycle state, which genuinely
        // doesn't exist here.
        $tenant = $this->tenant();

        $this->assertNull($this->service()->status($tenant));
    }

    public function test_a_tenant_with_no_subscription_record_has_analytics_disabled_and_is_not_on_trial(): void
    {
        // Fail-closed defaults when even the Free Plan isn't seeded yet.
        $tenant = $this->tenant();

        $this->assertFalse($this->service()->analyticsEnabled($tenant));
        $this->assertFalse($this->service()->isOnTrial($tenant));
    }

    // --- No subscription record, Free Plan fallback (Product Owner decision) ---

    public function test_a_tenant_with_no_subscription_record_falls_back_to_the_free_plan(): void
    {
        SubscriptionPlan::factory()->create(['name' => 'Free', 'customer_limit' => 2, 'storage_limit' => 10, 'analytics_enabled' => false]);
        $tenant = $this->tenant();

        $this->assertSame('Free', $this->service()->currentPlan($tenant)->name);
        $this->assertSame(2, $this->service()->customerLimit($tenant));
        $this->assertSame(10, $this->service()->storageLimit($tenant));
        $this->assertFalse($this->service()->analyticsEnabled($tenant));
    }

    public function test_a_tenant_with_no_subscription_record_still_has_null_status_even_with_a_free_plan_seeded(): void
    {
        // The fallback is scoped to plan-derived limits, not the
        // subscription record's own state.
        SubscriptionPlan::factory()->create(['name' => 'Free']);
        $tenant = $this->tenant();

        $this->assertNull($this->service()->status($tenant));
        $this->assertFalse($this->service()->isOnTrial($tenant));
    }

    public function test_a_subscribed_tenant_is_unaffected_by_the_free_plan_fallback(): void
    {
        // The fallback only applies when there is no subscription record
        // at all — a real subscription always wins.
        SubscriptionPlan::factory()->create(['name' => 'Free', 'customer_limit' => 2]);
        $tenant = $this->tenant();
        $corporatePlan = SubscriptionPlan::factory()->unlimited()->create(['name' => 'Corporate']);
        TenantSubscription::factory()->for($tenant, 'tenant')->for($corporatePlan, 'plan')->active()->create();

        $this->assertSame('Corporate', $this->service()->currentPlan($tenant)->name);
        $this->assertNull($this->service()->customerLimit($tenant));
    }

    // --- Current subscription / plan lookup ---

    public function test_current_subscription_and_plan_are_returned_for_a_subscribed_tenant(): void
    {
        $tenant = $this->tenant();
        $plan = SubscriptionPlan::factory()->create(['name' => 'Small Business']);
        TenantSubscription::factory()->for($tenant, 'tenant')->for($plan, 'plan')->active()->create();

        $subscription = $this->service()->currentSubscription($tenant);
        $plan2 = $this->service()->currentPlan($tenant);

        $this->assertNotNull($subscription);
        $this->assertTrue($subscription->tenant->is($tenant));
        $this->assertSame('Small Business', $plan2->name);
    }

    // --- Customer limit ---

    public function test_customer_limit_reflects_the_current_plans_limit(): void
    {
        $tenant = $this->tenant();
        $plan = SubscriptionPlan::factory()->create(['customer_limit' => 110]);
        TenantSubscription::factory()->for($tenant, 'tenant')->for($plan, 'plan')->active()->create();

        $this->assertSame(110, $this->service()->customerLimit($tenant));
    }

    public function test_customer_limit_is_null_for_a_plan_with_an_unlimited_customer_limit(): void
    {
        // Corporate's approved "Unlimited customers" -> NULL, not a magic number.
        $tenant = $this->tenant();
        $plan = SubscriptionPlan::factory()->unlimited()->create();
        TenantSubscription::factory()->for($tenant, 'tenant')->for($plan, 'plan')->active()->create();

        $this->assertNull($this->service()->customerLimit($tenant));
    }

    // --- Storage limit ---

    public function test_storage_limit_reflects_the_current_plans_limit(): void
    {
        $tenant = $this->tenant();
        $plan = SubscriptionPlan::factory()->create(['storage_limit' => 25]);
        TenantSubscription::factory()->for($tenant, 'tenant')->for($plan, 'plan')->active()->create();

        $this->assertSame(25, $this->service()->storageLimit($tenant));
    }

    // --- Analytics availability ---

    public function test_analytics_enabled_is_true_when_the_plan_enables_it(): void
    {
        $tenant = $this->tenant();
        $plan = SubscriptionPlan::factory()->create(['analytics_enabled' => true]);
        TenantSubscription::factory()->for($tenant, 'tenant')->for($plan, 'plan')->active()->create();

        $this->assertTrue($this->service()->analyticsEnabled($tenant));
    }

    public function test_analytics_enabled_is_false_for_the_free_plans_approved_restriction(): void
    {
        $tenant = $this->tenant();
        $plan = SubscriptionPlan::factory()->analyticsDisabled()->create(['name' => 'Free']);
        TenantSubscription::factory()->for($tenant, 'tenant')->for($plan, 'plan')->active()->create();

        $this->assertFalse($this->service()->analyticsEnabled($tenant));
    }

    // --- Subscription status ---

    public function test_status_reflects_the_stored_subscription_status(): void
    {
        $tenant = $this->tenant();
        $plan = SubscriptionPlan::factory()->create();
        TenantSubscription::factory()->for($tenant, 'tenant')->for($plan, 'plan')->expired()->create();

        $this->assertSame('expired', $this->service()->status($tenant));
    }

    // --- Trial detection ---

    public function test_is_on_trial_is_true_within_the_trial_window(): void
    {
        $tenant = $this->tenant();
        $plan = SubscriptionPlan::factory()->create();
        TenantSubscription::factory()->for($tenant, 'tenant')->for($plan, 'plan')->create([
            'status' => 'trialing',
            'trial_started_at' => now(),
            'trial_ends_at' => now()->addDays(7),
        ]);

        $this->assertTrue($this->service()->isOnTrial($tenant));
    }

    public function test_is_on_trial_is_false_once_the_trial_window_has_elapsed(): void
    {
        // Status still says 'trialing' (the not-yet-built expiration job
        // hasn't run) but the window itself has passed — isOnTrial()
        // checks both, not status alone.
        $tenant = $this->tenant();
        $plan = SubscriptionPlan::factory()->create();
        TenantSubscription::factory()->for($tenant, 'tenant')->for($plan, 'plan')->create([
            'status' => 'trialing',
            'trial_started_at' => now()->subDays(10),
            'trial_ends_at' => now()->subDay(),
        ]);

        $this->assertFalse($this->service()->isOnTrial($tenant));
    }

    public function test_is_on_trial_is_false_for_an_active_non_trial_subscription(): void
    {
        $tenant = $this->tenant();
        $plan = SubscriptionPlan::factory()->create();
        TenantSubscription::factory()->for($tenant, 'tenant')->for($plan, 'plan')->active()->create();

        $this->assertFalse($this->service()->isOnTrial($tenant));
    }

    public function test_is_on_trial_is_false_for_an_expired_subscription(): void
    {
        $tenant = $this->tenant();
        $plan = SubscriptionPlan::factory()->create();
        TenantSubscription::factory()->for($tenant, 'tenant')->for($plan, 'plan')->expired()->create();

        $this->assertFalse($this->service()->isOnTrial($tenant));
    }

    // --- Tenant isolation ---

    public function test_current_subscription_is_tenant_isolated(): void
    {
        $tenantA = $this->tenant();
        $tenantB = Tenant::create(['business_name' => 'Other Co']);
        $planA = SubscriptionPlan::factory()->create(['customer_limit' => 2]);
        $planB = SubscriptionPlan::factory()->create(['customer_limit' => 250]);
        TenantSubscription::factory()->for($tenantA, 'tenant')->for($planA, 'plan')->active()->create();
        TenantSubscription::factory()->for($tenantB, 'tenant')->for($planB, 'plan')->active()->create();

        $this->assertSame(2, $this->service()->customerLimit($tenantA));
        $this->assertSame(250, $this->service()->customerLimit($tenantB));
    }
}
