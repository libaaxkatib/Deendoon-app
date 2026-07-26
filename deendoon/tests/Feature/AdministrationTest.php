<?php

namespace Tests\Feature;

use App\Models\Customer;
use App\Models\ReferenceData;
use App\Models\Tenant;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class AdministrationTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RoleSeeder::class);
        Storage::fake('local');
    }

    private function actingAsTenantUser(Tenant $tenant, string $role = 'admin'): User
    {
        $user = User::factory()->create();
        $user->tenant()->associate($tenant);
        $user->save();
        $user->assignRole($role);

        $token = $user->createToken('test')->plainTextToken;
        $this->withHeader('Authorization', 'Bearer '.$token);

        return $user;
    }

    // --- FR-066: User Administration ---

    public function test_admin_can_create_a_user_with_a_role(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson('/api/v1/admin/users', [
            'name' => 'Jane Staff',
            'email' => 'jane@acme.test',
            'password' => 'Password123!',
            'password_confirmation' => 'Password123!',
            'role' => 'sales_finance',
        ]);

        $response->assertStatus(201);
        $this->assertDatabaseHas('users', ['email' => 'jane@acme.test', 'tenant_id' => $tenant->id]);
        $newUser = User::where('email', 'jane@acme.test')->first();
        $this->assertTrue($newUser->hasRole('sales_finance'));
    }

    public function test_creating_a_user_rejects_the_platform_administrator_role(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $this->postJson('/api/v1/admin/users', [
            'name' => 'Jane Staff',
            'email' => 'jane@acme.test',
            'password' => 'Password123!',
            'password_confirmation' => 'Password123!',
            'role' => 'deendoon_platform_administrator',
        ])->assertStatus(422);
    }

    public function test_sales_finance_role_cannot_administer_users(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant, 'sales_finance');

        $this->getJson('/api/v1/admin/users')->assertStatus(403);
    }

    public function test_admin_can_update_and_deactivate_a_user(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        $staff = User::factory()->create(['name' => 'Old Name']);
        $staff->tenant()->associate($tenant);
        $staff->save();
        $staff->assignRole('sales_finance');

        $this->putJson("/api/v1/admin/users/{$staff->id}", [
            'name' => 'New Name',
            'email' => $staff->email,
        ])->assertStatus(200)->assertJsonPath('data.name', 'New Name');

        $this->postJson("/api/v1/admin/users/{$staff->id}/deactivate")->assertStatus(200);
        $fresh = $staff->fresh();
        $this->assertNotNull($fresh->archived_at);
        $this->assertSame('archived', $fresh->status);
    }

    public function test_restoring_a_user_returns_status_to_active(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        $staff = User::factory()->create();
        $staff->tenant()->associate($tenant);
        $staff->save();
        $staff->assignRole('sales_finance');
        $staff->delete();

        $this->assertSame('archived', $staff->fresh()->status);

        $staff->fresh()->restore();

        $restored = $staff->fresh();
        $this->assertSame('active', $restored->status);
        $this->assertNull($restored->archived_at);
    }

    public function test_deactivating_the_sole_holder_of_a_role_is_blocked(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $admin = $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/admin/users/{$admin->id}/deactivate")->assertStatus(409);
        $this->assertDatabaseHas('users', ['id' => $admin->id, 'archived_at' => null, 'status' => 'active']);
    }

    public function test_deactivated_users_are_excluded_from_the_index_by_default(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        $staff = User::factory()->create();
        $staff->tenant()->associate($tenant);
        $staff->save();
        $staff->assignRole('sales_finance');
        $staff->delete();

        $response = $this->getJson('/api/v1/admin/users');
        $ids = collect($response->json('data.users'))->pluck('id');
        $this->assertFalse($ids->contains((string) $staff->id));

        $response = $this->getJson('/api/v1/admin/users?includeArchived=true');
        $ids = collect($response->json('data.users'))->pluck('id');
        $this->assertTrue($ids->contains((string) $staff->id));
    }

    // --- FR-067: Role & Permission Management ---

    public function test_admin_can_change_a_users_role(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        $staff = User::factory()->create();
        $staff->tenant()->associate($tenant);
        $staff->save();
        $staff->assignRole('sales_finance');

        $this->patchJson("/api/v1/admin/users/{$staff->id}/role", ['role' => 'collection_officer'])
            ->assertStatus(200)
            ->assertJsonPath('data.role', 'collection_officer');

        $this->assertTrue($staff->fresh()->hasRole('collection_officer'));
        $this->assertFalse($staff->fresh()->hasRole('sales_finance'));
    }

    // --- FR-068: Company Profile & Branding ---

    public function test_admin_can_update_the_company_profile_with_a_logo(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $response = $this->post('/api/v1/admin/settings/company-profile', [
            '_method' => 'PUT',
            'business_name' => 'Acme Trading Co',
            'address' => '123 Main St',
            'logo' => UploadedFile::fake()->image('logo.png'),
        ]);

        $response->assertStatus(200)->assertJsonPath('data.business_name', 'Acme Trading Co');
        $this->assertSame('Acme Trading Co', $tenant->fresh()->business_name);
        $this->assertNotNull($tenant->fresh()->logo_path);
    }

    public function test_oversized_logo_is_rejected(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $this->post('/api/v1/admin/settings/company-profile', [
            '_method' => 'PUT',
            'business_name' => 'Acme Trading Co',
            'logo' => UploadedFile::fake()->create('logo.png', 3000, 'image/png'),
        ])->assertStatus(422);
    }

    // --- FR-069: System Preferences ---

    public function test_admin_can_read_and_update_system_preferences(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $this->getJson('/api/v1/admin/settings/preferences')->assertStatus(200)
            ->assertJsonStructure(['data' => ['system_settings', 'document_templates']]);

        $response = $this->putJson('/api/v1/admin/settings/preferences', [
            'default_credit_limit' => 750,
            'credit_limit_reminder_enabled' => false,
            'soft_limit_warning_threshold' => 90,
            'document_templates' => [
                ['template_type' => 'first_reminder', 'content' => 'Custom first reminder wording.'],
            ],
        ]);

        $response->assertStatus(200)->assertJsonPath('data.system_settings.default_credit_limit', '750.00');
        $this->assertDatabaseHas('document_templates', [
            'tenant_id' => $tenant->id,
            'template_type' => 'first_reminder',
            'content' => 'Custom first reminder wording.',
        ]);
    }

    public function test_preference_values_outside_the_approved_range_are_rejected(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $this->putJson('/api/v1/admin/settings/preferences', [
            'default_credit_limit' => -1,
            'credit_limit_reminder_enabled' => true,
        ])->assertStatus(422);
    }

    // --- FR-070: Lookup & Reference Data ---

    public function test_admin_can_add_reference_data_values(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $response = $this->putJson('/api/v1/admin/reference-data/risk_level', [
            'values' => [
                ['value_label' => 'low', 'sort_order' => 1],
                ['value_label' => 'medium', 'sort_order' => 2],
            ],
        ]);

        $response->assertStatus(200);
        $this->assertDatabaseHas('reference_data', ['tenant_id' => $tenant->id, 'category' => 'risk_level', 'value_label' => 'low']);
    }

    public function test_unknown_reference_data_category_is_rejected(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $this->getJson('/api/v1/admin/reference-data/not_a_real_category')->assertStatus(404);
    }

    public function test_deactivating_an_in_use_reference_data_value_is_blocked(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        $referenceData = ReferenceData::factory()->for($tenant, 'tenant')->create([
            'category' => 'risk_level', 'value_label' => 'high', 'is_active' => true,
        ]);
        Customer::factory()->for($tenant, 'tenant')->create(['risk_level' => 'high']);

        $this->putJson('/api/v1/admin/reference-data/risk_level', [
            'values' => [
                ['id' => $referenceData->id, 'value_label' => 'high', 'is_active' => false],
            ],
        ])->assertStatus(409);
    }

    // --- FR-071: Audit Trail Viewing ---

    public function test_admin_can_view_the_audit_trail(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        $this->postJson('/api/v1/admin/users', [
            'name' => 'Jane Staff', 'email' => 'jane@acme.test',
            'password' => 'Password123!', 'password_confirmation' => 'Password123!', 'role' => 'sales_finance',
        ])->assertStatus(201);

        $response = $this->getJson('/api/v1/admin/audit-trail');

        $response->assertStatus(200);
        $actions = collect($response->json('data.audit_trail'))->pluck('action');
        $this->assertTrue($actions->contains('created'));
    }

    public function test_unauthenticated_requests_are_rejected(): void
    {
        $this->getJson('/api/v1/admin/users')->assertStatus(401);
    }
}
