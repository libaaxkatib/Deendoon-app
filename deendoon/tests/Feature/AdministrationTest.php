<?php

namespace Tests\Feature;

use App\Models\Customer;
use App\Models\ReferenceData;
use App\Models\Tenant;
use App\Models\User;
use App\Services\ReferenceDataService;
use Database\Seeders\RoleSeeder;
use Database\Seeders\SubscriptionPlanSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

/**
 * Version 1 authentication model (RBAC Architecture Amendment, Product
 * Owner Decision, 2026-07-30): AdminUserController/UserPolicy are
 * deprecated (no second tenant user exists to administer under the
 * one-account-per-tenant model) but left functional pending confirmation
 * of no residual dependency — these tests continue to exercise them
 * against the one role that still exists (`admin`).
 */
class AdministrationTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RoleSeeder::class);
        // Backend Completion Roadmap (Phase 4.2): logo upload now fails
        // closed without a resolvable plan.
        $this->seed(SubscriptionPlanSeeder::class);
        Storage::fake('local');
    }

    private function actingAsTenantUser(Tenant $tenant, string $role = 'admin'): User
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
            'role' => 'admin',
        ]);

        $response->assertStatus(201);
        $this->assertDatabaseHas('users', ['email' => 'jane@acme.test', 'tenant_id' => $tenant->id]);
        $newUser = User::where('email', 'jane@acme.test')->first();
        $this->assertTrue($newUser->hasRole('admin'));
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

    public function test_user_without_admin_role_cannot_administer_users(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $user = User::factory()->create(['tenant_id' => $tenant->id]);
        $token = $user->createToken('test')->plainTextToken;

        $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/v1/admin/users')
            ->assertStatus(403);
    }

    public function test_admin_can_update_and_deactivate_a_user(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        $staff = User::factory()->create(['name' => 'Old Name']);
        $staff->tenant()->associate($tenant);
        $staff->save();
        $staff->assignRole('admin');

        $this->putJson("/api/v1/admin/users/{$staff->id}", [
            'name' => 'New Name',
            'email' => $staff->email,
        ])->assertStatus(200)->assertJsonPath('data.name', 'New Name');

        $this->postJson("/api/v1/admin/users/{$staff->id}/deactivate")->assertStatus(200);
        $fresh = $staff->fresh();
        $this->assertNotNull($fresh->archived_at);
        $this->assertSame('archived', $fresh->status);
    }

    // --- Sprint 1.2: deactivation/role-change revoke all active tokens (08 §9) ---

    public function test_deactivating_a_user_revokes_their_active_tokens(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        $staff = User::factory()->create();
        $staff->tenant()->associate($tenant);
        $staff->save();
        $staff->assignRole('admin');
        $staff->createToken('test');

        $this->assertSame(1, $staff->tokens()->count());

        $this->postJson("/api/v1/admin/users/{$staff->id}/deactivate")->assertStatus(200);

        $this->assertSame(0, $staff->tokens()->count());
    }

    public function test_changing_a_users_role_revokes_their_active_tokens(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        $staff = User::factory()->create();
        $staff->tenant()->associate($tenant);
        $staff->save();
        $staff->createToken('test');

        $this->assertSame(1, $staff->tokens()->count());

        $this->patchJson("/api/v1/admin/users/{$staff->id}/role", ['role' => 'admin'])->assertStatus(200);

        $this->assertSame(0, $staff->tokens()->count());
    }

    public function test_restoring_a_user_returns_status_to_active(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        $staff = User::factory()->create();
        $staff->tenant()->associate($tenant);
        $staff->save();
        $staff->assignRole('admin');
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
        $staff->assignRole('admin');
        $staff->delete();

        $response = $this->getJson('/api/v1/admin/users');
        $ids = collect($response->json('data.users'))->pluck('id');
        $this->assertFalse($ids->contains((string) $staff->id));

        $response = $this->getJson('/api/v1/admin/users?includeArchived=true');
        $ids = collect($response->json('data.users'))->pluck('id');
        $this->assertTrue($ids->contains((string) $staff->id));
    }

    // --- FR-067: Role & Permission Management ---

    /**
     * Version 1 has only one tenant-side role (`admin`), so this no longer
     * exercises a *change* between two distinct roles (that scenario no
     * longer exists) — it confirms the endpoint still functions correctly
     * against the one role that remains.
     */
    public function test_admin_can_assign_the_admin_role_to_a_user(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        $staff = User::factory()->create();
        $staff->tenant()->associate($tenant);
        $staff->save();

        $this->patchJson("/api/v1/admin/users/{$staff->id}/role", ['role' => 'admin'])
            ->assertStatus(200)
            ->assertJsonPath('data.role', 'admin');

        $this->assertTrue($staff->fresh()->hasRole('admin'));
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

    // --- Professional Collection Reference Data fix: provisioned defaults ---

    public function test_a_newly_registered_tenant_receives_the_13_default_transfer_reasons(): void
    {
        $response = $this->postJson('/api/v1/register', [
            'business_name' => 'Acme Co',
            'name' => 'Jane Owner',
            'phone' => '+252612345678',
            'email' => 'jane@example.com',
            'password' => 'Password123!',
            'password_confirmation' => 'Password123!',
        ]);
        $response->assertStatus(201);
        $this->withHeader('Authorization', 'Bearer '.$response->json('data.token'));

        $response = $this->getJson('/api/v1/admin/reference-data/transfer_reason');

        $response->assertStatus(200);
        $labels = collect($response->json('data'))->pluck('value_label');
        $this->assertCount(13, $labels);
        $this->assertContains('Customer stopped answering calls', $labels);
        $this->assertContains('Other', $labels);
        $this->assertTrue(collect($response->json('data'))->every(fn ($item) => $item['is_active'] === true));
    }

    public function test_a_newly_registered_tenant_receives_the_13_default_requested_services(): void
    {
        $response = $this->postJson('/api/v1/register', [
            'business_name' => 'Acme Co',
            'name' => 'Jane Owner',
            'phone' => '+252612345678',
            'email' => 'jane2@example.com',
            'password' => 'Password123!',
            'password_confirmation' => 'Password123!',
        ]);
        $response->assertStatus(201);
        $this->withHeader('Authorization', 'Bearer '.$response->json('data.token'));

        $response = $this->getJson('/api/v1/admin/reference-data/requested_service');

        $response->assertStatus(200);
        $labels = collect($response->json('data'))->pluck('value_label');
        $this->assertCount(13, $labels);
        $this->assertContains('Telephone Collection', $labels);
        $this->assertContains('Court Preparation', $labels);
    }

    public function test_reference_data_defaults_are_tenant_isolated(): void
    {
        $tenantA = Tenant::create(['business_name' => 'Tenant A']);
        $tenantB = Tenant::create(['business_name' => 'Tenant B']);
        app(ReferenceDataService::class)->provisionDefaults($tenantA);
        app(ReferenceDataService::class)->provisionDefaults($tenantB);

        $this->actingAsTenantUser($tenantA);
        $response = $this->getJson('/api/v1/admin/reference-data/transfer_reason');

        $response->assertStatus(200);
        $this->assertCount(13, $response->json('data'));
        // Scoped to these two tenants' transfer_reason/requested_service
        // rows only — the table also legitimately holds platform-owned
        // (tenant_id NULL) subscription/storage rejection reason rows
        // seeded independently of this feature.
        $count = ReferenceData::withoutGlobalScope('tenant')
            ->whereIn('tenant_id', [$tenantA->id, $tenantB->id])
            ->whereIn('category', ['transfer_reason', 'requested_service'])
            ->count();
        $this->assertSame(52, $count); // 13 + 13 reasons/services x 2 tenants
    }

    public function test_provisioning_defaults_twice_for_the_same_tenant_is_idempotent(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $service = app(ReferenceDataService::class);

        $service->provisionDefaults($tenant);
        $service->provisionDefaults($tenant);

        $this->assertSame(
            13,
            ReferenceData::where('tenant_id', $tenant->id)->where('category', 'transfer_reason')->count(),
        );
        $this->assertSame(
            13,
            ReferenceData::where('tenant_id', $tenant->id)->where('category', 'requested_service')->count(),
        );
    }

    public function test_provisioning_defaults_does_not_touch_a_tenants_own_customized_values(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        $custom = ReferenceData::factory()->for($tenant, 'tenant')->create([
            'category' => 'transfer_reason',
            'value_label' => 'A custom tenant-specific reason',
            'is_active' => true,
        ]);

        app(ReferenceDataService::class)->provisionDefaults($tenant);

        $this->assertDatabaseHas('reference_data', [
            'id' => $custom->id,
            'value_label' => 'A custom tenant-specific reason',
        ]);
        $this->assertSame(
            14,
            ReferenceData::where('tenant_id', $tenant->id)->where('category', 'transfer_reason')->count(),
        );
    }

    public function test_reference_data_is_active_flag_round_trips_correctly(): void
    {
        // ReferenceDataService::forCategory() intentionally returns every
        // row (active and inactive) — `AdminReferenceDataController::show()`
        // is the admin editing view, so the Business Owner must see
        // inactive rows too when managing the list. The Professional
        // Collection submission form (the actual consumer) is what filters
        // to `is_active` client-side — this test verifies the flag itself
        // is stored and returned correctly, which that filtering depends on.
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        app(ReferenceDataService::class)->provisionDefaults($tenant);
        $active = ReferenceData::where('tenant_id', $tenant->id)->where('category', 'transfer_reason')->first();
        $active->update(['is_active' => false]);

        $response = $this->getJson('/api/v1/admin/reference-data/transfer_reason');

        $inactiveCount = collect($response->json('data'))->where('is_active', false)->count();
        $activeCount = collect($response->json('data'))->where('is_active', true)->count();
        $this->assertSame(1, $inactiveCount);
        $this->assertSame(12, $activeCount);
    }

    // --- FR-071: Audit Trail Viewing ---

    public function test_admin_can_view_the_audit_trail(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        $this->postJson('/api/v1/admin/users', [
            'name' => 'Jane Staff', 'email' => 'jane@acme.test',
            'password' => 'Password123!', 'password_confirmation' => 'Password123!', 'role' => 'admin',
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
