<?php

namespace Tests\Feature;

use App\Models\Customer;
use App\Models\Debt;
use App\Models\Tenant;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * Sprint 17B — `GET /dashboard/business-health` (`Mobile_UI_V1_Frozen.md`
 * §4.1: "Required APIs: Business Health Score retrieval API"). Exact
 * scoring math is covered by `tests/Unit/Services/
 * BusinessHealthServiceTest.php`; these tests only prove the endpoint is
 * wired correctly and enforces the documented, narrower-than-`kpis()`
 * authorization ("Visible to Business Owner" only, per §4.1).
 */
class BusinessHealthTest extends TestCase
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

    private function actingAsPlatformAdmin(): User
    {
        $admin = User::factory()->create();
        $admin->assignRole('deendoon_platform_administrator');

        Sanctum::actingAs($admin, ['*']);

        return $admin;
    }

    public function test_admin_can_view_business_health(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $response = $this->getJson('/api/v1/dashboard/business-health');

        $response->assertStatus(200)
            ->assertJsonPath('data.status', 'neutral_baseline')
            ->assertJsonPath('data.score', null);
    }

    public function test_business_health_returns_neutral_baseline_even_with_real_portfolio_data(): void
    {
        // Locks in the same guarantee as BusinessHealthServiceTest's core
        // assertion, at the HTTP layer: Collection Performance (DD-032)
        // and Outstanding Exposure remain unresolved, so the endpoint
        // must not return a computed score just because real Customer/
        // Debt data — and a resolvable Portfolio Risk Levels input —
        // exist.
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $customer = Customer::factory()->for($tenant, 'tenant')->create(['risk_level' => 'low']);
        Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create();

        $response = $this->getJson('/api/v1/dashboard/business-health');

        $response->assertStatus(200)
            ->assertJsonPath('data.status', 'neutral_baseline')
            ->assertJsonPath('data.score', null);
    }

    public function test_unauthenticated_requests_are_rejected(): void
    {
        $this->getJson('/api/v1/dashboard/business-health')->assertStatus(401);
    }

    public function test_user_without_admin_role_cannot_view_business_health(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant, null);

        $this->getJson('/api/v1/dashboard/business-health')->assertStatus(403);
    }

    /**
     * `Mobile_UI_V1_Frozen.md` §4.1: "Permissions: Visible to Business
     * Owner" — unlike `kpis()`, Business Health has no system-wide
     * variant for the Deendoon Platform Administrator (there is no
     * cross-tenant "business" for it to measure), so this must be
     * rejected rather than silently returning something meaningless.
     */
    public function test_platform_admin_cannot_view_business_health(): void
    {
        $this->actingAsPlatformAdmin();

        $this->getJson('/api/v1/dashboard/business-health')->assertStatus(403);
    }
}
