<?php

namespace Tests\Feature;

use App\Models\Tenant;
use App\Models\User;
use Illuminate\Database\QueryException;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class TenantTest extends TestCase
{
    use RefreshDatabase;

    // --- Migration integrity ---

    public function test_tenants_table_has_expected_columns(): void
    {
        $this->assertTrue(Schema::hasColumns('tenants', [
            'id', 'business_name', 'logo_path', 'address', 'contact_email', 'contact_phone', 'created_at', 'updated_at',
        ]));
    }

    public function test_users_table_has_tenant_id_column(): void
    {
        $this->assertTrue(Schema::hasColumn('users', 'tenant_id'));
    }

    public function test_tenant_id_foreign_key_rejects_a_nonexistent_tenant(): void
    {
        $this->expectException(QueryException::class);

        $user = User::factory()->create();
        $user->tenant_id = 'nonexistent00000000000000';
        $user->save();
    }

    // --- Tenant relationship ---

    public function test_tenant_is_created_with_a_26_character_ulid_primary_key(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Trading Co']);

        $this->assertIsString($tenant->id);
        $this->assertSame(26, strlen($tenant->id));
    }

    public function test_user_belongs_to_tenant(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Trading Co']);
        $user = User::factory()->create();
        $user->tenant()->associate($tenant);
        $user->save();

        $this->assertTrue($user->fresh()->tenant->is($tenant));
    }

    public function test_tenant_has_many_users(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Trading Co']);
        $user = User::factory()->create();
        $user->tenant()->associate($tenant);
        $user->save();

        $this->assertTrue($tenant->users->contains($user));
    }

    public function test_user_tenant_id_is_nullable_and_defaults_to_null(): void
    {
        $user = User::factory()->create();

        $this->assertNull($user->tenant_id);
        $this->assertNull($user->tenant);
    }

    public function test_tenant_id_is_not_mass_assignable_on_user(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Trading Co']);

        $user = User::factory()->create();
        $user->fill(['tenant_id' => $tenant->id]);

        $this->assertNull($user->tenant_id);
    }

    // --- Authenticated user tenant ownership ---

    public function test_authenticated_user_tenant_relationship_resolves_correctly_at_the_model_layer(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Trading Co']);
        $user = User::factory()->create([
            'password' => Hash::make('Password123!'),
        ]);
        $user->tenant()->associate($tenant);
        $user->save();

        $response = $this->postJson('/api/v1/login', [
            'email' => $user->email,
            'password' => 'Password123!',
        ]);

        $response->assertStatus(200);

        $this->assertTrue($user->fresh()->tenant->is($tenant));
    }

    public function test_login_response_does_not_expose_tenant_id(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Trading Co']);
        $user = User::factory()->create([
            'password' => Hash::make('Password123!'),
        ]);
        $user->tenant()->associate($tenant);
        $user->save();

        $response = $this->postJson('/api/v1/login', [
            'email' => $user->email,
            'password' => 'Password123!',
        ]);

        $response->assertStatus(200)
            ->assertJsonMissingPath('data.user.tenant_id');
    }
}
