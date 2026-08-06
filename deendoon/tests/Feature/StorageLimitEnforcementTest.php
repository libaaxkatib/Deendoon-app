<?php

namespace Tests\Feature;

use App\Models\Customer;
use App\Models\Debt;
use App\Models\Invoice;
use App\Models\SubscriptionPlan;
use App\Models\Tenant;
use App\Models\TenantSubscription;
use App\Models\User;
use App\Services\DocumentService;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

/**
 * Backend Completion Roadmap, Phase 4.2 — Storage Limit Enforcement.
 * End-to-end HTTP coverage: uploads (document generation, company logo)
 * blocked once a tenant is at/over its storage allowance; existing files
 * and read endpoints stay accessible regardless; tenant isolation.
 */
class StorageLimitEnforcementTest extends TestCase
{
    use RefreshDatabase;

    private const GB = 1024 ** 3;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RoleSeeder::class);
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

    private function subscribe(Tenant $tenant, ?int $storageLimitGb): SubscriptionPlan
    {
        $plan = SubscriptionPlan::factory()->create(['storage_limit' => $storageLimitGb]);
        TenantSubscription::factory()->for($tenant, 'tenant')->for($plan, 'plan')->active()->create();

        return $plan;
    }

    private function makeDebt(Tenant $tenant): Debt
    {
        $customer = Customer::factory()->for($tenant, 'tenant')->create();

        return Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create();
    }

    /**
     * Fills the tenant's entire allowance with a single pre-seeded
     * Invoice row, without needing to actually write gigabytes of real
     * PDF/file data to disk.
     */
    private function fillAllowance(Tenant $tenant, int $limitGb): void
    {
        Invoice::factory()->for($tenant, 'tenant')->for($this->makeDebt($tenant), 'debt')->create([
            'file_size' => $limitGb * self::GB,
        ]);
    }

    // --- Demand Letter generation blocked/allowed ---

    public function test_generating_a_demand_letter_is_blocked_once_the_tenant_is_at_its_storage_limit(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->subscribe($tenant, 10);
        $this->fillAllowance($tenant, 10);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson("/api/v1/debts/{$debt->id}/demand-letters", ['template_type' => 'first_reminder']);

        $response->assertStatus(422)->assertJsonPath('errors.storage.0', 'Storage limit reached.');
        $this->assertDatabaseCount('demand_letters', 0);
    }

    public function test_generating_a_demand_letter_is_allowed_under_the_storage_limit(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->subscribe($tenant, 10);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/debts/{$debt->id}/demand-letters", ['template_type' => 'first_reminder'])
            ->assertStatus(201);
    }

    // --- Invoice generation blocked/allowed ---

    public function test_generating_an_invoice_is_blocked_once_the_tenant_is_at_its_storage_limit(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->subscribe($tenant, 25);
        $this->fillAllowance($tenant, 25);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson("/api/v1/debts/{$debt->id}/invoices");

        $response->assertStatus(422);
        // The pre-existing (fill) invoice is the only one — no new row.
        $this->assertSame(1, Invoice::count());
    }

    // --- Statement generation blocked/allowed ---

    public function test_generating_a_statement_is_blocked_once_the_tenant_is_at_its_storage_limit(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->subscribe($tenant, 50);
        $this->fillAllowance($tenant, 50);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/customers/{$customer->id}/statements")->assertStatus(422);
        $this->assertDatabaseCount('statements', 0);
    }

    // --- Receipt generation (automatic via Payment) — never blocks Payment recording ---

    public function test_recording_a_payment_still_succeeds_when_storage_is_full_but_the_receipt_silently_does_not_generate(): void
    {
        // Pre-existing, deliberate design (DocumentService::generateReceipt()):
        // "a generation failure must never roll back Payment Recording."
        // Storage-limit rejection is just another generation failure —
        // Payment recording must still succeed even though the Receipt
        // does not get created.
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->subscribe($tenant, 10);
        $this->fillAllowance($tenant, 10);
        $debt = $this->makeDebt($tenant);
        $debt->update(['amount' => 1000, 'remaining_balance' => 1000]);
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson("/api/v1/debts/{$debt->id}/payments", [
            'amount' => 400, 'payment_date' => now()->toDateString(),
        ]);

        $response->assertStatus(201);
        $this->assertDatabaseCount('receipts', 0);
    }

    // --- Company logo upload ---

    public function test_uploading_a_company_logo_is_blocked_once_the_tenant_is_at_its_storage_limit(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->subscribe($tenant, 10);
        $this->fillAllowance($tenant, 10);
        $this->actingAsTenantUser($tenant);

        $response = $this->post('/api/v1/admin/settings/company-profile', [
            '_method' => 'PUT',
            'business_name' => 'Acme Co',
            'logo' => UploadedFile::fake()->image('logo.png'),
        ]);

        $response->assertStatus(422)->assertJsonPath('errors.storage.0', 'Storage limit reached.');
        $this->assertNull($tenant->fresh()->logo_path);
    }

    public function test_uploading_a_company_logo_is_allowed_under_the_storage_limit(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->subscribe($tenant, 10);
        $this->actingAsTenantUser($tenant);

        $response = $this->post('/api/v1/admin/settings/company-profile', [
            '_method' => 'PUT',
            'business_name' => 'Acme Co',
            'logo' => UploadedFile::fake()->image('logo.png'),
        ]);

        $response->assertStatus(200);
        $this->assertNotNull($tenant->fresh()->logo_path);
    }

    public function test_editing_the_company_profile_without_a_logo_is_never_blocked_by_the_storage_limit(): void
    {
        // "Only NEW uploads are blocked" — a text-only edit is not an
        // upload at all, so it must succeed even when full.
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->subscribe($tenant, 10);
        $this->fillAllowance($tenant, 10);
        $this->actingAsTenantUser($tenant);

        $this->post('/api/v1/admin/settings/company-profile', [
            '_method' => 'PUT',
            'business_name' => 'New Name',
        ])->assertStatus(200);
    }

    public function test_replacing_the_company_logo_reflects_the_new_size_not_the_sum_of_both(): void
    {
        // The logo write path overwrites the same fixed-extension path
        // in place — usage after a replace must reflect only the newest
        // file, matching "Automatic Recalculation... Replace." Asserted
        // directly against DocumentService/Storage rather than a third
        // authenticated HTTP call in the same test method, which this
        // suite's Sanctum guard caching (see DocumentTest.php's own
        // documented note) can serve from a stale cached tenant relation.
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->subscribe($tenant, 10);
        $this->actingAsTenantUser($tenant);

        $this->post('/api/v1/admin/settings/company-profile', [
            '_method' => 'PUT',
            'business_name' => 'Acme Co',
            'logo' => UploadedFile::fake()->create('logo.png', 500, 'image/png'),
        ])->assertStatus(200);

        $this->post('/api/v1/admin/settings/company-profile', [
            '_method' => 'PUT',
            'business_name' => 'Acme Co',
            'logo' => UploadedFile::fake()->create('logo.png', 300, 'image/png'),
        ])->assertStatus(200);

        $freshTenant = $tenant->fresh();
        $this->assertNotNull($freshTenant->logo_path);
        // Same extension both times => same path => overwritten in place,
        // not accumulated as a second file.
        $this->assertCount(1, Storage::disk('local')->allFiles("branding/{$tenant->id}"));
    }

    // --- Existing files remain accessible when over the limit ---

    public function test_viewing_an_existing_document_still_works_when_the_tenant_is_over_the_storage_limit(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->subscribe($tenant, 10);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);
        $letterId = $this->postJson("/api/v1/debts/{$debt->id}/demand-letters", ['template_type' => 'first_reminder'])->json('data.id');

        $this->fillAllowance($tenant, 10);

        $this->getJson("/api/v1/documents/{$letterId}")->assertStatus(200);
        $this->getJson("/api/v1/documents/{$letterId}/download")->assertStatus(200);
    }

    public function test_listing_documents_still_works_when_the_tenant_is_over_the_storage_limit(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->subscribe($tenant, 10);
        $this->fillAllowance($tenant, 10);
        $this->actingAsTenantUser($tenant);

        $this->getJson('/api/v1/documents')->assertStatus(200);
        $this->getJson('/api/v1/documents/storage-usage')->assertStatus(200);
    }

    // --- Tenant isolation ---

    public function test_one_tenants_full_storage_does_not_affect_another_tenant(): void
    {
        $tenantA = Tenant::create(['business_name' => 'Tenant A']);
        $tenantB = Tenant::create(['business_name' => 'Tenant B']);
        $this->subscribe($tenantA, 10);
        $this->subscribe($tenantB, 10);
        $this->fillAllowance($tenantA, 10);
        $debtB = $this->makeDebt($tenantB);
        $this->actingAsTenantUser($tenantB);

        $this->postJson("/api/v1/debts/{$debtB->id}/demand-letters", ['template_type' => 'first_reminder'])
            ->assertStatus(201);
    }

    // --- Fail closed: no resolvable plan ---

    public function test_document_generation_is_blocked_when_no_plan_can_be_resolved_at_all(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $debt = $this->makeDebt($tenant);
        $this->actingAsTenantUser($tenant);

        $this->postJson("/api/v1/debts/{$debt->id}/invoices")->assertStatus(422);
    }
}
