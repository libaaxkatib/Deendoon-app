<?php

namespace Tests\Feature;

use App\Models\CollectionCase;
use App\Models\Customer;
use App\Models\Debt;
use App\Models\Reminder;
use App\Models\SubscriptionPlan;
use App\Models\Tenant;
use App\Models\TenantSubscription;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Backend Completion Roadmap, Phase 4.1 — Customer Limit Enforcement.
 * End-to-end HTTP coverage: Create/Edit/Archive blocked once a Customer
 * is read-only; the read-only cascade to Debts, Collection Cases, and
 * Reminders; read operations (view/list/search) continue working
 * regardless of read-only status; tenant isolation.
 */
class CustomerLimitEnforcementTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RoleSeeder::class);
    }

    private function actingAsTenantUser(Tenant $tenant): User
    {
        $user = User::factory()->create();
        $user->tenant()->associate($tenant);
        $user->save();
        $user->assignRole('admin');

        $token = $user->createToken('test')->plainTextToken;
        $this->withHeader('Authorization', 'Bearer '.$token);

        return $user;
    }

    private function subscribe(Tenant $tenant, ?int $customerLimit): SubscriptionPlan
    {
        $plan = SubscriptionPlan::factory()->create(['customer_limit' => $customerLimit]);
        TenantSubscription::factory()->for($tenant, 'tenant')->for($plan, 'plan')->active()->create();

        return $plan;
    }

    private function markReadOnly(Customer $customer): void
    {
        Customer::where('id', $customer->id)->update(['is_read_only' => true]);
    }

    // --- Create Customer blocked at limit ---

    public function test_creating_a_customer_beyond_the_plan_limit_is_forbidden(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->subscribe($tenant, 1);
        Customer::factory()->for($tenant, 'tenant')->create();
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson('/api/v1/customers', [
            'name' => 'Overflow Customer',
            'phone' => '254712345678',
            'credit_limit' => 1000,
        ]);

        $response->assertStatus(403);
        $this->assertSame(1, Customer::count());
    }

    public function test_creating_a_customer_within_the_plan_limit_is_allowed(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->subscribe($tenant, 2);
        Customer::factory()->for($tenant, 'tenant')->create();
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson('/api/v1/customers', [
            'name' => 'Second Customer',
            'phone' => '254712345678',
            'credit_limit' => 1000,
        ]);

        $response->assertStatus(201);
        $this->assertSame(2, Customer::count());
    }

    public function test_creating_a_customer_is_always_allowed_on_an_unlimited_plan(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->subscribe($tenant, null);
        Customer::factory()->for($tenant, 'tenant')->count(5)->create();
        $this->actingAsTenantUser($tenant);

        $this->postJson('/api/v1/customers', [
            'name' => 'Sixth Customer',
            'phone' => '254712345678',
            'credit_limit' => 1000,
        ])->assertStatus(201);
    }

    public function test_new_customer_creation_correctly_reports_its_own_read_only_status(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->subscribe($tenant, 1);
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson('/api/v1/customers', [
            'name' => 'Only Customer',
            'phone' => '254712345678',
            'credit_limit' => 1000,
        ]);

        $response->assertStatus(201)->assertJsonPath('data.customer.is_read_only', false);
    }

    // --- Edit / Archive blocked on read-only customer ---

    public function test_editing_a_read_only_customer_is_forbidden(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create(['name' => 'Old Name']);
        $this->markReadOnly($customer);
        $this->actingAsTenantUser($tenant);

        $response = $this->putJson("/api/v1/customers/{$customer->id}", [
            'name' => 'New Name',
            'phone' => $customer->phone,
            'credit_limit' => $customer->credit_limit,
        ]);

        $response->assertStatus(403);
        $this->assertSame('Old Name', $customer->fresh()->name);
    }

    public function test_archiving_a_read_only_customer_is_forbidden(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $this->markReadOnly($customer);
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson("/api/v1/customers/{$customer->id}/archive");

        $response->assertStatus(403);
        $this->assertNull($customer->fresh()->archived_at);
    }

    public function test_restoring_an_archived_customer_is_not_blocked_by_read_only_status(): void
    {
        // Restore is checked against the tenant's CURRENT limit via
        // recalculation after the restore, not against a frozen
        // pre-archive snapshot — so restore itself is never gated on
        // is_read_only (see CustomerPolicy::restore()'s docblock).
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->subscribe($tenant, 5);
        $customer = Customer::factory()->for($tenant, 'tenant')->archived()->create();
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/customers/{$customer->id}/restore")->assertStatus(200);
    }

    public function test_restore_is_always_allowed_even_when_the_tenant_is_already_at_its_limit(): void
    {
        // Product Owner Decision (2026-08-06): restore is never blocked
        // by the plan limit — recalculate() alone decides the outcome
        // afterward.
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->subscribe($tenant, 1);
        Customer::factory()->for($tenant, 'tenant')->create(['created_at' => '2026-01-01']);
        $archived = Customer::factory()->for($tenant, 'tenant')->archived()->create(['created_at' => '2026-01-02']);
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson("/api/v1/customers/{$archived->id}/restore");

        $response->assertStatus(200);
        // Restore succeeded, but the tenant is still over its limit of 1
        // — recalculate() correctly leaves the newly-restored (newer)
        // customer read-only rather than silently allowing 2 editable.
        $this->assertTrue($archived->fresh()->is_read_only);
    }

    public function test_restore_recalculates_the_restored_customer_as_editable_when_within_the_limit(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->subscribe($tenant, 2);
        Customer::factory()->for($tenant, 'tenant')->create(['created_at' => '2026-01-01']);
        $archived = Customer::factory()->for($tenant, 'tenant')->archived()->create(['created_at' => '2026-01-02']);
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/customers/{$archived->id}/restore")->assertStatus(200);

        $this->assertFalse($archived->fresh()->is_read_only);
    }

    // --- Read operations continue working ---

    public function test_viewing_a_read_only_customer_still_works(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $this->markReadOnly($customer);
        $this->actingAsTenantUser($tenant);

        $this->getJson("/api/v1/customers/{$customer->id}")->assertStatus(200);
    }

    public function test_listing_includes_read_only_customers(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create(['name' => 'Read Only One']);
        $this->markReadOnly($customer);
        $this->actingAsTenantUser($tenant);

        $response = $this->getJson('/api/v1/customers');

        $names = collect($response->json('data.customers'))->pluck('name');
        $this->assertTrue($names->contains('Read Only One'));
    }

    public function test_searching_for_a_read_only_customer_still_works(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create(['name' => 'Findable ReadOnly']);
        $this->markReadOnly($customer);
        $this->actingAsTenantUser($tenant);

        $response = $this->getJson('/api/v1/customers?search=Findable');

        $names = collect($response->json('data.customers'))->pluck('name');
        $this->assertTrue($names->contains('Findable ReadOnly'));
    }

    // --- Cascade: Debt ---

    public function test_creating_a_debt_for_a_read_only_customer_is_forbidden(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create(['credit_limit' => 5000]);
        $this->markReadOnly($customer);
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson("/api/v1/customers/{$customer->id}/debts", [
            'amount' => 1000,
            'due_date' => now()->addDays(30)->toDateString(),
        ]);

        $response->assertStatus(403);
        $this->assertSame(0, Debt::count());
    }

    public function test_updating_a_debt_of_a_read_only_customer_is_forbidden(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create();
        $this->markReadOnly($customer);
        $this->actingAsTenantUser($tenant);

        $this->putJson("/api/v1/debts/{$debt->id}", [
            'due_date' => now()->addDays(60)->toDateString(),
        ])->assertStatus(403);
    }

    public function test_archiving_a_debt_of_a_read_only_customer_is_forbidden(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create();
        $this->markReadOnly($customer);
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/debts/{$debt->id}/archive")->assertStatus(403);
    }

    public function test_recording_a_payment_for_a_read_only_customers_debt_is_forbidden(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create(['remaining_balance' => 500]);
        $this->markReadOnly($customer);
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson("/api/v1/debts/{$debt->id}/payments", [
            'amount' => 100,
            'payment_date' => now()->toDateString(),
        ]);

        $response->assertStatus(403);
        $this->assertSame('500.00', $debt->fresh()->remaining_balance);
    }

    public function test_escalating_a_read_only_customers_debt_to_collection_is_forbidden(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create();
        $this->markReadOnly($customer);
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/debts/{$debt->id}/collection-cases")->assertStatus(403);
        $this->assertSame(0, CollectionCase::count());
    }

    public function test_reading_a_debt_of_a_read_only_customer_still_works(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create();
        $this->markReadOnly($customer);
        $this->actingAsTenantUser($tenant);

        $this->getJson("/api/v1/debts/{$debt->id}")->assertStatus(200);
    }

    // --- Cascade: Collection Case ---

    public function test_recording_a_collection_activity_for_a_read_only_customer_is_forbidden(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create();
        $case = CollectionCase::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create();
        $this->markReadOnly($customer);
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/collection-cases/{$case->id}/activities", [
            'details' => 'Called the customer',
        ])->assertStatus(403);
    }

    public function test_closing_a_collection_case_for_a_read_only_customer_is_forbidden(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create();
        $case = CollectionCase::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create();
        $this->markReadOnly($customer);
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/collection-cases/{$case->id}/close", [
            'closure_outcome' => 'recovered',
        ])->assertStatus(403);
    }

    public function test_viewing_a_collection_case_for_a_read_only_customer_still_works(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create();
        $case = CollectionCase::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create();
        $this->markReadOnly($customer);
        $this->actingAsTenantUser($tenant);

        $this->getJson("/api/v1/collection-cases/{$case->id}")->assertStatus(200);
    }

    // --- Cascade: Reminder ---

    public function test_creating_a_reminder_for_a_read_only_customer_is_forbidden(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $this->markReadOnly($customer);
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson('/api/v1/reminders', [
            'type' => 'follow_up_call',
            'related_entity_type' => 'customer',
            'related_entity_id' => $customer->id,
            'due_date' => now()->addDay()->toDateString(),
            'timing_rule' => 'same_day',
            'delivery_methods' => ['in_app'],
        ]);

        $response->assertStatus(403);
        $this->assertSame(0, Reminder::count());
    }

    public function test_updating_a_reminder_for_a_read_only_customer_is_forbidden(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $user = $this->actingAsTenantUser($tenant);
        $reminder = Reminder::factory()->for($tenant, 'tenant')->create([
            'created_by_user_id' => (string) $user->id,
            'related_entity_type' => 'customer',
            'related_entity_id' => $customer->id,
        ]);
        $this->markReadOnly($customer);

        $this->putJson("/api/v1/reminders/{$reminder->id}", [
            'notes' => 'Updated notes',
        ])->assertStatus(403);
    }

    public function test_deleting_a_reminder_for_a_read_only_customer_is_forbidden(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $user = $this->actingAsTenantUser($tenant);
        $reminder = Reminder::factory()->for($tenant, 'tenant')->create([
            'created_by_user_id' => (string) $user->id,
            'related_entity_type' => 'customer',
            'related_entity_id' => $customer->id,
        ]);
        $this->markReadOnly($customer);

        $this->deleteJson("/api/v1/reminders/{$reminder->id}")->assertStatus(403);
        $this->assertNotSoftDeleted('reminders', ['id' => $reminder->id]);
    }

    public function test_completing_a_reminder_for_a_read_only_customer_is_forbidden(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $user = $this->actingAsTenantUser($tenant);
        $reminder = Reminder::factory()->for($tenant, 'tenant')->create([
            'created_by_user_id' => (string) $user->id,
            'related_entity_type' => 'customer',
            'related_entity_id' => $customer->id,
        ]);
        $this->markReadOnly($customer);

        $this->patchJson("/api/v1/reminders/{$reminder->id}/complete")->assertStatus(403);
        $this->assertNull($reminder->fresh()->completed_at);
    }

    public function test_viewing_a_reminder_for_a_read_only_customer_still_works(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $user = $this->actingAsTenantUser($tenant);
        $reminder = Reminder::factory()->for($tenant, 'tenant')->create([
            'created_by_user_id' => (string) $user->id,
            'related_entity_type' => 'customer',
            'related_entity_id' => $customer->id,
        ]);
        $this->markReadOnly($customer);

        $this->getJson("/api/v1/reminders/{$reminder->id}")->assertStatus(200);
    }

    // --- Promotion after archive, through the real HTTP + service stack ---

    public function test_archiving_the_only_editable_customer_promotes_the_next_oldest_via_http(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->subscribe($tenant, 1);
        $oldest = Customer::factory()->for($tenant, 'tenant')->create(['created_at' => '2026-01-01']);
        $second = Customer::factory()->for($tenant, 'tenant')->create(['created_at' => '2026-01-02']);
        $this->markReadOnly($second);
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/customers/{$oldest->id}/archive")->assertStatus(200);

        $this->assertFalse($second->fresh()->is_read_only);
    }

    // --- Tenant isolation ---

    public function test_a_tenants_customer_limit_does_not_affect_another_tenant(): void
    {
        $tenantA = Tenant::create(['business_name' => 'Tenant A']);
        $tenantB = Tenant::create(['business_name' => 'Tenant B']);
        $this->subscribe($tenantA, 1);
        $this->subscribe($tenantB, 5);
        Customer::factory()->for($tenantA, 'tenant')->create();
        $this->actingAsTenantUser($tenantB);

        $this->postJson('/api/v1/customers', [
            'name' => 'Tenant B Customer',
            'phone' => '254712345678',
            'credit_limit' => 1000,
        ])->assertStatus(201);
    }

    // --- Fail closed: no resolvable plan (Product Owner Decision, 2026-08-06) ---

    public function test_creating_a_customer_is_forbidden_when_no_plan_can_be_resolved_at_all(): void
    {
        // No TenantSubscription set up, and this test does not seed the
        // Free Plan — must never fall back to "unlimited".
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson('/api/v1/customers', [
            'name' => 'First Customer',
            'phone' => '254712345678',
            'credit_limit' => 1000,
        ]);

        $response->assertStatus(403);
        $this->assertSame(0, Customer::count());
    }

    public function test_existing_customers_become_read_only_when_no_plan_can_be_resolved_at_all(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $this->actingAsTenantUser($tenant);

        // is_read_only defaults false at the column level until the
        // first recalculation runs; restore is never blocked, so it's a
        // reliable way to trigger one without depending on any other
        // enforcement path.
        $throwaway = Customer::factory()->for($tenant, 'tenant')->archived()->create();
        $this->postJson("/api/v1/customers/{$throwaway->id}/restore")->assertStatus(200);

        $this->assertTrue($customer->fresh()->is_read_only);
    }
}
