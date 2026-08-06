<?php

namespace Tests\Unit\Models;

use App\Models\StorageAddon;
use App\Models\SubscriptionChangeRequest;
use App\Models\SubscriptionPlan;
use App\Models\Tenant;
use App\Models\TenantSubscription;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Tests\TestCase;

/**
 * Backend Completion Roadmap, Phase 3.2 — relationships and casts for the
 * 4 Subscription domain models plus Tenant's 3 new relations. No service
 * currently exercises every path here (e.g. SubscriptionChangeRequest's
 * relations aren't touched by SubscriptionService/StorageAddonService at
 * all), hence a dedicated model-level test rather than folding this into
 * the service tests.
 */
class SubscriptionModelsTest extends TestCase
{
    use RefreshDatabase;

    private function tenant(): Tenant
    {
        return Tenant::create(['business_name' => 'Acme Co']);
    }

    // --- Tenant relations ---

    public function test_tenant_has_one_subscription(): void
    {
        $tenant = $this->tenant();
        $plan = SubscriptionPlan::factory()->create();
        $subscription = TenantSubscription::factory()->for($tenant, 'tenant')->for($plan, 'plan')->create();

        $this->assertTrue($tenant->subscription->is($subscription));
    }

    public function test_tenant_has_many_subscription_change_requests(): void
    {
        $tenant = $this->tenant();
        $plan = SubscriptionPlan::factory()->create();
        SubscriptionChangeRequest::factory()->for($plan, 'requestedPlan')->create(['tenant_id' => $tenant->id]);
        SubscriptionChangeRequest::factory()->for($plan, 'requestedPlan')->create(['tenant_id' => $tenant->id]);

        $this->assertCount(2, $tenant->subscriptionChangeRequests);
    }

    public function test_tenant_has_many_storage_addons(): void
    {
        $tenant = $this->tenant();
        StorageAddon::factory()->for($tenant, 'tenant')->create();
        StorageAddon::factory()->for($tenant, 'tenant')->create();

        $this->assertCount(2, $tenant->storageAddons);
    }

    // --- SubscriptionPlan relations ---

    public function test_subscription_plan_has_many_tenant_subscriptions(): void
    {
        $plan = SubscriptionPlan::factory()->create();
        TenantSubscription::factory()->for($this->tenant(), 'tenant')->for($plan, 'plan')->create();
        TenantSubscription::factory()->for($this->tenant(), 'tenant')->for($plan, 'plan')->create();

        $this->assertCount(2, $plan->tenantSubscriptions);
    }

    public function test_subscription_plan_distinguishes_requested_from_current_change_requests(): void
    {
        $requestedPlan = SubscriptionPlan::factory()->create(['name' => 'Medium Business']);
        $currentPlan = SubscriptionPlan::factory()->create(['name' => 'Small Business']);
        $tenant = $this->tenant();
        SubscriptionChangeRequest::factory()
            ->for($requestedPlan, 'requestedPlan')
            ->for($currentPlan, 'currentPlan')
            ->create(['tenant_id' => $tenant->id]);

        $this->assertCount(1, $requestedPlan->requestedInChangeRequests);
        $this->assertCount(0, $requestedPlan->currentInChangeRequests);
        $this->assertCount(1, $currentPlan->currentInChangeRequests);
        $this->assertCount(0, $currentPlan->requestedInChangeRequests);
    }

    // --- TenantSubscription relations ---

    public function test_tenant_subscription_belongs_to_tenant_and_plan(): void
    {
        $tenant = $this->tenant();
        $plan = SubscriptionPlan::factory()->create();
        $subscription = TenantSubscription::factory()->for($tenant, 'tenant')->for($plan, 'plan')->create();

        $this->assertTrue($subscription->tenant->is($tenant));
        $this->assertTrue($subscription->plan->is($plan));
    }

    // --- SubscriptionChangeRequest relations ---

    public function test_subscription_change_request_belongs_to_tenant_and_both_plans(): void
    {
        $tenant = $this->tenant();
        $requestedPlan = SubscriptionPlan::factory()->create();
        $currentPlan = SubscriptionPlan::factory()->create();
        $request = SubscriptionChangeRequest::factory()
            ->for($requestedPlan, 'requestedPlan')
            ->for($currentPlan, 'currentPlan')
            ->create(['tenant_id' => $tenant->id]);

        $this->assertTrue($request->tenant->is($tenant));
        $this->assertTrue($request->requestedPlan->is($requestedPlan));
        $this->assertTrue($request->currentPlan->is($currentPlan));
    }

    // --- StorageAddon relations ---

    public function test_storage_addon_belongs_to_tenant(): void
    {
        $tenant = $this->tenant();
        $addon = StorageAddon::factory()->for($tenant, 'tenant')->create();

        $this->assertTrue($addon->tenant->is($tenant));
    }

    // --- Casts ---

    public function test_subscription_plan_casts(): void
    {
        $plan = SubscriptionPlan::factory()->create([
            'customer_limit' => '110',
            'analytics_enabled' => 1,
            'storage_limit' => '25',
            'monthly_price' => '5.00',
            'active' => 1,
        ]);

        $this->assertIsInt($plan->customer_limit);
        $this->assertIsBool($plan->analytics_enabled);
        $this->assertIsInt($plan->storage_limit);
        $this->assertSame('5.00', $plan->monthly_price);
        $this->assertIsBool($plan->active);
    }

    public function test_subscription_plan_customer_limit_cast_preserves_null_for_unlimited(): void
    {
        $plan = SubscriptionPlan::factory()->unlimited()->create();

        $this->assertNull($plan->customer_limit);
    }

    public function test_tenant_subscription_date_casts(): void
    {
        $tenant = $this->tenant();
        $plan = SubscriptionPlan::factory()->create();
        $subscription = TenantSubscription::factory()->for($tenant, 'tenant')->for($plan, 'plan')->create([
            'started_at' => now(),
            'trial_started_at' => now(),
            'trial_ends_at' => now()->addDays(7),
        ]);

        $this->assertInstanceOf(Carbon::class, $subscription->started_at);
        $this->assertInstanceOf(Carbon::class, $subscription->trial_started_at);
        $this->assertInstanceOf(Carbon::class, $subscription->trial_ends_at);
    }

    public function test_storage_addon_casts(): void
    {
        $tenant = $this->tenant();
        $addon = StorageAddon::factory()->for($tenant, 'tenant')->create([
            'storage_size' => '25',
            'monthly_price' => '4.00',
        ]);

        $this->assertIsInt($addon->storage_size);
        $this->assertSame('4.00', $addon->monthly_price);
    }
}
