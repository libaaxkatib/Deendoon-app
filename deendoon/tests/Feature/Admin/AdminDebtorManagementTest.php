<?php

namespace Tests\Feature\Admin;

use App\Models\Customer;
use App\Models\Debt;
use App\Models\Tenant;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminDebtorManagementTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RoleSeeder::class);
    }

    private function platformAdmin(): User
    {
        $admin = User::factory()->create();
        $admin->assignRole('deendoon_platform_administrator');

        return $admin;
    }

    public function test_platform_administrator_can_view_debtors(): void
    {
        $tenant = Tenant::factory()->create();
        Customer::factory()->for($tenant, 'tenant')->create(['name' => 'Amina Ali']);

        $response = $this->actingAs($this->platformAdmin())->get('/admin/debtors');

        $response->assertOk();
        $response->assertSee('Amina Ali');
    }

    public function test_debtors_from_multiple_tenants_are_visible(): void
    {
        $tenantA = Tenant::factory()->create(['business_name' => 'Hodan Trading']);
        $tenantB = Tenant::factory()->create(['business_name' => 'Barwaqo Imports']);
        Customer::factory()->for($tenantA, 'tenant')->create(['name' => 'Amina Ali']);
        Customer::factory()->for($tenantB, 'tenant')->create(['name' => 'Yusuf Nur']);

        $response = $this->actingAs($this->platformAdmin())->get('/admin/debtors');

        $response->assertOk();
        $response->assertSee('Amina Ali');
        $response->assertSee('Yusuf Nur');
        $response->assertSee('Hodan Trading');
        $response->assertSee('Barwaqo Imports');
    }

    public function test_debtor_list_can_be_searched_by_name(): void
    {
        $tenant = Tenant::factory()->create();
        Customer::factory()->for($tenant, 'tenant')->create(['name' => 'Amina Ali']);
        Customer::factory()->for($tenant, 'tenant')->create(['name' => 'Yusuf Nur']);

        $response = $this->actingAs($this->platformAdmin())->get('/admin/debtors?search=amina');

        $response->assertOk();
        $response->assertSee('Amina Ali');
        $response->assertDontSee('Yusuf Nur');
    }

    public function test_debtor_list_can_be_searched_by_phone(): void
    {
        $tenant = Tenant::factory()->create();
        Customer::factory()->for($tenant, 'tenant')->create(['name' => 'Amina Ali', 'phone' => '252611112222']);
        Customer::factory()->for($tenant, 'tenant')->create(['name' => 'Yusuf Nur', 'phone' => '252699998888']);

        $response = $this->actingAs($this->platformAdmin())->get('/admin/debtors?search=611112222');

        $response->assertOk();
        $response->assertSee('Amina Ali');
        $response->assertDontSee('Yusuf Nur');
    }

    public function test_debtor_list_can_be_filtered_by_status(): void
    {
        $tenant = Tenant::factory()->create();
        Customer::factory()->for($tenant, 'tenant')->create(['name' => 'Amina Ali', 'customer_status' => 'blocked']);
        Customer::factory()->for($tenant, 'tenant')->create(['name' => 'Yusuf Nur', 'customer_status' => 'active']);

        $response = $this->actingAs($this->platformAdmin())->get('/admin/debtors?status=blocked');

        $response->assertOk();
        $response->assertSee('Amina Ali');
        $response->assertDontSee('Yusuf Nur');
    }

    public function test_debtor_list_can_be_filtered_by_risk_level(): void
    {
        $tenant = Tenant::factory()->create();
        Customer::factory()->for($tenant, 'tenant')->create(['name' => 'Amina Ali', 'risk_level' => 'high']);
        Customer::factory()->for($tenant, 'tenant')->create(['name' => 'Yusuf Nur', 'risk_level' => 'low']);

        $response = $this->actingAs($this->platformAdmin())->get('/admin/debtors?risk_level=high');

        $response->assertOk();
        $response->assertSee('Amina Ali');
        $response->assertDontSee('Yusuf Nur');
    }

    public function test_debtor_list_is_paginated(): void
    {
        $tenant = Tenant::factory()->create();
        foreach (range(1, 25) as $i) {
            Customer::factory()->for($tenant, 'tenant')->create(['name' => 'Debtor '.str_pad((string) $i, 2, '0', STR_PAD_LEFT)]);
        }

        $page1 = $this->actingAs($this->platformAdmin())->get('/admin/debtors');
        $page1->assertOk();
        $page1->assertSee('Debtor 01');
        $page1->assertDontSee('Debtor 25');

        $page2 = $this->actingAs($this->platformAdmin())->get('/admin/debtors?page=2');
        $page2->assertOk();
        $page2->assertSee('Debtor 25');
    }

    public function test_platform_administrator_can_view_a_debtor_detail_page(): void
    {
        $tenant = Tenant::factory()->create(['business_name' => 'Hodan Trading']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create(['name' => 'Amina Ali']);

        $response = $this->actingAs($this->platformAdmin())->get("/admin/debtors/{$customer->id}");

        $response->assertOk();
        $response->assertSee('Amina Ali');
        $response->assertSee('Hodan Trading');
    }

    public function test_debtor_detail_shows_associated_debts_linking_to_recovery_debts(): void
    {
        $tenant = Tenant::factory()->create();
        $customer = Customer::factory()->for($tenant, 'tenant')->create(['name' => 'Amina Ali']);
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')
            ->create(['reference_number' => 'DBT-000001']);

        $response = $this->actingAs($this->platformAdmin())->get("/admin/debtors/{$customer->id}");

        $response->assertOk();
        $response->assertSee('DBT-000001');
        $response->assertSee(route('admin.recovery-debts.show', $debt), false);
    }

    public function test_a_business_owner_is_forbidden_from_debtors(): void
    {
        $tenant = Tenant::factory()->create();
        $owner = User::factory()->create();
        $owner->tenant()->associate($tenant);
        $owner->save();
        $owner->assignRole('admin');

        $this->actingAs($owner)->get('/admin/debtors')->assertForbidden();
    }

    public function test_guest_is_redirected_to_admin_login(): void
    {
        $response = $this->get('/admin/debtors');

        $response->assertRedirect(route('admin.login'));
    }

    public function test_tenant_isolation_is_not_accidentally_applied_to_the_cross_tenant_query(): void
    {
        // The Platform Administrator has tenant_id === null. If the admin
        // controller ever forgot withoutGlobalScope('tenant'), BelongsToTenant
        // would fail closed to `WHERE tenant_id IS NULL`, silently returning
        // zero debtors instead of erroring — this guards against that regression.
        $tenant = Tenant::factory()->create();
        Customer::factory()->for($tenant, 'tenant')->count(3)->create();

        $response = $this->actingAs($this->platformAdmin())->get('/admin/debtors');

        $response->assertOk();
        $response->assertDontSee('No debtors match your filters');
    }
}
