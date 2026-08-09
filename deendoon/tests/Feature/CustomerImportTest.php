<?php

namespace Tests\Feature;

use App\Models\Customer;
use App\Models\SubscriptionPlan;
use App\Models\Tenant;
use App\Models\TenantSubscription;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Database\Seeders\SubscriptionPlanSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use PhpOffice\PhpSpreadsheet\Spreadsheet;
use PhpOffice\PhpSpreadsheet\Writer\Xlsx;
use Tests\TestCase;

class CustomerImportTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RoleSeeder::class);
        // Backend Completion Roadmap (Phase 4.1, Product Owner review
        // 2026-08-06): import commit now enforces the same fail-closed
        // customer limit as direct creation — every tenant here needs
        // the Free Plan (limit 2) resolvable.
        $this->seed(SubscriptionPlanSeeder::class);
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

    /**
     * @param  array<int, array<int, mixed>>  $rows
     */
    private function makeExcelFile(array $rows, string $filename = 'customers.xlsx'): UploadedFile
    {
        $spreadsheet = new Spreadsheet;
        $sheet = $spreadsheet->getActiveSheet();
        $sheet->fromArray(['name', 'phone', 'credit_limit'], null, 'A1');
        $sheet->fromArray($rows, null, 'A2');

        $path = tempnam(sys_get_temp_dir(), 'import').'.xlsx';
        (new Xlsx($spreadsheet))->save($path);

        return new UploadedFile($path, $filename, null, null, true);
    }

    // --- Upload / Preview ---

    public function test_admin_can_upload_and_preview_a_valid_import_file(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $file = $this->makeExcelFile([
            ['Jane Trader', '254711111111', 1000],
            ['John Vendor', '254722222222', 2000],
        ]);

        $response = $this->postJson('/api/v1/customers/import', ['file' => $file]);

        $response->assertStatus(201)
            ->assertJson(['success' => true])
            ->assertJsonPath('data.status', 'preview')
            ->assertJsonCount(2, 'data.rows');

        $this->assertDatabaseHas('import_batches', ['tenant_id' => $tenant->id, 'status' => 'preview']);
        $this->assertDatabaseCount('import_rows', 2);
    }

    public function test_import_flags_rows_missing_required_fields_as_invalid(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $file = $this->makeExcelFile([
            ['', '254711111111', 1000],
            ['Valid Person', '254722222222', 2000],
        ]);

        $response = $this->postJson('/api/v1/customers/import', ['file' => $file]);

        $response->assertStatus(201);
        $rows = collect($response->json('data.rows'));

        $this->assertSame('invalid', $rows->firstWhere('row_number', 1)['validation_status']);
        $this->assertSame('valid', $rows->firstWhere('row_number', 2)['validation_status']);
    }

    public function test_import_requires_credit_limit_per_row(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $file = $this->makeExcelFile([
            ['No Limit Person', '254711111111', null],
        ]);

        $response = $this->postJson('/api/v1/customers/import', ['file' => $file]);

        $rows = collect($response->json('data.rows'));
        $this->assertSame('invalid', $rows->first()['validation_status']);
    }

    public function test_import_flags_a_duplicate_phone_match(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        Customer::factory()->for($tenant, 'tenant')->create(['phone' => '254711111111']);
        $this->actingAsTenantUser($tenant);

        $file = $this->makeExcelFile([
            ['Existing Person', '254711111111', 1000],
        ]);

        $response = $this->postJson('/api/v1/customers/import', ['file' => $file]);

        $rows = collect($response->json('data.rows'));
        $this->assertNotNull($rows->first()['duplicate_match']);
    }

    public function test_import_rejects_an_unsupported_file_format(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $file = UploadedFile::fake()->create('notes.txt', 10, 'text/plain');

        $response = $this->postJson('/api/v1/customers/import', ['file' => $file]);

        $response->assertStatus(422);
        $this->assertDatabaseCount('import_batches', 0);
    }

    public function test_import_requires_a_file(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $this->postJson('/api/v1/customers/import', [])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['file']);
    }

    public function test_import_batch_is_scoped_to_the_uploaders_tenant(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $file = $this->makeExcelFile([['Jane Trader', '254711111111', 1000]]);
        $this->postJson('/api/v1/customers/import', ['file' => $file]);

        $this->assertDatabaseHas('import_batches', ['tenant_id' => $tenant->id]);
    }

    // --- Commit ---

    public function test_commit_creates_new_customers_for_valid_non_duplicate_rows(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $file = $this->makeExcelFile([['Jane Trader', '254711111111', 1000]]);
        $batchId = $this->postJson('/api/v1/customers/import', ['file' => $file])->json('data.batch_id');

        $response = $this->postJson("/api/v1/customers/import/{$batchId}/commit", ['resolutions' => []]);

        $response->assertStatus(200)->assertJsonPath('data.status', 'committed');
        $this->assertDatabaseHas('customers', ['tenant_id' => $tenant->id, 'name' => 'Jane Trader']);
    }

    public function test_commit_skips_invalid_rows_regardless_of_submitted_resolution(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $file = $this->makeExcelFile([['', '254711111111', 1000]]);
        $batchId = $this->postJson('/api/v1/customers/import', ['file' => $file])->json('data.batch_id');

        $response = $this->postJson("/api/v1/customers/import/{$batchId}/commit", [
            'resolutions' => [['row_number' => 1, 'resolution' => 'new']],
        ]);

        $response->assertStatus(200)->assertJsonPath('data.results.0.outcome', 'skipped_invalid');
        $this->assertDatabaseCount('customers', 0);
    }

    public function test_commit_updates_existing_customer_when_resolution_is_update(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $existing = Customer::factory()->for($tenant, 'tenant')->create([
            'name' => 'Old Name', 'phone' => '254711111111', 'credit_limit' => 500,
        ]);
        $this->actingAsTenantUser($tenant);

        $file = $this->makeExcelFile([['New Name', '254711111111', 900]]);
        $batchId = $this->postJson('/api/v1/customers/import', ['file' => $file])->json('data.batch_id');

        $response = $this->postJson("/api/v1/customers/import/{$batchId}/commit", [
            'resolutions' => [['row_number' => 1, 'resolution' => 'update']],
        ]);

        $response->assertStatus(200)->assertJsonPath('data.results.0.outcome', 'updated');
        $this->assertSame('New Name', $existing->fresh()->name);
        $this->assertSame('900.00', $existing->fresh()->credit_limit);
        $this->assertSame(1, Customer::count());
    }

    public function test_commit_skips_the_update_resolution_when_the_matched_customer_is_read_only(): void
    {
        // Backend Completion Roadmap (Phase 4.5 — Final Verification
        // fix): this "update" resolution previously bypassed
        // is_read_only entirely, a write path CustomerPolicy::update()
        // would have rejected for a direct edit.
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $existing = Customer::factory()->for($tenant, 'tenant')->create([
            'name' => 'Old Name', 'phone' => '254711111111', 'credit_limit' => 500,
        ]);
        Customer::where('id', $existing->id)->update(['is_read_only' => true]);
        $this->actingAsTenantUser($tenant);

        $file = $this->makeExcelFile([['New Name', '254711111111', 900]]);
        $batchId = $this->postJson('/api/v1/customers/import', ['file' => $file])->json('data.batch_id');

        $response = $this->postJson("/api/v1/customers/import/{$batchId}/commit", [
            'resolutions' => [['row_number' => 1, 'resolution' => 'update']],
        ]);

        $response->assertStatus(200)->assertJsonPath('data.results.0.outcome', 'skipped_read_only');
        $this->assertSame('Old Name', $existing->fresh()->name);
        $this->assertSame('500.00', $existing->fresh()->credit_limit);
    }

    public function test_commit_creates_a_new_customer_when_resolution_is_new_despite_a_duplicate_match(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        Customer::factory()->for($tenant, 'tenant')->create(['phone' => '254711111111']);
        $this->actingAsTenantUser($tenant);

        $file = $this->makeExcelFile([['Someone New', '254711111111', 900]]);
        $batchId = $this->postJson('/api/v1/customers/import', ['file' => $file])->json('data.batch_id');

        $this->postJson("/api/v1/customers/import/{$batchId}/commit", [
            'resolutions' => [['row_number' => 1, 'resolution' => 'new']],
        ])->assertStatus(200)->assertJsonPath('data.results.0.outcome', 'created');

        $this->assertSame(2, Customer::count());
    }

    public function test_commit_defaults_to_skip_when_a_duplicate_row_has_no_submitted_resolution(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        Customer::factory()->for($tenant, 'tenant')->create(['phone' => '254711111111']);
        $this->actingAsTenantUser($tenant);

        $file = $this->makeExcelFile([['Someone', '254711111111', 900]]);
        $batchId = $this->postJson('/api/v1/customers/import', ['file' => $file])->json('data.batch_id');

        $response = $this->postJson("/api/v1/customers/import/{$batchId}/commit", ['resolutions' => []]);

        $response->assertStatus(200)->assertJsonPath('data.results.0.outcome', 'skipped');
        $this->assertSame(1, Customer::count());
    }

    // --- Customer limit enforcement (Product Owner Decision, 2026-08-06) ---

    public function test_commit_skips_a_new_row_that_would_exceed_the_customer_limit(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        // Free Plan limit is 2 (seeded in setUp()).
        Customer::factory()->for($tenant, 'tenant')->count(2)->create();
        $this->actingAsTenantUser($tenant);

        $file = $this->makeExcelFile([['Overflow Person', '254711111111', 1000]]);
        $batchId = $this->postJson('/api/v1/customers/import', ['file' => $file])->json('data.batch_id');

        $response = $this->postJson("/api/v1/customers/import/{$batchId}/commit", ['resolutions' => []]);

        $response->assertStatus(200)->assertJsonPath('data.results.0.outcome', 'skipped_limit_reached');
        $this->assertSame(2, Customer::count());
    }

    public function test_commit_creates_rows_up_to_the_limit_then_skips_the_rest(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        Customer::factory()->for($tenant, 'tenant')->create();
        $this->actingAsTenantUser($tenant);

        $file = $this->makeExcelFile([
            ['Person One', '254711111111', 1000],
            ['Person Two', '254722222222', 1000],
        ]);
        $batchId = $this->postJson('/api/v1/customers/import', ['file' => $file])->json('data.batch_id');

        $response = $this->postJson("/api/v1/customers/import/{$batchId}/commit", ['resolutions' => []]);

        $response->assertStatus(200)
            ->assertJsonPath('data.results.0.outcome', 'created')
            ->assertJsonPath('data.results.1.outcome', 'skipped_limit_reached');
        $this->assertSame(2, Customer::count());
    }

    public function test_commit_triggers_recalculation_so_the_created_row_is_correctly_editable(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        Customer::factory()->for($tenant, 'tenant')->create();
        $this->actingAsTenantUser($tenant);

        $file = $this->makeExcelFile([['New Person', '254711111111', 1000]]);
        $batchId = $this->postJson('/api/v1/customers/import', ['file' => $file])->json('data.batch_id');
        $response = $this->postJson("/api/v1/customers/import/{$batchId}/commit", ['resolutions' => []]);

        $customerId = $response->json('data.results.0.customer_id');
        $this->assertFalse(Customer::find($customerId)->is_read_only);
    }

    public function test_commit_is_unrestricted_on_an_unlimited_plan(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $unlimited = SubscriptionPlan::factory()->create(['name' => 'Unlimited Test Plan', 'customer_limit' => null]);
        TenantSubscription::factory()->for($tenant, 'tenant')->for($unlimited, 'plan')->active()->create();
        Customer::factory()->for($tenant, 'tenant')->count(5)->create();
        $this->actingAsTenantUser($tenant);

        $file = $this->makeExcelFile([['Sixth Person', '254711111111', 1000]]);
        $batchId = $this->postJson('/api/v1/customers/import', ['file' => $file])->json('data.batch_id');

        $response = $this->postJson("/api/v1/customers/import/{$batchId}/commit", ['resolutions' => []]);

        $response->assertStatus(200)->assertJsonPath('data.results.0.outcome', 'created');
        $this->assertSame(6, Customer::count());
    }

    public function test_commit_records_audit_events(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $file = $this->makeExcelFile([['Jane Trader', '254711111111', 1000]]);
        $batchId = $this->postJson('/api/v1/customers/import', ['file' => $file])->json('data.batch_id');
        $this->postJson("/api/v1/customers/import/{$batchId}/commit", ['resolutions' => []]);

        $customerId = Customer::first()->id;
        $this->assertDatabaseHas('audit_log', [
            'entity_type' => 'customer',
            'entity_id' => $customerId,
            'action' => 'created',
        ]);
    }

    public function test_committing_an_already_committed_batch_is_rejected(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $file = $this->makeExcelFile([['Jane Trader', '254711111111', 1000]]);
        $batchId = $this->postJson('/api/v1/customers/import', ['file' => $file])->json('data.batch_id');
        $this->postJson("/api/v1/customers/import/{$batchId}/commit", ['resolutions' => []])->assertStatus(200);

        $response = $this->postJson("/api/v1/customers/import/{$batchId}/commit", ['resolutions' => []]);

        $response->assertStatus(422)->assertJson(['success' => false]);
    }

    // --- Authentication / Authorization ---

    public function test_unauthenticated_import_requests_are_rejected(): void
    {
        $file = $this->makeExcelFile([['Jane Trader', '254711111111', 1000]]);

        $this->postJson('/api/v1/customers/import', ['file' => $file])->assertStatus(401);
    }

    public function test_user_without_admin_role_cannot_import(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant, null);

        $file = $this->makeExcelFile([['Jane Trader', '254711111111', 1000]]);

        $this->postJson('/api/v1/customers/import', ['file' => $file])->assertStatus(403);
    }

    // --- Template download (P2.1) ---

    public function test_admin_can_download_the_sample_import_template(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $response = $this->get('/api/v1/customers/import/template');

        $response->assertStatus(200);
        $response->assertHeader(
            'content-type',
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        );
    }

    public function test_unauthenticated_template_download_is_rejected(): void
    {
        $this->getJson('/api/v1/customers/import/template')->assertStatus(401);
    }

    public function test_user_without_admin_role_cannot_download_the_template(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant, null);

        $this->getJson('/api/v1/customers/import/template')->assertStatus(403);
    }
}
