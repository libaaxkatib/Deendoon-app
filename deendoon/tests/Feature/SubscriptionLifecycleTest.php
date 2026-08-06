<?php

namespace Tests\Feature;

use App\Models\AuditLog;
use App\Models\Customer;
use App\Models\SubscriptionPlan;
use App\Models\Tenant;
use App\Models\TenantSubscription;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Backend Completion Roadmap, Phase 4.3 — Subscription Lifecycle.
 * End-to-end coverage of the two lifecycle Artisan commands
 * (`subscriptions:expire-trials`, `subscriptions:expire`), mirroring
 * FireDueRemindersTest's exact convention: $this->artisan(...), no
 * scheduler, no queue — these commands are the only precedent for
 * "background-style" processing this codebase has.
 */
class SubscriptionLifecycleTest extends TestCase
{
    use RefreshDatabase;

    private function tenant(): Tenant
    {
        return Tenant::create(['business_name' => 'Acme Co']);
    }

    // --- subscriptions:expire-trials ---

    public function test_expire_trials_command_moves_an_expired_trial_to_the_free_plan(): void
    {
        $tenant = $this->tenant();
        $trialPlan = SubscriptionPlan::factory()->create(['name' => 'Trial']);
        SubscriptionPlan::factory()->create(['name' => 'Free', 'customer_limit' => 2]);
        $subscription = TenantSubscription::factory()->for($tenant, 'tenant')->for($trialPlan, 'plan')->create([
            'status' => 'trialing',
            'trial_ends_at' => now()->subMinute(),
        ]);

        $this->artisan('subscriptions:expire-trials')->assertExitCode(0);

        $subscription->refresh();
        $this->assertSame('Free', $subscription->plan->name);
        $this->assertSame('active', $subscription->status);
    }

    public function test_expire_trials_command_leaves_a_trial_still_within_its_7_day_window_untouched(): void
    {
        // Product Owner Decision (2026-08-06): trial duration remains 7
        // days (provisionTrial() unchanged) — the "14 days" wording in
        // this phase's own brief was outdated documentation.
        $tenant = $this->tenant();
        $trialPlan = SubscriptionPlan::factory()->create(['name' => 'Trial']);
        SubscriptionPlan::factory()->create(['name' => 'Free']);
        $subscription = TenantSubscription::factory()->for($tenant, 'tenant')->for($trialPlan, 'plan')->create([
            'status' => 'trialing',
            'started_at' => now()->subDays(6),
            'trial_started_at' => now()->subDays(6),
            'trial_ends_at' => now()->subDays(6)->addDays(7),
        ]);

        $this->artisan('subscriptions:expire-trials')->assertExitCode(0);

        $this->assertSame('trialing', $subscription->fresh()->status);
    }

    public function test_expire_trials_command_moves_a_trial_exactly_at_its_7_day_boundary(): void
    {
        $tenant = $this->tenant();
        $trialPlan = SubscriptionPlan::factory()->create(['name' => 'Trial']);
        SubscriptionPlan::factory()->create(['name' => 'Free']);
        $startedAt = now()->subDays(7)->subSecond();
        $subscription = TenantSubscription::factory()->for($tenant, 'tenant')->for($trialPlan, 'plan')->create([
            'status' => 'trialing',
            'started_at' => $startedAt,
            'trial_started_at' => $startedAt,
            'trial_ends_at' => $startedAt->copy()->addDays(7),
        ]);

        $this->artisan('subscriptions:expire-trials')->assertExitCode(0);

        $this->assertSame('active', $subscription->fresh()->status);
    }

