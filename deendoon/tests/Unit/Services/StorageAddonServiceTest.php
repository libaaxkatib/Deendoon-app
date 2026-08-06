<?php

namespace Tests\Unit\Services;

use App\Models\StorageAddon;
use App\Models\SubscriptionPlan;
use App\Models\Tenant;
use App\Models\TenantSubscription;
use App\Services\StorageAddonService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Backend Completion Roadmap, Phase 3.2 — direct coverage of
 * StorageAddonService. Read-only only.
 */
class StorageAddonServiceTest extends TestCase
{
    use RefreshDatabase;

    private function service(): StorageAddonService
    {
        return app(StorageAddonService::class);
    }

    private function tenant(): Tenant
    {
        return Tenant::create(['business_name' => 'Acme Co']);
    }

    private function subscribe(Tenant $tenant, int $storageLimit = 10): void
    {
        $plan = SubscriptionPlan::factory()->create(['storage_limit' => $storageLimit]);
        TenantSubscription::factory()->for($tenant, 'tenant')->for($plan, 'plan')->active()->create();
    }

    // --- Active add-ons ---

    public function test_active_addons_is_empty_when_the_tenant_has_none(): void
    {
        $tenant = $this->tenant();

        $this->assertCount(0, $this->service()->activeAddons($tenant));
    }

    public function test_active_addons_excludes_pending_expired_and_rejected_addons(): void
    {
        $tenant = $this->tenant();
        StorageAddon::factory()->for($tenant, 'tenant')->active()->create();
        StorageAddon::factory()->create(['tenant_id' => $tenant->id, 'status' => 'pending']);
        StorageAddon::factory()->create(['tenant_id' => $tenant->id, 'status' => 'expired']);
        StorageAddon::factory()->create(['tenant_id' => $tenant->id, 'status' => 'rejected']);

        $this->assertCount(1, $this->service()->activeAddons($tenant));
    }

    public function test_active_addons_includes_multiple_simultaneously_active_addons(): void
    {
        // No "at most one active add-on" constraint exists (Phase 3.1) —
        // a tenant can stack multiple.
        $tenant = $this->tenant();
        StorageAddon::factory()->for($tenant, 'tenant')->active()->create(['storage_package' => '10gb', 'storage_size' => 10]);
        StorageAddon::factory()->for($tenant, 'tenant')->active()->create(['storage_package' => '25gb', 'storage_size' => 25]);

        $this->assertCount(2, $this->service()->activeAddons($tenant));
    }

    // --- Total storage allowance ---

    public function test_total_storage_allowance_is_the_plan_limit_when_there_are_no_addons(): void
    {
        $tenant = $this->tenant();
        $this->subscribe($tenant, storageLimit: 10);

        $this->assertSame(10, $this->service()->totalStorageAllowance($tenant));
    }

    public function test_total_storage_allowance_adds_active_addons_to_the_plan_limit(): void
    {
        $tenant = $this->tenant();
        $this->subscribe($tenant, storageLimit: 10);
        StorageAddon::factory()->for($tenant, 'tenant')->active()->create(['storage_package' => '25gb', 'storage_size' => 25]);

        $this->assertSame(35, $this->service()->totalStorageAllowance($tenant));
    }

    public function test_total_storage_allowance_sums_multiple_active_addons(): void
    {
        $tenant = $this->tenant();
        $this->subscribe($tenant, storageLimit: 10);
        StorageAddon::factory()->for($tenant, 'tenant')->active()->create(['storage_package' => '10gb', 'storage_size' => 10]);
        StorageAddon::factory()->for($tenant, 'tenant')->active()->create(['storage_package' => '50gb', 'storage_size' => 50]);

        $this->assertSame(70, $this->service()->totalStorageAllowance($tenant));
    }

    public function test_total_storage_allowance_ignores_non_active_addons(): void
    {
        $tenant = $this->tenant();
        $this->subscribe($tenant, storageLimit: 10);
        StorageAddon::factory()->create(['tenant_id' => $tenant->id, 'status' => 'pending', 'storage_size' => 100]);

        $this->assertSame(10, $this->service()->totalStorageAllowance($tenant));
    }

    public function test_total_storage_allowance_is_null_when_the_tenant_has_no_subscription_and_no_free_plan_seeded(): void
    {
        $tenant = $this->tenant();

        $this->assertNull($this->service()->totalStorageAllowance($tenant));
    }

    public function test_total_storage_allowance_falls_back_to_the_free_plans_limit_when_the_tenant_has_no_subscription(): void
    {
        // Product Owner decision: a tenant with no subscription record is
        // treated as being on the Free Plan (approved base storage: 10GB).
        SubscriptionPlan::factory()->create(['name' => 'Free', 'storage_limit' => 10]);
        $tenant = $this->tenant();
        StorageAddon::factory()->for($tenant, 'tenant')->active()->create(['storage_package' => '25gb', 'storage_size' => 25]);

        $this->assertSame(35, $this->service()->totalStorageAllowance($tenant));
    }

    // --- Tenant isolation ---

    public function test_active_addons_is_tenant_isolated(): void
    {
        $tenantA = $this->tenant();
        $tenantB = Tenant::create(['business_name' => 'Other Co']);
        StorageAddon::factory()->for($tenantA, 'tenant')->active()->create();
        StorageAddon::factory()->for($tenantB, 'tenant')->active()->create();
        StorageAddon::factory()->for($tenantB, 'tenant')->active()->create();

        $this->assertCount(1, $this->service()->activeAddons($tenantA));
        $this->assertCount(2, $this->service()->activeAddons($tenantB));
    }
}
