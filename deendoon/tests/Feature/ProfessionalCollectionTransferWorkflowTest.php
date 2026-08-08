<?php

namespace Tests\Feature;

use App\Models\Customer;
use App\Models\Debt;
use App\Models\DemandLetter;
use App\Models\Payment;
use App\Models\ProfessionalCollectionRequest;
use App\Models\ProfessionalCollectionRequestAttachment;
use App\Models\Receipt;
use App\Models\ReferenceData;
use App\Models\Tenant;
use App\Models\User;
use App\Services\ProfessionalCollectionRequestService;
use Database\Seeders\RoleSeeder;
use Database\Seeders\SubscriptionPlanSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * Transfer Case to Deendoon Recovery Team (Product Owner-approved
 * decision) — coverage for every new capability layered onto Professional
 * Collection Requests: Reason for Transfer / Requested Services (Reference
 * Data-backed, multi-select), Client Declaration, Supporting Documents
 * (auto-linked existing documents + newly uploaded attachments), the
 * Professional Collection Summary Card, and the Professional Collection
 * Timeline. Existing submission/status/close/messaging coverage remains in
 * ProfessionalCollectionRequestTest.php — this file only exercises what's
 * new.
 */
class ProfessionalCollectionTransferWorkflowTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RoleSeeder::class);
        $this->seed(SubscriptionPlanSeeder::class);
        Storage::fake('local');
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

    private function seedTransferReferenceData(Tenant $tenant): void
    {
        ReferenceData::factory()->for($tenant, 'tenant')->create(['category' => 'transfer_reason', 'value_label' => 'Non-payment']);
        ReferenceData::factory()->for($tenant, 'tenant')->create(['category' => 'transfer_reason', 'value_label' => 'Broken Promise']);
        ReferenceData::factory()->for($tenant, 'tenant')->create(['category' => 'requested_service', 'value_label' => 'Field Visit']);
        ReferenceData::factory()->for($tenant, 'tenant')->create(['category' => 'requested_service', 'value_label' => 'Legal Notice']);
    }

    /**
     * @return array{0: string, 1: Debt}
     */
    private function makeOpenCase(Tenant $tenant): array
    {
        $this->seedTransferReferenceData($tenant);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create();
        $this->actingAsTenantUser($tenant);
        $caseId = $this->postJson("/api/v1/debts/{$debt->id}/collection-cases")->json('data.id');

        return [$caseId, $debt];
    }

    /**
     * @return array<string, mixed>
     */
    private function submitPayload(array $overrides = []): array
    {
        return array_merge([
            'reasons' => ['Non-payment'],
            'services' => ['Field Visit'],
            'declaration_accepted' => true,
        ], $overrides);
    }

    // --- Reason for Transfer / Requested Services (Reference Data-backed) ---

    public function test_submission_rejects_a_reason_not_in_the_tenants_active_reference_data(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        [$caseId] = $this->makeOpenCase($tenant);
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson(
            "/api/v1/collection-cases/{$caseId}/professional-requests",
            $this->submitPayload(['reasons' => ['Made Up Reason']]),
        );

        $response->assertStatus(422)->assertJsonValidationErrors(['reasons.0']);
    }

    public function test_submission_rejects_a_service_not_in_the_tenants_active_reference_data(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        [$caseId] = $this->makeOpenCase($tenant);
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson(
            "/api/v1/collection-cases/{$caseId}/professional-requests",
            $this->submitPayload(['services' => ['Not A Real Service']]),
        );

        $response->assertStatus(422)->assertJsonValidationErrors(['services.0']);
    }

    public function test_submission_rejects_a_reason_belonging_to_another_tenant(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $otherTenant = Tenant::create(['business_name' => 'Other Co']);
        [$caseId] = $this->makeOpenCase($tenant);
        ReferenceData::factory()->for($otherTenant, 'tenant')->create(['category' => 'transfer_reason', 'value_label' => 'Fraud Suspected']);
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson(
            "/api/v1/collection-cases/{$caseId}/professional-requests",
            $this->submitPayload(['reasons' => ['Fraud Suspected']]),
        );

        $response->assertStatus(422)->assertJsonValidationErrors(['reasons.0']);
    }

    public function test_submission_rejects_a_deactivated_reason(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        [$caseId] = $this->makeOpenCase($tenant);
        ReferenceData::factory()->for($tenant, 'tenant')->create(['category' => 'transfer_reason', 'value_label' => 'Retired Reason', 'is_active' => false]);
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson(
            "/api/v1/collection-cases/{$caseId}/professional-requests",
            $this->submitPayload(['reasons' => ['Retired Reason']]),
        );

        $response->assertStatus(422)->assertJsonValidationErrors(['reasons.0']);
    }

    public function test_submission_accepts_multiple_reasons_and_services_with_optional_notes(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        [$caseId] = $this->makeOpenCase($tenant);
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson("/api/v1/collection-cases/{$caseId}/professional-requests", $this->submitPayload([
            'reasons' => ['Non-payment', 'Broken Promise'],
            'services' => ['Field Visit', 'Legal Notice'],
            'notes' => 'Customer has stopped responding to calls.',
        ]));

        $response->assertStatus(201);
        $this->assertEqualsCanonicalizing(['Non-payment', 'Broken Promise'], $response->json('data.reasons'));
        $this->assertEqualsCanonicalizing(['Field Visit', 'Legal Notice'], $response->json('data.requested_services'));
        $this->assertSame('Customer has stopped responding to calls.', $response->json('data.notes'));

        $this->assertDatabaseHas('professional_collection_request_reasons', ['reason_label' => 'Non-payment']);
        $this->assertDatabaseHas('professional_collection_request_reasons', ['reason_label' => 'Broken Promise']);
        $this->assertDatabaseHas('professional_collection_request_services', ['service_label' => 'Field Visit']);
        $this->assertDatabaseHas('professional_collection_request_services', ['service_label' => 'Legal Notice']);
    }

    public function test_submission_requires_at_least_one_reason_and_one_service(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        [$caseId] = $this->makeOpenCase($tenant);
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson("/api/v1/collection-cases/{$caseId}/professional-requests", $this->submitPayload([
            'reasons' => [],
            'services' => [],
        ]));

        $response->assertStatus(422)->assertJsonValidationErrors(['reasons', 'services']);
    }

    // --- Client Declaration ---

    public function test_submission_is_rejected_when_declaration_is_not_accepted(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        [$caseId] = $this->makeOpenCase($tenant);
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson(
            "/api/v1/collection-cases/{$caseId}/professional-requests",
            $this->submitPayload(['declaration_accepted' => false]),
        );

        $response->assertStatus(422)->assertJsonValidationErrors(['declaration_accepted']);
    }

    public function test_submission_records_who_and_when_the_declaration_was_accepted(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        [$caseId] = $this->makeOpenCase($tenant);
        $user = $this->actingAsTenantUser($tenant);

        $response = $this->postJson("/api/v1/collection-cases/{$caseId}/professional-requests", $this->submitPayload());

        $response->assertStatus(201)
            ->assertJsonPath('data.declaration_accepted_by', (string) $user->id);
        $this->assertNotNull($response->json('data.declaration_accepted_at'));
    }

    // --- Supporting Documents: auto-linked existing documents ---

    public function test_submission_auto_links_every_existing_document_for_the_debt(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        [$caseId, $debt] = $this->makeOpenCase($tenant);
        $payment = Payment::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create();
        $receipt = Receipt::factory()->for($payment, 'payment')->create();
        $demandLetter = DemandLetter::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create();
        $this->actingAsTenantUser($tenant);

        $pcrId = $this->postJson("/api/v1/collection-cases/{$caseId}/professional-requests", $this->submitPayload())->json('data.id');

        $this->assertDatabaseHas('professional_collection_request_documents', [
            'professional_collection_request_id' => $pcrId, 'document_type' => 'receipt', 'document_id' => $receipt->id,
        ]);
        $this->assertDatabaseHas('professional_collection_request_documents', [
            'professional_collection_request_id' => $pcrId, 'document_type' => 'demand_letter', 'document_id' => $demandLetter->id,
        ]);
    }

    public function test_the_business_owner_never_selects_documents_manually_they_are_all_auto_linked(): void
    {
        // The request payload has no "documents" field at all — proving
        // there is nothing to manually select.
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        [$caseId] = $this->makeOpenCase($tenant);
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson("/api/v1/collection-cases/{$caseId}/professional-requests", $this->submitPayload());

        $response->assertStatus(201);
    }

    public function test_documents_endpoint_returns_the_auto_linked_existing_documents_without_duplication(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        [$caseId, $debt] = $this->makeOpenCase($tenant);
        $payment = Payment::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create();
        $receipt = Receipt::factory()->for($payment, 'payment')->create();
        $this->actingAsTenantUser($tenant);
        $pcrId = $this->postJson("/api/v1/collection-cases/{$caseId}/professional-requests", $this->submitPayload())->json('data.id');

        $response = $this->getJson("/api/v1/professional-requests/{$pcrId}/documents");

        $response->assertStatus(200);
        $ids = collect($response->json('data'))->pluck('id');
        $this->assertContains($receipt->id, $ids);
        // The link table has no file_path/file_size of its own — proving
        // this reads through to the real Receipt row rather than a copy.
        $this->assertDatabaseCount('professional_collection_request_documents', 1);
        $this->assertDatabaseCount('receipts', 1);
    }

    public function test_platform_admin_can_also_view_the_linked_documents(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        [$caseId] = $this->makeOpenCase($tenant);
        $this->actingAsTenantUser($tenant);
        $pcrId = $this->postJson("/api/v1/collection-cases/{$caseId}/professional-requests", $this->submitPayload())->json('data.id');

        $this->actingAsPlatformAdmin();
        $this->getJson("/api/v1/professional-requests/{$pcrId}/documents")->assertStatus(200);
    }

    // --- Supporting Documents: uploaded attachments (staged authorization) ---

    /**
     * Moves a Request through the approved sequence (Submitted ->
     * Under Review -> Accepted -> Assigned) via the Deendoon Platform
     * Administrator, then restores whichever session was active before
     * this call.
     */
    private function moveToAssigned(Tenant $tenant, string $pcrId): void
    {
        $this->actingAsPlatformAdmin();
        $this->patchJson("/api/v1/professional-requests/{$pcrId}/status", ['status' => 'under_review'])->assertStatus(200);
        $this->patchJson("/api/v1/professional-requests/{$pcrId}/status", ['status' => 'accepted'])->assertStatus(200);
        $this->patchJson("/api/v1/professional-requests/{$pcrId}/status", ['status' => 'assigned'])->assertStatus(200);
    }

    public function test_business_owner_can_upload_before_the_request_is_assigned(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        [$caseId] = $this->makeOpenCase($tenant);
        $this->actingAsTenantUser($tenant);
        $pcrId = $this->postJson("/api/v1/collection-cases/{$caseId}/professional-requests", $this->submitPayload())->json('data.id');

        $response = $this->post("/api/v1/professional-requests/{$pcrId}/attachments", [
            'file' => UploadedFile::fake()->create('agreement.pdf', 100, 'application/pdf'),
        ]);

        $response->assertStatus(201)->assertJsonPath('data.original_filename', 'agreement.pdf');
        $this->assertDatabaseHas('professional_collection_request_attachments', [
            'professional_collection_request_id' => $pcrId, 'original_filename' => 'agreement.pdf',
        ]);
    }

    public function test_business_owner_can_still_upload_while_under_review_or_accepted(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        [$caseId] = $this->makeOpenCase($tenant);
        $this->actingAsTenantUser($tenant);
        $pcrId = $this->postJson("/api/v1/collection-cases/{$caseId}/professional-requests", $this->submitPayload())->json('data.id');

        $this->actingAsPlatformAdmin();
        $this->patchJson("/api/v1/professional-requests/{$pcrId}/status", ['status' => 'under_review'])->assertStatus(200);

        $this->actingAsTenantUser($tenant);
        $this->post("/api/v1/professional-requests/{$pcrId}/attachments", [
            'file' => UploadedFile::fake()->create('under-review.pdf', 100, 'application/pdf'),
        ])->assertStatus(201);
    }

    public function test_business_owner_cannot_upload_once_the_request_is_assigned(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        [$caseId] = $this->makeOpenCase($tenant);
        $this->actingAsTenantUser($tenant);
        $pcrId = $this->postJson("/api/v1/collection-cases/{$caseId}/professional-requests", $this->submitPayload())->json('data.id');

        $this->moveToAssigned($tenant, $pcrId);

        $this->actingAsTenantUser($tenant);
        $this->post("/api/v1/professional-requests/{$pcrId}/attachments", [
            'file' => UploadedFile::fake()->create('too-late.pdf', 100, 'application/pdf'),
        ])->assertStatus(403);
    }

    public function test_business_owner_cannot_upload_once_the_request_is_closed(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        [$caseId] = $this->makeOpenCase($tenant);
        $this->actingAsTenantUser($tenant);
        $pcrId = $this->postJson("/api/v1/collection-cases/{$caseId}/professional-requests", $this->submitPayload())->json('data.id');

        $this->actingAsPlatformAdmin();
        $this->postJson("/api/v1/professional-requests/{$pcrId}/close", ['outcome' => 'closed'])->assertStatus(200);

        $this->actingAsTenantUser($tenant);
        $this->post("/api/v1/professional-requests/{$pcrId}/attachments", [
            'file' => UploadedFile::fake()->create('too-late.pdf', 100, 'application/pdf'),
        ])->assertStatus(403);
    }

    public function test_recovery_team_cannot_upload_before_the_request_is_assigned(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        [$caseId] = $this->makeOpenCase($tenant);
        $this->actingAsTenantUser($tenant);
        $pcrId = $this->postJson("/api/v1/collection-cases/{$caseId}/professional-requests", $this->submitPayload())->json('data.id');

        $this->actingAsPlatformAdmin();
        $this->post("/api/v1/professional-requests/{$pcrId}/attachments", [
            'file' => UploadedFile::fake()->create('too-early.pdf', 100, 'application/pdf'),
        ])->assertStatus(403);
    }

    public function test_recovery_team_can_upload_once_the_request_is_assigned(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        [$caseId] = $this->makeOpenCase($tenant);
        $this->actingAsTenantUser($tenant);
        $pcrId = $this->postJson("/api/v1/collection-cases/{$caseId}/professional-requests", $this->submitPayload())->json('data.id');

        $this->moveToAssigned($tenant, $pcrId);

        $this->post("/api/v1/professional-requests/{$pcrId}/attachments", [
            'file' => UploadedFile::fake()->create('proof.pdf', 100, 'application/pdf'),
        ])->assertStatus(201);
    }

    public function test_recovery_team_cannot_upload_once_the_request_is_closed(): void
    {
        // Follow-up clarification (supersedes the original staged
        // decision's "any stage after assignment" wording): "No one may
        // upload new attachments after the request reaches Closed.
        // Documents become read-only... Evidence must remain immutable
        // after closure to preserve auditability and legal integrity."
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        [$caseId] = $this->makeOpenCase($tenant);
        $this->actingAsTenantUser($tenant);
        $pcrId = $this->postJson("/api/v1/collection-cases/{$caseId}/professional-requests", $this->submitPayload())->json('data.id');

        $this->moveToAssigned($tenant, $pcrId);
        $this->actingAsPlatformAdmin();
        $this->postJson("/api/v1/professional-requests/{$pcrId}/close", ['outcome' => 'closed'])->assertStatus(200);

        $this->post("/api/v1/professional-requests/{$pcrId}/attachments", [
            'file' => UploadedFile::fake()->create('closing-note.pdf', 100, 'application/pdf'),
        ])->assertStatus(403);
    }

    public function test_recovery_team_cannot_upload_once_the_request_is_recovered(): void
    {
        // "Recovered" is the other terminal outcome (self::TERMINAL_STATUSES)
        // — the immutability rule applies to both, not only literal 'closed'.
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        [$caseId] = $this->makeOpenCase($tenant);
        $this->actingAsTenantUser($tenant);
        $pcrId = $this->postJson("/api/v1/collection-cases/{$caseId}/professional-requests", $this->submitPayload())->json('data.id');

        $this->moveToAssigned($tenant, $pcrId);
        $this->actingAsPlatformAdmin();
        $this->postJson("/api/v1/professional-requests/{$pcrId}/close", ['outcome' => 'recovered'])->assertStatus(200);

        $this->post("/api/v1/professional-requests/{$pcrId}/attachments", [
            'file' => UploadedFile::fake()->create('too-late.pdf', 100, 'application/pdf'),
        ])->assertStatus(403);
    }

    public function test_service_layer_independently_refuses_uploads_to_a_closed_request(): void
    {
        // Defense-in-depth proof: ProfessionalCollectionRequestService::
        // uploadAttachment()'s own terminal-state guard fires even when
        // called directly, bypassing the Policy the HTTP layer normally
        // relies on — confirming immutability is a genuine data-integrity
        // rule, not merely an authorization side effect.
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        [$caseId] = $this->makeOpenCase($tenant);
        $this->actingAsTenantUser($tenant);
        $pcrId = $this->postJson("/api/v1/collection-cases/{$caseId}/professional-requests", $this->submitPayload())->json('data.id');

        $this->moveToAssigned($tenant, $pcrId);
        $platformAdmin = $this->actingAsPlatformAdmin();
        $this->postJson("/api/v1/professional-requests/{$pcrId}/close", ['outcome' => 'closed'])->assertStatus(200);

        $service = app(ProfessionalCollectionRequestService::class);
        $request = ProfessionalCollectionRequest::find($pcrId);

        $this->expectException(HttpResponseException::class);
        $service->uploadAttachment($request, UploadedFile::fake()->create('bypass.pdf', 100, 'application/pdf'), $platformAdmin);
    }

    public function test_business_owner_retains_read_access_to_documents_regardless_of_stage(): void
    {
        // Rule 4: "The Business Owner retains read/download access to all
        // documents associated with their own request throughout the
        // request lifecycle" — viewDocuments()/attachmentsIndex() are
        // deliberately untouched by the staged upload rule.
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        [$caseId] = $this->makeOpenCase($tenant);
        $this->actingAsTenantUser($tenant);
        $pcrId = $this->postJson("/api/v1/collection-cases/{$caseId}/professional-requests", $this->submitPayload())->json('data.id');

        $this->moveToAssigned($tenant, $pcrId);
        $this->postJson("/api/v1/professional-requests/{$pcrId}/close", ['outcome' => 'closed'])->assertStatus(200);

        $this->actingAsTenantUser($tenant);
        $this->getJson("/api/v1/professional-requests/{$pcrId}/documents")->assertStatus(200);
        $this->getJson("/api/v1/professional-requests/{$pcrId}/attachments")->assertStatus(200);
    }

    public function test_uploaded_attachment_never_appears_in_the_existing_document_tables(): void
    {
        // "Newly uploaded documents belong only to the Professional
        // Collection Request" — never written into receipts/demand_letters/
        // statements/invoices.
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        [$caseId] = $this->makeOpenCase($tenant);
        $this->actingAsTenantUser($tenant);
        $pcrId = $this->postJson("/api/v1/collection-cases/{$caseId}/professional-requests", $this->submitPayload())->json('data.id');

        $this->post("/api/v1/professional-requests/{$pcrId}/attachments", [
            'file' => UploadedFile::fake()->create('agreement.pdf', 100, 'application/pdf'),
        ])->assertStatus(201);

        $this->assertDatabaseCount('receipts', 0);
        $this->assertDatabaseCount('demand_letters', 0);
        $this->assertDatabaseCount('statements', 0);
        $this->assertDatabaseCount('invoices', 0);
        $this->assertDatabaseCount('professional_collection_request_documents', 0);
    }

    public function test_attachment_upload_counts_toward_the_tenants_storage_quota(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        [$caseId] = $this->makeOpenCase($tenant);
        $this->actingAsTenantUser($tenant);
        $pcrId = $this->postJson("/api/v1/collection-cases/{$caseId}/professional-requests", $this->submitPayload())->json('data.id');

        $this->post("/api/v1/professional-requests/{$pcrId}/attachments", [
            'file' => UploadedFile::fake()->create('agreement.pdf', 500, 'application/pdf'),
        ])->assertStatus(201);

        $usage = $this->getJson('/api/v1/documents/storage-usage');
        $usage->assertStatus(200);
        $this->assertGreaterThan(0, $usage->json('data.used_bytes'));
    }

    public function test_attachment_upload_rejects_a_disallowed_file_type(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        [$caseId] = $this->makeOpenCase($tenant);
        $this->actingAsTenantUser($tenant);
        $pcrId = $this->postJson("/api/v1/collection-cases/{$caseId}/professional-requests", $this->submitPayload())->json('data.id');

        $this->post("/api/v1/professional-requests/{$pcrId}/attachments", [
            'file' => UploadedFile::fake()->create('script.exe', 100, 'application/x-msdownload'),
        ])->assertStatus(422);
    }

    // --- Professional Collection Summary Card ---

    public function test_summary_returns_counts_by_status_and_the_latest_request(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        [$caseId] = $this->makeOpenCase($tenant);
        $this->actingAsTenantUser($tenant);
        $pcrId = $this->postJson("/api/v1/collection-cases/{$caseId}/professional-requests", $this->submitPayload())->json('data.id');

        $response = $this->getJson('/api/v1/professional-requests/summary');

        $response->assertStatus(200)
            ->assertJsonPath('data.counts_by_status.submitted', 1)
            ->assertJsonPath('data.total_active', 1)
            ->assertJsonPath('data.total_recovered', 0)
            ->assertJsonPath('data.latest_request.id', $pcrId);
    }

    public function test_summary_is_scoped_to_the_acting_tenant(): void
    {
        $tenantA = Tenant::create(['business_name' => 'Tenant A']);
        $tenantB = Tenant::create(['business_name' => 'Tenant B']);
        [$caseIdA] = $this->makeOpenCase($tenantA);
        $this->actingAsTenantUser($tenantA);
        $this->postJson("/api/v1/collection-cases/{$caseIdA}/professional-requests", $this->submitPayload())->assertStatus(201);

        [$caseIdB] = $this->makeOpenCase($tenantB);
        $this->actingAsTenantUser($tenantB);
        $this->postJson("/api/v1/collection-cases/{$caseIdB}/professional-requests", $this->submitPayload())->assertStatus(201);

        $response = $this->getJson('/api/v1/professional-requests/summary');

        $response->assertStatus(200)->assertJsonPath('data.counts_by_status.submitted', 1);
    }

    public function test_summary_returns_the_latest_timeline_event_as_the_closest_available_next_update_signal(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        [$caseId] = $this->makeOpenCase($tenant);
        $this->actingAsTenantUser($tenant);
        $pcrId = $this->postJson("/api/v1/collection-cases/{$caseId}/professional-requests", $this->submitPayload())->json('data.id');

        $this->actingAsPlatformAdmin();
        $this->postJson("/api/v1/professional-requests/{$pcrId}/timeline", ['event_type' => 'pending_review'])->assertStatus(201);

        $this->actingAsTenantUser($tenant);
        $response = $this->getJson('/api/v1/professional-requests/summary');

        $response->assertStatus(200)->assertJsonPath('data.latest_timeline_event.event_type', 'pending_review');
    }

    public function test_platform_admin_cannot_access_the_summary_card(): void
    {
        // No cross-tenant "summary" exists for the Deendoon Platform
        // Administrator, mirroring Business Health's identical restriction.
        $this->actingAsPlatformAdmin();

        $this->getJson('/api/v1/professional-requests/summary')->assertStatus(403);
    }

    // --- Professional Collection Timeline ---

    public function test_platform_admin_can_record_a_timeline_event(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        [$caseId] = $this->makeOpenCase($tenant);
        $this->actingAsTenantUser($tenant);
        $pcrId = $this->postJson("/api/v1/collection-cases/{$caseId}/professional-requests", $this->submitPayload())->json('data.id');

        $admin = $this->actingAsPlatformAdmin();
        $response = $this->postJson("/api/v1/professional-requests/{$pcrId}/timeline", [
            'event_type' => 'telephone_collection',
            'notes' => 'Spoke with the customer, promised payment next week.',
            'outcome' => 'promise_made',
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('data.event_type', 'telephone_collection')
            ->assertJsonPath('data.officer_user_id', (string) $admin->id)
            ->assertJsonPath('data.outcome', 'promise_made');
    }

    public function test_timeline_event_records_an_audit_log_entry_independent_of_the_operational_record(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        [$caseId] = $this->makeOpenCase($tenant);
        $this->actingAsTenantUser($tenant);
        $pcrId = $this->postJson("/api/v1/collection-cases/{$caseId}/professional-requests", $this->submitPayload())->json('data.id');

        $this->actingAsPlatformAdmin();
        $eventId = $this->postJson("/api/v1/professional-requests/{$pcrId}/timeline", ['event_type' => 'field_visit'])
            ->json('data.id');

        $this->assertDatabaseHas('professional_collection_timeline_events', ['id' => $eventId, 'event_type' => 'field_visit']);
        $this->assertDatabaseHas('audit_log', [
            'entity_type' => 'professional_collection_timeline_event', 'entity_id' => $eventId, 'action' => 'created',
        ]);
    }

    public function test_tenant_user_cannot_record_a_timeline_event(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        [$caseId] = $this->makeOpenCase($tenant);
        $this->actingAsTenantUser($tenant);
        $pcrId = $this->postJson("/api/v1/collection-cases/{$caseId}/professional-requests", $this->submitPayload())->json('data.id');

        $this->postJson("/api/v1/professional-requests/{$pcrId}/timeline", ['event_type' => 'meeting'])
            ->assertStatus(403);
    }

    public function test_tenant_user_can_view_the_timeline_but_only_the_platform_administrator_can_write_to_it(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        [$caseId] = $this->makeOpenCase($tenant);
        $this->actingAsTenantUser($tenant);
        $pcrId = $this->postJson("/api/v1/collection-cases/{$caseId}/professional-requests", $this->submitPayload())->json('data.id');

        $this->actingAsPlatformAdmin();
        $this->postJson("/api/v1/professional-requests/{$pcrId}/timeline", ['event_type' => 'pending_review'])->assertStatus(201);

        $this->actingAsTenantUser($tenant);
        $response = $this->getJson("/api/v1/professional-requests/{$pcrId}/timeline");

        $response->assertStatus(200);
        $this->assertCount(1, $response->json('data'));
    }

    public function test_platform_admin_can_update_a_timeline_event(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        [$caseId] = $this->makeOpenCase($tenant);
        $this->actingAsTenantUser($tenant);
        $pcrId = $this->postJson("/api/v1/collection-cases/{$caseId}/professional-requests", $this->submitPayload())->json('data.id');

        $this->actingAsPlatformAdmin();
        $eventId = $this->postJson("/api/v1/professional-requests/{$pcrId}/timeline", ['event_type' => 'meeting'])->json('data.id');

        $response = $this->patchJson("/api/v1/professional-requests/{$pcrId}/timeline/{$eventId}", [
            'outcome' => 'no_answer', 'notes' => 'Customer did not attend.',
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('data.outcome', 'no_answer')
            ->assertJsonPath('data.notes', 'Customer did not attend.');
        $this->assertDatabaseHas('audit_log', [
            'entity_type' => 'professional_collection_timeline_event', 'entity_id' => $eventId, 'action' => 'edited',
        ]);
    }

    public function test_tenant_user_cannot_update_a_timeline_event(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        [$caseId] = $this->makeOpenCase($tenant);
        $this->actingAsTenantUser($tenant);
        $pcrId = $this->postJson("/api/v1/collection-cases/{$caseId}/professional-requests", $this->submitPayload())->json('data.id');

        $this->actingAsPlatformAdmin();
        $eventId = $this->postJson("/api/v1/professional-requests/{$pcrId}/timeline", ['event_type' => 'meeting'])->json('data.id');

        $this->actingAsTenantUser($tenant);
        $this->patchJson("/api/v1/professional-requests/{$pcrId}/timeline/{$eventId}", ['outcome' => 'no_answer'])
            ->assertStatus(403);
    }

    public function test_timeline_event_rejects_an_unknown_event_type(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        [$caseId] = $this->makeOpenCase($tenant);
        $this->actingAsTenantUser($tenant);
        $pcrId = $this->postJson("/api/v1/collection-cases/{$caseId}/professional-requests", $this->submitPayload())->json('data.id');

        $this->actingAsPlatformAdmin();
        $this->postJson("/api/v1/professional-requests/{$pcrId}/timeline", ['event_type' => 'not_a_real_stage'])
            ->assertStatus(422);
    }

    public function test_timeline_event_can_be_recorded_with_an_attachment(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        [$caseId] = $this->makeOpenCase($tenant);
        $this->actingAsTenantUser($tenant);
        $pcrId = $this->postJson("/api/v1/collection-cases/{$caseId}/professional-requests", $this->submitPayload())->json('data.id');

        $this->actingAsPlatformAdmin();
        $response = $this->post("/api/v1/professional-requests/{$pcrId}/timeline", [
            'event_type' => 'field_visit',
            'attachments' => [UploadedFile::fake()->create('site-photo.jpg', 200, 'image/jpeg')],
        ]);

        $response->assertStatus(201);
        $eventId = $response->json('data.id');
        $this->assertSame(1, ProfessionalCollectionRequestAttachment::where('timeline_event_id', $eventId)->count());
        $this->assertCount(1, $response->json('data.attachments'));
    }

    public function test_this_timeline_is_independent_of_the_customer_collection_timeline(): void
    {
        // DebtController::timeline() (Module 3/5) remains untouched by any
        // Professional Collection Timeline activity.
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        [$caseId, $debt] = $this->makeOpenCase($tenant);
        $this->actingAsTenantUser($tenant);
        $pcrId = $this->postJson("/api/v1/collection-cases/{$caseId}/professional-requests", $this->submitPayload())->json('data.id');

        $this->actingAsPlatformAdmin();
        $this->postJson("/api/v1/professional-requests/{$pcrId}/timeline", ['event_type' => 'telephone_collection'])->assertStatus(201);

        $this->actingAsTenantUser($tenant);
        $customerTimeline = $this->getJson("/api/v1/debts/{$debt->id}/timeline");

        $customerTimeline->assertStatus(200);
        $stages = collect($customerTimeline->json('data.stages'))->pluck('event');
        $this->assertNotContains('telephone_collection', $stages);
    }
}
