<?php

namespace Tests\Feature;

use App\Models\Customer;
use App\Models\Tenant;
use App\Models\User;
use App\Services\AdminSettingsService;
use Database\Seeders\RoleSeeder;
use Database\Seeders\SubscriptionPlanSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class CustomerTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RoleSeeder::class);
        // Backend Completion Roadmap (Phase 4.1, Product Owner review
        // 2026-08-06): customer creation now fails closed to a limit of
        // 0 when no plan can be resolved at all — every tenant in this
        // file needs the Free Plan (limit 2) resolvable, matching how a
        // real tenant with no subscription behaves in production.
        $this->seed(SubscriptionPlanSeeder::class);
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

    // --- Create ---

    public function test_admin_can_create_a_customer(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson('/api/v1/customers', [
            'name' => 'Jane Trader',
            'phone' => '254712345678',
            'credit_limit' => 5000,
        ]);

        $response->assertStatus(201)
            ->assertJson(['success' => true])
            ->assertJsonPath('data.customer.name', 'Jane Trader')
            ->assertJsonPath('data.customer.customer_status', 'active')
            ->assertJsonPath('data.customer.outstanding_balance', '0.00')
            ->assertJsonPath('data.warning', null);

        $this->assertDatabaseHas('customers', [
            'name' => 'Jane Trader',
            'tenant_id' => $tenant->id,
            'customer_status' => 'active',
        ]);
    }

    public function test_omitting_credit_limit_applies_the_tenants_default_credit_limit(): void
    {
        // FR-007/BR-034 (Business Owner Backend Completion): resolves what
        // was previously an unimplemented gap — credit_limit used to be a
        // required client field with the tenant's configured
        // SystemSetting::default_credit_limit never consulted.
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $user = $this->actingAsTenantUser($tenant);
        app(AdminSettingsService::class)->updatePreferences($tenant->id, ['default_credit_limit' => 7500], $user);

        $response = $this->postJson('/api/v1/customers', [
            'name' => 'Jane Trader',
            'phone' => '254712345678',
        ]);

        $response->assertStatus(201)->assertJsonPath('data.customer.credit_limit', '7500.00');
        $this->assertDatabaseHas('customers', ['name' => 'Jane Trader', 'credit_limit' => 7500]);
    }

    public function test_an_explicit_credit_limit_overrides_the_tenants_default(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $user = $this->actingAsTenantUser($tenant);
        app(AdminSettingsService::class)->updatePreferences($tenant->id, ['default_credit_limit' => 7500], $user);

        $response = $this->postJson('/api/v1/customers', [
            'name' => 'Jane Trader',
            'phone' => '254712345678',
            'credit_limit' => 5000,
        ]);

        $response->assertStatus(201)->assertJsonPath('data.customer.credit_limit', '5000.00');
    }

    public function test_omitting_credit_limit_applies_zero_when_the_tenant_has_no_configured_default(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson('/api/v1/customers', [
            'name' => 'Jane Trader',
            'phone' => '254712345678',
        ]);

        $response->assertStatus(201)->assertJsonPath('data.customer.credit_limit', '0.00');
    }

    public function test_creating_a_customer_requires_name_and_phone(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson('/api/v1/customers', []);

        $response->assertStatus(422)->assertJsonValidationErrors(['name', 'phone']);
    }

    public function test_created_customer_is_automatically_scoped_to_the_authenticated_users_tenant(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $this->postJson('/api/v1/customers', [
            'name' => 'Jane Trader',
            'phone' => '254712345678',
            'credit_limit' => 5000,
        ])->assertStatus(201);

        $customer = Customer::first();
        $this->assertSame($tenant->id, $customer->tenant_id);
    }

    public function test_creating_a_customer_with_a_duplicate_phone_returns_a_warning_but_still_creates_it(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $this->postJson('/api/v1/customers', [
            'name' => 'Jane Trader',
            'phone' => '254712345678',
            'credit_limit' => 5000,
        ])->assertStatus(201);

        $response = $this->postJson('/api/v1/customers', [
            'name' => 'Someone Else',
            'phone' => '254712345678',
            'credit_limit' => 3000,
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('data.warning.type', 'POSSIBLE_DUPLICATE_CUSTOMER');

        $this->assertSame(2, Customer::count());
    }

    public function test_customer_creation_records_a_created_audit_event(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $user = $this->actingAsTenantUser($tenant);

        $response = $this->postJson('/api/v1/customers', [
            'name' => 'Jane Trader',
            'phone' => '254712345678',
            'credit_limit' => 5000,
        ]);

        $customerId = $response->json('data.customer.id');

        $this->assertDatabaseHas('audit_log', [
            'tenant_id' => $tenant->id,
            'user_id' => (string) $user->id,
            'action' => 'created',
            'entity_type' => 'customer',
            'entity_id' => $customerId,
        ]);
    }

    // --- List / tenant isolation ---

    public function test_index_lists_only_the_authenticated_users_own_tenant_customers(): void
    {
        $tenantA = Tenant::create(['business_name' => 'Tenant A']);
        $tenantB = Tenant::create(['business_name' => 'Tenant B']);

        Customer::factory()->for($tenantA, 'tenant')->create(['name' => 'Customer A']);
        Customer::factory()->for($tenantB, 'tenant')->create(['name' => 'Customer B']);

        $this->actingAsTenantUser($tenantA);

        $response = $this->getJson('/api/v1/customers');

        $response->assertStatus(200);
        $names = collect($response->json('data.customers'))->pluck('name');
        $this->assertTrue($names->contains('Customer A'));
        $this->assertFalse($names->contains('Customer B'));
    }

    public function test_index_excludes_archived_customers_by_default(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        Customer::factory()->for($tenant, 'tenant')->create(['name' => 'Active One']);
        Customer::factory()->for($tenant, 'tenant')->archived()->create(['name' => 'Archived One']);

        $this->actingAsTenantUser($tenant);

        $response = $this->getJson('/api/v1/customers');

        $names = collect($response->json('data.customers'))->pluck('name');
        $this->assertTrue($names->contains('Active One'));
        $this->assertFalse($names->contains('Archived One'));
    }

    public function test_index_can_include_archived_customers_when_requested(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        Customer::factory()->for($tenant, 'tenant')->archived()->create(['name' => 'Archived One']);

        $this->actingAsTenantUser($tenant);

        $response = $this->getJson('/api/v1/customers?includeArchived=1');

        $names = collect($response->json('data.customers'))->pluck('name');
        $this->assertTrue($names->contains('Archived One'));
    }

    public function test_index_can_filter_by_status(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        Customer::factory()->for($tenant, 'tenant')->create(['name' => 'Blocked One', 'customer_status' => 'blocked']);
        Customer::factory()->for($tenant, 'tenant')->create(['name' => 'Active One', 'customer_status' => 'active']);

        $this->actingAsTenantUser($tenant);

        $response = $this->getJson('/api/v1/customers?status=blocked');

        $names = collect($response->json('data.customers'))->pluck('name');
        $this->assertTrue($names->contains('Blocked One'));
        $this->assertFalse($names->contains('Active One'));
    }

    public function test_index_can_search_by_name_or_phone(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        Customer::factory()->for($tenant, 'tenant')->create(['name' => 'Findable Person', 'phone' => '254700000001']);
        Customer::factory()->for($tenant, 'tenant')->create(['name' => 'Someone Else', 'phone' => '254700000002']);

        $this->actingAsTenantUser($tenant);

        $response = $this->getJson('/api/v1/customers?search=Findable');

        $names = collect($response->json('data.customers'))->pluck('name');
        $this->assertTrue($names->contains('Findable Person'));
        $this->assertFalse($names->contains('Someone Else'));
    }

    // --- Show / tenant isolation ---

    public function test_show_returns_customer_details(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();

        $this->actingAsTenantUser($tenant);

        $response = $this->getJson("/api/v1/customers/{$customer->id}");

        $response->assertStatus(200)->assertJsonPath('data.id', $customer->id);
    }

    public function test_show_returns_404_for_another_tenants_customer(): void
    {
        $tenantA = Tenant::create(['business_name' => 'Tenant A']);
        $tenantB = Tenant::create(['business_name' => 'Tenant B']);
        $otherCustomer = Customer::factory()->for($tenantB, 'tenant')->create();

        $this->actingAsTenantUser($tenantA);

        $response = $this->getJson("/api/v1/customers/{$otherCustomer->id}");

        $response->assertStatus(404);
    }

    // --- Update ---

    public function test_update_changes_fields_and_records_an_edited_audit_event(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create(['name' => 'Old Name']);
        $user = $this->actingAsTenantUser($tenant);

        $response = $this->putJson("/api/v1/customers/{$customer->id}", [
            'name' => 'New Name',
            'phone' => $customer->phone,
            'credit_limit' => $customer->credit_limit,
        ]);

        $response->assertStatus(200)->assertJsonPath('data.customer.name', 'New Name');

        $this->assertDatabaseHas('audit_log', [
            'entity_id' => $customer->id,
            'action' => 'edited',
        ]);
    }

    public function test_update_that_changes_credit_limit_records_a_credit_limit_changed_audit_event(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create(['credit_limit' => 1000]);
        $this->actingAsTenantUser($tenant);

        $this->putJson("/api/v1/customers/{$customer->id}", [
            'name' => $customer->name,
            'phone' => $customer->phone,
            'credit_limit' => 2000,
        ])->assertStatus(200);

        $this->assertDatabaseHas('audit_log', [
            'entity_id' => $customer->id,
            'action' => 'credit_limit_changed',
        ]);
        $this->assertDatabaseMissing('audit_log', [
            'entity_id' => $customer->id,
            'action' => 'edited',
        ]);
    }

    public function test_update_rechecks_duplicates_when_identifying_fields_change(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        Customer::factory()->for($tenant, 'tenant')->create(['phone' => '254799999999']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create(['phone' => '254711111111']);
        $this->actingAsTenantUser($tenant);

        $response = $this->putJson("/api/v1/customers/{$customer->id}", [
            'name' => $customer->name,
            'phone' => '254799999999',
            'credit_limit' => $customer->credit_limit,
        ]);

        $response->assertStatus(200)->assertJsonPath('data.warning.type', 'POSSIBLE_DUPLICATE_CUSTOMER');
    }

    public function test_outstanding_balance_cannot_be_set_via_update(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $this->actingAsTenantUser($tenant);

        $this->putJson("/api/v1/customers/{$customer->id}", [
            'name' => $customer->name,
            'phone' => $customer->phone,
            'credit_limit' => $customer->credit_limit,
            'outstanding_balance' => 99999,
        ])->assertStatus(200);

        $this->assertSame('0.00', $customer->fresh()->outstanding_balance);
    }

    // --- Archive / Restore ---

    public function test_archive_soft_deletes_and_records_an_audit_event(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson("/api/v1/customers/{$customer->id}/archive");

        $response->assertStatus(200);
        $this->assertNotNull($customer->fresh()->archived_at);
        $this->assertDatabaseHas('audit_log', ['entity_id' => $customer->id, 'action' => 'archived']);
    }

    public function test_archived_customer_is_viewable_in_a_restore_eligible_state(): void
    {
        // FR-008 (Business Owner Backend Completion): previously 404'd —
        // now viewable so a Business Owner can review it before restoring.
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->archived()->create();
        $this->actingAsTenantUser($tenant);

        $response = $this->getJson("/api/v1/customers/{$customer->id}");

        $response->assertStatus(200)
            ->assertJsonPath('data.id', $customer->id)
            ->assertJsonPath('data.archived_at', fn (?string $value): bool => $value !== null);
    }

    public function test_show_returns_404_for_another_tenants_archived_customer(): void
    {
        $tenantA = Tenant::create(['business_name' => 'Tenant A']);
        $tenantB = Tenant::create(['business_name' => 'Tenant B']);
        $otherCustomer = Customer::factory()->for($tenantB, 'tenant')->archived()->create();
        $this->actingAsTenantUser($tenantA);

        $this->getJson("/api/v1/customers/{$otherCustomer->id}")->assertStatus(404);
    }

    public function test_restore_reactivates_an_archived_customer_and_records_an_audit_event(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->archived()->create();
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson("/api/v1/customers/{$customer->id}/restore");

        $response->assertStatus(200);
        $this->assertNull($customer->fresh()->archived_at);
        $this->assertDatabaseHas('audit_log', ['entity_id' => $customer->id, 'action' => 'restored']);
    }

    // --- Status ---

    public function test_status_can_be_updated_to_an_approved_value(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create(['customer_status' => 'active']);
        $this->actingAsTenantUser($tenant);

        $response = $this->patchJson("/api/v1/customers/{$customer->id}/status", [
            'customer_status' => 'high_risk',
        ]);

        $response->assertStatus(200)->assertJsonPath('data.customer_status', 'high_risk');
        $this->assertDatabaseHas('audit_log', ['entity_id' => $customer->id, 'action' => 'status_changed']);
    }

    public function test_status_update_rejects_an_unapproved_value(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $this->actingAsTenantUser($tenant);

        $response = $this->patchJson("/api/v1/customers/{$customer->id}/status", [
            'customer_status' => 'not_a_real_status',
        ]);

        $response->assertStatus(422)->assertJsonValidationErrors(['customer_status']);
    }

    // --- Credit profile / credit limit ---

    public function test_credit_profile_returns_credit_fields(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create([
            'credit_limit' => 1000,
            'outstanding_balance' => 300,
        ]);
        $this->actingAsTenantUser($tenant);

        $response = $this->getJson("/api/v1/customers/{$customer->id}/credit-profile");

        $response->assertStatus(200)
            ->assertJsonPath('data.credit_limit', '1000.00')
            ->assertJsonPath('data.outstanding_balance', '300.00')
            ->assertJsonPath('data.remaining_credit', '700.00');
    }

    public function test_credit_limit_endpoint_updates_limit_and_records_audit_event(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create(['credit_limit' => 1000]);
        $this->actingAsTenantUser($tenant);

        $response = $this->patchJson("/api/v1/customers/{$customer->id}/credit-limit", [
            'credit_limit' => 4000,
        ]);

        $response->assertStatus(200)->assertJsonPath('data.credit_limit', '4000.00');
        $this->assertDatabaseHas('audit_log', ['entity_id' => $customer->id, 'action' => 'credit_limit_changed']);
    }

    // --- Duplicate check (standalone) ---

    public function test_check_duplicate_detects_an_existing_phone(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        Customer::factory()->for($tenant, 'tenant')->create(['phone' => '254733333333']);
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson('/api/v1/customers/check-duplicate', [
            'name' => 'Anyone',
            'phone' => '254733333333',
        ]);

        $response->assertStatus(200)->assertJsonPath('data.duplicate_found', true);
    }

    public function test_check_duplicate_returns_false_when_no_match(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson('/api/v1/customers/check-duplicate', [
            'name' => 'Nobody Yet',
            'phone' => '254700000099',
        ]);

        $response->assertStatus(200)->assertJsonPath('data.duplicate_found', false);
    }

    // --- Authentication ---

    public function test_unauthenticated_requests_are_rejected(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();

        $this->getJson('/api/v1/customers')->assertStatus(401);
        $this->postJson('/api/v1/customers', [])->assertStatus(401);
        $this->getJson("/api/v1/customers/{$customer->id}")->assertStatus(401);
    }

    // --- Authorization ---

    public function test_user_without_admin_role_cannot_manage_customers(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant, null);

        $this->getJson('/api/v1/customers')->assertStatus(403);
        $this->postJson('/api/v1/customers', [
            'name' => 'Jane', 'phone' => '254711111111', 'credit_limit' => 100,
        ])->assertStatus(403);
    }
}
