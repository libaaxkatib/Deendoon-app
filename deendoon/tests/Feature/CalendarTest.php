<?php

namespace Tests\Feature;

use App\Models\Customer;
use App\Models\Debt;
use App\Models\PromiseToPay;
use App\Models\Tenant;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class CalendarTest extends TestCase
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

    private function makeDebt(Tenant $tenant, array $attributes = []): Debt
    {
        $customer = Customer::factory()->for($tenant, 'tenant')->create();

        return Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create($attributes);
    }

    public function test_admin_can_view_the_calendar(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $this->getJson('/api/v1/calendar')->assertStatus(200)->assertJsonStructure(['data' => ['from', 'to', 'entries']]);
    }

    public function test_calendar_includes_debt_due_dates_within_range(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant, ['due_date' => now()->addDays(5)->toDateString()]);
        $this->actingAsTenantUser($tenant);

        $from = now()->toDateString();
        $to = now()->addDays(10)->toDateString();
        $response = $this->getJson("/api/v1/calendar?from={$from}&to={$to}");

        $entries = collect($response->json('data.entries'));
        $this->assertTrue($entries->contains(fn ($e) => $e['type'] === 'due_date' && $e['related_entity_id'] === $debt->id));
    }

    public function test_calendar_excludes_closed_debts(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant, ['due_date' => now()->addDays(5)->toDateString(), 'debt_status' => 'paid']);
        $this->actingAsTenantUser($tenant);

        $from = now()->toDateString();
        $to = now()->addDays(10)->toDateString();
        $response = $this->getJson("/api/v1/calendar?from={$from}&to={$to}");

        $entries = collect($response->json('data.entries'));
        $this->assertFalse($entries->contains(fn ($e) => $e['related_entity_id'] === $debt->id));
    }

    public function test_calendar_includes_open_promise_to_pay_dates(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $user = $this->actingAsTenantUser($tenant);
        $promise = PromiseToPay::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create([
            'promised_date' => now()->addDays(3)->toDateString(),
            'status' => 'open',
            'created_by_user_id' => (string) $user->id,
        ]);

        $from = now()->toDateString();
        $to = now()->addDays(10)->toDateString();
        $response = $this->getJson("/api/v1/calendar?from={$from}&to={$to}");

        $entries = collect($response->json('data.entries'));
        $this->assertTrue($entries->contains(fn ($e) => $e['type'] === 'promise_to_pay' && $e['related_entity_id'] === $promise->id));
    }

    public function test_calendar_includes_manual_reminder_activity(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);
        $this->postJson("/api/v1/debts/{$debt->id}/reminders/call", [])->assertStatus(200);

        $from = now()->subDays(1)->toDateString();
        $to = now()->addDays(1)->toDateString();
        $response = $this->getJson("/api/v1/calendar?from={$from}&to={$to}");

        $entries = collect($response->json('data.entries'));
        $this->assertTrue($entries->contains(fn ($e) => $e['type'] === 'follow_up' && $e['related_entity_id'] === $debt->id));
    }

    public function test_calendar_excludes_items_outside_the_requested_range(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant, ['due_date' => now()->addDays(60)->toDateString()]);
        $this->actingAsTenantUser($tenant);

        $from = now()->toDateString();
        $to = now()->addDays(10)->toDateString();
        $response = $this->getJson("/api/v1/calendar?from={$from}&to={$to}");

        $entries = collect($response->json('data.entries'));
        $this->assertFalse($entries->contains(fn ($e) => $e['related_entity_id'] === $debt->id));
    }

    public function test_unauthenticated_requests_are_rejected(): void
    {
        $this->getJson('/api/v1/calendar')->assertStatus(401);
    }

    public function test_customer_role_cannot_view_calendar(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant, 'customer');

        $this->getJson('/api/v1/calendar')->assertStatus(403);
    }
}
