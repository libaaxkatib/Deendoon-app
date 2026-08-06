<?php

namespace Tests\Unit\Services;

use App\Models\AuditLog;
use App\Models\Customer;
use App\Models\SubscriptionPlan;
use App\Models\Tenant;
use App\Models\TenantSubscription;
use App\Models\User;
use App\Services\CustomerReadOnlyService;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Backend Completion Roadmap, Phase 4.1 — Customer Limit Enforcement.
 * Direct coverage of CustomerReadOnlyService's recompute-from-source
 * engine: the oldest customers (by created_at) up to the plan's limit
 * stay editable, the rest become read-only, and unlimited plans never
 * mark anyone read-only.
 */
class CustomerReadOnlyServiceTest extends TestCase
{
    use RefreshDatabase;

    private function service(): CustomerReadOnlyService
    {
        return app(CustomerReadOnlyService::class);
    }

    private function tenant(): Tenant
    {
        return Tenant::create(['business_name' => 'Acme Co']);
    }

    private function subscribe(Tenant $tenant, ?int $customerLimit): SubscriptionPlan
    {
        $plan = SubscriptionPlan::factory()->create(['customer_limit' => $customerLimit]);
        TenantSubscription::factory()->for($tenant, 'tenant')->for($plan, 'plan')->active()->create();

        return $plan;
    }

    private function customerAt(Tenant $tenant, string $createdAt): Customer
    {
        return Customer::factory()->for($tenant, 'tenant')->create(['created_at' => $createdAt]);
    }

    // --- Free = 2 ---

    public function test_free_plan_keeps_only_the_oldest_2_customers_editable(): void
    {
        $tenant = $this->tenant();
        $this->subscribe($tenant, 2);
        $oldest = $this->customerAt($tenant, '2026-01-01');
        $second = $this->customerAt($tenant, '2026-01-02');
        $third = $this->customerAt($tenant, '2026-01-03');

        $this->service()->recalculate($tenant);

        $this->assertFalse($oldest->fresh()->is_read_only);
        $this->assertFalse($second->fresh()->is_read_only);
        $this->assertTrue($third->fresh()->is_read_only);
    }

    // --- Small Business = 110, Medium Business = 250 (boundary-proving, not literally 110/250 rows) ---

    public function test_customer_limit_is_respected_at_a_higher_boundary(): void
    {
        $tenant = $this->tenant();
        $this->subscribe($tenant, 3);
        $editable = [
            $this->customerAt($tenant, '2026-01-01'),
            $this->customerAt($tenant, '2026-01-02'),
            $this->customerAt($tenant, '2026-01-03'),
        ];
        $readOnly = $this->customerAt($tenant, '2026-01-04');

        $this->service()->recalculate($tenant);

        foreach ($editable as $customer) {
            $this->assertFalse($customer->fresh()->is_read_only);
        }
        $this->assertTrue($readOnly->fresh()->is_read_only);
    }

    public function test_customer_count_within_the_limit_leaves_everyone_editable(): void
    {
        $tenant = $this->tenant();
        $this->subscribe($tenant, 110);
        $customer = $this->customerAt($tenant, '2026-01-01');

        $this->service()->recalculate($tenant);

        $this->assertFalse($customer->fresh()->is_read_only);
    }

    // --- Unlimited (Corporate / Trial) ---

    public function test_unlimited_plan_never_marks_anyone_read_only(): void
    {
        $tenant = $this->tenant();
        $this->subscribe($tenant, null);
        $customers = collect(range(1, 5))->map(fn ($i) => $this->customerAt($tenant, "2026-01-0{$i}"));

        $this->service()->recalculate($tenant);

        $customers->each(fn (Customer $c) => $this->assertFalse($c->fresh()->is_read_only));
    }

    public function test_no_resolvable_plan_at_all_fails_closed_instead_of_unlimited(): void
    {
        // No TenantSubscription, no Free plan seeded — Product Owner
        // Decision (2026-08-06): this must NEVER be treated as
        // unlimited. effectiveCustomerLimit() returns 0 in this case,
        // so every existing customer becomes read-only.
        $tenant = $this->tenant();
        $customer = $this->customerAt($tenant, '2026-01-01');

        $this->service()->recalculate($tenant);

        $this->assertTrue($customer->fresh()->is_read_only);
    }

    public function test_no_resolvable_plan_marks_every_customer_read_only_not_just_the_newest(): void
    {
        $tenant = $this->tenant();
        $oldest = $this->customerAt($tenant, '2026-01-01');
        $newest = $this->customerAt($tenant, '2026-01-02');

        $this->service()->recalculate($tenant);

        $this->assertTrue($oldest->fresh()->is_read_only);
        $this->assertTrue($newest->fresh()->is_read_only);
    }

