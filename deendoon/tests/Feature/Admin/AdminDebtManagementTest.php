<?php

namespace Tests\Feature\Admin;

use App\Models\CollectionCase;
use App\Models\Customer;
use App\Models\Debt;
use App\Models\Payment;
use App\Models\Tenant;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminDebtManagementTest extends TestCase
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

    public function test_platform_administrator_sees_debts_across_multiple_tenants(): void
    {
        $tenantA = Tenant::factory()->create(['business_name' => 'Hodan Trading']);
        $tenantB = Tenant::factory()->create(['business_name' => 'Barwaqo Imports']);
        $customerA = Customer::factory()->for($tenantA, 'tenant')->create(['name' => 'Amina Ali']);
        $customerB = Customer::factory()->for($tenantB, 'tenant')->create(['name' => 'Yusuf Nur']);
        Debt::factory()->for($tenantA, 'tenant')->for($customerA, 'customer')->create(['reference_number' => 'DBT-000001']);
        Debt::factory()->for($tenantB, 'tenant')->for($customerB, 'customer')->create(['reference_number' => 'DBT-000002']);

        $response = $this->actingAs($this->platformAdmin())->get('/admin/recovery-debts');

        $response->assertOk();
        $response->assertSee('DBT-000001');
        $response->assertSee('DBT-000002');
        $response->assertSee('Hodan Trading');
        $response->assertSee('Barwaqo Imports');
    }

    public function test_debt_list_can_be_searched_by_reference_number(): void
    {
        [$tenant, $customer] = $this->tenantAndCustomer();
        Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create(['reference_number' => 'DBT-000123']);
        Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create(['reference_number' => 'DBT-000999']);

        $response = $this->actingAs($this->platformAdmin())->get('/admin/recovery-debts?search=000123');

        $response->assertOk();
        $response->assertSee('DBT-000123');
        $response->assertDontSee('DBT-000999');
    }

    public function test_debt_list_can_be_searched_by_debtor_name(): void
    {
        [$tenant, $customer] = $this->tenantAndCustomer('Amina Ali');
        $otherCustomer = Customer::factory()->for($tenant, 'tenant')->create(['name' => 'Yusuf Nur']);
        Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create(['reference_number' => 'DBT-000001']);
        Debt::factory()->for($tenant, 'tenant')->for($otherCustomer, 'customer')->create(['reference_number' => 'DBT-000002']);

        $response = $this->actingAs($this->platformAdmin())->get('/admin/recovery-debts?search=amina');

        $response->assertOk();
        $response->assertSee('DBT-000001');
        $response->assertDontSee('DBT-000002');
    }

    public function test_debt_list_can_be_filtered_by_status(): void
    {
        [$tenant, $customer] = $this->tenantAndCustomer();
        Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')
            ->create(['reference_number' => 'DBT-000001', 'debt_status' => 'paid']);
        Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')
            ->create(['reference_number' => 'DBT-000002', 'debt_status' => 'pending']);

        $response = $this->actingAs($this->platformAdmin())->get('/admin/recovery-debts?status=paid');

        $response->assertOk();
        $response->assertSee('DBT-000001');
        $response->assertDontSee('DBT-000002');
    }

    public function test_debt_list_can_be_filtered_to_overdue_only(): void
    {
        [$tenant, $customer] = $this->tenantAndCustomer();
        Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->overdue()
            ->create(['reference_number' => 'DBT-000001', 'debt_status' => 'pending']);
        Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')
            ->create(['reference_number' => 'DBT-000002', 'debt_status' => 'pending']);

        $response = $this->actingAs($this->platformAdmin())->get('/admin/recovery-debts?overdue_only=1');

        $response->assertOk();
        $response->assertSee('DBT-000001');
        $response->assertDontSee('DBT-000002');
    }

    public function test_platform_administrator_can_view_a_debt_detail_page_with_payments_and_case(): void
    {
        $tenant = Tenant::factory()->create(['business_name' => 'Hodan Trading']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create(['name' => 'Amina Ali']);
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')
            ->create(['reference_number' => 'DBT-000001']);
        Payment::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create(['amount' => 150]);
        CollectionCase::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create(['reference_number' => 'COL-000001']);

        $response = $this->actingAs($this->platformAdmin())->get("/admin/recovery-debts/{$debt->id}");

        $response->assertOk();
        $response->assertSee('DBT-000001');
        $response->assertSee('Amina Ali');
        $response->assertSee('Hodan Trading');
        $response->assertSee('150.00');
        $response->assertSee('COL-000001');
    }

    public function test_a_business_owner_is_forbidden_from_recovery_debts(): void
    {
        $tenant = Tenant::factory()->create();
        $owner = User::factory()->create();
        $owner->tenant()->associate($tenant);
        $owner->save();
        $owner->assignRole('admin');

        $this->actingAs($owner)->get('/admin/recovery-debts')->assertForbidden();
    }

    public function test_guest_is_redirected_to_login(): void
    {
        $response = $this->get('/admin/recovery-debts');

        $response->assertRedirect(route('admin.login'));
    }

    /**
     * @return array{0: Tenant, 1: Customer}
     */
    private function tenantAndCustomer(string $customerName = 'Test Debtor'): array
    {
        $tenant = Tenant::factory()->create();
        $customer = Customer::factory()->for($tenant, 'tenant')->create(['name' => $customerName]);

        return [$tenant, $customer];
    }
}
