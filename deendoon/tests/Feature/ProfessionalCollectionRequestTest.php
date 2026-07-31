<?php

namespace Tests\Feature;

use App\Models\CollectionCase;
use App\Models\Customer;
use App\Models\Debt;
use App\Models\Tenant;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * Uses Sanctum::actingAs() rather than the manual Bearer-token pattern used
 * throughout the rest of this suite: this module is the first to need a
 * genuine mid-test identity switch (tenant submits, Platform Administrator
 * reviews, within the same test). Sanctum's guard caches its resolved user
 * once per test; a second manually-issued token's header is never
 * re-resolved, silently keeping the first identity active. actingAs()
 * explicitly overwrites the guard's cached user instead of relying on
 * header re-resolution.
 */
class ProfessionalCollectionRequestTest extends TestCase
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

        Sanctum::actingAs($user, ['*']);

        return $user;
    }

    private function actingAsPlatformAdmin(): User
    {
        $admin = User::factory()->create();
        $admin->assignRole('deendoon_platform_administrator');

        Sanctum::actingAs($admin, ['*']);

        return $admin;
    }

    private function makeOpenCase(Tenant $tenant): array
    {
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create();
        $this->actingAsTenantUser($tenant);
        $caseId = $this->postJson("/api/v1/debts/{$debt->id}/collection-cases")->json('data.id');

        return [$caseId, $debt];
    }

    // --- Submission (FR-072) ---

    public function test_admin_can_submit_an_open_case_to_deendoon(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        [$caseId] = $this->makeOpenCase($tenant);
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson("/api/v1/collection-cases/{$caseId}/professional-requests");

        $response->assertStatus(201)
            ->assertJsonPath('data.collection_case_id', $caseId)
            ->assertJsonPath('data.status', 'submitted')
            ->assertJsonPath('data.reference_number', 'PCR-000001');
    }

    public function test_submission_records_a_professional_collection_request_submitted_audit_event(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        [$caseId] = $this->makeOpenCase($tenant);
        $user = $this->actingAsTenantUser($tenant);

        $pcrId = $this->postJson("/api/v1/collection-cases/{$caseId}/professional-requests")->json('data.id');

        $this->assertDatabaseHas('audit_log', [
            'entity_type' => 'professional_collection_request',
            'entity_id' => $pcrId,
            'action' => 'professional_collection_request_submitted',
            'tenant_id' => $tenant->id,
            'user_id' => (string) $user->id,
        ]);
    }

    public function test_submitting_a_closed_case_is_rejected(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        [$caseId] = $this->makeOpenCase($tenant);
        $this->actingAsTenantUser($tenant);
        $this->postJson("/api/v1/collection-cases/{$caseId}/close", ['closure_outcome' => 'recovered'])->assertStatus(200);

        $this->postJson("/api/v1/collection-cases/{$caseId}/professional-requests")->assertStatus(409);
    }

    public function test_submitting_a_case_with_an_existing_active_request_is_rejected(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        [$caseId] = $this->makeOpenCase($tenant);
        $this->actingAsTenantUser($tenant);
        $this->postJson("/api/v1/collection-cases/{$caseId}/professional-requests")->assertStatus(201);

        $this->postJson("/api/v1/collection-cases/{$caseId}/professional-requests")->assertStatus(409);
    }

    // --- Visibility (FR-073, FR-074) ---

    public function test_tenant_user_can_view_their_own_request(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        [$caseId] = $this->makeOpenCase($tenant);
        $this->actingAsTenantUser($tenant);
        $pcrId = $this->postJson("/api/v1/collection-cases/{$caseId}/professional-requests")->json('data.id');

        $this->getJson("/api/v1/professional-requests/{$pcrId}")->assertStatus(200);
    }

    public function test_tenant_user_cannot_view_another_tenants_request(): void
    {
        $tenantA = Tenant::create(['business_name' => 'Tenant A']);
        $tenantB = Tenant::create(['business_name' => 'Tenant B']);
        [$caseIdB] = $this->makeOpenCase($tenantB);
        $this->actingAsTenantUser($tenantB);
        $pcrId = $this->postJson("/api/v1/collection-cases/{$caseIdB}/professional-requests")->json('data.id');

        $this->actingAsTenantUser($tenantA);
        $this->getJson("/api/v1/professional-requests/{$pcrId}")->assertStatus(404);
    }

    public function test_platform_admin_can_view_any_tenants_request(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        [$caseId] = $this->makeOpenCase($tenant);
        $this->actingAsTenantUser($tenant);
        $pcrId = $this->postJson("/api/v1/collection-cases/{$caseId}/professional-requests")->json('data.id');

        $this->actingAsPlatformAdmin();
        $this->getJson("/api/v1/professional-requests/{$pcrId}")->assertStatus(200);
    }

    public function test_index_is_tenant_filtered_for_tenant_sessions_and_unfiltered_for_platform_admin(): void
    {
        $tenantA = Tenant::create(['business_name' => 'Tenant A']);
        $tenantB = Tenant::create(['business_name' => 'Tenant B']);
        [$caseIdA] = $this->makeOpenCase($tenantA);
        $this->actingAsTenantUser($tenantA);
        $this->postJson("/api/v1/collection-cases/{$caseIdA}/professional-requests")->assertStatus(201);

        [$caseIdB] = $this->makeOpenCase($tenantB);
        $this->actingAsTenantUser($tenantB);
        $this->postJson("/api/v1/collection-cases/{$caseIdB}/professional-requests")->assertStatus(201);

        $this->actingAsTenantUser($tenantA);
        $tenantView = $this->getJson('/api/v1/professional-requests');
        $this->assertCount(1, $tenantView->json('data.professional_requests'));

        $this->actingAsPlatformAdmin();
        $adminView = $this->getJson('/api/v1/professional-requests');
        $this->assertCount(2, $adminView->json('data.professional_requests'));
    }

    // --- Status Transitions (FR-073) ---

    public function test_platform_admin_can_transition_status_through_the_approved_sequence(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        [$caseId] = $this->makeOpenCase($tenant);
        $this->actingAsTenantUser($tenant);
        $pcrId = $this->postJson("/api/v1/collection-cases/{$caseId}/professional-requests")->json('data.id');

        $this->actingAsPlatformAdmin();
        $this->patchJson("/api/v1/professional-requests/{$pcrId}/status", ['status' => 'under_review'])
            ->assertStatus(200)->assertJsonPath('data.status', 'under_review');
        $this->patchJson("/api/v1/professional-requests/{$pcrId}/status", ['status' => 'accepted'])
            ->assertStatus(200)->assertJsonPath('data.status', 'accepted');
        $this->patchJson("/api/v1/professional-requests/{$pcrId}/status", ['status' => 'assigned'])
            ->assertStatus(200)->assertJsonPath('data.status', 'assigned');
        $this->patchJson("/api/v1/professional-requests/{$pcrId}/status", ['status' => 'in_progress'])
            ->assertStatus(200)->assertJsonPath('data.status', 'in_progress');
    }

    public function test_need_more_information_cycles_back_to_under_review(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        [$caseId] = $this->makeOpenCase($tenant);
        $this->actingAsTenantUser($tenant);
        $pcrId = $this->postJson("/api/v1/collection-cases/{$caseId}/professional-requests")->json('data.id');

        $this->actingAsPlatformAdmin();
        $this->patchJson("/api/v1/professional-requests/{$pcrId}/status", ['status' => 'under_review'])->assertStatus(200);
        $this->patchJson("/api/v1/professional-requests/{$pcrId}/status", ['status' => 'need_more_information'])
            ->assertStatus(200)->assertJsonPath('data.status', 'need_more_information');
        $this->patchJson("/api/v1/professional-requests/{$pcrId}/status", ['status' => 'under_review'])
            ->assertStatus(200)->assertJsonPath('data.status', 'under_review');
    }

    public function test_an_invalid_status_transition_is_rejected(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        [$caseId] = $this->makeOpenCase($tenant);
        $this->actingAsTenantUser($tenant);
        $pcrId = $this->postJson("/api/v1/collection-cases/{$caseId}/professional-requests")->json('data.id');

        $this->actingAsPlatformAdmin();
        $this->patchJson("/api/v1/professional-requests/{$pcrId}/status", ['status' => 'assigned'])
            ->assertStatus(409);
    }

    public function test_transitioning_to_recovered_via_the_status_endpoint_is_rejected(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        [$caseId] = $this->makeOpenCase($tenant);
        $this->actingAsTenantUser($tenant);
        $pcrId = $this->postJson("/api/v1/collection-cases/{$caseId}/professional-requests")->json('data.id');

        $this->actingAsPlatformAdmin();
        $this->patchJson("/api/v1/professional-requests/{$pcrId}/status", ['status' => 'recovered'])
            ->assertStatus(409);
    }

    public function test_a_tenant_user_cannot_transition_status_even_on_their_own_request(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        [$caseId] = $this->makeOpenCase($tenant);
        $this->actingAsTenantUser($tenant);
        $pcrId = $this->postJson("/api/v1/collection-cases/{$caseId}/professional-requests")->json('data.id');

        $this->patchJson("/api/v1/professional-requests/{$pcrId}/status", ['status' => 'under_review'])
            ->assertStatus(403);
    }

    // --- Closure (FR-076) ---

    public function test_platform_admin_can_close_a_request_with_an_outcome(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        [$caseId] = $this->makeOpenCase($tenant);
        $this->actingAsTenantUser($tenant);
        $pcrId = $this->postJson("/api/v1/collection-cases/{$caseId}/professional-requests")->json('data.id');

        $this->actingAsPlatformAdmin();
        $response = $this->postJson("/api/v1/professional-requests/{$pcrId}/close", ['outcome' => 'recovered']);

        $response->assertStatus(200)->assertJsonPath('data.status', 'recovered');
        $this->assertDatabaseHas('audit_log', [
            'entity_type' => 'professional_collection_request', 'entity_id' => $pcrId, 'action' => 'professional_collection_request_status_changed', 'tenant_id' => $tenant->id,
        ]);
    }

    public function test_closing_an_already_closed_request_is_rejected(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        [$caseId] = $this->makeOpenCase($tenant);
        $this->actingAsTenantUser($tenant);
        $pcrId = $this->postJson("/api/v1/collection-cases/{$caseId}/professional-requests")->json('data.id');

        $this->actingAsPlatformAdmin();
        $this->postJson("/api/v1/professional-requests/{$pcrId}/close", ['outcome' => 'closed'])->assertStatus(200);

        $this->postJson("/api/v1/professional-requests/{$pcrId}/close", ['outcome' => 'recovered'])->assertStatus(409);
    }

    public function test_a_tenant_user_cannot_close_a_request(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        [$caseId] = $this->makeOpenCase($tenant);
        $this->actingAsTenantUser($tenant);
        $pcrId = $this->postJson("/api/v1/collection-cases/{$caseId}/professional-requests")->json('data.id');

        $this->postJson("/api/v1/professional-requests/{$pcrId}/close", ['outcome' => 'recovered'])
            ->assertStatus(403);
    }

    // --- Conversation (FR-075) ---

    public function test_either_party_can_post_and_read_messages(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        [$caseId] = $this->makeOpenCase($tenant);
        $tenantUser = $this->actingAsTenantUser($tenant);
        $pcrId = $this->postJson("/api/v1/collection-cases/{$caseId}/professional-requests")->json('data.id');

        $this->postJson("/api/v1/professional-requests/{$pcrId}/messages", ['content' => 'Please review our case.'])
            ->assertStatus(201)->assertJsonPath('data.sender_user_id', (string) $tenantUser->id);

        $admin = $this->actingAsPlatformAdmin();
        $this->postJson("/api/v1/professional-requests/{$pcrId}/messages", ['content' => 'Reviewing now.'])
            ->assertStatus(201)->assertJsonPath('data.sender_user_id', (string) $admin->id);

        $response = $this->getJson("/api/v1/professional-requests/{$pcrId}/messages");
        $response->assertStatus(200);
        $this->assertCount(2, $response->json('data'));
    }

    public function test_messaging_is_rejected_once_the_request_is_terminal(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        [$caseId] = $this->makeOpenCase($tenant);
        $this->actingAsTenantUser($tenant);
        $pcrId = $this->postJson("/api/v1/collection-cases/{$caseId}/professional-requests")->json('data.id');

        $this->actingAsPlatformAdmin();
        $this->postJson("/api/v1/professional-requests/{$pcrId}/close", ['outcome' => 'closed'])->assertStatus(200);

        $this->postJson("/api/v1/professional-requests/{$pcrId}/messages", ['content' => 'Too late'])
            ->assertStatus(409);
    }

    // --- Authentication / Authorization ---

    public function test_unauthenticated_requests_are_rejected(): void
    {
        // Deliberately built via factory, not makeOpenCase()/actingAsTenantUser()
        // — either would leave Sanctum's guard authenticated for the rest of
        // this test, defeating the point of testing unauthenticated access.
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create();
        $case = CollectionCase::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create();

        $this->postJson("/api/v1/collection-cases/{$case->id}/professional-requests")->assertStatus(401);
        $this->getJson('/api/v1/professional-requests')->assertStatus(401);
    }

    public function test_user_without_admin_role_cannot_submit_requests(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        [$caseId] = $this->makeOpenCase($tenant);
        $this->actingAsTenantUser($tenant, null);

        $this->postJson("/api/v1/collection-cases/{$caseId}/professional-requests")->assertStatus(403);
    }
}
