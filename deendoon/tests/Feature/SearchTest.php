<?php

namespace Tests\Feature;

use App\Models\CollectionCase;
use App\Models\Customer;
use App\Models\Debt;
use App\Models\Tenant;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class SearchTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RoleSeeder::class);
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

    public function test_search_finds_a_customer_by_name(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create(['name' => 'Farah Trading Co']);
        $this->actingAsTenantUser($tenant);

        $response = $this->getJson('/api/v1/search?q=Farah');

        $response->assertStatus(200);
        $ids = collect($response->json('data.customers'))->pluck('id');
        $this->assertTrue($ids->contains($customer->id));
    }

    public function test_search_finds_a_debt_by_reference_number(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create(['reference_number' => 'DBT-000123']);
        $this->actingAsTenantUser($tenant);

        $response = $this->getJson('/api/v1/search?q=DBT-000123');

        $ids = collect($response->json('data.debts'))->pluck('id');
        $this->assertTrue($ids->contains($debt->id));
    }

    public function test_search_finds_a_collection_case_by_reference_number(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create();
        $case = CollectionCase::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create(['reference_number' => 'COL-000456']);
        $this->actingAsTenantUser($tenant);

        $response = $this->getJson('/api/v1/search?q=COL-000456');

        $ids = collect($response->json('data.collection_cases'))->pluck('id');
        $this->assertTrue($ids->contains($case->id));
    }

    public function test_search_excludes_archived_customers_by_default(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->archived()->for($tenant, 'tenant')->create(['name' => 'Old Archived Co']);
        $this->actingAsTenantUser($tenant);

        $response = $this->getJson('/api/v1/search?q=Archived');
        $ids = collect($response->json('data.customers'))->pluck('id');
        $this->assertFalse($ids->contains($customer->id));

        $response = $this->getJson('/api/v1/search?q=Archived&includeArchived=true');
        $ids = collect($response->json('data.customers'))->pluck('id');
        $this->assertTrue($ids->contains($customer->id));
    }

    public function test_customer_role_gets_no_results_for_any_entity_type(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        Customer::factory()->for($tenant, 'tenant')->create(['name' => 'Visible To Nobody']);
        $this->actingAsTenantUser($tenant, 'customer');

        $response = $this->getJson('/api/v1/search?q=Visible');

        $response->assertStatus(200);
        $this->assertNull($response->json('data.customers'));
    }

    public function test_search_is_scoped_to_the_requesting_tenant(): void
    {
        $tenantA = Tenant::create(['business_name' => 'Acme Co']);
        $tenantB = Tenant::create(['business_name' => 'Other Co']);
        Customer::factory()->for($tenantB, 'tenant')->create(['name' => 'Other Tenant Customer']);
        $this->actingAsTenantUser($tenantA);

        $response = $this->getJson('/api/v1/search?q=Other Tenant');

        $this->assertEmpty($response->json('data.customers'));
    }

    public function test_missing_query_is_rejected(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $this->getJson('/api/v1/search')->assertStatus(422);
    }

    public function test_unauthenticated_requests_are_rejected(): void
    {
        $this->getJson('/api/v1/search?q=test')->assertStatus(401);
    }
}
