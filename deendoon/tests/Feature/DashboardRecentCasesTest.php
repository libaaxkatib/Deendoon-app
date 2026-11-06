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

/**
 * Mobile QA Fix — Archived Customer: `DashboardController::recentCases()`
 * reuses `CollectionCaseResource` with the same `debt.customer` eager load
 * as CollectionCaseController — so it shared the identical "Unknown
 * Customer" bug once a Customer with an active Case was archived.
 */
class DashboardRecentCasesTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RoleSeeder::class);
    }

    public function test_recent_cases_still_shows_the_customer_name_after_the_customer_is_archived(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $user = User::factory()->create();
        $user->tenant()->associate($tenant);
        $user->save();
        $user->assignRole('admin');
        $this->withHeader('Authorization', 'Bearer '.$user->createToken('test')->plainTextToken);

        $customer = Customer::factory()->for($tenant, 'tenant')->create(['name' => 'Ahmed Trading Co.']);
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create();
        CollectionCase::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create();

        $customer->delete();

        $this->getJson('/api/v1/dashboard/recent-cases')
            ->assertStatus(200)
            ->assertJsonPath('data.0.customer_name', 'Ahmed Trading Co.')
            ->assertJsonPath('data.0.customer_archived', true);
    }
}
