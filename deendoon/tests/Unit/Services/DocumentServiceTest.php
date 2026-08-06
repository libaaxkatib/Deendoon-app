<?php

namespace Tests\Unit\Services;

use App\Models\Customer;
use App\Models\Debt;
use App\Models\DemandLetter;
use App\Models\Invoice;
use App\Models\Payment;
use App\Models\Receipt;
use App\Models\Statement;
use App\Models\StorageAddon;
use App\Models\SubscriptionPlan;
use App\Models\Tenant;
use App\Models\TenantSubscription;
use App\Services\DocumentService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

/**
 * Backend Completion Roadmap, Phase 4.2 — Storage Limit Enforcement.
 * Direct coverage of DocumentService::storageUsage() (the single source
 * of truth for current usage) and assertCanUpload() (the enforcement
 * check: "If Usage >= Allowance: Reject upload").
 */
class DocumentServiceTest extends TestCase
{
    use RefreshDatabase;

    private const GB = 1024 ** 3;

    protected function setUp(): void
    {
        parent::setUp();

        Storage::fake('local');
    }

    private function service(): DocumentService
    {
        return app(DocumentService::class);
    }

    private function tenant(): Tenant
    {
        return Tenant::create(['business_name' => 'Acme Co']);
    }

    private function subscribe(Tenant $tenant, ?int $storageLimitGb): SubscriptionPlan
    {
        $plan = SubscriptionPlan::factory()->create(['storage_limit' => $storageLimitGb]);
        TenantSubscription::factory()->for($tenant, 'tenant')->for($plan, 'plan')->active()->create();

        return $plan;
    }

    private function debt(Tenant $tenant): Debt
    {
        $customer = Customer::factory()->for($tenant, 'tenant')->create();

        return Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create();
    }

    private function invoiceOfSize(Tenant $tenant, int $bytes): Invoice
    {
        return Invoice::factory()->for($tenant, 'tenant')->for($this->debt($tenant), 'debt')->create(['file_size' => $bytes]);
    }

    // --- storageUsage(): the four document tables ---

    public function test_storage_usage_sums_all_four_document_tables(): void
    {
        $tenant = $this->tenant();
        $debtA = $this->debt($tenant);
        $payment = Payment::factory()->for($tenant, 'tenant')->for($debtA, 'debt')->create();
        Receipt::factory()->for($tenant, 'tenant')->for($payment, 'payment')->create(['file_size' => 100]);
        DemandLetter::factory()->for($tenant, 'tenant')->for($this->debt($tenant), 'debt')->create(['file_size' => 200]);
        Statement::factory()->for($tenant, 'tenant')->for(Customer::factory()->for($tenant, 'tenant'), 'customer')->create(['file_size' => 300]);
        $this->invoiceOfSize($tenant, 400);

        $usage = $this->service()->storageUsage($tenant);

        $this->assertSame(1000, $usage['used_bytes']);
    }

    public function test_storage_usage_is_zero_for_a_tenant_with_no_documents(): void
    {
        $tenant = $this->tenant();

        $this->assertSame(0, $this->service()->storageUsage($tenant)['used_bytes']);
    }

    public function test_storage_usage_includes_the_company_logo_read_from_disk(): void
    {
        $tenant = $this->tenant();
        Storage::disk('local')->put("branding/{$tenant->id}/logo.png", str_repeat('a', 500));
        $tenant->logo_path = "branding/{$tenant->id}/logo.png";
        $tenant->save();

        $usage = $this->service()->storageUsage($tenant->fresh());

        $this->assertSame(500, $usage['used_bytes']);
    }

    public function test_storage_usage_logo_bytes_are_zero_when_no_logo_is_set(): void
    {
        $tenant = $this->tenant();

        $this->assertSame(0, $this->service()->storageUsage($tenant)['used_bytes']);
    }

    public function test_storage_usage_logo_bytes_are_zero_when_the_path_is_set_but_the_file_is_missing(): void
    {
        $tenant = $this->tenant();
        $tenant->logo_path = "branding/{$tenant->id}/logo.png";
        $tenant->save();

        $this->assertSame(0, $this->service()->storageUsage($tenant->fresh())['used_bytes']);
    }

    public function test_storage_usage_only_reflects_the_given_tenants_documents(): void
    {
        $tenantA = $this->tenant();
        $tenantB = Tenant::create(['business_name' => 'Other Co']);
        $this->invoiceOfSize($tenantA, 999);

        $this->assertSame(0, $this->service()->storageUsage($tenantB)['used_bytes']);
    }

    // --- assertCanUpload(): boundary conditions ---

    public function test_assert_can_upload_does_not_throw_when_well_under_the_allowance(): void
    {
        $tenant = $this->tenant();
        $this->subscribe($tenant, 10);

        $this->service()->assertCanUpload($tenant);

        $this->assertTrue(true);
    }

