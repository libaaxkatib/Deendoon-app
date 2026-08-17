<?php

namespace Tests\Unit\Services;

use App\Models\Customer;
use App\Models\Tenant;
use App\Models\User;
use App\Services\CustomerPhoneNumberService;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Validation\ValidationException;
use Tests\TestCase;

class CustomerPhoneNumberServiceTest extends TestCase
{
    use RefreshDatabase;

    private CustomerPhoneNumberService $service;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);
        $this->service = new CustomerPhoneNumberService;
    }

    private function actingAsTenantUser(Tenant $tenant): void
    {
        $user = User::factory()->create();
        $user->tenant()->associate($tenant);
        $user->save();
        $user->assignRole('admin');
        $this->actingAs($user, 'sanctum');
    }

    // --- normalizeEntries ---

    public function test_normalize_entries_falls_back_to_legacy_phone_as_sole_primary(): void
    {
        $entries = $this->service->normalizeEntries(['phone' => '254700000001', 'phone_numbers' => null]);

        $this->assertSame([['id' => null, 'phone' => '254700000001', 'is_primary' => true]], $entries);
    }

    public function test_normalize_entries_uses_phone_numbers_array_when_present(): void
    {
        $entries = $this->service->normalizeEntries([
            'phone' => 'ignored',
            'phone_numbers' => [
                ['id' => null, 'phone' => '254700000001', 'is_primary' => true],
                ['id' => null, 'phone' => '254700000002', 'is_primary' => false],
            ],
        ]);

        $this->assertCount(2, $entries);
        $this->assertSame('254700000001', $entries[0]['phone']);
        $this->assertTrue($entries[0]['is_primary']);
    }

    // --- validationErrors ---

    public function test_rejects_zero_phone_numbers(): void
    {
        $this->assertNotEmpty($this->service->validationErrors([]));
    }

    public function test_rejects_four_phone_numbers(): void
    {
        $entries = array_map(
            fn ($i) => ['id' => null, 'phone' => "25470000000{$i}", 'is_primary' => $i === 0],
            range(0, 3),
        );

        $this->assertNotEmpty($this->service->validationErrors($entries));
    }

    public function test_accepts_exactly_three_phone_numbers(): void
    {
        $entries = array_map(
            fn ($i) => ['id' => null, 'phone' => "25470000000{$i}", 'is_primary' => $i === 0],
            range(0, 2),
        );

        $this->assertSame([], $this->service->validationErrors($entries));
    }

    public function test_rejects_zero_primary_numbers(): void
    {
        $entries = [
            ['id' => null, 'phone' => '254700000001', 'is_primary' => false],
        ];

        $this->assertNotEmpty($this->service->validationErrors($entries));
    }

    public function test_rejects_two_primary_numbers(): void
    {
        $entries = [
            ['id' => null, 'phone' => '254700000001', 'is_primary' => true],
            ['id' => null, 'phone' => '254700000002', 'is_primary' => true],
        ];

        $this->assertNotEmpty($this->service->validationErrors($entries));
    }

    // --- reconcile ---

    public function test_reconcile_creates_all_submitted_entries_and_mirrors_primary_into_customers_phone(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        $customer = Customer::factory()->for($tenant, 'tenant')->create(['phone' => 'old']);

        $this->service->reconcile($customer, [
            ['id' => null, 'phone' => '254700000001', 'is_primary' => true],
            ['id' => null, 'phone' => '254700000002', 'is_primary' => false],
        ]);

        $this->assertSame('254700000001', $customer->fresh()->phone);
        $this->assertCount(2, $customer->phoneNumbers()->get());
    }

    public function test_reconcile_deletes_entries_no_longer_present(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $this->service->reconcile($customer, [
            ['id' => null, 'phone' => '254700000001', 'is_primary' => true],
            ['id' => null, 'phone' => '254700000002', 'is_primary' => false],
        ]);
        $keptId = $customer->phoneNumbers()->where('is_primary', true)->first()->id;

        $this->service->reconcile($customer, [
            ['id' => $keptId, 'phone' => '254700000001', 'is_primary' => true],
        ]);

        $this->assertCount(1, $customer->phoneNumbers()->get());
    }

    public function test_reconcile_throws_validation_exception_for_an_invalid_set(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();

        $this->expectException(ValidationException::class);

        $this->service->reconcile($customer, []);
    }

    public function test_reconcile_ignores_a_foreign_id_by_treating_it_as_a_new_entry(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        $customerA = Customer::factory()->for($tenant, 'tenant')->create();
        $customerB = Customer::factory()->for($tenant, 'tenant')->create();
        $this->service->reconcile($customerB, [
            ['id' => null, 'phone' => '254700000099', 'is_primary' => true],
        ]);
        $foreignId = $customerB->phoneNumbers()->first()->id;

        $this->service->reconcile($customerA, [
            ['id' => $foreignId, 'phone' => '254700000001', 'is_primary' => true],
        ]);

        // customerA gets a brand-new row of its own — customerB's row is
        // untouched, never reassigned to a different customer.
        $this->assertSame('254700000001', $customerA->fresh()->phone);
        $this->assertSame('254700000099', $customerB->fresh()->phone);
        $this->assertNotSame($foreignId, $customerA->phoneNumbers()->first()->id);
    }

    // --- upsertFromImport ---

    public function test_upsert_from_import_creates_primary_and_secondary(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();

        $this->service->upsertFromImport($customer, '254700000001', '254700000002');

        $this->assertSame('254700000001', $customer->fresh()->phone);
        $this->assertCount(2, $customer->phoneNumbers()->get());
    }

    public function test_upsert_from_import_never_touches_a_manually_added_third_number(): void
    {
        $tenant = Tenant::create(['business_name' => 'Acme Co']);
        $this->actingAsTenantUser($tenant);
        $customer = Customer::factory()->for($tenant, 'tenant')->create();
        $this->service->reconcile($customer, [
            ['id' => null, 'phone' => '254700000001', 'is_primary' => true],
            ['id' => null, 'phone' => '254700000002', 'is_primary' => false],
            ['id' => null, 'phone' => '254700000003', 'is_primary' => false],
        ]);

        $this->service->upsertFromImport($customer, '254700009999', null);

        $phones = $customer->phoneNumbers()->pluck('phone')->all();
        $this->assertContains('254700000003', $phones);
        $this->assertContains('254700009999', $phones);
    }
}
