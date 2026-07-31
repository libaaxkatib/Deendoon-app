<?php

namespace Tests\Feature\Auth;

use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Gate;
use Tests\TestCase;

/**
 * Version 1 authentication model (RBAC Architecture Amendment, Product
 * Owner Decision, 2026-07-30): exactly two account types — Business Owner
 * (`admin`, Customer Mobile App) and Platform Administrator
 * (`deendoon_platform_administrator`, Super Admin Web Dashboard, tenant_id
 * null). The former interim `sales_finance`/`customer` roles and the
 * `collection_officer` role (never truly an authentication role) are
 * retired — see database/migrations/2026_08_10_090000_retire_obsolete_roles.php.
 */
class RoleAuthorizationTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RoleSeeder::class);
    }

    // --- Role assignment ---

    public function test_role_seeder_creates_exactly_the_two_approved_roles(): void
    {
        $this->assertDatabaseCount('roles', 2);

        foreach (['admin', 'deendoon_platform_administrator'] as $role) {
            $this->assertDatabaseHas('roles', ['name' => $role]);
        }
    }

    public function test_role_seeder_is_idempotent(): void
    {
        $this->seed(RoleSeeder::class);
        $this->seed(RoleSeeder::class);

        $this->assertDatabaseCount('roles', 2);
    }

    public function test_user_can_be_assigned_a_role(): void
    {
        $user = User::factory()->create();

        $user->assignRole('admin');

        $this->assertTrue($user->fresh()->hasRole('admin'));
    }

    public function test_user_without_assigned_role_has_no_role(): void
    {
        $user = User::factory()->create();

        $this->assertFalse($user->hasRole('admin'));
        $this->assertFalse($user->hasRole('deendoon_platform_administrator'));
    }

    // --- Permission checks ---

    public function test_admin_gate_allows_admin_role(): void
    {
        $user = User::factory()->create();
        $user->assignRole('admin');

        $this->assertTrue(Gate::forUser($user)->allows('admin-only'));
    }

    public function test_admin_gate_denies_platform_administrator_role(): void
    {
        $user = User::factory()->create();
        $user->assignRole('deendoon_platform_administrator');

        $this->assertTrue(Gate::forUser($user)->denies('admin-only'));
    }

    public function test_admin_gate_denies_user_with_no_role(): void
    {
        $user = User::factory()->create();

        $this->assertTrue(Gate::forUser($user)->denies('admin-only'));
    }

    // --- Protected routes / unauthenticated requests ---

    public function test_protected_route_rejects_unauthenticated_request(): void
    {
        $response = $this->postJson('/api/v1/logout');

        $response->assertStatus(401)->assertJson(['success' => false]);
    }

    public function test_protected_route_accepts_authenticated_request_regardless_of_role(): void
    {
        $user = User::factory()->create();
        $user->assignRole('admin');
        $token = $user->createToken('auth_token')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson('/api/v1/logout');

        $response->assertStatus(200)->assertJson(['success' => true]);
    }
}