    public function test_expire_trials_command_recalculates_customer_read_only_status_against_the_free_limit(): void
    {
        // "Customer/Storage limits immediately become Free limits" —
        // Trial is unlimited, so both customers below start editable;
        // Free's limit of 1 must immediately mark the newer one
        // read-only once the command runs.
        $tenant = $this->tenant();
        $trialPlan = SubscriptionPlan::factory()->unlimited()->create(['name' => 'Trial']);
        SubscriptionPlan::factory()->create(['name' => 'Free', 'customer_limit' => 1]);
        TenantSubscription::factory()->for($tenant, 'tenant')->for($trialPlan, 'plan')->create([
            'status' => 'trialing',
            'trial_ends_at' => now()->subMinute(),
        ]);
        $oldest = Customer::factory()->for($tenant, 'tenant')->create(['created_at' => '2026-01-01']);
        $newest = Customer::factory()->for($tenant, 'tenant')->create(['created_at' => '2026-01-02']);

        $this->artisan('subscriptions:expire-trials')->assertExitCode(0);

        $this->assertFalse($oldest->fresh()->is_read_only);
        $this->assertTrue($newest->fresh()->is_read_only);
    }

    public function test_expire_trials_command_records_an_audit_entry(): void
    {
        $tenant = $this->tenant();
        $trialPlan = SubscriptionPlan::factory()->create(['name' => 'Trial']);
        SubscriptionPlan::factory()->create(['name' => 'Free']);
        $subscription = TenantSubscription::factory()->for($tenant, 'tenant')->for($trialPlan, 'plan')->create([
            'status' => 'trialing',
            'trial_ends_at' => now()->subMinute(),
        ]);

        $this->artisan('subscriptions:expire-trials');

        $this->assertDatabaseHas('audit_log', [
            'tenant_id' => $tenant->id,
            'action' => 'trial_expired',
            'entity_type' => 'tenant_subscription',
            'entity_id' => $subscription->id,
        ]);
    }

    public function test_expire_trials_command_run_twice_does_not_duplicate_the_audit_entry(): void
    {
        $tenant = $this->tenant();
        $trialPlan = SubscriptionPlan::factory()->create(['name' => 'Trial']);
        SubscriptionPlan::factory()->create(['name' => 'Free']);
        TenantSubscription::factory()->for($tenant, 'tenant')->for($trialPlan, 'plan')->create([
            'status' => 'trialing',
            'trial_ends_at' => now()->subMinute(),
        ]);

        $this->artisan('subscriptions:expire-trials')->assertExitCode(0);
        $this->artisan('subscriptions:expire-trials')->assertExitCode(0);

        $this->assertSame(1, AuditLog::where('action', 'trial_expired')->count());
    }

    public function test_expire_trials_command_only_affects_the_tenant_whose_trial_actually_expired(): void
    {
        $tenantA = $this->tenant();
        $tenantB = Tenant::create(['business_name' => 'Other Co']);
        $trialPlan = SubscriptionPlan::factory()->create(['name' => 'Trial']);
        SubscriptionPlan::factory()->create(['name' => 'Free']);
        $subscriptionA = TenantSubscription::factory()->for($tenantA, 'tenant')->for($trialPlan, 'plan')->create([
            'status' => 'trialing', 'trial_ends_at' => now()->subMinute(),
        ]);
        $subscriptionB = TenantSubscription::factory()->for($tenantB, 'tenant')->for($trialPlan, 'plan')->create([
            'status' => 'trialing', 'trial_ends_at' => now()->addDays(3),
        ]);

        $this->artisan('subscriptions:expire-trials')->assertExitCode(0);

        $this->assertSame('active', $subscriptionA->fresh()->status);
        $this->assertSame('trialing', $subscriptionB->fresh()->status);
    }

    // --- subscriptions:expire ---

    public function test_expire_command_marks_an_expired_paid_subscription_as_expired(): void
    {
        $tenant = $this->tenant();
        $plan = SubscriptionPlan::factory()->create(['name' => 'Small Business']);
        $subscription = TenantSubscription::factory()->for($tenant, 'tenant')->for($plan, 'plan')->create([
            'status' => 'active',
            'expires_at' => now()->subMinute(),
        ]);

        $this->artisan('subscriptions:expire')->assertExitCode(0);

        $this->assertSame('expired', $subscription->fresh()->status);
    }

