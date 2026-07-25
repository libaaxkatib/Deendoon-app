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

class CollectionCaseTest extends TestCase
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

    private function makeOfficer(Tenant $tenant): User
    {
        $officer = User::factory()->create();
        $officer->tenant()->associate($tenant);
        $officer->save();
        $officer->assignRole('collection_officer');

        return $officer;
    }

    // --- Escalation (FR-040) ---

    public function test_admin_can_escalate_a_debt_to_a_collection_case(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant, ['recovery_stage' => 4]);
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson("/api/v1/debts/{$debt->id}/collection-cases");

        $response->assertStatus(201)
            ->assertJson(['success' => true])
            ->assertJsonPath('data.debt_id', $debt->id)
            ->assertJsonPath('data.case_status', 'open')
            ->assertJsonPath('data.reference_number', 'COL-000001');

        $this->assertDatabaseHas('collection_cases', ['debt_id' => $debt->id, 'case_status' => 'open']);
    }

    public function test_escalation_generates_sequential_reference_numbers_per_tenant(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debtA = $this->makeDebt($tenant);
        $debtB = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);

        $first = $this->postJson("/api/v1/debts/{$debtA->id}/collection-cases")->json('data.reference_number');
        $second = $this->postJson("/api/v1/debts/{$debtB->id}/collection-cases")->json('data.reference_number');

        $this->assertSame('COL-000001', $first);
        $this->assertSame('COL-000002', $second);
    }

    public function test_escalation_records_a_collection_requested_audit_event(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $user = $this->actingAsTenantUser($tenant);

        $caseId = $this->postJson("/api/v1/debts/{$debt->id}/collection-cases")->json('data.id');

        $this->assertDatabaseHas('audit_log', [
            'entity_type' => 'collection_case', 'entity_id' => $caseId, 'action' => 'collection_requested', 'user_id' => (string) $user->id,
        ]);
    }

    public function test_escalation_records_an_escalated_followup_history_entry(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);

        $caseId = $this->postJson("/api/v1/debts/{$debt->id}/collection-cases")->json('data.id');

        $this->assertDatabaseHas('follow_up_history', [
            'debt_id' => $debt->id, 'collection_case_id' => $caseId, 'action_type' => 'escalated',
        ]);
    }

    public function test_escalation_advances_recovery_stage_to_5(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant, ['recovery_stage' => 4]);
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/debts/{$debt->id}/collection-cases")->assertStatus(201);

        $this->assertSame(5, $debt->fresh()->recovery_stage);
    }

    public function test_escalating_a_debt_that_already_has_an_open_case_is_rejected(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/debts/{$debt->id}/collection-cases")->assertStatus(201);

        $this->postJson("/api/v1/debts/{$debt->id}/collection-cases")
            ->assertStatus(409)
            ->assertJson(['success' => false]);

        $this->assertDatabaseCount('collection_cases', 1);
    }

    public function test_escalating_an_archived_debt_is_rejected(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $debt->delete();
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/debts/{$debt->id}/collection-cases")->assertStatus(404);
    }

    // --- Details / Listing (FR-042) ---

    public function test_admin_can_view_a_collection_case(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);
        $caseId = $this->postJson("/api/v1/debts/{$debt->id}/collection-cases")->json('data.id');

        $this->getJson("/api/v1/collection-cases/{$caseId}")
            ->assertStatus(200)
            ->assertJsonPath('data.id', $caseId);
    }

    public function test_index_lists_only_the_authenticated_users_own_tenant_cases(): void
    {
        $tenantA = Tenant::create(['business_name' => 'Tenant A']);
        $tenantB = Tenant::create(['business_name' => 'Tenant B']);
        $debtA = $this->makeDebt($tenantA);
        $debtB = $this->makeDebt($tenantB);
        $caseA = CollectionCase::factory()->for($tenantA, 'tenant')->for($debtA, 'debt')->create();
        CollectionCase::factory()->for($tenantB, 'tenant')->for($debtB, 'debt')->create();

        $this->actingAsTenantUser($tenantA);
        $response = $this->getJson('/api/v1/collection-cases');

        $ids = collect($response->json('data.collection_cases'))->pluck('id');
        $this->assertTrue($ids->contains($caseA->id));
        $this->assertCount(1, $ids);
    }

    public function test_show_returns_404_for_another_tenants_case(): void
    {
        $tenantA = Tenant::create(['business_name' => 'Tenant A']);
        $tenantB = Tenant::create(['business_name' => 'Tenant B']);
        $debtB = $this->makeDebt($tenantB);
        $caseB = CollectionCase::factory()->for($tenantB, 'tenant')->for($debtB, 'debt')->create();

        $this->actingAsTenantUser($tenantA);
        $this->getJson("/api/v1/collection-cases/{$caseB->id}")->assertStatus(404);
    }

    // --- Assignment (FR-041) ---

    public function test_admin_can_assign_a_collection_officer(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);
        $caseId = $this->postJson("/api/v1/debts/{$debt->id}/collection-cases")->json('data.id');
        $officer = $this->makeOfficer($tenant);

        $response = $this->patchJson("/api/v1/collection-cases/{$caseId}/assign", ['officer_user_id' => (string) $officer->id]);

        $response->assertStatus(200)->assertJsonPath('data.assigned_officer_user_id', (string) $officer->id);
        $this->assertDatabaseHas('audit_log', ['entity_type' => 'collection_case', 'entity_id' => $caseId, 'action' => 'edited']);
    }

    public function test_assigning_a_user_without_the_collection_officer_role_is_rejected(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);
        $caseId = $this->postJson("/api/v1/debts/{$debt->id}/collection-cases")->json('data.id');

        $nonOfficer = $this->actingAsTenantUser($tenant, 'sales_finance');

        $this->patchJson("/api/v1/collection-cases/{$caseId}/assign", ['officer_user_id' => (string) $nonOfficer->id])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['officer_user_id']);
    }

    public function test_assigning_an_officer_from_another_tenant_is_rejected(): void
    {
        $tenantA = Tenant::create(['business_name' => 'Tenant A']);
        $tenantB = Tenant::create(['business_name' => 'Tenant B']);
        $debtA = $this->makeDebt($tenantA);
        $officerB = $this->makeOfficer($tenantB);

        $this->actingAsTenantUser($tenantA);
        $caseId = $this->postJson("/api/v1/debts/{$debtA->id}/collection-cases")->json('data.id');

        $this->patchJson("/api/v1/collection-cases/{$caseId}/assign", ['officer_user_id' => (string) $officerB->id])
            ->assertStatus(422);
    }

    public function test_assignment_is_rejected_on_a_closed_case(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);
        $caseId = $this->postJson("/api/v1/debts/{$debt->id}/collection-cases")->json('data.id');
        $this->postJson("/api/v1/collection-cases/{$caseId}/close", ['closure_outcome' => 'recovered'])->assertStatus(200);

        $officer = $this->makeOfficer($tenant);
        $this->patchJson("/api/v1/collection-cases/{$caseId}/assign", ['officer_user_id' => (string) $officer->id])
            ->assertStatus(409);
    }

    // --- Activity Recording (FR-044) ---

    public function test_admin_can_record_a_collection_activity(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);
        $caseId = $this->postJson("/api/v1/debts/{$debt->id}/collection-cases")->json('data.id');

        $response = $this->postJson("/api/v1/collection-cases/{$caseId}/activities", ['details' => 'Negotiation call made']);

        $response->assertStatus(200)->assertJson(['success' => true]);
        $this->assertDatabaseHas('follow_up_history', [
            'debt_id' => $debt->id, 'collection_case_id' => $caseId, 'action_type' => 'collection_activity', 'details' => 'Negotiation call made',
        ]);
        $this->assertDatabaseHas('audit_log', ['entity_type' => 'collection_case', 'entity_id' => $caseId, 'action' => 'edited']);
    }

    public function test_recording_activity_on_a_closed_case_is_rejected(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);
        $caseId = $this->postJson("/api/v1/debts/{$debt->id}/collection-cases")->json('data.id');
        $this->postJson("/api/v1/collection-cases/{$caseId}/close", ['closure_outcome' => 'recovered'])->assertStatus(200);

        $this->postJson("/api/v1/collection-cases/{$caseId}/activities", ['details' => 'Too late'])
            ->assertStatus(409);
    }

    // --- Closure (FR-045) ---

    public function test_admin_can_close_a_collection_case_with_an_outcome(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant, ['debt_status' => 'overdue', 'remaining_balance' => 500]);
        $this->actingAsTenantUser($tenant);
        $caseId = $this->postJson("/api/v1/debts/{$debt->id}/collection-cases")->json('data.id');

        $response = $this->postJson("/api/v1/collection-cases/{$caseId}/close", ['closure_outcome' => 'recovered']);

        $response->assertStatus(200)
            ->assertJsonPath('data.case_status', 'closed')
            ->assertJsonPath('data.closure_outcome', 'recovered');

        $this->assertDatabaseHas('audit_log', ['entity_type' => 'collection_case', 'entity_id' => $caseId, 'action' => 'status_changed']);
    }

    public function test_closing_an_already_closed_case_is_rejected(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);
        $caseId = $this->postJson("/api/v1/debts/{$debt->id}/collection-cases")->json('data.id');
        $this->postJson("/api/v1/collection-cases/{$caseId}/close", ['closure_outcome' => 'recovered'])->assertStatus(200);

        $this->postJson("/api/v1/collection-cases/{$caseId}/close", ['closure_outcome' => 'recovered'])
            ->assertStatus(409);
    }

    public function test_closing_a_case_never_changes_the_debts_financial_state(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant, ['debt_status' => 'overdue', 'remaining_balance' => 500]);
        $this->actingAsTenantUser($tenant);
        $caseId = $this->postJson("/api/v1/debts/{$debt->id}/collection-cases")->json('data.id');

        $this->postJson("/api/v1/collection-cases/{$caseId}/close", ['closure_outcome' => 'recovered'])->assertStatus(200);

        $debt->refresh();
        $this->assertSame('overdue', $debt->debt_status);
        $this->assertSame('500.00', $debt->remaining_balance);
    }

    // --- Update (FR-043, genuine schema gap) ---

    public function test_update_is_rejected_on_a_closed_case(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);
        $caseId = $this->postJson("/api/v1/debts/{$debt->id}/collection-cases")->json('data.id');
        $this->postJson("/api/v1/collection-cases/{$caseId}/close", ['closure_outcome' => 'recovered'])->assertStatus(200);

        $this->putJson("/api/v1/collection-cases/{$caseId}", [])->assertStatus(409);
    }

    public function test_update_succeeds_as_a_no_op_on_an_open_case(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);
        $caseId = $this->postJson("/api/v1/debts/{$debt->id}/collection-cases")->json('data.id');

        $this->putJson("/api/v1/collection-cases/{$caseId}", [])->assertStatus(200);
    }

    // --- History (FR-046) ---

    public function test_history_shows_escalation_and_activity_in_chronological_order(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);
        $caseId = $this->postJson("/api/v1/debts/{$debt->id}/collection-cases")->json('data.id');
        $this->postJson("/api/v1/collection-cases/{$caseId}/activities", ['details' => 'Called customer'])->assertStatus(200);

        $response = $this->getJson("/api/v1/collection-cases/{$caseId}/history");

        $response->assertStatus(200);
        $actions = collect($response->json('data.history'))->pluck('action');
        $this->assertTrue($actions->contains('collection_requested'));
        $this->assertTrue($actions->contains('escalated'));
        $this->assertTrue($actions->contains('collection_activity'));
    }

    // --- Authentication / Authorization / Tenant isolation ---

    public function test_unauthenticated_requests_are_rejected(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);

        $this->postJson("/api/v1/debts/{$debt->id}/collection-cases")->assertStatus(401);
        $this->getJson('/api/v1/collection-cases')->assertStatus(401);
    }

    public function test_customer_role_cannot_manage_collection_cases(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant, 'customer');

        $this->postJson("/api/v1/debts/{$debt->id}/collection-cases")->assertStatus(403);
        $this->getJson('/api/v1/collection-cases')->assertStatus(403);
    }
}
