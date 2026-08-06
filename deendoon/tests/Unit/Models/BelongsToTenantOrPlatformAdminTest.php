<?php

namespace Tests\Unit\Models;

use App\Models\StorageAddon;
use App\Models\SubscriptionChangeRequest;
use App\Models\SubscriptionPlan;
use App\Models\Tenant;
use App\Models\TenantSubscription;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * Backend Completion Roadmap, Phase 3.2 (Product Owner Decision: Option B
 * — Conditional Global Scope). Direct coverage of the
 * BelongsToTenantOrPlatformAdmin trait's query-scoping behavior, via raw
 * model queries (deliberately NOT through SubscriptionService/
 * StorageAddonService, which always filter explicitly regardless of this
 * scope) — this is what proves the scope itself, not the services'
 * belt-and-suspenders filtering.
 *
 * All 3 models the trait is applied to are exercised individually, not
 * just one representative — a per-file application mistake wouldn't be
 * caught by testing only one.
 */
class BelongsToTenantOrPlatformAdminTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RoleSeeder::class);
    }

    private function tenantUser(Tenant $tenant): User
    {
        $user = User::factory()->create();
        $user->tenant()->associate($tenant);
        $user->save();
        $user->assignRole('admin');

        return $user;
    }

    private function platformAdmin(): User
    {
        $admin = User::factory()->create();
        $admin->assignRole('deendoon_platform_administrator');

        return $admin;
    }

    private function seedTwoTenants(): array
    {
        $tenantA = Tenant::create(['business_name' => 'Tenant A']);
        $tenantB = Tenant::create(['business_name' => 'Tenant B']);
        $plan = SubscriptionPlan::factory()->create();

        TenantSubscription::factory()->for($tenantA, 'tenant')->for($plan, 'plan')->create();
        TenantSubscription::factory()->for($tenantB, 'tenant')->for($plan, 'plan')->create();

        return [$tenantA, $tenantB, $plan];
    }

    // --- TenantSubscription ---

    public function test_tenant_subscription_query_is_restricted_to_the_authenticated_tenant_users_own_tenant(): void
    {
        [$tenantA, $tenantB] = $this->seedTwoTenants();
        Sanctum::actingAs($this->tenantUser($tenantA));

        $results = TenantSubscription::all();

        $this->assertCount(1, $results);
        $this->assertTrue($results->first()->tenant_id === $tenantA->id);
    }

    public function test_tenant_subscription_query_is_unrestricted_for_the_platform_administrator(): void
    {
        [$tenantA, $tenantB] = $this->seedTwoTenants();
        Sanctum::actingAs($this->platformAdmin());

        $this->assertCount(2, TenantSubscription::all());
    }

    public function test_tenant_subscription_query_is_unrestricted_with_no_authenticated_user(): void
    {
        // Matches BelongsToTenant's own unauthenticated-context behavior
        // (console/job/test setup, no filter applied).
        $this->seedTwoTenants();

        $this->assertCount(2, TenantSubscription::all());
    }

    public function test_tenant_subscription_query_fails_closed_for_a_null_tenant_user_without_the_admin_role(): void
    {
        // A null-tenant actor alone is not sufficient — isPlatformAdmin()
        // requires the specific role too. Without it, this falls through
        // to the ordinary tenant-restriction branch with a null tenant_id,
        // matching nothing (the same fail-closed outcome BelongsToTenant
        // documents for this exact case).
        $this->seedTwoTenants();
        $rogueUser = User::factory()->create();
        Sanctum::actingAs($rogueUser);

        $this->assertCount(0, TenantSubscription::all());
    }

    // --- SubscriptionChangeRequest ---

    public function test_subscription_change_request_query_is_restricted_to_the_authenticated_tenant_users_own_tenant(): void
    {
        $tenantA = Tenant::create(['business_name' => 'Tenant A']);
        $tenantB = Tenant::create(['business_name' => 'Tenant B']);
        $plan = SubscriptionPlan::factory()->create();
        SubscriptionChangeRequest::factory()->for($plan, 'requestedPlan')->create(['tenant_id' => $tenantA->id]);
        SubscriptionChangeRequest::factory()->for($plan, 'requestedPlan')->create(['tenant_id' => $tenantB->id]);

        Sanctum::actingAs($this->tenantUser($tenantA));

        $results = SubscriptionChangeRequest::all();

        $this->assertCount(1, $results);
        $this->assertSame($tenantA->id, $results->first()->tenant_id);
    }

    public function test_subscription_change_request_query_is_unrestricted_for_the_platform_administrator(): void
    {
        $tenantA = Tenant::create(['business_name' => 'Tenant A']);
        $tenantB = Tenant::create(['business_name' => 'Tenant B']);
        $plan = SubscriptionPlan::factory()->create();
        SubscriptionChangeRequest::factory()->for($plan, 'requestedPlan')->create(['tenant_id' => $tenantA->id]);
        SubscriptionChangeRequest::factory()->for($plan, 'requestedPlan')->create(['tenant_id' => $tenantB->id]);

        Sanctum::actingAs($this->platformAdmin());

        $this->assertCount(2, SubscriptionChangeRequest::all());
    }

    // --- StorageAddon ---

    public function test_storage_addon_query_is_restricted_to_the_authenticated_tenant_users_own_tenant(): void
    {
        $tenantA = Tenant::create(['business_name' => 'Tenant A']);
        $tenantB = Tenant::create(['business_name' => 'Tenant B']);
        StorageAddon::factory()->create(['tenant_id' => $tenantA->id]);
        StorageAddon::factory()->create(['tenant_id' => $tenantB->id]);

        Sanctum::actingAs($this->tenantUser($tenantA));

        $results = StorageAddon::all();

        $this->assertCount(1, $results);
        $this->assertSame($tenantA->id, $results->first()->tenant_id);
    }

    public function test_storage_addon_query_is_unrestricted_for_the_platform_administrator(): void
    {
        $tenantA = Tenant::create(['business_name' => 'Tenant A']);
        $tenantB = Tenant::create(['business_name' => 'Tenant B']);
        StorageAddon::factory()->create(['tenant_id' => $tenantA->id]);
        StorageAddon::factory()->create(['tenant_id' => $tenantB->id]);

        Sanctum::actingAs($this->platformAdmin());

        $this->assertCount(2, StorageAddon::all());
    }

    // --- User::isPlatformAdmin() ---

    public function test_is_platform_admin_requires_both_null_tenant_and_the_role(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $tenantUser = $this->tenantUser($tenant);
        $rogueNullTenantUser = User::factory()->create();
        $realAdmin = $this->platformAdmin();

        $this->assertFalse($tenantUser->isPlatformAdmin());
        $this->assertFalse($rogueNullTenantUser->isPlatformAdmin());
        $this->assertTrue($realAdmin->isPlatformAdmin());
    }
}
