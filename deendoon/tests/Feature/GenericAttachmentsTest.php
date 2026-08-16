<?php

namespace Tests\Feature;

use App\Models\CollectionCase;
use App\Models\Customer;
use App\Models\Debt;
use App\Models\Tenant;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Database\Seeders\SubscriptionPlanSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * Final Product Completion Roadmap, P1.6 — generic file attachments on
 * Customer/Debt/CollectionCase. One combined file since all three follow
 * the identical shape/rules (mirrors
 * `professional_collection_request_attachments`'s validation/quota
 * conventions exactly), covering upload/list, validation, the read-only
 * gate, and tenant isolation for each entity.
 */
class GenericAttachmentsTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RoleSeeder::class);
        $this->seed(SubscriptionPlanSeeder::class);
        Storage::fake('local');
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

    /**
     * Switches the authenticated identity mid-test, for a second tenant
     * user or a cross-tenant attempt. `actingAsTenantUser()`'s manual
     * token + `withHeader()` re-set does not reliably re-resolve on a
     * second call within the same test (the Sanctum guard instance is
     * cached for the test's app lifetime) — `Sanctum::actingAs()` bypasses
     * that guard-resolution caching, matching the reliable pattern
     * `SupportTicketTest` already uses for its own mid-test identity
     * switches.
     */
    private function switchToTenantUser(Tenant $tenant): User
    {
        $user = User::factory()->create();
        $user->tenant()->associate($tenant);
        $user->save();
        $user->assignRole('admin');

        Sanctum::actingAs($user, ['*']);

        return $user;
    }

    private function makeCustomer(Tenant $tenant): Customer
    {
        return Customer::factory()->for($tenant, 'tenant')->create();
    }

    private function makeDebt(Tenant $tenant, Customer $customer): Debt
    {
        return Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create();
    }

    private function makeCase(Tenant $tenant, Debt $debt): CollectionCase
    {
        return CollectionCase::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create();
    }

    // --- Customer Attachments ---

    public function test_business_owner_can_upload_and_list_a_customer_attachment(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->makeCustomer($tenant);
        $this->actingAsTenantUser($tenant);

        $response = $this->post("/api/v1/customers/{$customer->id}/attachments", [
            'file' => UploadedFile::fake()->create('id-card.pdf', 100, 'application/pdf'),
            'description' => 'Customer ID card',
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('data.original_filename', 'id-card.pdf')
            ->assertJsonPath('data.description', 'Customer ID card');
        $this->assertDatabaseHas('customer_attachments', [
            'customer_id' => $customer->id, 'original_filename' => 'id-card.pdf',
        ]);

        $this->getJson("/api/v1/customers/{$customer->id}/attachments")
            ->assertStatus(200)
            ->assertJsonCount(1, 'data');
    }

    public function test_customer_attachment_upload_rejects_a_disallowed_file_type(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->makeCustomer($tenant);
        $this->actingAsTenantUser($tenant);

        $this->post("/api/v1/customers/{$customer->id}/attachments", [
            'file' => UploadedFile::fake()->create('malware.exe', 100, 'application/x-msdownload'),
        ])->assertStatus(422);
    }

    public function test_customer_attachment_upload_is_blocked_for_a_read_only_customer(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->makeCustomer($tenant);
        Customer::where('id', $customer->id)->update(['is_read_only' => true]);
        $this->actingAsTenantUser($tenant);

        $this->post("/api/v1/customers/{$customer->id}/attachments", [
            'file' => UploadedFile::fake()->create('doc.pdf', 100, 'application/pdf'),
        ])->assertStatus(403);
    }

    public function test_customer_attachments_are_tenant_isolated(): void
    {
        $tenantA = Tenant::create(['business_name' => 'Acme Co']);
        $tenantB = Tenant::create(['business_name' => 'Other Co']);
        $customerB = $this->makeCustomer($tenantB);
        $this->actingAsTenantUser($tenantA);

        $this->getJson("/api/v1/customers/{$customerB->id}/attachments")->assertStatus(404);
    }

    public function test_the_uploader_can_delete_their_own_customer_attachment(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->makeCustomer($tenant);
        $this->actingAsTenantUser($tenant);
        $attachmentId = $this->post("/api/v1/customers/{$customer->id}/attachments", [
            'file' => UploadedFile::fake()->create('id-card.pdf', 100, 'application/pdf'),
        ])->json('data.id');

        $this->deleteJson("/api/v1/customers/{$customer->id}/attachments/{$attachmentId}")->assertStatus(200);

        $this->assertDatabaseMissing('customer_attachments', ['id' => $attachmentId]);
        $this->assertDatabaseHas('audit_log', [
            'action' => 'deleted', 'entity_type' => 'customer_attachment', 'entity_id' => $attachmentId,
        ]);
    }

    public function test_a_customer_attachment_cannot_be_deleted_by_a_user_who_did_not_upload_it(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->makeCustomer($tenant);
        $this->actingAsTenantUser($tenant);
        $attachmentId = $this->post("/api/v1/customers/{$customer->id}/attachments", [
            'file' => UploadedFile::fake()->create('id-card.pdf', 100, 'application/pdf'),
        ])->json('data.id');

        $this->switchToTenantUser($tenant);

        $this->deleteJson("/api/v1/customers/{$customer->id}/attachments/{$attachmentId}")->assertStatus(403);
        $this->assertDatabaseHas('customer_attachments', ['id' => $attachmentId]);
    }

    public function test_a_customer_attachment_cannot_be_deleted_once_the_customer_is_read_only(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->makeCustomer($tenant);
        $this->actingAsTenantUser($tenant);
        $attachmentId = $this->post("/api/v1/customers/{$customer->id}/attachments", [
            'file' => UploadedFile::fake()->create('id-card.pdf', 100, 'application/pdf'),
        ])->json('data.id');
        Customer::where('id', $customer->id)->update(['is_read_only' => true]);

        $this->deleteJson("/api/v1/customers/{$customer->id}/attachments/{$attachmentId}")->assertStatus(403);
        $this->assertDatabaseHas('customer_attachments', ['id' => $attachmentId]);
    }

    public function test_deleting_another_tenants_customer_attachment_is_rejected(): void
    {
        $tenantA = Tenant::create(['business_name' => 'Acme Co']);
        $tenantB = Tenant::create(['business_name' => 'Other Co']);
        $customerB = $this->makeCustomer($tenantB);
        $this->actingAsTenantUser($tenantB);
        $attachmentId = $this->post("/api/v1/customers/{$customerB->id}/attachments", [
            'file' => UploadedFile::fake()->create('id-card.pdf', 100, 'application/pdf'),
        ])->json('data.id');

        $this->switchToTenantUser($tenantA);

        $this->deleteJson("/api/v1/customers/{$customerB->id}/attachments/{$attachmentId}")->assertStatus(404);
    }

    // --- Debt Attachments ---

    public function test_business_owner_can_upload_and_list_a_debt_attachment(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->makeCustomer($tenant);
        $debt = $this->makeDebt($tenant, $customer);
        $this->actingAsTenantUser($tenant);

        $response = $this->post("/api/v1/debts/{$debt->id}/attachments", [
            'file' => UploadedFile::fake()->create('invoice-scan.jpg', 100, 'image/jpeg'),
            'description' => 'Scanned invoice',
        ]);

        $response->assertStatus(201)->assertJsonPath('data.original_filename', 'invoice-scan.jpg');
        $this->assertDatabaseHas('debt_attachments', [
            'debt_id' => $debt->id, 'original_filename' => 'invoice-scan.jpg',
        ]);

        $this->getJson("/api/v1/debts/{$debt->id}/attachments")->assertStatus(200)->assertJsonCount(1, 'data');
    }

    public function test_debt_attachment_upload_is_blocked_when_the_customer_is_read_only(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->makeCustomer($tenant);
        $debt = $this->makeDebt($tenant, $customer);
        Customer::where('id', $customer->id)->update(['is_read_only' => true]);
        $this->actingAsTenantUser($tenant);

        $this->post("/api/v1/debts/{$debt->id}/attachments", [
            'file' => UploadedFile::fake()->create('doc.pdf', 100, 'application/pdf'),
        ])->assertStatus(403);
    }

    public function test_debt_attachments_are_tenant_isolated(): void
    {
        $tenantA = Tenant::create(['business_name' => 'Acme Co']);
        $tenantB = Tenant::create(['business_name' => 'Other Co']);
        $customerB = $this->makeCustomer($tenantB);
        $debtB = $this->makeDebt($tenantB, $customerB);
        $this->actingAsTenantUser($tenantA);

        $this->getJson("/api/v1/debts/{$debtB->id}/attachments")->assertStatus(404);
    }

    public function test_the_uploader_can_delete_their_own_debt_attachment(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->makeCustomer($tenant);
        $debt = $this->makeDebt($tenant, $customer);
        $this->actingAsTenantUser($tenant);
        $attachmentId = $this->post("/api/v1/debts/{$debt->id}/attachments", [
            'file' => UploadedFile::fake()->create('invoice-scan.jpg', 100, 'image/jpeg'),
        ])->json('data.id');

        $this->deleteJson("/api/v1/debts/{$debt->id}/attachments/{$attachmentId}")->assertStatus(200);

        $this->assertDatabaseMissing('debt_attachments', ['id' => $attachmentId]);
        $this->assertDatabaseHas('audit_log', [
            'action' => 'deleted', 'entity_type' => 'debt_attachment', 'entity_id' => $attachmentId,
        ]);
    }

    public function test_a_debt_attachment_cannot_be_deleted_by_a_user_who_did_not_upload_it(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->makeCustomer($tenant);
        $debt = $this->makeDebt($tenant, $customer);
        $this->actingAsTenantUser($tenant);
        $attachmentId = $this->post("/api/v1/debts/{$debt->id}/attachments", [
            'file' => UploadedFile::fake()->create('invoice-scan.jpg', 100, 'image/jpeg'),
        ])->json('data.id');

        $this->switchToTenantUser($tenant);

        $this->deleteJson("/api/v1/debts/{$debt->id}/attachments/{$attachmentId}")->assertStatus(403);
        $this->assertDatabaseHas('debt_attachments', ['id' => $attachmentId]);
    }

    public function test_a_debt_attachment_cannot_be_deleted_once_the_debt_is_in_a_terminal_status(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->makeCustomer($tenant);
        $debt = $this->makeDebt($tenant, $customer);
        $this->actingAsTenantUser($tenant);
        $attachmentId = $this->post("/api/v1/debts/{$debt->id}/attachments", [
            'file' => UploadedFile::fake()->create('invoice-scan.jpg', 100, 'image/jpeg'),
        ])->json('data.id');
        Debt::where('id', $debt->id)->update(['debt_status' => 'paid']);

        $this->deleteJson("/api/v1/debts/{$debt->id}/attachments/{$attachmentId}")->assertStatus(403);
        $this->assertDatabaseHas('debt_attachments', ['id' => $attachmentId]);
    }

    public function test_a_debt_attachment_cannot_be_deleted_once_the_customer_is_read_only(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->makeCustomer($tenant);
        $debt = $this->makeDebt($tenant, $customer);
        $this->actingAsTenantUser($tenant);
        $attachmentId = $this->post("/api/v1/debts/{$debt->id}/attachments", [
            'file' => UploadedFile::fake()->create('invoice-scan.jpg', 100, 'image/jpeg'),
        ])->json('data.id');
        Customer::where('id', $customer->id)->update(['is_read_only' => true]);

        $this->deleteJson("/api/v1/debts/{$debt->id}/attachments/{$attachmentId}")->assertStatus(403);
        $this->assertDatabaseHas('debt_attachments', ['id' => $attachmentId]);
    }

    public function test_deleting_another_tenants_debt_attachment_is_rejected(): void
    {
        $tenantA = Tenant::create(['business_name' => 'Acme Co']);
        $tenantB = Tenant::create(['business_name' => 'Other Co']);
        $customerB = $this->makeCustomer($tenantB);
        $debtB = $this->makeDebt($tenantB, $customerB);
        $this->actingAsTenantUser($tenantB);
        $attachmentId = $this->post("/api/v1/debts/{$debtB->id}/attachments", [
            'file' => UploadedFile::fake()->create('invoice-scan.jpg', 100, 'image/jpeg'),
        ])->json('data.id');

        $this->switchToTenantUser($tenantA);

        $this->deleteJson("/api/v1/debts/{$debtB->id}/attachments/{$attachmentId}")->assertStatus(404);
    }

    // --- Collection Case Attachments ---

    public function test_business_owner_can_upload_and_list_a_case_attachment(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->makeCustomer($tenant);
        $debt = $this->makeDebt($tenant, $customer);
        $case = $this->makeCase($tenant, $debt);
        $this->actingAsTenantUser($tenant);

        $response = $this->post("/api/v1/collection-cases/{$case->id}/attachments", [
            'file' => UploadedFile::fake()->create('evidence.pdf', 100, 'application/pdf'),
        ]);

        $response->assertStatus(201)->assertJsonPath('data.original_filename', 'evidence.pdf');
        $this->assertDatabaseHas('collection_case_attachments', [
            'collection_case_id' => $case->id, 'original_filename' => 'evidence.pdf',
        ]);

        $this->getJson("/api/v1/collection-cases/{$case->id}/attachments")->assertStatus(200)->assertJsonCount(1, 'data');
    }

    public function test_case_attachment_upload_is_blocked_when_the_customer_is_read_only(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->makeCustomer($tenant);
        $debt = $this->makeDebt($tenant, $customer);
        $case = $this->makeCase($tenant, $debt);
        Customer::where('id', $customer->id)->update(['is_read_only' => true]);
        $this->actingAsTenantUser($tenant);

        $this->post("/api/v1/collection-cases/{$case->id}/attachments", [
            'file' => UploadedFile::fake()->create('doc.pdf', 100, 'application/pdf'),
        ])->assertStatus(403);
    }

    public function test_case_attachments_are_tenant_isolated(): void
    {
        $tenantA = Tenant::create(['business_name' => 'Acme Co']);
        $tenantB = Tenant::create(['business_name' => 'Other Co']);
        $customerB = $this->makeCustomer($tenantB);
        $debtB = $this->makeDebt($tenantB, $customerB);
        $caseB = $this->makeCase($tenantB, $debtB);
        $this->actingAsTenantUser($tenantA);

        $this->getJson("/api/v1/collection-cases/{$caseB->id}/attachments")->assertStatus(404);
    }

    public function test_the_uploader_can_delete_their_own_case_attachment(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->makeCustomer($tenant);
        $debt = $this->makeDebt($tenant, $customer);
        $case = $this->makeCase($tenant, $debt);
        $this->actingAsTenantUser($tenant);
        $attachmentId = $this->post("/api/v1/collection-cases/{$case->id}/attachments", [
            'file' => UploadedFile::fake()->create('evidence.pdf', 100, 'application/pdf'),
        ])->json('data.id');

        $this->deleteJson("/api/v1/collection-cases/{$case->id}/attachments/{$attachmentId}")->assertStatus(200);

        $this->assertDatabaseMissing('collection_case_attachments', ['id' => $attachmentId]);
        $this->assertDatabaseHas('audit_log', [
            'action' => 'deleted', 'entity_type' => 'collection_case_attachment', 'entity_id' => $attachmentId,
        ]);
    }

    public function test_a_case_attachment_cannot_be_deleted_by_a_user_who_did_not_upload_it(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->makeCustomer($tenant);
        $debt = $this->makeDebt($tenant, $customer);
        $case = $this->makeCase($tenant, $debt);
        $this->actingAsTenantUser($tenant);
        $attachmentId = $this->post("/api/v1/collection-cases/{$case->id}/attachments", [
            'file' => UploadedFile::fake()->create('evidence.pdf', 100, 'application/pdf'),
        ])->json('data.id');

        $this->switchToTenantUser($tenant);

        $this->deleteJson("/api/v1/collection-cases/{$case->id}/attachments/{$attachmentId}")->assertStatus(403);
        $this->assertDatabaseHas('collection_case_attachments', ['id' => $attachmentId]);
    }

    public function test_a_case_attachment_cannot_be_deleted_once_the_case_is_closed(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->makeCustomer($tenant);
        $debt = $this->makeDebt($tenant, $customer);
        $case = $this->makeCase($tenant, $debt);
        $this->actingAsTenantUser($tenant);
        $attachmentId = $this->post("/api/v1/collection-cases/{$case->id}/attachments", [
            'file' => UploadedFile::fake()->create('evidence.pdf', 100, 'application/pdf'),
        ])->json('data.id');
        CollectionCase::where('id', $case->id)->update(['case_status' => 'closed']);

        $this->deleteJson("/api/v1/collection-cases/{$case->id}/attachments/{$attachmentId}")->assertStatus(403);
        $this->assertDatabaseHas('collection_case_attachments', ['id' => $attachmentId]);
    }

    public function test_deleting_another_tenants_case_attachment_is_rejected(): void
    {
        $tenantA = Tenant::create(['business_name' => 'Acme Co']);
        $tenantB = Tenant::create(['business_name' => 'Other Co']);
        $customerB = $this->makeCustomer($tenantB);
        $debtB = $this->makeDebt($tenantB, $customerB);
        $caseB = $this->makeCase($tenantB, $debtB);
        $this->actingAsTenantUser($tenantB);
        $attachmentId = $this->post("/api/v1/collection-cases/{$caseB->id}/attachments", [
            'file' => UploadedFile::fake()->create('evidence.pdf', 100, 'application/pdf'),
        ])->json('data.id');

        $this->switchToTenantUser($tenantA);

        $this->deleteJson("/api/v1/collection-cases/{$caseB->id}/attachments/{$attachmentId}")->assertStatus(404);
    }

    // --- Storage quota accounting ---

    public function test_attachment_file_size_counts_toward_the_tenants_storage_usage(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $customer = $this->makeCustomer($tenant);
        $this->actingAsTenantUser($tenant);

        $before = $this->getJson('/api/v1/documents/storage-usage')->json('data.used_bytes');

        $this->post("/api/v1/customers/{$customer->id}/attachments", [
            'file' => UploadedFile::fake()->create('doc.pdf', 100, 'application/pdf'),
        ])->assertStatus(201);

        $after = $this->getJson('/api/v1/documents/storage-usage')->json('data.used_bytes');

        $this->assertGreaterThan($before, $after);
    }
}