    public function test_expire_command_ignores_a_subscription_that_has_not_expired_yet(): void
    {
        $tenant = $this->tenant();
        $plan = SubscriptionPlan::factory()->create();
        $subscription = TenantSubscription::factory()->for($tenant, 'tenant')->for($plan, 'plan')->create([
            'status' => 'active',
            'expires_at' => now()->addDays(10),
        ]);

        $this->artisan('subscriptions:expire')->assertExitCode(0);

        $this->assertSame('active', $subscription->fresh()->status);
    }

    public function test_expire_command_ignores_an_already_expired_subscription(): void
    {
        $tenant = $this->tenant();
        $plan = SubscriptionPlan::factory()->create();
        TenantSubscription::factory()->for($tenant, 'tenant')->for($plan, 'plan')->expired()->create();

        $this->artisan('subscriptions:expire')->assertExitCode(0);

        $this->assertSame(0, AuditLog::where('action', 'subscription_expired')->count());
    }

    public function test_expire_command_never_expires_a_free_plan_subscription_produced_by_trial_expiration(): void
    {
        $tenant = $this->tenant();
        $trialPlan = SubscriptionPlan::factory()->create(['name' => 'Trial']);
        SubscriptionPlan::factory()->create(['name' => 'Free']);
        $subscription = TenantSubscription::factory()->for($tenant, 'tenant')->for($trialPlan, 'plan')->create([
            'status' => 'trialing',
            'trial_ends_at' => now()->subMinute(),
        ]);
        $this->artisan('subscriptions:expire-trials')->assertExitCode(0);

        $this->artisan('subscriptions:expire')->assertExitCode(0);

        $this->assertSame('active', $subscription->fresh()->status);
    }

    public function test_expire_command_records_an_audit_entry(): void
    {
        $tenant = $this->tenant();
        $plan = SubscriptionPlan::factory()->create();
        $subscription = TenantSubscription::factory()->for($tenant, 'tenant')->for($plan, 'plan')->create([
            'status' => 'active',
            'expires_at' => now()->subMinute(),
        ]);

        $this->artisan('subscriptions:expire');

        $this->assertDatabaseHas('audit_log', [
            'tenant_id' => $tenant->id,
            'action' => 'subscription_expired',
            'entity_type' => 'tenant_subscription',
            'entity_id' => $subscription->id,
        ]);
    }

    public function test_expire_command_run_twice_does_not_duplicate_the_audit_entry(): void
    {
        $tenant = $this->tenant();
        $plan = SubscriptionPlan::factory()->create();
        TenantSubscription::factory()->for($tenant, 'tenant')->for($plan, 'plan')->create([
            'status' => 'active',
            'expires_at' => now()->subMinute(),
        ]);

        $this->artisan('subscriptions:expire')->assertExitCode(0);
        $this->artisan('subscriptions:expire')->assertExitCode(0);

        $this->assertSame(1, AuditLog::where('action', 'subscription_expired')->count());
    }

    public function test_expire_command_only_affects_the_tenant_whose_subscription_actually_expired(): void
    {
        $tenantA = $this->tenant();
        $tenantB = Tenant::create(['business_name' => 'Other Co']);
        $plan = SubscriptionPlan::factory()->create();
        $subscriptionA = TenantSubscription::factory()->for($tenantA, 'tenant')->for($plan, 'plan')->create([
            'status' => 'active', 'expires_at' => now()->subMinute(),
        ]);
        $subscriptionB = TenantSubscription::factory()->for($tenantB, 'tenant')->for($plan, 'plan')->create([
            'status' => 'active', 'expires_at' => now()->addDays(5),
        ]);

        $this->artisan('subscriptions:expire')->assertExitCode(0);

        $this->assertSame('expired', $subscriptionA->fresh()->status);
        $this->assertSame('active', $subscriptionB->fresh()->status);
    }
}