    public function test_falling_back_to_the_seeded_free_plan_applies_its_limit_not_unlimited(): void
    {
        $tenant = $this->tenant();
        SubscriptionPlan::factory()->create(['name' => 'Free', 'customer_limit' => 2]);
        $oldest = $this->customerAt($tenant, '2026-01-01');
        $second = $this->customerAt($tenant, '2026-01-02');
        $third = $this->customerAt($tenant, '2026-01-03');

        $this->service()->recalculate($tenant);

        $this->assertFalse($oldest->fresh()->is_read_only);
        $this->assertFalse($second->fresh()->is_read_only);
        $this->assertTrue($third->fresh()->is_read_only);
    }

    // --- Downgrade: previously-unlimited customers become read-only ---

    public function test_downgrading_the_plan_marks_the_newest_excess_customers_read_only(): void
    {
        $tenant = $this->tenant();
        $this->subscribe($tenant, null);
        $oldest = $this->customerAt($tenant, '2026-01-01');
        $newest = $this->customerAt($tenant, '2026-01-02');
        $this->service()->recalculate($tenant);
        $this->assertFalse($newest->fresh()->is_read_only);

        // Downgrade: replace the subscription with a limit of 1.
        TenantSubscription::where('tenant_id', $tenant->id)->delete();
        $this->subscribe($tenant, 1);
        $this->service()->recalculate($tenant);

        $this->assertFalse($oldest->fresh()->is_read_only);
        $this->assertTrue($newest->fresh()->is_read_only);
    }

    // --- Upgrade: previously read-only customers become editable again ---

    public function test_upgrading_the_plan_restores_previously_read_only_customers(): void
    {
        $tenant = $this->tenant();
        $this->subscribe($tenant, 1);
        $oldest = $this->customerAt($tenant, '2026-01-01');
        $newest = $this->customerAt($tenant, '2026-01-02');
        $this->service()->recalculate($tenant);
        $this->assertTrue($newest->fresh()->is_read_only);

        // Upgrade: replace the subscription with an unlimited plan.
        TenantSubscription::where('tenant_id', $tenant->id)->delete();
        $this->subscribe($tenant, null);
        $this->service()->recalculate($tenant);

        $this->assertFalse($oldest->fresh()->is_read_only);
        $this->assertFalse($newest->fresh()->is_read_only);
    }

    // --- Promotion after archive/delete ---

    public function test_archiving_an_editable_customer_promotes_the_next_oldest_read_only_customer(): void
    {
        $tenant = $this->tenant();
        $this->subscribe($tenant, 1);
        $oldest = $this->customerAt($tenant, '2026-01-01');
        $second = $this->customerAt($tenant, '2026-01-02');
        $this->service()->recalculate($tenant);
        $this->assertFalse($oldest->fresh()->is_read_only);
        $this->assertTrue($second->fresh()->is_read_only);

        $oldest->delete(); // archive (Customer::DELETED_AT = archived_at)
        $this->service()->recalculate($tenant);

        $this->assertFalse($second->fresh()->is_read_only);
    }

    public function test_an_archived_customer_is_excluded_from_the_editable_calculation_entirely(): void
    {
        $tenant = $this->tenant();
        $this->subscribe($tenant, 1);
        $customer = $this->customerAt($tenant, '2026-01-01');
        $customer->delete();

        $this->service()->recalculate($tenant);

        // No exception, no false promotion of a non-existent customer —
        // simply nothing to mark, since the archived row is excluded by
        // its own soft-delete scope.
        $this->assertSame(0, Customer::where('tenant_id', $tenant->id)->count());
    }

    // --- Tenant isolation ---

    public function test_recalculate_only_affects_the_given_tenants_customers(): void
    {
        $tenantA = $this->tenant();
        $tenantB = Tenant::create(['business_name' => 'Other Co']);
        $this->subscribe($tenantA, 1);
        $this->subscribe($tenantB, 1);
        $this->customerAt($tenantA, '2026-01-01');
        $overflowA = $this->customerAt($tenantA, '2026-01-02');
        $this->customerAt($tenantB, '2026-01-01');
        $overflowB = $this->customerAt($tenantB, '2026-01-02');

        $this->service()->recalculate($tenantA);

        $this->assertTrue($overflowA->fresh()->is_read_only);
        // Tenant B never recalculated — still at the column default.
        $this->assertFalse($overflowB->fresh()->is_read_only);
    }

