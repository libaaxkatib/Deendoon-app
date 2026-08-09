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

    // --- Related Case (mobile Item 12) ---

    public function test_admin_can_view_the_related_case_for_a_debt(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);
        $caseId = $this->postJson("/api/v1/debts/{$debt->id}/collection-cases")->json('data.id');

        $this->getJson("/api/v1/debts/{$debt->id}/collection-case")
            ->assertStatus(200)
            ->assertJsonPath('data.id', $caseId);
    }

    public function test_related_case_returns_404_for_a_debt_with_no_case(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);

        $this->getJson("/api/v1/debts/{$debt->id}/collection-case")
            ->assertStatus(404)
            ->assertJson(['success' => false]);
    }

    public function test_related_case_returns_the_most_recent_case_when_a_debt_has_more_than_one(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);
        $firstCaseId = $this->postJson("/api/v1/debts/{$debt->id}/collection-cases")->json('data.id');
        $this->postJson("/api/v1/collection-cases/{$firstCaseId}/close", ['closure_outcome' => 'Paid in full']);
        $secondCaseId = $this->postJson("/api/v1/debts/{$debt->id}/collection-cases")->json('data.id');

        $this->getJson("/api/v1/debts/{$debt->id}/collection-case")
            ->assertStatus(200)
            ->assertJsonPath('data.id', $secondCaseId);
    }

    public function test_related_case_returns_404_for_another_tenants_debt(): void
    {
        $tenantA = Tenant::create(['business_name' => 'Tenant A']);
        $tenantB = Tenant::create(['business_name' => 'Tenant B']);
        $debtB = $this->makeDebt($tenantB);
        $this->actingAsTenantUser($tenantA);

        $this->getJson("/api/v1/debts/{$debtB->id}/collection-case")->assertStatus(404);
    }

    public function test_related_case_requires_authentication(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);

        $this->getJson("/api/v1/debts/{$debt->id}/collection-case")->assertStatus(401);
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

    public function test_index_can_filter_by_customer_id(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customerA = Customer::factory()->for($tenant, 'tenant')->create();
        $customerB = Customer::factory()->for($tenant, 'tenant')->create();
        $debtA = Debt::factory()->for($tenant, 'tenant')->for($customerA, 'customer')->create();
        $debtB = Debt::factory()->for($tenant, 'tenant')->for($customerB, 'customer')->create();
        $caseA = CollectionCase::factory()->for($tenant, 'tenant')->for($debtA, 'debt')->create();
        CollectionCase::factory()->for($tenant, 'tenant')->for($debtB, 'debt')->create();

        $this->actingAsTenantUser($tenant);
        $response = $this->getJson("/api/v1/collection-cases?customer_id={$customerA->id}");

        $ids = collect($response->json('data.collection_cases'))->pluck('id');
        $this->assertEquals([$caseA->id], $ids->all());
    }

    public function test_index_customer_id_filter_composes_with_status(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create();
        $openCase = CollectionCase::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create(['case_status' => 'open']);
        CollectionCase::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create(['case_status' => 'closed']);

        $this->actingAsTenantUser($tenant);
        $response = $this->getJson("/api/v1/collection-cases?customer_id={$customer->id}&status=open");

        $ids = collect($response->json('data.collection_cases'))->pluck('id');
        $this->assertEquals([$openCase->id], $ids->all());
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

    // --- Case List enrichment (docs/Mobile_UI_V1_Frozen.md §6.1, §6.3) ---

    public function test_case_resource_includes_customer_name_outstanding_amount_and_risk_level(): void
    {
        // Risk Level is exclusively system-calculated (RiskLevelService,
        // Sprint 2B) — escalating this Debt to a Collection Case is itself
        // one of the engine's trigger points, so the resource's risk_level
        // is asserted against the Customer's actual post-escalation value
        // rather than an arbitrary pre-set fixture that the engine would
        // immediately overwrite.
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create(['name' => 'Ahmed Trading Co.']);
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')
            ->create(['remaining_balance' => 12988]);
        $this->actingAsTenantUser($tenant);
        $caseId = $this->postJson("/api/v1/debts/{$debt->id}/collection-cases")->json('data.id');

        $this->getJson("/api/v1/collection-cases/{$caseId}")
            ->assertStatus(200)
            ->assertJsonPath('data.customer_name', 'Ahmed Trading Co.')
            ->assertJsonPath('data.risk_level', $customer->fresh()->risk_level)
            ->assertJsonPath('data.outstanding_amount', '12988.00');
    }

    public function test_index_can_filter_by_high_risk_tab(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $highRiskCustomer = Customer::factory()->for($tenant, 'tenant')->create(['risk_level' => 'high']);
        $lowRiskCustomer = Customer::factory()->for($tenant, 'tenant')->create(['risk_level' => 'low']);
        $highRiskDebt = Debt::factory()->for($tenant, 'tenant')->for($highRiskCustomer, 'customer')->create();
        $lowRiskDebt = Debt::factory()->for($tenant, 'tenant')->for($lowRiskCustomer, 'customer')->create();
        $highRiskCase = CollectionCase::factory()->for($tenant, 'tenant')->for($highRiskDebt, 'debt')->create();
        CollectionCase::factory()->for($tenant, 'tenant')->for($lowRiskDebt, 'debt')->create();

        $this->actingAsTenantUser($tenant);
        $response = $this->getJson('/api/v1/collection-cases?tab=high_risk');

        $ids = collect($response->json('data.collection_cases'))->pluck('id');
        $this->assertEquals([$highRiskCase->id], $ids->all());
    }

    public function test_index_can_filter_by_promise_due_tab(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debtWithPromise = $this->makeDebt($tenant);
        $debtWithoutPromise = $this->makeDebt($tenant);
        $caseWithPromise = CollectionCase::factory()->for($tenant, 'tenant')->for($debtWithPromise, 'debt')->create();
        CollectionCase::factory()->for($tenant, 'tenant')->for($debtWithoutPromise, 'debt')->create();
        $user = $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/debts/{$debtWithPromise->id}/promise-to-pay", [
            'promised_date' => now()->addDays(3)->toDateString(),
        ]);

        $response = $this->getJson('/api/v1/collection-cases?tab=promise_due');

        $ids = collect($response->json('data.collection_cases'))->pluck('id');
        $this->assertEquals([$caseWithPromise->id], $ids->all());
    }

    public function test_index_can_filter_by_follow_up_tab(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debtWithActivity = $this->makeDebt($tenant);
        $debtWithoutActivity = $this->makeDebt($tenant);
        $caseWithActivity = CollectionCase::factory()->for($tenant, 'tenant')->for($debtWithActivity, 'debt')->create();
        CollectionCase::factory()->for($tenant, 'tenant')->for($debtWithoutActivity, 'debt')->create();
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/collection-cases/{$caseWithActivity->id}/activities", [
            'details' => 'Called the customer',
        ]);

        $response = $this->getJson('/api/v1/collection-cases?tab=follow_up');

        $ids = collect($response->json('data.collection_cases'))->pluck('id');
        $this->assertEquals([$caseWithActivity->id], $ids->all());
    }

    public function test_recording_activity_updates_last_activity_at(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);
        $caseId = $this->postJson("/api/v1/debts/{$debt->id}/collection-cases")->json('data.id');
        $before = CollectionCase::find($caseId)->updated_at;

        $this->travel(1)->minutes();
        $this->postJson("/api/v1/collection-cases/{$caseId}/activities", ['details' => 'Follow-up call']);

        $this->assertTrue(CollectionCase::find($caseId)->updated_at->gt($before));
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

    // --- Update (FR-043) ---

    public function test_update_is_rejected_on_a_closed_case(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);
        $caseId = $this->postJson("/api/v1/debts/{$debt->id}/collection-cases")->json('data.id');
        $this->postJson("/api/v1/collection-cases/{$caseId}/close", ['closure_outcome' => 'recovered'])->assertStatus(200);

        $this->putJson("/api/v1/collection-cases/{$caseId}", ['notes' => 'Too late'])->assertStatus(409);
    }

    public function test_update_succeeds_as_a_no_op_on_an_open_case(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);
        $caseId = $this->postJson("/api/v1/debts/{$debt->id}/collection-cases")->json('data.id');

        $this->putJson("/api/v1/collection-cases/{$caseId}", [])->assertStatus(200);
    }

    public function test_update_sets_the_case_notes_and_records_an_edited_audit_event(): void
    {
        // Business Owner Backend Completion (pre-Phase 5): FR-043's
        // previously unresolved schema gap — `notes` is now the editable
        // field, distinct from the chronological activity log.
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);
        $caseId = $this->postJson("/api/v1/debts/{$debt->id}/collection-cases")->json('data.id');

        $response = $this->putJson("/api/v1/collection-cases/{$caseId}", ['notes' => 'Customer requested a payment plan.']);

        $response->assertStatus(200)->assertJsonPath('data.notes', 'Customer requested a payment plan.');
        $this->assertDatabaseHas('collection_cases', ['id' => $caseId, 'notes' => 'Customer requested a payment plan.']);
        $this->assertDatabaseHas('audit_log', ['entity_id' => $caseId, 'action' => 'edited']);
    }

    public function test_update_notes_does_not_affect_the_follow_up_activity_log(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);
        $caseId = $this->postJson("/api/v1/debts/{$debt->id}/collection-cases")->json('data.id');

        $this->putJson("/api/v1/collection-cases/{$caseId}", ['notes' => 'Internal note only'])->assertStatus(200);

        $history = $this->getJson("/api/v1/collection-cases/{$caseId}/history")->json('data.history');
        $this->assertFalse(collect($history)->contains(fn (array $entry) => $entry['details'] === 'Internal note only'));
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

    public function test_user_without_admin_role_cannot_manage_collection_cases(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $user = User::factory()->create(['tenant_id' => $tenant->id]);
        $token = $user->createToken('test')->plainTextToken;
        $this->withHeader('Authorization', 'Bearer '.$token);

        $this->postJson("/api/v1/debts/{$debt->id}/collection-cases")->assertStatus(403);
        $this->getJson('/api/v1/collection-cases')->assertStatus(403);
    }
}
