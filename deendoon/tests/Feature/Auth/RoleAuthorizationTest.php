<?php

namespace Tests\Feature\Auth;

use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Gate;
use Tests\TestCase;

class RoleAuthorizationTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RoleSeeder::class);
    }

    // --- Role assignment ---

    /**
     * Module 7 (Professional Collection) added 'collection_officer' (FR-041
     * E2 names it explicitly by role) and 'deendoon_platform_administrator'
     * (FR-072–076's distinct, non-tenant-scoped actor) to the original
     * three-role interim set — see RoleSeeder.
     */
    public function test_role_seeder_creates_exactly_the_five_approved_roles(): void
    {
        $this->assertDatabaseCount('roles', 5);

        foreach (['admin', 'sales_finance', 'customer', 'collection_officer', 'deendoon_platform_administrator'] as $role) {
            $this->assertDatabaseHas('roles', ['name' => $role]);
        }
    }

    public function test_role_seeder_is_idempotent(): void
    {
        $this->seed(RoleSeeder::class);
        $this->seed(RoleSeeder::class);

        $this->assertDatabaseCount('roles', 5);
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
        $this->assertFalse($user->hasRole('sales_finance'));
        $this->assertFalse($user->hasRole('customer'));
    }

    // --- Permission checks ---

    public function test_admin_gate_allows_admin_role(): void
    {
        $user = User::factory()->create();
        $user->assignRole('admin');

        $this->assertTrue(Gate::forUser($user)->allows('admin-only'));
    }

    public function test_sales_finance_gate_allows_sales_finance_role(): void
    {
        $user = User::factory()->create();
        $user->assignRole('sales_finance');

        $this->assertTrue(Gate::forUser($user)->allows('sales-finance-only'));
    }

    public function test_customer_gate_allows_customer_role(): void
    {
        $user = User::factory()->create();
        $user->assignRole('customer');

        $this->assertTrue(Gate::forUser($user)->allows('customer-only'));
    }

    // --- Forbidden requests (role mismatch) ---

    public function test_admin_gate_denies_non_admin_role(): void
    {
        $user = User::factory()->create();
        $user->assignRole('customer');

        $this->assertTrue(Gate::forUser($user)->denies('admin-only'));
    }

    public function test_sales_finance_gate_denies_non_sales_finance_role(): void
    {
        $user = User::factory()->create();
        $user->assignRole('admin');

        $this->assertTrue(Gate::forUser($user)->denies('sales-finance-only'));
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
        $user->assignRole('customer');
        $token = $user->createToken('auth_token')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson('/api/v1/logout');

        $response->assertStatus(200)->assertJson(['success' => true]);
    }
}
