<?php

namespace Tests\Feature\Auth;

use App\Models\Tenant;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * FR-006 — Role Resolution. Version 1 authentication model (RBAC
 * Architecture Amendment, Product Owner Decision, 2026-07-30): GET /me
 * resolves the authenticated user's profile and single role — no
 * permission array, no multi-role support.
 */
class MeTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RoleSeeder::class);
    }

    public function test_business_owner_can_resolve_their_own_profile_and_role(): void
    {
        $tenant = Tenant::create(['business_name' => 'Test Business']);
        $user = User::factory()->create(['tenant_id' => $tenant->id, 'name' => 'Asad Mohamed', 'email' => 'asad@example.com']);
        $user->assignRole('admin');
        $token = $user->createToken('auth_token')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer '.$token)->getJson('/api/v1/me');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'id' => $user->id,
                    'name' => 'Asad Mohamed',
                    'email' => 'asad@example.com',
                    'role' => 'admin',
                ],
            ]);
    }

    public function test_platform_administrator_can_resolve_their_own_profile_and_role(): void
    {
        $user = User::factory()->create(['tenant_id' => null]);
        $user->assignRole('deendoon_platform_administrator');
        $token = $user->createToken('auth_token')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer '.$token)->getJson('/api/v1/me');

        $response->assertStatus(200)
            ->assertJsonPath('data.role', 'deendoon_platform_administrator');
    }

    public function test_me_rejects_unauthenticated_request(): void
    {
        $response = $this->getJson('/api/v1/me');

        $response->assertStatus(401)->assertJson(['success' => false]);
    }

    public function test_me_response_does_not_expose_a_permission_array(): void
    {
        $tenant = Tenant::create(['business_name' => 'Test Business']);
        $user = User::factory()->create(['tenant_id' => $tenant->id]);
        $user->assignRole('admin');
        $token = $user->createToken('auth_token')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer '.$token)->getJson('/api/v1/me');

        $response->assertJsonMissingPath('data.permissions')
            ->assertJsonMissingPath('data.roles');
    }
}
