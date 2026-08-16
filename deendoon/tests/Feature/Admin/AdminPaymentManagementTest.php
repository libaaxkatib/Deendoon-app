<?php

namespace Tests\Feature\Admin;

use App\Models\Customer;
use App\Models\Debt;
use App\Models\Payment;
use App\Models\Tenant;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminPaymentManagementTest extends TestCase
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

    /**
     * @return array{0: Tenant, 1: Customer, 2: Debt}
     */
    private function tenantCustomerDebt(string $businessName = 'Hodan Trading', string $customerName = 'Amina Ali'): array
    {
        $tenant = Tenant::factory()->create(['business_name' => $businessName]);
        $customer = Customer::factory()->for($tenant, 'tenant')->create(['name' => $customerName]);
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')
            ->create(['reference_number' => 'DBT-000001']);

        return [$tenant, $customer, $debt];
    }

    public function test_platform_administrator_can_view_payments(): void
    {
        [$tenant, , $debt] = $this->tenantCustomerDebt();
        Payment::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create(['amount' => 150]);

        $response = $this->actingAs($this->platformAdmin())->get('/admin/payments');

        $response->assertOk();
        $response->assertSee('150.00');
    }

    public function test_payments_from_multiple_tenants_are_visible(): void
    {
        [$tenantA, , $debtA] = $this->tenantCustomerDebt('Hodan Trading', 'Amina Ali');
        [$tenantB, , $debtB] = $this->tenantCustomerDebt('Barwaqo Imports', 'Yusuf Nur');
        Payment::factory()->for($tenantA, 'tenant')->for($debtA, 'debt')->create(['amount' => 150]);
        Payment::factory()->for($tenantB, 'tenant')->for($debtB, 'debt')->create(['amount' => 275]);

        $response = $this->actingAs($this->platformAdmin())->get('/admin/payments');

        $response->assertOk();
        $response->assertSee('150.00');
        $response->assertSee('275.00');
        $response->assertSee('Hodan Trading');
        $response->assertSee('Barwaqo Imports');
        $response->assertSee('Amina Ali');
        $response->assertSee('Yusuf Nur');
    }

    public function test_payment_list_can_be_searched_by_debt_reference(): void
    {
        [$tenant, $customer] = $this->tenantCustomerDebt();
        $debtA = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create(['reference_number' => 'DBT-000123']);
        $debtB = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create(['reference_number' => 'DBT-000999']);
        Payment::factory()->for($tenant, 'tenant')->for($debtA, 'debt')->create(['amount' => 111]);
        Payment::factory()->for($tenant, 'tenant')->for($debtB, 'debt')->create(['amount' => 222]);

        $response = $this->actingAs($this->platformAdmin())->get('/admin/payments?search=000123');

        $response->assertOk();
        $response->assertSee('111.00');
        $response->assertDontSee('222.00');
    }

    public function test_payment_list_can_be_searched_by_debtor_name(): void
    {
        [$tenant, , $debtA] = $this->tenantCustomerDebt('Hodan Trading', 'Amina Ali');
        $customerB = Customer::factory()->for($tenant, 'tenant')->create(['name' => 'Yusuf Nur']);
        $debtB = Debt::factory()->for($tenant, 'tenant')->for($customerB, 'customer')->create(['reference_number' => 'DBT-000002']);
        Payment::factory()->for($tenant, 'tenant')->for($debtA, 'debt')->create(['amount' => 111]);
        Payment::factory()->for($tenant, 'tenant')->for($debtB, 'debt')->create(['amount' => 222]);

        $response = $this->actingAs($this->platformAdmin())->get('/admin/payments?search=amina');

        $response->assertOk();
        $response->assertSee('111.00');
        $response->assertDontSee('222.00');
    }

    public function test_payment_list_can_be_filtered_by_payment_method(): void
    {
        [$tenant, , $debt] = $this->tenantCustomerDebt();
        Payment::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create(['amount' => 111, 'payment_method' => 'cash']);
        Payment::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create(['amount' => 222, 'payment_method' => 'bank_transfer']);

        $response = $this->actingAs($this->platformAdmin())->get('/admin/payments?payment_method=cash');

        $response->assertOk();
        $response->assertSee('111.00');
        $response->assertDontSee('222.00');
    }

    public function test_payment_list_can_be_filtered_by_date_range(): void
    {
        [$tenant, , $debt] = $this->tenantCustomerDebt();
        Payment::factory()->for($tenant, 'tenant')->for($debt, 'debt')
            ->create(['amount' => 111, 'payment_date' => '2026-01-15']);
        Payment::factory()->for($tenant, 'tenant')->for($debt, 'debt')
            ->create(['amount' => 222, 'payment_date' => '2026-06-15']);

        $response = $this->actingAs($this->platformAdmin())
            ->get('/admin/payments?date_from=2026-01-01&date_to=2026-02-01');

        $response->assertOk();
        $response->assertSee('111.00');
        $response->assertDontSee('222.00');
    }

    public function test_payment_list_is_paginated(): void
    {
        [$tenant, , $debt] = $this->tenantCustomerDebt();
        foreach (range(1, 25) as $i) {
            Payment::factory()->for($tenant, 'tenant')->for($debt, 'debt')
                ->create([
                    'amount' => $i,
                    'payment_date' => now()->subDays(30 - $i),
                    'created_at' => now()->subMinutes(30 - $i),
                ]);
        }

        $page1 = $this->actingAs($this->platformAdmin())->get('/admin/payments');
        $page1->assertOk();
        // Newest created_at first (highest $i) on page 1.
        $page1->assertSee('25.00');

        $page2 = $this->actingAs($this->platformAdmin())->get('/admin/payments?page=2');
        $page2->assertOk();
        $page2->assertSee('1.00');
    }

    public function test_platform_administrator_can_view_a_payment_detail_page(): void
    {
        [$tenant, , $debt] = $this->tenantCustomerDebt();
        $payment = Payment::factory()->for($tenant, 'tenant')->for($debt, 'debt')
            ->create(['amount' => 150, 'payment_method' => 'cash', 'reference_notes' => 'Partial settlement']);

        $response = $this->actingAs($this->platformAdmin())->get("/admin/payments/{$payment->id}");

        $response->assertOk();
        $response->assertSee('150.00');
        $response->assertSee('Cash');
        $response->assertSee('Partial settlement');
    }

    public function test_payment_detail_shows_related_debtor_business_and_debt(): void
    {
        [$tenant, $customer, $debt] = $this->tenantCustomerDebt('Hodan Trading', 'Amina Ali');
        $payment = Payment::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create(['amount' => 150]);

        $response = $this->actingAs($this->platformAdmin())->get("/admin/payments/{$payment->id}");

        $response->assertOk();
        $response->assertSee('Hodan Trading');
        $response->assertSee('Amina Ali');
        $response->assertSee('DBT-000001');
        $response->assertSee(route('admin.recovery-debts.show', $debt), false);
        $response->assertSee(route('admin.businesses.show', $tenant), false);
        $response->assertSee(route('admin.debtors.show', $customer), false);
    }

    public function test_payment_detail_has_no_write_actions(): void
    {
        [$tenant, , $debt] = $this->tenantCustomerDebt();
        $payment = Payment::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create(['amount' => 150]);

        $response = $this->actingAs($this->platformAdmin())->get("/admin/payments/{$payment->id}");

        $response->assertOk();
        // The shared admin layout always renders a logout <form> in the
        // sidebar — that's not a payment action, so it's excluded from
        // this check; no payment-specific write/action control exists.
        $response->assertDontSee('Edit Payment');
        $response->assertDontSee('Delete Payment');
        $response->assertDontSee('Refund');
        $response->assertDontSee('Record Payment');
        $response->assertDontSee('Void Payment');
    }

    public function test_a_business_owner_is_forbidden_from_payments(): void
    {
        $tenant = Tenant::factory()->create();
        $owner = User::factory()->create();
        $owner->tenant()->associate($tenant);
        $owner->save();
        $owner->assignRole('admin');

        $this->actingAs($owner)->get('/admin/payments')->assertForbidden();
    }

    public function test_guest_is_redirected_to_admin_login(): void
    {
        $response = $this->get('/admin/payments');

        $response->assertRedirect(route('admin.login'));
    }

    public function test_no_payment_is_hidden_by_tenant_scope(): void
    {
        // The Platform Administrator has tenant_id === null. If the admin
        // controller ever forgot withoutGlobalScope('tenant'), BelongsToTenant
        // would fail closed to `WHERE tenant_id IS NULL`, silently returning
        // zero payments instead of erroring — this guards against that regression.
        [$tenantA, , $debtA] = $this->tenantCustomerDebt('Hodan Trading', 'Amina Ali');
        [$tenantB, , $debtB] = $this->tenantCustomerDebt('Barwaqo Imports', 'Yusuf Nur');
        Payment::factory()->for($tenantA, 'tenant')->for($debtA, 'debt')->count(2)->create();
        Payment::factory()->for($tenantB, 'tenant')->for($debtB, 'debt')->count(3)->create();

        $response = $this->actingAs($this->platformAdmin())->get('/admin/payments');

        $response->assertOk();
        $response->assertDontSee('No payments match your filters');
    }
}