    public function test_assert_can_upload_throws_when_usage_is_exactly_at_the_allowance(): void
    {
        $tenant = $this->tenant();
        $this->subscribe($tenant, 10);
        $this->invoiceOfSize($tenant, 10 * self::GB);

        $this->expectException(HttpResponseException::class);

        $this->service()->assertCanUpload($tenant);
    }

    public function test_assert_can_upload_does_not_throw_when_one_byte_under_the_allowance(): void
    {
        $tenant = $this->tenant();
        $this->subscribe($tenant, 10);
        $this->invoiceOfSize($tenant, 10 * self::GB - 1);

        $this->service()->assertCanUpload($tenant);

        $this->assertTrue(true);
    }

    public function test_assert_can_upload_throws_when_one_byte_over_the_allowance(): void
    {
        $tenant = $this->tenant();
        $this->subscribe($tenant, 10);
        $this->invoiceOfSize($tenant, 10 * self::GB + 1);

        $this->expectException(HttpResponseException::class);

        $this->service()->assertCanUpload($tenant);
    }

    // --- Base plan limits: 10 / 25 / 50 / 100 GB ---

    public function test_25gb_plan_allows_upload_under_its_limit(): void
    {
        $tenant = $this->tenant();
        $this->subscribe($tenant, 25);
        $this->invoiceOfSize($tenant, 24 * self::GB);

        $this->service()->assertCanUpload($tenant);

        $this->assertTrue(true);
    }

    public function test_50gb_plan_blocks_upload_at_its_limit(): void
    {
        $tenant = $this->tenant();
        $this->subscribe($tenant, 50);
        $this->invoiceOfSize($tenant, 50 * self::GB);

        $this->expectException(HttpResponseException::class);

        $this->service()->assertCanUpload($tenant);
    }

    public function test_100gb_plan_blocks_upload_at_its_limit(): void
    {
        $tenant = $this->tenant();
        $this->subscribe($tenant, 100);
        $this->invoiceOfSize($tenant, 100 * self::GB);

        $this->expectException(HttpResponseException::class);

        $this->service()->assertCanUpload($tenant);
    }

    // --- Storage add-on combinations ---

    public function test_active_storage_addons_are_added_to_the_base_plan_allowance(): void
    {
        $tenant = $this->tenant();
        $this->subscribe($tenant, 10);
        StorageAddon::factory()->for($tenant, 'tenant')->active()->create(['storage_size' => 25]);
        StorageAddon::factory()->for($tenant, 'tenant')->active()->create(['storage_size' => 50]);
        // 10 + 25 + 50 = 85 GB allowance.
        $this->invoiceOfSize($tenant, 84 * self::GB);

        $this->service()->assertCanUpload($tenant);
        $this->assertTrue(true);
    }

    public function test_storage_addon_combination_blocks_upload_once_the_combined_allowance_is_reached(): void
    {
        $tenant = $this->tenant();
        $this->subscribe($tenant, 10);
        StorageAddon::factory()->for($tenant, 'tenant')->active()->create(['storage_size' => 25]);
        StorageAddon::factory()->for($tenant, 'tenant')->active()->create(['storage_size' => 50]);
        // 10 + 25 + 50 = 85 GB allowance, exactly reached.
        $this->invoiceOfSize($tenant, 85 * self::GB);

        $this->expectException(HttpResponseException::class);

        $this->service()->assertCanUpload($tenant);
    }

    public function test_pending_storage_addons_do_not_count_toward_the_allowance(): void
    {
        $tenant = $this->tenant();
        $this->subscribe($tenant, 10);
        StorageAddon::factory()->for($tenant, 'tenant')->create(['storage_size' => 100, 'status' => 'pending']);
        $this->invoiceOfSize($tenant, 10 * self::GB);

        // Still only the 10GB base plan — the pending 100GB add-on must not count.
        $this->expectException(HttpResponseException::class);

        $this->service()->assertCanUpload($tenant);
    }

    // --- Fail closed ---

    public function test_assert_can_upload_fails_closed_with_no_resolvable_plan(): void
    {
        $tenant = $this->tenant();

        $this->expectException(HttpResponseException::class);

        $this->service()->assertCanUpload($tenant);
    }

    // --- Tenant isolation ---

    public function test_assert_can_upload_only_evaluates_the_given_tenant(): void
    {
        $tenantA = $this->tenant();
        $tenantB = Tenant::create(['business_name' => 'Other Co']);
        $this->subscribe($tenantA, 10);
        $this->subscribe($tenantB, 10);
        $this->invoiceOfSize($tenantA, 10 * self::GB);

        // Tenant A is at its limit; Tenant B is untouched and unaffected.
        $this->service()->assertCanUpload($tenantB);
        $this->assertTrue(true);
    }
}
