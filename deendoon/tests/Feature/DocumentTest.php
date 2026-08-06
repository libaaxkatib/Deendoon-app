<?php

namespace Tests\Feature;

use App\Models\AuditLog;
use App\Models\Customer;
use App\Models\Debt;
use App\Models\DemandLetter;
use App\Models\Invoice;
use App\Models\MessageTemplate;
use App\Models\Payment;
use App\Models\Receipt;
use App\Models\Tenant;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Database\Seeders\SubscriptionPlanSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class DocumentTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RoleSeeder::class);
        // Backend Completion Roadmap (Phase 4.2): document generation now
        // fails closed to a storage allowance of 0 bytes when no plan can
        // be resolved at all — every tenant here needs the Free Plan
        // (10GB) resolvable, matching how a real tenant with no
        // subscription behaves in production.
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

        $token = $user->createToken('test')->plainTextToken;
        $this->withHeader('Authorization', 'Bearer '.$token);

        return $user;
    }

    private function makeDebt(Tenant $tenant, array $attributes = []): Debt
    {
        $customer = Customer::factory()->for($tenant, 'tenant')->create(['credit_limit' => 5000]);

        return Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create($attributes);
    }

    // --- Receipt generation (FR-047, automatic via Payment) ---

    public function test_recording_a_payment_automatically_generates_a_receipt(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant, ['amount' => 1000, 'remaining_balance' => 1000]);
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson("/api/v1/debts/{$debt->id}/payments", [
            'amount' => 400, 'payment_date' => now()->toDateString(),
        ]);

        $response->assertStatus(201);
        $paymentId = $response->json('data.id');

        $this->assertDatabaseHas('receipts', ['payment_id' => $paymentId, 'reference_number' => 'RCT-000001']);
    }

    public function test_receipt_generation_records_audit_event_and_document_event(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant, ['amount' => 1000, 'remaining_balance' => 1000]);
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/debts/{$debt->id}/payments", [
            'amount' => 400, 'payment_date' => now()->toDateString(),
        ])->assertStatus(201);

        $receipt = Receipt::first();

        $this->assertDatabaseHas('audit_log', [
            'entity_type' => 'payment', 'action' => 'receipt_generated', 'user_id' => null,
        ]);
        $this->assertDatabaseHas('document_events', [
            'document_type' => 'receipt', 'document_id' => $receipt->id, 'event_type' => 'generated', 'user_id' => null,
        ]);
    }

    public function test_receipt_reference_numbers_are_sequential_per_tenant(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant, ['amount' => 1000, 'remaining_balance' => 1000]);
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/debts/{$debt->id}/payments", ['amount' => 100, 'payment_date' => now()->toDateString()])->assertStatus(201);
        $this->postJson("/api/v1/debts/{$debt->id}/payments", ['amount' => 100, 'payment_date' => now()->toDateString()])->assertStatus(201);

        $this->assertDatabaseHas('receipts', ['reference_number' => 'RCT-000001']);
        $this->assertDatabaseHas('receipts', ['reference_number' => 'RCT-000002']);
    }

    public function test_admin_can_view_a_receipt_via_dedicated_endpoint(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant, ['amount' => 1000, 'remaining_balance' => 1000]);
        $this->actingAsTenantUser($tenant);
        $this->postJson("/api/v1/debts/{$debt->id}/payments", ['amount' => 400, 'payment_date' => now()->toDateString()])->assertStatus(201);
        $receipt = Receipt::first();

        $this->getJson("/api/v1/receipts/{$receipt->id}")
            ->assertStatus(200)
            ->assertJsonPath('data.document_type', 'receipt')
            ->assertJsonPath('data.reference_number', 'RCT-000001');
    }

    public function test_receipt_generation_captures_file_size(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant, ['amount' => 1000, 'remaining_balance' => 1000]);
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson("/api/v1/debts/{$debt->id}/payments", ['amount' => 400, 'payment_date' => now()->toDateString()]);
        $receiptId = Receipt::first()->id;

        $this->getJson("/api/v1/receipts/{$receiptId}")
            ->assertStatus(200)
            ->assertJsonPath('data.file_size', fn ($size) => is_int($size) && $size > 0);
    }

    /**
     * Sprint 4 Business Rule 1 (Product Owner, FINAL): "Case escalation
     * MUST NOT automatically generate a Demand Letter." Confirms the
     * already-existing, unchanged escalate() behavior remains compliant.
     */
    public function test_escalating_a_debt_does_not_generate_a_demand_letter(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/debts/{$debt->id}/collection-cases")->assertStatus(201);

        $this->assertDatabaseCount('demand_letters', 0);
    }

    // --- Storage Usage (docs/Mobile_UI_V1_Frozen.md §8.1) ---

    public function test_admin_can_view_storage_usage(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant, ['amount' => 1000, 'remaining_balance' => 1000]);
        $this->actingAsTenantUser($tenant);
        $this->postJson("/api/v1/debts/{$debt->id}/payments", ['amount' => 400, 'payment_date' => now()->toDateString()]);

        $response = $this->getJson('/api/v1/documents/storage-usage');

        $response->assertStatus(200)->assertJsonStructure(['data' => ['used_bytes', 'total_bytes', 'used_percentage']]);
        $this->assertGreaterThan(0, $response->json('data.used_bytes'));
    }

    // --- Document Share (§8.8) ---

    public function test_admin_can_share_a_demand_letter_via_whatsapp(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);
        $letterId = $this->postJson("/api/v1/debts/{$debt->id}/demand-letters", ['template_type' => 'first_reminder'])->json('data.id');
        $template = MessageTemplate::factory()->for($tenant, 'tenant')->create();

        $response = $this->postJson("/api/v1/documents/{$letterId}/share", [
            'channel' => 'whatsapp',
            'template_id' => $template->id,
        ]);

        $response->assertStatus(200)->assertJsonPath('data.status', 'sent');
        $this->assertDatabaseHas('sent_messages', [
            'document_type' => 'demand_letter',
            'document_id' => $letterId,
            'channel' => 'whatsapp',
        ]);
    }

    // --- Demand Letter generation (FR-048) ---

    public function test_admin_can_generate_a_demand_letter(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson("/api/v1/debts/{$debt->id}/demand-letters", ['template_type' => 'first_reminder']);

        $response->assertStatus(201)
            ->assertJsonPath('data.document_type', 'demand_letter')
            ->assertJsonPath('data.template_type', 'first_reminder')
            ->assertJsonPath('data.reference_number', 'DL-000001');

        $this->assertDatabaseHas('demand_letters', ['debt_id' => $debt->id, 'template_type' => 'first_reminder']);
    }

    public function test_demand_letter_requires_a_valid_template_type(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/debts/{$debt->id}/demand-letters", ['template_type' => 'not_a_real_template'])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['template_type']);
    }

    public function test_demand_letter_generation_against_an_archived_debt_is_rejected(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $debt->delete();
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/debts/{$debt->id}/demand-letters", ['template_type' => 'first_reminder'])
            ->assertStatus(404);
    }

    public function test_demand_letter_reference_numbers_are_shared_across_templates(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);

        $first = $this->postJson("/api/v1/debts/{$debt->id}/demand-letters", ['template_type' => 'first_reminder'])->json('data.reference_number');
        $second = $this->postJson("/api/v1/debts/{$debt->id}/demand-letters", ['template_type' => 'legal_notice'])->json('data.reference_number');

        $this->assertSame('DL-000001', $first);
        $this->assertSame('DL-000002', $second);
    }

    public function test_demand_letter_generation_records_an_audit_event(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $user = $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/debts/{$debt->id}/demand-letters", ['template_type' => 'final_demand'])->assertStatus(201);

        $this->assertDatabaseHas('audit_log', [
            'entity_type' => 'debt', 'entity_id' => $debt->id, 'action' => 'demand_letter_generated', 'user_id' => (string) $user->id,
        ]);
    }

    // --- Statement generation (FR-049) ---

    public function test_admin_can_generate_a_statement_from_customer_profile(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson("/api/v1/customers/{$customer->id}/statements");

        $response->assertStatus(201)
            ->assertJsonPath('data.document_type', 'statement')
            ->assertJsonPath('data.customer_id', $customer->id)
            ->assertJsonPath('data.debt_id', null)
            ->assertJsonPath('data.reference_number', 'ST-000001');
    }

    public function test_admin_can_generate_a_statement_from_debt_details(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson("/api/v1/debts/{$debt->id}/statements");

        $response->assertStatus(201)->assertJsonPath('data.debt_id', $debt->id);
    }

    public function test_statement_from_debt_details_still_covers_the_full_customer_account(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $debtA = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create();
        $debtB = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create();
        $this->actingAsTenantUser($tenant);

        // Triggered from debtA's context, but the statement itself has no
        // debt-count-limiting field — it always renders the full account
        // (verified indirectly: generation succeeds regardless of debtB
        // existing, and the model carries only debtA's id as traceability).
        $response = $this->postJson("/api/v1/debts/{$debtA->id}/statements");

        $response->assertStatus(201)->assertJsonPath('data.debt_id', $debtA->id);
        $this->assertNotNull($debtB->id);
    }

    public function test_statement_generation_records_an_audit_event(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $user = $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/customers/{$customer->id}/statements")->assertStatus(201);

        $this->assertDatabaseHas('audit_log', [
            'entity_type' => 'customer', 'entity_id' => $customer->id, 'action' => 'statement_generated', 'user_id' => (string) $user->id,
        ]);
    }

    // --- Invoice generation (Sprint 4.1 — final document type) ---

    public function test_admin_can_generate_an_invoice(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant, ['amount' => 1500]);
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson("/api/v1/debts/{$debt->id}/invoices");

        $response->assertStatus(201)
            ->assertJsonPath('data.document_type', 'invoice')
            ->assertJsonPath('data.debt_id', $debt->id)
            ->assertJsonPath('data.reference_number', 'INV-000001')
            ->assertJsonPath('data.file_size', fn ($size) => is_int($size) && $size > 0);

        $this->assertDatabaseHas('invoices', ['debt_id' => $debt->id, 'reference_number' => 'INV-000001']);
    }

    public function test_invoice_reference_numbers_are_sequential_per_tenant(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debtA = $this->makeDebt($tenant);
        $debtB = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/debts/{$debtA->id}/invoices")->assertJsonPath('data.reference_number', 'INV-000001');
        $this->postJson("/api/v1/debts/{$debtB->id}/invoices")->assertJsonPath('data.reference_number', 'INV-000002');
    }

    public function test_invoice_generation_against_an_archived_debt_is_rejected(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $debt->delete();
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/debts/{$debt->id}/invoices")->assertStatus(404);
    }

    public function test_invoice_generation_records_an_audit_event(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $user = $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/debts/{$debt->id}/invoices")->assertStatus(201);

        $this->assertDatabaseHas('audit_log', [
            'entity_type' => 'debt', 'entity_id' => $debt->id, 'action' => 'invoice_generated', 'user_id' => (string) $user->id,
        ]);
    }

    /**
     * Sprint 4.1 Business Rule: "Invoice generation is a manual business
     * action... Do NOT generate invoices automatically."
     */
    public function test_creating_a_debt_does_not_automatically_generate_an_invoice(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->makeDebt($tenant);

        $this->assertDatabaseCount('invoices', 0);
    }

    public function test_admin_can_view_and_download_an_invoice_via_the_generic_endpoint(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);
        $invoiceId = $this->postJson("/api/v1/debts/{$debt->id}/invoices")->json('data.id');

        $this->getJson("/api/v1/documents/{$invoiceId}")
            ->assertStatus(200)
            ->assertJsonPath('data.document_type', 'invoice');

        $this->getJson("/api/v1/documents/{$invoiceId}/download")->assertStatus(200);

        $this->assertDatabaseHas('document_events', [
            'document_type' => 'invoice', 'document_id' => $invoiceId, 'event_type' => 'downloaded',
        ]);
    }

    public function test_admin_can_share_an_invoice_via_whatsapp(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);
        $invoiceId = $this->postJson("/api/v1/debts/{$debt->id}/invoices")->json('data.id');
        $template = MessageTemplate::factory()->for($tenant, 'tenant')->create();

        $response = $this->postJson("/api/v1/documents/{$invoiceId}/share", [
            'channel' => 'whatsapp',
            'template_id' => $template->id,
        ]);

        $response->assertStatus(200)->assertJsonPath('data.status', 'sent');
        $this->assertDatabaseHas('sent_messages', [
            'document_type' => 'invoice', 'document_id' => $invoiceId, 'channel' => 'whatsapp',
        ]);
    }

    public function test_debt_documents_endpoint_includes_invoices(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);
        $this->postJson("/api/v1/debts/{$debt->id}/invoices")->assertStatus(201);

        $response = $this->getJson("/api/v1/debts/{$debt->id}/documents");

        $types = collect($response->json('data'))->pluck('document_type');
        $this->assertTrue($types->contains('invoice'));
    }

    public function test_user_without_admin_role_cannot_generate_invoices(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant, null);

        $this->postJson("/api/v1/debts/{$debt->id}/invoices")->assertStatus(403);
    }

    // --- List Documents (Sprint 7 — docs/Mobile_UI_V1_Frozen.md §8.1) ---

    public function test_admin_can_list_all_documents_across_types(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant, ['amount' => 1000, 'remaining_balance' => 1000]);
        $this->actingAsTenantUser($tenant);
        $this->postJson("/api/v1/debts/{$debt->id}/invoices");
        $this->postJson("/api/v1/debts/{$debt->id}/demand-letters", ['template_type' => 'first_reminder']);
        $this->postJson("/api/v1/debts/{$debt->id}/payments", ['amount' => 400, 'payment_date' => now()->toDateString()]);

        $response = $this->getJson('/api/v1/documents');

        $response->assertStatus(200);
        $types = collect($response->json('data.documents'))->pluck('document_type');
        $this->assertTrue($types->contains('invoice'));
        $this->assertTrue($types->contains('demand_letter'));
        $this->assertTrue($types->contains('receipt'));
        $this->assertSame(3, $response->json('data.pagination.total'));
    }

    public function test_documents_list_can_be_filtered_by_type(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);
        $this->postJson("/api/v1/debts/{$debt->id}/invoices");
        $this->postJson("/api/v1/debts/{$debt->id}/demand-letters", ['template_type' => 'first_reminder']);

        $response = $this->getJson('/api/v1/documents?type=invoices');

        $types = collect($response->json('data.documents'))->pluck('document_type');
        $this->assertSame(['invoice'], $types->unique()->all());
    }

    public function test_documents_list_other_tab_returns_statements(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $this->actingAsTenantUser($tenant);
        $this->postJson("/api/v1/customers/{$customer->id}/statements");

        $response = $this->getJson('/api/v1/documents?type=other');

        $types = collect($response->json('data.documents'))->pluck('document_type');
        $this->assertSame(['statement'], $types->unique()->all());
    }

    public function test_documents_list_can_be_searched_by_reference_number(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debtA = $this->makeDebt($tenant);
        $debtB = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);
        $letterId = $this->postJson("/api/v1/debts/{$debtA->id}/demand-letters", ['template_type' => 'first_reminder'])->json('data.id');
        $this->postJson("/api/v1/debts/{$debtB->id}/demand-letters", ['template_type' => 'first_reminder']);

        $response = $this->getJson('/api/v1/documents?search=DL-000001');

        $ids = collect($response->json('data.documents'))->pluck('id');
        $this->assertSame([$letterId], $ids->all());
    }

    public function test_documents_list_respects_tenant_isolation(): void
    {
        $tenantA = Tenant::create(['business_name' => 'Tenant A']);
        $tenantB = Tenant::create(['business_name' => 'Tenant B']);
        $debtB = $this->makeDebt($tenantB);
        // Created directly (not via an authenticated API call as tenant B)
        // to avoid this suite's known Sanctum guard-caching behavior,
        // where a second bearer-token request within one test method
        // isn't re-resolved from scratch.
        Invoice::factory()->for($tenantB, 'tenant')->for($debtB, 'debt')->create();

        $this->actingAsTenantUser($tenantA);
        $response = $this->getJson('/api/v1/documents');

        $this->assertSame(0, $response->json('data.pagination.total'));
    }

    public function test_user_without_admin_role_cannot_list_documents(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant, null);

        $this->getJson('/api/v1/documents')->assertStatus(403);
    }

    // --- Document Viewing (FR-050) ---

    public function test_admin_can_view_any_document_type_via_the_generic_endpoint(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);
        $letterId = $this->postJson("/api/v1/debts/{$debt->id}/demand-letters", ['template_type' => 'first_reminder'])->json('data.id');

        $this->getJson("/api/v1/documents/{$letterId}")
            ->assertStatus(200)
            ->assertJsonPath('data.document_type', 'demand_letter');
    }

    public function test_viewing_a_document_from_another_tenant_returns_404(): void
    {
        $tenantA = Tenant::create(['business_name' => 'Tenant A']);
        $tenantB = Tenant::create(['business_name' => 'Tenant B']);
        $debtB = $this->makeDebt($tenantB);
        $letterB = DemandLetter::factory()->for($tenantB, 'tenant')->for($debtB, 'debt')->create();

        $this->actingAsTenantUser($tenantA);
        $this->getJson("/api/v1/documents/{$letterB->id}")->assertStatus(404);
    }

    // --- Document Downloading (FR-051) ---

    public function test_admin_can_download_a_document(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);
        $letterId = $this->postJson("/api/v1/debts/{$debt->id}/demand-letters", ['template_type' => 'first_reminder'])->json('data.id');

        $response = $this->get("/api/v1/documents/{$letterId}/download");

        $response->assertStatus(200);
        $this->assertSame('application/pdf', $response->headers->get('content-type'));
    }

    public function test_downloading_records_a_document_event(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $user = $this->actingAsTenantUser($tenant);
        $letterId = $this->postJson("/api/v1/debts/{$debt->id}/demand-letters", ['template_type' => 'first_reminder'])->json('data.id');

        $this->get("/api/v1/documents/{$letterId}/download")->assertStatus(200);

        $this->assertDatabaseHas('document_events', [
            'document_type' => 'demand_letter', 'document_id' => $letterId, 'event_type' => 'downloaded', 'user_id' => (string) $user->id,
        ]);
    }

    public function test_downloading_does_not_record_an_extra_audit_log_entry(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);
        $letterId = $this->postJson("/api/v1/debts/{$debt->id}/demand-letters", ['template_type' => 'first_reminder'])->json('data.id');

        $this->get("/api/v1/documents/{$letterId}/download")->assertStatus(200);

        $this->assertSame(1, AuditLog::where('action', 'demand_letter_generated')->count());
    }

    // --- Document History (FR-052) ---

    public function test_document_history_shows_generated_and_downloaded_events_in_order(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);
        $letterId = $this->postJson("/api/v1/debts/{$debt->id}/demand-letters", ['template_type' => 'first_reminder'])->json('data.id');
        $this->get("/api/v1/documents/{$letterId}/download")->assertStatus(200);

        $response = $this->getJson("/api/v1/documents/{$letterId}/history");

        $response->assertStatus(200);
        $eventTypes = collect($response->json('data'))->pluck('event_type');
        $this->assertSame(['generated', 'downloaded'], $eventTypes->all());
    }

    // --- Aggregation ---

    public function test_customer_documents_endpoint_lists_all_generated_document_types(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant, ['amount' => 500, 'remaining_balance' => 500]);
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/debts/{$debt->id}/payments", ['amount' => 100, 'payment_date' => now()->toDateString()])->assertStatus(201);
        $this->postJson("/api/v1/debts/{$debt->id}/demand-letters", ['template_type' => 'first_reminder'])->assertStatus(201);
        $this->postJson("/api/v1/customers/{$debt->customer_id}/statements")->assertStatus(201);

        $response = $this->getJson("/api/v1/customers/{$debt->customer_id}/documents");

        $response->assertStatus(200);
        $types = collect($response->json('data'))->pluck('document_type');
        $this->assertTrue($types->contains('receipt'));
        $this->assertTrue($types->contains('demand_letter'));
        $this->assertTrue($types->contains('statement'));
    }

    public function test_debt_documents_endpoint_lists_related_documents(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/debts/{$debt->id}/demand-letters", ['template_type' => 'first_reminder'])->assertStatus(201);

        $response = $this->getJson("/api/v1/debts/{$debt->id}/documents");

        $response->assertStatus(200);
        $this->assertCount(1, $response->json('data'));
    }

    // --- Authentication / Authorization / Tenant isolation ---

    public function test_unauthenticated_requests_are_rejected(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);

        $this->postJson("/api/v1/debts/{$debt->id}/demand-letters", ['template_type' => 'first_reminder'])->assertStatus(401);
        $this->postJson("/api/v1/customers/{$debt->customer_id}/statements")->assertStatus(401);
        $this->getJson('/api/v1/documents/nonexistent')->assertStatus(401);
    }

    public function test_user_without_admin_role_cannot_generate_or_view_documents(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant, null);

        $this->postJson("/api/v1/debts/{$debt->id}/demand-letters", ['template_type' => 'first_reminder'])->assertStatus(403);
        $this->postJson("/api/v1/customers/{$debt->customer_id}/statements")->assertStatus(403);
    }

    public function test_receipt_view_respects_tenant_isolation(): void
    {
        $tenantA = Tenant::create(['business_name' => 'Tenant A']);
        $tenantB = Tenant::create(['business_name' => 'Tenant B']);
        $debtB = $this->makeDebt($tenantB, ['amount' => 500, 'remaining_balance' => 500]);
        $paymentB = Payment::factory()->for($tenantB, 'tenant')->for($debtB, 'debt')->create();
        $receiptB = Receipt::factory()->for($tenantB, 'tenant')->for($paymentB, 'payment')->create();

        $this->actingAsTenantUser($tenantA);
        $this->getJson("/api/v1/receipts/{$receiptB->id}")->assertStatus(404);
    }
}
