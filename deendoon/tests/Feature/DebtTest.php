<?php

namespace Tests\Feature;

use App\Models\Customer;
use App\Models\Debt;
use App\Models\Tenant;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DebtTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RoleSeeder::class);
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

    public function test_admin_can_create_a_debt_against_a_customer(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create(['credit_limit' => 5000]);
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson("/api/v1/customers/{$customer->id}/debts", [
            'amount' => 1000,
            'due_date' => now()->addDays(30)->toDateString(),
        ]);

        $response->assertStatus(201)
            ->assertJson(['success' => true])
            ->assertJsonPath('data.debt.debt_status', 'pending')
            ->assertJsonPath('data.debt.remaining_balance', '1000.00')
            ->assertJsonPath('data.debt.recovery_stage', 1)
            ->assertJsonPath('data.warning', null);

        $this->assertDatabaseHas('debts', [
            'tenant_id' => $tenant->id,
            'customer_id' => $customer->id,
            'debt_status' => 'pending',
        ]);
    }

    public function test_debt_creation_requires_amount_and_due_date(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/customers/{$customer->id}/debts", [])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['amount', 'due_date']);
    }

    public function test_debt_amount_must_be_positive(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/customers/{$customer->id}/debts", [
            'amount' => -50,
            'due_date' => now()->addDays(10)->toDateString(),
        ])->assertStatus(422)->assertJsonValidationErrors(['amount']);
    }

    public function test_debt_creation_generates_sequential_reference_numbers_per_tenant(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $this->actingAsTenantUser($tenant);

        $first = $this->postJson("/api/v1/customers/{$customer->id}/debts", [
            'amount' => 100, 'due_date' => now()->addDays(10)->toDateString(),
        ])->json('data.debt.reference_number');

        $second = $this->postJson("/api/v1/customers/{$customer->id}/debts", [
            'amount' => 200, 'due_date' => now()->addDays(10)->toDateString(),
        ])->json('data.debt.reference_number');

        $this->assertSame('DBT-000001', $first);
        $this->assertSame('DBT-000002', $second);
    }

    public function test_debt_creation_recalculates_customer_outstanding_balance(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create(['credit_limit' => 5000]);
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/customers/{$customer->id}/debts", [
            'amount' => 1000, 'due_date' => now()->addDays(10)->toDateString(),
        ])->assertStatus(201);

        $this->assertSame('1000.00', $customer->fresh()->outstanding_balance);
    }

    public function test_debt_creation_against_an_archived_customer_is_rejected(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->archived()->create();
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/customers/{$customer->id}/debts", [
            'amount' => 100, 'due_date' => now()->addDays(10)->toDateString(),
        ])->assertStatus(404);
    }

    public function test_debt_creation_triggers_a_credit_limit_warning_but_still_creates_the_debt(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create(['credit_limit' => 500]);
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson("/api/v1/customers/{$customer->id}/debts", [
            'amount' => 1000, 'due_date' => now()->addDays(10)->toDateString(),
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('data.warning.type', 'CREDIT_LIMIT_EXCEEDED')
            ->assertJsonPath('data.warning.credit_limit', '500.00')
            ->assertJsonPath('data.warning.projected_outstanding', '1000.00');

        $this->assertDatabaseCount('debts', 1);
    }

    public function test_debt_creation_records_a_created_audit_event(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $user = $this->actingAsTenantUser($tenant);

        $debtId = $this->postJson("/api/v1/customers/{$customer->id}/debts", [
            'amount' => 100, 'due_date' => now()->addDays(10)->toDateString(),
        ])->json('data.debt.id');

        $this->assertDatabaseHas('audit_log', [
            'tenant_id' => $tenant->id,
            'user_id' => (string) $user->id,
            'action' => 'created',
            'entity_type' => 'debt',
            'entity_id' => $debtId,
        ]);
    }

    // --- List / tenant isolation ---

    public function test_index_lists_only_the_authenticated_users_own_tenant_debts(): void
    {
        $tenantA = Tenant::create(['business_name' => 'Tenant A']);
        $tenantB = Tenant::create(['business_name' => 'Tenant B']);
        $customerA = Customer::factory()->for($tenantA, 'tenant')->create();
        $customerB = Customer::factory()->for($tenantB, 'tenant')->create();

        Debt::factory()->for($tenantA, 'tenant')->for($customerA, 'customer')->create(['reference_number' => 'DBT-A00001']);
        Debt::factory()->for($tenantB, 'tenant')->for($customerB, 'customer')->create(['reference_number' => 'DBT-B00001']);

        $this->actingAsTenantUser($tenantA);

        $response = $this->getJson('/api/v1/debts');

        $refs = collect($response->json('data.debts'))->pluck('reference_number');
        $this->assertTrue($refs->contains('DBT-A00001'));
        $this->assertFalse($refs->contains('DBT-B00001'));
    }

    public function test_index_can_filter_by_customer_id(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customerA = Customer::factory()->for($tenant, 'tenant')->create();
        $customerB = Customer::factory()->for($tenant, 'tenant')->create();
        Debt::factory()->for($tenant, 'tenant')->for($customerA, 'customer')->create(['reference_number' => 'DBT-A00001']);
        Debt::factory()->for($tenant, 'tenant')->for($customerB, 'customer')->create(['reference_number' => 'DBT-B00001']);

        $this->actingAsTenantUser($tenant);

        $response = $this->getJson("/api/v1/debts?customer_id={$customerA->id}");

        $refs = collect($response->json('data.debts'))->pluck('reference_number');
        $this->assertTrue($refs->contains('DBT-A00001'));
        $this->assertFalse($refs->contains('DBT-B00001'));
    }

    public function test_index_can_filter_by_status(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create(['reference_number' => 'DBT-000001', 'debt_status' => 'cancelled']);
        Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create(['reference_number' => 'DBT-000002', 'debt_status' => 'pending']);

        $this->actingAsTenantUser($tenant);

        $response = $this->getJson('/api/v1/debts?status=cancelled');

        $refs = collect($response->json('data.debts'))->pluck('reference_number');
        $this->assertTrue($refs->contains('DBT-000001'));
        $this->assertFalse($refs->contains('DBT-000002'));
    }

    // --- Show / tenant isolation / overdue transition ---

    public function test_show_returns_debt_details(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create();
        $this->actingAsTenantUser($tenant);

        $this->getJson("/api/v1/debts/{$debt->id}")
            ->assertStatus(200)
            ->assertJsonPath('data.id', $debt->id);
    }

    public function test_show_returns_404_for_another_tenants_debt(): void
    {
        $tenantA = Tenant::create(['business_name' => 'Tenant A']);
        $tenantB = Tenant::create(['business_name' => 'Tenant B']);
        $customerB = Customer::factory()->for($tenantB, 'tenant')->create();
        $debtB = Debt::factory()->for($tenantB, 'tenant')->for($customerB, 'customer')->create();

        $this->actingAsTenantUser($tenantA);

        $this->getJson("/api/v1/debts/{$debtB->id}")->assertStatus(404);
    }

    public function test_show_automatically_transitions_an_overdue_debt(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->overdue()->create(['debt_status' => 'pending']);
        $this->actingAsTenantUser($tenant);

        $response = $this->getJson("/api/v1/debts/{$debt->id}");

        $response->assertStatus(200)->assertJsonPath('data.debt_status', 'overdue');
        $this->assertDatabaseHas('audit_log', [
            'entity_id' => $debt->id,
            'action' => 'status_changed',
            'user_id' => null,
        ]);
    }

    // --- Update ---

    public function test_update_changes_non_financial_fields_and_records_an_edited_audit_event(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create(['notes' => 'old note']);
        $this->actingAsTenantUser($tenant);

        $newDueDate = now()->addDays(60)->toDateString();
        $response = $this->putJson("/api/v1/debts/{$debt->id}", [
            'due_date' => $newDueDate,
            'notes' => 'new note',
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('data.due_date', $newDueDate)
            ->assertJsonPath('data.notes', 'new note');

        $this->assertDatabaseHas('audit_log', ['entity_id' => $debt->id, 'action' => 'edited']);
    }

    public function test_update_does_not_accept_an_amount_change(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create(['amount' => 500]);
        $this->actingAsTenantUser($tenant);

        $this->putJson("/api/v1/debts/{$debt->id}", [
            'due_date' => now()->addDays(10)->toDateString(),
            'amount' => 9999,
        ])->assertStatus(200);

        $this->assertSame('500.00', $debt->fresh()->amount);
    }

    // --- Status ---

    public function test_status_can_be_manually_set_to_cancelled(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create();
        $this->actingAsTenantUser($tenant);

        $response = $this->patchJson("/api/v1/debts/{$debt->id}/status", ['debt_status' => 'cancelled']);

        $response->assertStatus(200)->assertJsonPath('data.debt_status', 'cancelled');
        $this->assertDatabaseHas('audit_log', ['entity_id' => $debt->id, 'action' => 'status_changed']);
    }

    public function test_status_rejects_paid_as_a_manual_value(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create();
        $this->actingAsTenantUser($tenant);

        $this->patchJson("/api/v1/debts/{$debt->id}/status", ['debt_status' => 'paid'])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['debt_status']);
    }

    public function test_status_change_to_terminal_recalculates_customer_outstanding_balance(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create(['outstanding_balance' => 1000]);
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create(['remaining_balance' => 1000]);
        $this->actingAsTenantUser($tenant);

        $this->patchJson("/api/v1/debts/{$debt->id}/status", ['debt_status' => 'written_off'])->assertStatus(200);

        $this->assertSame('0.00', $customer->fresh()->outstanding_balance);
    }

    public function test_status_change_on_an_already_terminal_debt_is_rejected(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create(['debt_status' => 'cancelled']);
        $this->actingAsTenantUser($tenant);

        $this->patchJson("/api/v1/debts/{$debt->id}/status", ['debt_status' => 'written_off'])
            ->assertStatus(422)
            ->assertJson(['success' => false]);
    }

    // --- Archive / Restore ---

    public function test_archive_soft_deletes_and_records_an_audit_event(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create();
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/debts/{$debt->id}/archive")->assertStatus(200);

        $this->assertNotNull($debt->fresh()->archived_at);
        $this->assertDatabaseHas('audit_log', ['entity_id' => $debt->id, 'action' => 'archived']);
    }

    public function test_restore_reactivates_an_archived_debt_and_records_an_audit_event(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->archived()->create();
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/debts/{$debt->id}/restore")->assertStatus(200);

        $this->assertNull($debt->fresh()->archived_at);
        $this->assertDatabaseHas('audit_log', ['entity_id' => $debt->id, 'action' => 'restored']);
    }

    public function test_archived_debt_is_viewable_in_a_restore_eligible_state(): void
    {
        // FR-019 (Business Owner Backend Completion): archived Debts are
        // now viewable via show() so a Business Owner can review one
        // before deciding to restore it.
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->archived()->create();
        $this->actingAsTenantUser($tenant);

        $response = $this->getJson("/api/v1/debts/{$debt->id}");

        $response->assertStatus(200)
            ->assertJsonPath('data.id', $debt->id)
            ->assertJsonPath('data.archived_at', fn (?string $value): bool => $value !== null);
    }

    public function test_show_returns_404_for_another_tenants_archived_debt(): void
    {
        $tenantA = Tenant::create(['business_name' => 'Tenant A']);
        $tenantB = Tenant::create(['business_name' => 'Tenant B']);
        $customer = Customer::factory()->for($tenantB, 'tenant')->create();
        $otherDebt = Debt::factory()->for($tenantB, 'tenant')->for($customer, 'customer')->archived()->create();
        $this->actingAsTenantUser($tenantA);

        $this->getJson("/api/v1/debts/{$otherDebt->id}")->assertStatus(404);
    }

    public function test_viewing_an_archived_debt_does_not_advance_its_overdue_status(): void
    {
        // Reviewing an archived record for a restore decision must not
        // silently mutate it via the same on-view side effects show()
        // applies to live Debts.
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')
            ->archived()->create(['debt_status' => 'pending', 'due_date' => now()->subDays(5)]);
        $this->actingAsTenantUser($tenant);

        $this->getJson("/api/v1/debts/{$debt->id}")->assertStatus(200)->assertJsonPath('data.debt_status', 'pending');

        $this->assertSame('pending', $debt->fresh()->debt_status);
    }

    // --- Timeline ---

    public function test_timeline_shows_debt_created_as_completed_and_the_rest_as_pending(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $this->actingAsTenantUser($tenant);
        $debtId = $this->postJson("/api/v1/customers/{$customer->id}/debts", [
            'amount' => 100, 'due_date' => now()->addDays(10)->toDateString(),
        ])->json('data.debt.id');

        $response = $this->getJson("/api/v1/debts/{$debtId}/timeline");

        $stages = collect($response->json('data.stages'));
        $this->assertSame('completed', $stages->firstWhere('event', 'debt_created')['status']);
        $this->assertSame('pending', $stages->firstWhere('event', 'payment')['status']);
        $this->assertSame('pending', $stages->firstWhere('event', 'recovered')['status']);
    }

    // --- Recovery Stage ---

    public function test_recovery_stage_can_be_overridden_with_a_reason(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create();
        $this->actingAsTenantUser($tenant);

        $response = $this->patchJson("/api/v1/debts/{$debt->id}/recovery-stage", [
            'recovery_stage' => 4,
            'reason' => 'Customer requested manual escalation',
        ]);

        $response->assertStatus(200)->assertJsonPath('data.recovery_stage', 4);
        $this->assertDatabaseHas('audit_log', [
            'entity_id' => $debt->id,
            'action' => 'recovery_stage_override',
            'reason' => 'Customer requested manual escalation',
        ]);
    }

    public function test_recovery_stage_override_requires_a_reason(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create();
        $this->actingAsTenantUser($tenant);

        $this->patchJson("/api/v1/debts/{$debt->id}/recovery-stage", ['recovery_stage' => 4])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['reason']);
    }

    // --- Authentication / Authorization ---

    public function test_unauthenticated_requests_are_rejected(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create();

        $this->getJson('/api/v1/debts')->assertStatus(401);
        $this->getJson("/api/v1/debts/{$debt->id}")->assertStatus(401);
    }

    public function test_user_without_admin_role_cannot_manage_debts(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $this->actingAsTenantUser($tenant, null);

        $this->postJson("/api/v1/customers/{$customer->id}/debts", [
            'amount' => 100, 'due_date' => now()->addDays(10)->toDateString(),
        ])->assertStatus(403);

        $this->getJson('/api/v1/debts')->assertStatus(403);
    }
}