    // --- assertCanCreateCustomer() / lockAndGetEffectiveLimit() (race-safe recheck) ---

    public function test_assert_can_create_customer_throws_once_the_tenant_is_at_its_limit(): void
    {
        $tenant = $this->tenant();
        $this->subscribe($tenant, 1);
        $this->customerAt($tenant, '2026-01-01');

        $this->expectException(AuthorizationException::class);

        $this->service()->assertCanCreateCustomer($tenant);
    }

    public function test_assert_can_create_customer_does_not_throw_when_under_the_limit(): void
    {
        $tenant = $this->tenant();
        $this->subscribe($tenant, 2);
        $this->customerAt($tenant, '2026-01-01');

        $this->service()->assertCanCreateCustomer($tenant);

        $this->assertTrue(true);
    }

    public function test_assert_can_create_customer_never_throws_on_an_unlimited_plan(): void
    {
        $tenant = $this->tenant();
        $this->subscribe($tenant, null);
        $this->customerAt($tenant, '2026-01-01');
        $this->customerAt($tenant, '2026-01-02');

        $this->service()->assertCanCreateCustomer($tenant);

        $this->assertTrue(true);
    }

    public function test_assert_can_create_customer_fails_closed_with_no_resolvable_plan(): void
    {
        $tenant = $this->tenant();

        $this->expectException(AuthorizationException::class);

        $this->service()->assertCanCreateCustomer($tenant);
    }

    public function test_lock_and_get_effective_limit_returns_the_plans_limit(): void
    {
        $tenant = $this->tenant();
        $this->subscribe($tenant, 110);

        $this->assertSame(110, $this->service()->lockAndGetEffectiveLimit($tenant));
    }

    public function test_lock_and_get_effective_limit_returns_zero_with_no_resolvable_plan(): void
    {
        $tenant = $this->tenant();

        $this->assertSame(0, $this->service()->lockAndGetEffectiveLimit($tenant));
    }

    // --- Audit logging (Phase 4.5 — Final Verification fix) ---

    public function test_recalculate_records_an_audit_entry_when_a_customer_newly_becomes_read_only(): void
    {
        $tenant = $this->tenant();
        $this->subscribe($tenant, 1);
        $this->customerAt($tenant, '2026-01-01');
        $this->customerAt($tenant, '2026-01-02');

        $this->service()->recalculate($tenant);

        $this->assertDatabaseHas('audit_log', [
            'tenant_id' => $tenant->id,
            'user_id' => null,
            'action' => 'customer_read_only_recalculated',
            'entity_type' => 'tenant',
            'entity_id' => $tenant->id,
        ]);
        $this->assertSame(1, AuditLog::where('action', 'customer_read_only_recalculated')->count());
    }

    public function test_recalculate_records_the_acting_user_when_one_is_passed(): void
    {
        $tenant = $this->tenant();
        $this->subscribe($tenant, 1);
        $this->customerAt($tenant, '2026-01-01');
        $this->customerAt($tenant, '2026-01-02');
        $actor = User::factory()->create();
        $actor->tenant()->associate($tenant);
        $actor->save();

        $this->service()->recalculate($tenant, $actor);

        $this->assertDatabaseHas('audit_log', [
            'tenant_id' => $tenant->id,
            'user_id' => (string) $actor->id,
            'action' => 'customer_read_only_recalculated',
        ]);
    }

    public function test_recalculate_records_an_audit_entry_when_customers_are_restored_to_editable_on_an_unlimited_plan(): void
    {
        $tenant = $this->tenant();
        $this->subscribe($tenant, 1);
        $this->customerAt($tenant, '2026-01-01');
        $this->customerAt($tenant, '2026-01-02');
        $this->service()->recalculate($tenant);

        // Upgrade to unlimited.
        TenantSubscription::where('tenant_id', $tenant->id)->delete();
        $this->subscribe($tenant, null);
        $this->service()->recalculate($tenant);

        $this->assertSame(2, AuditLog::where('action', 'customer_read_only_recalculated')->count());
    }

    public function test_recalculate_does_not_record_an_audit_entry_when_nothing_changes(): void
    {
        $tenant = $this->tenant();
        $this->subscribe($tenant, 10);
        $this->customerAt($tenant, '2026-01-01');

        // Already well under the limit — calling this repeatedly must
        // not flood audit_log with no-op entries.
        $this->service()->recalculate($tenant);
        $this->service()->recalculate($tenant);
        $this->service()->recalculate($tenant);

        $this->assertSame(0, AuditLog::where('action', 'customer_read_only_recalculated')->count());
    }
}
