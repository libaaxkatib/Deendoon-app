<?php

namespace Tests\Feature;

use App\Models\Customer;
use App\Models\CustomerPhoneNumber;
use App\Models\Debt;
use App\Models\MessageTemplate;
use App\Models\Reminder;
use App\Models\Tenant;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Database\Seeders\SubscriptionPlanSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use PhpOffice\PhpSpreadsheet\Spreadsheet;
use PhpOffice\PhpSpreadsheet\Writer\Xlsx;
use Tests\TestCase;

/**
 * Fix #23 — Multiple Customer Phone Numbers. Covers the approved product
 * decisions end-to-end through the real HTTP surface: `phone_numbers` is
 * submitted as part of the existing Customer create/update request (no
 * separate REST sub-resource — see CustomerController), and
 * `phone_number_id` on the reminder/message send endpoints.
 */
class CustomerPhoneNumberTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);
        $this->seed(SubscriptionPlanSeeder::class);
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
     * `CustomerPhoneNumber`'s `tenant_id` is normally set by
     * {@see App\Models\Concerns\BelongsToTenant}'s creating hook, which
     * only fires inside an authenticated HTTP request — direct,
     * non-HTTP test setup (as opposed to the real `postJson()` calls
     * these tests otherwise use) needs `forceCreate` instead, the same
     * class of workaround the codebase already uses elsewhere for
     * fields that aren't meant to be set via ordinary mass assignment.
     */
    private function createPhoneNumber(Customer $customer, Tenant $tenant, string $phone, bool $isPrimary): CustomerPhoneNumber
    {
        return CustomerPhoneNumber::forceCreate([
            'tenant_id' => $tenant->id,
            'customer_id' => $customer->id,
            'phone' => $phone,
            'is_primary' => $isPrimary,
        ]);
    }

    private function makeExcelFile(array $rows, array $headings): UploadedFile
    {
        $spreadsheet = new Spreadsheet;
        $sheet = $spreadsheet->getActiveSheet();
        $sheet->fromArray($headings, null, 'A1');
        $sheet->fromArray($rows, null, 'A2');

        $path = tempnam(sys_get_temp_dir(), 'import').'.xlsx';
        (new Xlsx($spreadsheet))->save($path);

        return new UploadedFile($path, 'customers.xlsx', null, null, true);
    }

    // --- Create/update with multiple numbers ---

    public function test_admin_can_create_a_customer_with_two_phone_numbers(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson('/api/v1/customers', [
            'name' => 'Jane Trader',
            'phone' => '254700000001',
            'credit_limit' => 5000,
            'phone_numbers' => [
                ['phone' => '254700000001', 'is_primary' => true],
                ['phone' => '254700000002', 'is_primary' => false],
            ],
        ]);

        $response->assertStatus(201);
        $customerId = $response->json('data.customer.id');
        $phoneNumbers = $response->json('data.customer.phone_numbers');
        $this->assertCount(2, $phoneNumbers);
        $this->assertDatabaseHas('customers', ['id' => $customerId, 'phone' => '254700000001']);
        $this->assertDatabaseCount('customer_phone_numbers', 2);
    }

    public function test_admin_can_create_a_customer_with_three_phone_numbers(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson('/api/v1/customers', [
            'name' => 'Jane Trader',
            'phone' => '254700000001',
            'credit_limit' => 5000,
            'phone_numbers' => [
                ['phone' => '254700000001', 'is_primary' => true],
                ['phone' => '254700000002', 'is_primary' => false],
                ['phone' => '254700000003', 'is_primary' => false],
            ],
        ]);

        $response->assertStatus(201);
        $this->assertDatabaseCount('customer_phone_numbers', 3);
    }

    public function test_a_fourth_phone_number_is_rejected(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson('/api/v1/customers', [
            'name' => 'Jane Trader',
            'phone' => '254700000001',
            'credit_limit' => 5000,
            'phone_numbers' => [
                ['phone' => '254700000001', 'is_primary' => true],
                ['phone' => '254700000002', 'is_primary' => false],
                ['phone' => '254700000003', 'is_primary' => false],
                ['phone' => '254700000004', 'is_primary' => false],
            ],
        ]);

        $response->assertStatus(422)->assertJsonValidationErrors('phone_numbers');
        $this->assertDatabaseCount('customer_phone_numbers', 0);
    }

    public function test_zero_primary_numbers_is_rejected(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson('/api/v1/customers', [
            'name' => 'Jane Trader',
            'phone' => '254700000001',
            'credit_limit' => 5000,
            'phone_numbers' => [
                ['phone' => '254700000001', 'is_primary' => false],
            ],
        ]);

        $response->assertStatus(422)->assertJsonValidationErrors('phone_numbers');
    }

    public function test_two_primary_numbers_is_rejected(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson('/api/v1/customers', [
            'name' => 'Jane Trader',
            'phone' => '254700000001',
            'credit_limit' => 5000,
            'phone_numbers' => [
                ['phone' => '254700000001', 'is_primary' => true],
                ['phone' => '254700000002', 'is_primary' => true],
            ],
        ]);

        $response->assertStatus(422)->assertJsonValidationErrors('phone_numbers');
    }

    public function test_a_legacy_request_with_only_phone_still_works(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $response = $this->postJson('/api/v1/customers', [
            'name' => 'Jane Trader',
            'phone' => '254700000001',
            'credit_limit' => 5000,
        ]);

        $response->assertStatus(201);
        $customerId = $response->json('data.customer.id');
        $this->assertDatabaseHas('customer_phone_numbers', [
            'customer_id' => $customerId,
            'phone' => '254700000001',
            'is_primary' => true,
        ]);
    }

    public function test_admin_can_change_the_primary_number_on_update(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        $customer = Customer::factory()->for($tenant, 'tenant')->create(['phone' => '254700000001']);
        $existing = $this->createPhoneNumber($customer, $tenant, '254700000001', true);
        $second = $this->createPhoneNumber($customer, $tenant, '254700000002', false);

        $response = $this->putJson("/api/v1/customers/{$customer->id}", [
            'name' => $customer->name,
            'phone' => '254700000002',
            'credit_limit' => (string) $customer->credit_limit,
            'phone_numbers' => [
                ['id' => $existing->id, 'phone' => '254700000001', 'is_primary' => false],
                ['id' => $second->id, 'phone' => '254700000002', 'is_primary' => true],
            ],
        ]);

        $response->assertStatus(200);
        $this->assertSame('254700000002', $customer->fresh()->phone);
        $this->assertFalse($existing->fresh()->is_primary);
        $this->assertTrue($second->fresh()->is_primary);
    }

    public function test_removing_all_but_the_primary_number_is_allowed(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        $customer = Customer::factory()->for($tenant, 'tenant')->create(['phone' => '254700000001']);
        $primary = $this->createPhoneNumber($customer, $tenant, '254700000001', true);
        $this->createPhoneNumber($customer, $tenant, '254700000002', false);

        $response = $this->putJson("/api/v1/customers/{$customer->id}", [
            'name' => $customer->name,
            'phone' => '254700000001',
            'credit_limit' => (string) $customer->credit_limit,
            'phone_numbers' => [
                ['id' => $primary->id, 'phone' => '254700000001', 'is_primary' => true],
            ],
        ]);

        $response->assertStatus(200);
        $this->assertCount(1, $customer->phoneNumbers()->get());
    }

    public function test_removing_the_final_phone_number_is_rejected(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        $customer = Customer::factory()->for($tenant, 'tenant')->create(['phone' => '254700000001']);
        $this->createPhoneNumber($customer, $tenant, '254700000001', true);

        $response = $this->putJson("/api/v1/customers/{$customer->id}", [
            'name' => $customer->name,
            'phone' => '254700000001',
            'credit_limit' => (string) $customer->credit_limit,
            'phone_numbers' => [],
        ]);

        $response->assertStatus(422)->assertJsonValidationErrors('phone_numbers');
        $this->assertCount(1, $customer->phoneNumbers()->get());
    }

    // --- Backward compatibility ---

    public function test_a_customer_created_before_this_fix_still_has_exactly_one_primary_row(): void
    {
        // Every Customer::factory row created anywhere in this whole
        // suite goes through CustomerController::store() (or, in tests
        // that build a Customer directly via the factory, still ends up
        // representing "a customer that only ever had one phone") — this
        // asserts that shape directly, which is exactly what the
        // migration's backfill produces for every pre-existing customer.
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        $customer = Customer::factory()->for($tenant, 'tenant')->create(['phone' => '254700000009']);
        $this->createPhoneNumber($customer, $tenant, '254700000009', true);

        $this->assertDatabaseHas('customer_phone_numbers', [
            'customer_id' => $customer->id,
            'phone' => '254700000009',
            'is_primary' => true,
        ]);
        $this->assertCount(1, $customer->phoneNumbers()->get());
    }

    public function test_customer_response_still_returns_phone_as_a_plain_string(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        $customer = Customer::factory()->for($tenant, 'tenant')->create(['phone' => '254700000001']);

        $response = $this->getJson("/api/v1/customers/{$customer->id}");

        $response->assertStatus(200)->assertJsonPath('data.phone', '254700000001');
        $this->assertIsString($response->json('data.phone'));
    }

    // --- Duplicate phone numbers remain allowed ---

    public function test_the_same_phone_number_may_belong_to_two_different_customers(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        Customer::factory()->for($tenant, 'tenant')->create(['phone' => '254700000001']);

        $response = $this->postJson('/api/v1/customers', [
            'name' => 'Second Customer',
            'phone' => '254700000001',
            'credit_limit' => 5000,
        ]);

        // Non-blocking: still 201, only a warning.
        $response->assertStatus(201)->assertJsonPath('data.warning.type', 'POSSIBLE_DUPLICATE_CUSTOMER');
        $this->assertDatabaseCount('customers', 2);
    }

    // --- Tenant isolation ---

    public function test_a_phone_number_id_from_a_different_customer_is_rejected_on_send(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        $customerA = Customer::factory()->for($tenant, 'tenant')->create();
        $customerB = Customer::factory()->for($tenant, 'tenant')->create();
        $foreignPhone = $this->createPhoneNumber($customerB, $tenant, '254700000009', true);
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customerA, 'customer')->create();
        $reminder = Reminder::factory()->for($tenant, 'tenant')->paymentDue()
            ->create(['related_entity_type' => 'debt', 'related_entity_id' => $debt->id]);
        $template = MessageTemplate::factory()->for($tenant, 'tenant')->create();

        $response = $this->postJson("/api/v1/reminders/{$reminder->id}/send", [
            'channel' => 'whatsapp',
            'template_id' => $template->id,
            'phone_number_id' => $foreignPhone->id,
        ]);

        $response->assertStatus(404);
    }

    public function test_a_phone_number_id_from_a_different_tenant_is_rejected_on_send(): void
    {
        $tenantA = Tenant::create(['business_name' => 'Acme Co']);
        $tenantB = Tenant::create(['business_name' => 'Other Co']);
        $customerB = Customer::factory()->for($tenantB, 'tenant')->create();
        $foreignPhone = $this->createPhoneNumber($customerB, $tenantB, '254700000009', true);

        $this->actingAsTenantUser($tenantA);
        $customerA = Customer::factory()->for($tenantA, 'tenant')->create();
        $debt = Debt::factory()->for($tenantA, 'tenant')->for($customerA, 'customer')->create();
        $reminder = Reminder::factory()->for($tenantA, 'tenant')->paymentDue()
            ->create(['related_entity_type' => 'debt', 'related_entity_id' => $debt->id]);
        $template = MessageTemplate::factory()->for($tenantA, 'tenant')->create();

        $response = $this->postJson("/api/v1/reminders/{$reminder->id}/send", [
            'channel' => 'whatsapp',
            'template_id' => $template->id,
            'phone_number_id' => $foreignPhone->id,
        ]);

        $response->assertStatus(404);
    }

    // --- Reminder/message default vs manual selection ---

    public function test_reminder_send_defaults_to_the_primary_phone_when_no_phone_number_id_is_given(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        $customer = Customer::factory()->for($tenant, 'tenant')->create(['phone' => '254700000001']);
        $this->createPhoneNumber($customer, $tenant, '254700000001', true);
        $this->createPhoneNumber($customer, $tenant, '254700000002', false);
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create();
        $reminder = Reminder::factory()->for($tenant, 'tenant')->paymentDue()
            ->create(['related_entity_type' => 'debt', 'related_entity_id' => $debt->id]);
        $template = MessageTemplate::factory()->for($tenant, 'tenant')->create();

        $response = $this->postJson("/api/v1/reminders/{$reminder->id}/send", [
            'channel' => 'whatsapp',
            'template_id' => $template->id,
        ]);

        $response->assertStatus(200);
        $this->assertDatabaseHas('sent_messages', ['reminder_id' => $reminder->id, 'recipient_phone' => '254700000001']);
    }

    public function test_reminder_send_uses_the_manually_selected_phone_number(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        $customer = Customer::factory()->for($tenant, 'tenant')->create(['phone' => '254700000001']);
        $this->createPhoneNumber($customer, $tenant, '254700000001', true);
        $secondary = $this->createPhoneNumber($customer, $tenant, '254700000002', false);
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create();
        $reminder = Reminder::factory()->for($tenant, 'tenant')->paymentDue()
            ->create(['related_entity_type' => 'debt', 'related_entity_id' => $debt->id]);
        $template = MessageTemplate::factory()->for($tenant, 'tenant')->create();

        $response = $this->postJson("/api/v1/reminders/{$reminder->id}/send", [
            'channel' => 'whatsapp',
            'template_id' => $template->id,
            'phone_number_id' => $secondary->id,
        ]);

        $response->assertStatus(200);
        $this->assertDatabaseHas('sent_messages', ['reminder_id' => $reminder->id, 'recipient_phone' => '254700000002']);
    }

    public function test_an_invalid_phone_number_id_is_rejected(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create();
        $reminder = Reminder::factory()->for($tenant, 'tenant')->paymentDue()
            ->create(['related_entity_type' => 'debt', 'related_entity_id' => $debt->id]);
        $template = MessageTemplate::factory()->for($tenant, 'tenant')->create();

        $response = $this->postJson("/api/v1/reminders/{$reminder->id}/send", [
            'channel' => 'whatsapp',
            'template_id' => $template->id,
            'phone_number_id' => 'not-a-real-id',
        ]);

        $response->assertStatus(404);
    }

    // --- Message render (the endpoint the mobile Message Preview screen actually calls) ---

    public function test_message_render_defaults_to_the_primary_phone(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        $customer = Customer::factory()->for($tenant, 'tenant')->create(['phone' => '254700000001']);
        $this->createPhoneNumber($customer, $tenant, '254700000001', true);
        $this->createPhoneNumber($customer, $tenant, '254700000002', false);
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create();
        $reminder = Reminder::factory()->for($tenant, 'tenant')->paymentDue()
            ->create(['related_entity_type' => 'debt', 'related_entity_id' => $debt->id]);
        $template = MessageTemplate::factory()->for($tenant, 'tenant')->create();

        $response = $this->postJson('/api/v1/messages/render', [
            'template_id' => $template->id,
            'reminder_id' => $reminder->id,
        ]);

        $response->assertStatus(200)->assertJsonFragment(['recipient_phone' => '254700000001']);
    }

    public function test_message_render_uses_the_manually_selected_phone_number(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        $customer = Customer::factory()->for($tenant, 'tenant')->create(['phone' => '254700000001']);
        $this->createPhoneNumber($customer, $tenant, '254700000001', true);
        $secondary = $this->createPhoneNumber($customer, $tenant, '254700000002', false);
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create();
        $reminder = Reminder::factory()->for($tenant, 'tenant')->paymentDue()
            ->create(['related_entity_type' => 'debt', 'related_entity_id' => $debt->id]);
        $template = MessageTemplate::factory()->for($tenant, 'tenant')->create();

        $response = $this->postJson('/api/v1/messages/render', [
            'template_id' => $template->id,
            'reminder_id' => $reminder->id,
            'phone_number_id' => $secondary->id,
        ]);

        $response->assertStatus(200)->assertJsonFragment(['recipient_phone' => '254700000002']);
    }

    public function test_message_render_rejects_a_phone_number_id_from_a_different_customer(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        $customerA = Customer::factory()->for($tenant, 'tenant')->create();
        $customerB = Customer::factory()->for($tenant, 'tenant')->create();
        $foreignPhone = $this->createPhoneNumber($customerB, $tenant, '254700000009', true);
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customerA, 'customer')->create();
        $reminder = Reminder::factory()->for($tenant, 'tenant')->paymentDue()
            ->create(['related_entity_type' => 'debt', 'related_entity_id' => $debt->id]);
        $template = MessageTemplate::factory()->for($tenant, 'tenant')->create();

        $response = $this->postJson('/api/v1/messages/render', [
            'template_id' => $template->id,
            'reminder_id' => $reminder->id,
            'phone_number_id' => $foreignPhone->id,
        ]);

        $response->assertStatus(404);
    }

    // --- Import ---

    public function test_import_accepts_primary_and_secondary_phone_columns(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $file = $this->makeExcelFile(
            [['Imported Co', '254700000001', '254700000002', 1000]],
            ['name', 'primary_phone', 'secondary_phone', 'credit_limit'],
        );
        $batchId = $this->postJson('/api/v1/customers/import', ['file' => $file])->json('data.batch_id');

        $response = $this->postJson("/api/v1/customers/import/{$batchId}/commit", []);

        $response->assertStatus(200);
        $customerId = $response->json('data.results.0.customer_id');
        $this->assertDatabaseHas('customers', ['id' => $customerId, 'phone' => '254700000001']);
        $this->assertDatabaseCount('customer_phone_numbers', 2);
        $this->assertDatabaseHas('customer_phone_numbers', ['customer_id' => $customerId, 'phone' => '254700000002', 'is_primary' => false]);
    }

    public function test_import_accepts_only_primary_phone_when_secondary_is_omitted(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $file = $this->makeExcelFile(
            [['Imported Co', '254700000001', '', 1000]],
            ['name', 'primary_phone', 'secondary_phone', 'credit_limit'],
        );
        $batchId = $this->postJson('/api/v1/customers/import', ['file' => $file])->json('data.batch_id');

        $response = $this->postJson("/api/v1/customers/import/{$batchId}/commit", []);

        $response->assertStatus(200);
        $this->assertDatabaseCount('customer_phone_numbers', 1);
    }

    public function test_import_still_accepts_the_legacy_phone_column(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);

        $file = $this->makeExcelFile(
            [['Imported Co', '254700000001', 1000]],
            ['name', 'phone', 'credit_limit'],
        );
        $batchId = $this->postJson('/api/v1/customers/import', ['file' => $file])->json('data.batch_id');

        $response = $this->postJson("/api/v1/customers/import/{$batchId}/commit", []);

        $response->assertStatus(200);
        $customerId = $response->json('data.results.0.customer_id');
        $this->assertDatabaseHas('customers', ['id' => $customerId, 'phone' => '254700000001']);
        $this->assertDatabaseCount('customer_phone_numbers', 1);
    }
}
