<?php

namespace Tests\Unit\Services;

use App\Models\AuditLog;
use App\Models\SubscriptionPlan;
use App\Models\Tenant;
use App\Models\TenantSubscription;
use App\Services\SubscriptionService;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Backend Completion Roadmap, Phase 3.2 — direct coverage of
 * SubscriptionService. Mostly read-only queries; {@see requestUpgrade()}
 * (Phase 3.4) is covered end-to-end via tests/Feature/SubscriptionTest.php
 * instead (that phase's explicit ask was Feature Tests), while
 * {@see SubscriptionServiceTest::test_provision_trial_creates_a_trialing_subscription_on_the_trial_plan()}
 * below adds direct Unit coverage for {@see provisionTrial()} (Phase 3.5).
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

    // --- Effective customer limit: expired subscription (Phase 4.4) ---

    public function test_effective_customer_limit_is_zero_for_an_expired_subscription(): void
    {
        $tenant = $this->tenant();
        $plan = SubscriptionPlan::factory()->create(['customer_limit' => 250]);
        TenantSubscription::factory()->for($tenant, 'tenant')->for($plan, 'plan')->expired()->create();

        $this->assertSame(0, $this->service()->effectiveCustomerLimit($tenant));
    }

    public function test_effective_customer_limit_is_zero_for_an_expired_subscription_even_on_an_unlimited_plan(): void
    {
        // An expired Corporate subscription must not fall back to
        // "unlimited" just because the plan's own customer_limit is null.
        $tenant = $this->tenant();
        $plan = SubscriptionPlan::factory()->unlimited()->create(['name' => 'Corporate']);
        TenantSubscription::factory()->for($tenant, 'tenant')->for($plan, 'plan')->expired()->create();

        $this->assertSame(0, $this->service()->effectiveCustomerLimit($tenant));
    }

    public function test_effective_customer_limit_is_unaffected_by_expired_status_for_an_active_subscription(): void
    {
        $tenant = $this->tenant();
        $plan = SubscriptionPlan::factory()->create(['customer_limit' => 110]);
        TenantSubscription::factory()->for($tenant, 'tenant')->for($plan, 'plan')->active()->create();

        $this->assertSame(110, $this->service()->effectiveCustomerLimit($tenant));
    }

    public function test_effective_customer_limit_is_unaffected_by_expired_status_while_trialing(): void
    {
        $tenant = $this->tenant();
        $plan = SubscriptionPlan::factory()->unlimited()->create(['name' => 'Trial']);
        TenantSubscription::factory()->for($tenant, 'tenant')->for($plan, 'plan')->create([
            'status' => 'trialing',
            'trial_ends_at' => now()->addDays(7),
        ]);

        $this->assertNull($this->service()->effectiveCustomerLimit($tenant));
    }

    public function test_effective_customer_limit_does_not_treat_a_free_plan_subscription_as_expired(): void
    {
        // The exact state expireTrials() produces: status 'active',
        // expires_at null — must resolve to the Free plan's own limit,
        // not 0.
        $tenant = $this->tenant();
        $freePlan = SubscriptionPlan::factory()->create(['name' => 'Free', 'customer_limit' => 2]);
        TenantSubscription::factory()->for($tenant, 'tenant')->for($freePlan, 'plan')->create([
            'status' => 'active',
            'expires_at' => null,
        ]);

        $this->assertSame(2, $this->service()->effectiveCustomerLimit($tenant));
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

    // --- Trial provisioning (Phase 3.5) ---

    public function test_provision_trial_creates_a_trialing_subscription_on_the_trial_plan(): void
    {
        $tenant = $this->tenant();
        $trialPlan = SubscriptionPlan::factory()->create(['name' => 'Trial']);

        $subscription = $this->service()->provisionTrial($tenant);

        $this->assertSame($trialPlan->id, $subscription->plan_id);
        $this->assertSame('trialing', $subscription->status);
        $this->assertNotNull($subscription->started_at);
        $this->assertNotNull($subscription->trial_started_at);
        $this->assertTrue($subscription->trial_ends_at->isFuture());
        $this->assertSame(
            $subscription->trial_ends_at->toDateTimeString(),
            $subscription->expires_at->toDateTimeString(),
        );
    }

    public function test_provision_trial_fails_when_no_trial_plan_is_seeded(): void
    {
        $tenant = $this->tenant();

        $this->expectException(ModelNotFoundException::class);

        $this->service()->provisionTrial($tenant);
    }

    // --- Trial expiration (Phase 4.3) ---

    public function test_expire_trials_moves_an_expired_trial_to_the_free_plan(): void
    {
        $tenant = $this->tenant();
        $trialPlan = SubscriptionPlan::factory()->create(['name' => 'Trial']);
        $freePlan = SubscriptionPlan::factory()->create(['name' => 'Free']);
        $subscription = TenantSubscription::factory()->for($tenant, 'tenant')->for($trialPlan, 'plan')->create([
            'status' => 'trialing',
            'trial_ends_at' => now()->subMinute(),
        ]);

        $affected = $this->service()->expireTrials();

        $subscription->refresh();
        $this->assertSame($freePlan->id, $subscription->plan_id);
        $this->assertSame('active', $subscription->status);
        $this->assertNull($subscription->expires_at);
        $this->assertCount(1, $affected);
        $this->assertTrue($affected->first()->is($tenant));
    }

    public function test_expire_trials_preserves_the_original_trial_dates(): void
    {
        $tenant = $this->tenant();
        SubscriptionPlan::factory()->create(['name' => 'Trial']);
        SubscriptionPlan::factory()->create(['name' => 'Free']);
        $trialStarted = now()->subDays(8);
        $trialEnded = now()->subDay();
        $subscription = TenantSubscription::factory()->for($tenant, 'tenant')->for(SubscriptionPlan::where('name', 'Trial')->first(), 'plan')->create([
            'status' => 'trialing',
            'trial_started_at' => $trialStarted,
            'trial_ends_at' => $trialEnded,
        ]);

        $this->service()->expireTrials();

        $subscription->refresh();
        $this->assertSame($trialStarted->toDateTimeString(), $subscription->trial_started_at->toDateTimeString());
        $this->assertSame($trialEnded->toDateTimeString(), $subscription->trial_ends_at->toDateTimeString());
    }

    public function test_expire_trials_does_not_touch_a_trial_still_within_its_window(): void
    {
        $tenant = $this->tenant();
        $trialPlan = SubscriptionPlan::factory()->create(['name' => 'Trial']);
        SubscriptionPlan::factory()->create(['name' => 'Free']);
        $subscription = TenantSubscription::factory()->for($tenant, 'tenant')->for($trialPlan, 'plan')->create([
            'status' => 'trialing',
            'trial_ends_at' => now()->addDay(),
        ]);

        $affected = $this->service()->expireTrials();

        $this->assertCount(0, $affected);
        $this->assertSame('trialing', $subscription->fresh()->status);
    }

    public function test_expire_trials_ignores_a_non_trialing_subscription_regardless_of_its_trial_ends_at(): void
    {
        $tenant = $this->tenant();
        $plan = SubscriptionPlan::factory()->create();
        SubscriptionPlan::factory()->create(['name' => 'Free']);
        TenantSubscription::factory()->for($tenant, 'tenant')->for($plan, 'plan')->active()->create([
            'trial_ends_at' => now()->subMonth(),
        ]);

        $affected = $this->service()->expireTrials();

        $this->assertCount(0, $affected);
    }

    public function test_expire_trials_records_a_trial_expired_audit_entry(): void
    {
        $tenant = $this->tenant();
        $trialPlan = SubscriptionPlan::factory()->create(['name' => 'Trial']);
        SubscriptionPlan::factory()->create(['name' => 'Free']);
        $subscription = TenantSubscription::factory()->for($tenant, 'tenant')->for($trialPlan, 'plan')->create([
            'status' => 'trialing',
            'trial_ends_at' => now()->subMinute(),
        ]);

        $this->service()->expireTrials();

        $this->assertDatabaseHas('audit_log', [
            'tenant_id' => $tenant->id,
            'user_id' => null,
            'action' => 'trial_expired',
            'entity_type' => 'tenant_subscription',
            'entity_id' => $subscription->id,
        ]);
    }

    public function test_expire_trials_run_twice_is_idempotent(): void
    {
        $tenant = $this->tenant();
        $trialPlan = SubscriptionPlan::factory()->create(['name' => 'Trial']);
        SubscriptionPlan::factory()->create(['name' => 'Free']);
        TenantSubscription::factory()->for($tenant, 'tenant')->for($trialPlan, 'plan')->create([
            'status' => 'trialing',
            'trial_ends_at' => now()->subMinute(),
        ]);

        $first = $this->service()->expireTrials();
        $second = $this->service()->expireTrials();

        $this->assertCount(1, $first);
        $this->assertCount(0, $second);
        $this->assertSame(1, AuditLog::where('action', 'trial_expired')->count());
    }

    public function test_expire_trials_fails_when_no_free_plan_is_seeded(): void
    {
        $tenant = $this->tenant();
        $trialPlan = SubscriptionPlan::factory()->create(['name' => 'Trial']);
        TenantSubscription::factory()->for($tenant, 'tenant')->for($trialPlan, 'plan')->create([
            'status' => 'trialing',
            'trial_ends_at' => now()->subMinute(),
        ]);

        $this->expectException(ModelNotFoundException::class);

        $this->service()->expireTrials();
    }

    public function test_expire_trials_only_affects_tenants_with_an_actually_expired_trial(): void
    {
        $tenantA = $this->tenant();
        $tenantB = Tenant::create(['business_name' => 'Other Co']);
        $trialPlan = SubscriptionPlan::factory()->create(['name' => 'Trial']);
        SubscriptionPlan::factory()->create(['name' => 'Free']);
        TenantSubscription::factory()->for($tenantA, 'tenant')->for($trialPlan, 'plan')->create([
            'status' => 'trialing', 'trial_ends_at' => now()->subMinute(),
        ]);
        $subscriptionB = TenantSubscription::factory()->for($tenantB, 'tenant')->for($trialPlan, 'plan')->create([
            'status' => 'trialing', 'trial_ends_at' => now()->addDay(),
        ]);

        $affected = $this->service()->expireTrials();

        $this->assertCount(1, $affected);
        $this->assertTrue($affected->first()->is($tenantA));
        $this->assertSame('trialing', $subscriptionB->fresh()->status);
    }

    // --- Subscription expiration (Phase 4.3) ---

    public function test_expire_subscriptions_marks_an_expired_paid_subscription_as_expired(): void
    {
        $tenant = $this->tenant();
        $plan = SubscriptionPlan::factory()->create(['name' => 'Small Business']);
        $subscription = TenantSubscription::factory()->for($tenant, 'tenant')->for($plan, 'plan')->create([
            'status' => 'active',
            'expires_at' => now()->subMinute(),
        ]);

        $affected = $this->service()->expireSubscriptions();

        $this->assertCount(1, $affected);
        $this->assertTrue($affected->first()->is($tenant));
        $this->assertSame('expired', $subscription->fresh()->status);
    }

    public function test_expire_subscriptions_does_not_change_the_plan(): void
    {
        $tenant = $this->tenant();
        $plan = SubscriptionPlan::factory()->create(['name' => 'Small Business']);
        $subscription = TenantSubscription::factory()->for($tenant, 'tenant')->for($plan, 'plan')->create([
            'status' => 'active',
            'expires_at' => now()->subMinute(),
        ]);

        $this->service()->expireSubscriptions();

        $this->assertSame($plan->id, $subscription->fresh()->plan_id);
    }

    public function test_expire_subscriptions_ignores_a_subscription_expiring_in_the_future(): void
    {
        $tenant = $this->tenant();
        $plan = SubscriptionPlan::factory()->create();
        $subscription = TenantSubscription::factory()->for($tenant, 'tenant')->for($plan, 'plan')->create([
            'status' => 'active',
            'expires_at' => now()->addDay(),
        ]);

        $affected = $this->service()->expireSubscriptions();

        $this->assertCount(0, $affected);
        $this->assertSame('active', $subscription->fresh()->status);
    }

    public function test_expire_subscriptions_ignores_an_already_expired_subscription(): void
    {
        $tenant = $this->tenant();
        $plan = SubscriptionPlan::factory()->create();
        TenantSubscription::factory()->for($tenant, 'tenant')->for($plan, 'plan')->expired()->create();

        $affected = $this->service()->expireSubscriptions();

        $this->assertCount(0, $affected);
    }

    public function test_expire_subscriptions_never_sweeps_a_free_plan_subscription_with_no_expiry(): void
    {
        // The exact scenario expireTrials() produces: status 'active',
        // expires_at null. Must never be treated as expired.
        $tenant = $this->tenant();
        $freePlan = SubscriptionPlan::factory()->create(['name' => 'Free']);
        $subscription = TenantSubscription::factory()->for($tenant, 'tenant')->for($freePlan, 'plan')->create([
            'status' => 'active',
            'expires_at' => null,
        ]);

        $affected = $this->service()->expireSubscriptions();

        $this->assertCount(0, $affected);
        $this->assertSame('active', $subscription->fresh()->status);
    }

    public function test_expire_subscriptions_records_a_subscription_expired_audit_entry(): void
    {
        $tenant = $this->tenant();
        $plan = SubscriptionPlan::factory()->create();
        $subscription = TenantSubscription::factory()->for($tenant, 'tenant')->for($plan, 'plan')->create([
            'status' => 'active',
            'expires_at' => now()->subMinute(),
        ]);

        $this->service()->expireSubscriptions();

        $this->assertDatabaseHas('audit_log', [
            'tenant_id' => $tenant->id,
            'user_id' => null,
            'action' => 'subscription_expired',
            'entity_type' => 'tenant_subscription',
            'entity_id' => $subscription->id,
        ]);
    }

    public function test_expire_subscriptions_run_twice_is_idempotent(): void
    {
        $tenant = $this->tenant();
        $plan = SubscriptionPlan::factory()->create();
        TenantSubscription::factory()->for($tenant, 'tenant')->for($plan, 'plan')->create([
            'status' => 'active',
            'expires_at' => now()->subMinute(),
        ]);

        $first = $this->service()->expireSubscriptions();
        $second = $this->service()->expireSubscriptions();

        $this->assertCount(1, $first);
        $this->assertCount(0, $second);
        $this->assertSame(1, AuditLog::where('action', 'subscription_expired')->count());
    }

    public function test_expire_subscriptions_only_affects_tenants_with_an_actually_expired_subscription(): void
    {
        $tenantA = $this->tenant();
        $tenantB = Tenant::create(['business_name' => 'Other Co']);
        $plan = SubscriptionPlan::factory()->create();
        $subscriptionA = TenantSubscription::factory()->for($tenantA, 'tenant')->for($plan, 'plan')->create([
            'status' => 'active', 'expires_at' => now()->subMinute(),
        ]);
        $subscriptionB = TenantSubscription::factory()->for($tenantB, 'tenant')->for($plan, 'plan')->create([
            'status' => 'active', 'expires_at' => now()->addDay(),
        ]);

        $this->service()->expireSubscriptions();

        $this->assertSame('expired', $subscriptionA->fresh()->status);
        $this->assertSame('active', $subscriptionB->fresh()->status);
    }
}
