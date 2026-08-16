<?php

namespace Tests\Feature\Admin;

use App\Models\CollectionCase;
use App\Models\Customer;
use App\Models\Debt;
use App\Models\ProfessionalCollectionRequest;
use App\Models\Tenant;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Database\Seeders\SubscriptionPlanSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class AdminProfessionalCollectionManagementTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RoleSeeder::class);
        $this->seed(SubscriptionPlanSeeder::class);
        Storage::fake('local');
    }

    private function platformAdmin(): User
    {
        $admin = User::factory()->create();
        $admin->assignRole('deendoon_platform_administrator');

        return $admin;
    }

    private function businessOwner(Tenant $tenant): User
    {
        $owner = User::factory()->create();
        $owner->tenant()->associate($tenant);
        $owner->save();
        $owner->assignRole('admin');

        return $owner;
    }

    /**
     * @return array{0: Tenant, 1: User, 2: Debt, 3: CollectionCase, 4: ProfessionalCollectionRequest}
     */
    private function makeRequest(string $businessName = 'Hodan Trading', string $customerName = 'Amina Ali', string $status = 'submitted', string $refSuffix = '000001'): array
    {
        $tenant = Tenant::factory()->create(['business_name' => $businessName]);
        $owner = $this->businessOwner($tenant);
        $customer = Customer::factory()->for($tenant, 'tenant')->create(['name' => $customerName]);
        $debt = Debt::factory()->for($tenant, 'tenant')->for($customer, 'customer')->create(['reference_number' => "DBT-{$refSuffix}"]);
        $case = CollectionCase::factory()->for($tenant, 'tenant')->for($debt, 'debt')->create(['reference_number' => "COL-{$refSuffix}"]);
        $pcr = ProfessionalCollectionRequest::factory()->create([
            'tenant_id' => $tenant->id,
            'collection_case_id' => $case->id,
            'reference_number' => "PCR-{$refSuffix}",
            'status' => $status,
            'submitted_by_user_id' => $owner->id,
        ]);

        return [$tenant, $owner, $debt, $case, $pcr];
    }

    public function test_platform_administrator_can_view_requests_across_tenants(): void
    {
        [$tenantA, , , , $pcrA] = $this->makeRequest('Hodan Trading', 'Amina Ali');
        [$tenantB, , , , $pcrB] = $this->makeRequest('Barwaqo Imports', 'Yusuf Nur');

        $response = $this->actingAs($this->platformAdmin())->get('/admin/professional-collection');

        $response->assertOk();
        $response->assertSee($pcrA->reference_number);
        $response->assertSee($pcrB->reference_number);
        $response->assertSee('Hodan Trading');
        $response->assertSee('Barwaqo Imports');
    }

    public function test_list_can_be_searched_by_reference_number(): void
    {
        [, , , , $pcrA] = $this->makeRequest('Hodan Trading', 'Amina Ali', refSuffix: '000123');
        [, , , , $pcrB] = $this->makeRequest('Barwaqo Imports', 'Yusuf Nur', refSuffix: '999999');

        $response = $this->actingAs($this->platformAdmin())->get('/admin/professional-collection?search=000123');

        $response->assertOk();
        $response->assertSee($pcrA->reference_number);
        $response->assertDontSee($pcrB->reference_number);
    }

    public function test_list_can_be_searched_by_debtor_name(): void
    {
        [, , , , $pcrA] = $this->makeRequest('Hodan Trading', 'Amina Ali', refSuffix: '000111');
        [, , , , $pcrB] = $this->makeRequest('Barwaqo Imports', 'Yusuf Nur', refSuffix: '000222');

        $response = $this->actingAs($this->platformAdmin())->get('/admin/professional-collection?search=amina');

        $response->assertOk();
        $response->assertSee($pcrA->reference_number);
        $response->assertDontSee($pcrB->reference_number);
    }

    public function test_list_can_be_filtered_by_status(): void
    {
        [, , , , $pcrA] = $this->makeRequest('Hodan Trading', 'Amina Ali', 'under_review', '000111');
        [, , , , $pcrB] = $this->makeRequest('Barwaqo Imports', 'Yusuf Nur', 'submitted', '000222');

        $response = $this->actingAs($this->platformAdmin())->get('/admin/professional-collection?status=under_review');

        $response->assertOk();
        $response->assertSee($pcrA->reference_number);
        $response->assertDontSee($pcrB->reference_number);
    }

    public function test_a_business_owner_is_forbidden_from_professional_collection(): void
    {
        [$tenant, $owner] = $this->makeRequest();

        $this->actingAs($owner)->get('/admin/professional-collection')->assertForbidden();
    }

    public function test_guest_is_redirected_to_admin_login(): void
    {
        $response = $this->get('/admin/professional-collection');

        $response->assertRedirect(route('admin.login'));
    }

    public function test_detail_page_shows_business_debtor_debt_and_transfer_details(): void
    {
        [$tenant, , $debt, , $pcr] = $this->makeRequest('Hodan Trading', 'Amina Ali');
        $pcr->reasons()->create(['reason_label' => 'Non-payment']);
        $pcr->requestedServices()->create(['service_label' => 'Field Visit']);

        $response = $this->actingAs($this->platformAdmin())->get("/admin/professional-collection/{$pcr->id}");

        $response->assertOk();
        $response->assertSee('Hodan Trading');
        $response->assertSee('Amina Ali');
        $response->assertSee('DBT-000001');
        $response->assertSee('Non-payment');
        $response->assertSee('Field Visit');
        $response->assertSee(route('admin.businesses.show', $tenant), false);
        $response->assertSee(route('admin.recovery-debts.show', $debt), false);
    }

    public function test_platform_administrator_can_transition_status_through_the_approved_sequence(): void
    {
        [, , , , $pcr] = $this->makeRequest(status: 'submitted');

        $response = $this->actingAs($this->platformAdmin())
            ->post(route('admin.professional-collection.status', $pcr), ['status' => 'under_review']);

        $response->assertRedirect(route('admin.professional-collection.show', $pcr));
        $this->assertSame('under_review', $pcr->fresh()->status);
    }

    public function test_an_invalid_status_transition_is_rejected_with_a_friendly_error(): void
    {
        [, , , , $pcr] = $this->makeRequest(status: 'submitted');

        $response = $this->actingAs($this->platformAdmin())
            ->post(route('admin.professional-collection.status', $pcr), ['status' => 'in_progress']);

        $response->assertRedirect();
        $response->assertSessionHasErrors('action');
        $this->assertSame('submitted', $pcr->fresh()->status);
    }

    public function test_platform_administrator_can_close_a_request_with_an_outcome(): void
    {
        [, , , , $pcr] = $this->makeRequest(status: 'in_progress');

        $response = $this->actingAs($this->platformAdmin())
            ->post(route('admin.professional-collection.close', $pcr), ['outcome' => 'recovered']);

        $response->assertRedirect(route('admin.professional-collection.show', $pcr));
        $this->assertSame('recovered', $pcr->fresh()->status);
        $this->assertNotNull($pcr->fresh()->closed_at);
    }

    public function test_closing_an_already_closed_request_shows_a_friendly_error(): void
    {
        [, , , , $pcr] = $this->makeRequest(status: 'closed');

        $response = $this->actingAs($this->platformAdmin())
            ->post(route('admin.professional-collection.close', $pcr), ['outcome' => 'recovered']);

        $response->assertSessionHasErrors('action');
    }

    public function test_platform_administrator_can_post_a_message_and_it_is_visible(): void
    {
        [, , , , $pcr] = $this->makeRequest(status: 'under_review');
        $admin = $this->platformAdmin();

        $this->actingAs($admin)->post(route('admin.professional-collection.messages', $pcr), [
            'content' => 'Please provide the updated payment reference.',
        ]);

        $response = $this->actingAs($admin)->get("/admin/professional-collection/{$pcr->id}");
        $response->assertOk();
        $response->assertSee('Please provide the updated payment reference.');
    }

    public function test_platform_administrator_can_record_a_timeline_event(): void
    {
        [, , , , $pcr] = $this->makeRequest(status: 'assigned');
        $admin = $this->platformAdmin();

        $this->actingAs($admin)->post(route('admin.professional-collection.timeline', $pcr), [
            'event_type' => 'telephone_collection',
            'notes' => 'Called the debtor, promised payment next week.',
        ]);

        $this->assertDatabaseHas('professional_collection_timeline_events', [
            'professional_collection_request_id' => $pcr->id,
            'event_type' => 'telephone_collection',
        ]);

        $response = $this->actingAs($admin)->get("/admin/professional-collection/{$pcr->id}");
        $response->assertSee('Called the debtor, promised payment next week.');
    }

    public function test_platform_administrator_can_upload_an_attachment_once_assigned(): void
    {
        [, , , , $pcr] = $this->makeRequest(status: 'assigned');

        $response = $this->actingAs($this->platformAdmin())
            ->post(route('admin.professional-collection.attachments.store', $pcr), [
                'file' => UploadedFile::fake()->create('evidence.pdf', 100, 'application/pdf'),
            ]);

        $response->assertRedirect(route('admin.professional-collection.show', $pcr));
        $this->assertDatabaseHas('professional_collection_request_attachments', [
            'professional_collection_request_id' => $pcr->id,
            'original_filename' => 'evidence.pdf',
        ]);
    }

    public function test_platform_administrator_cannot_upload_an_attachment_before_the_request_is_assigned(): void
    {
        // Guards the state-dependent Policy rule specifically: pre-Assigned
        // upload rights belong to the tenant, not the Platform Administrator
        // — this must still be enforced from the Admin Panel.
        [, , , , $pcr] = $this->makeRequest(status: 'under_review');

        $response = $this->actingAs($this->platformAdmin())
            ->post(route('admin.professional-collection.attachments.store', $pcr), [
                'file' => UploadedFile::fake()->create('evidence.pdf', 100, 'application/pdf'),
            ]);

        $response->assertForbidden();
        $this->assertDatabaseMissing('professional_collection_request_attachments', [
            'professional_collection_request_id' => $pcr->id,
        ]);
    }

    public function test_attachment_can_be_downloaded(): void
    {
        [, , , , $pcr] = $this->makeRequest(status: 'assigned');
        $admin = $this->platformAdmin();
        $this->actingAs($admin)->post(route('admin.professional-collection.attachments.store', $pcr), [
            'file' => UploadedFile::fake()->create('evidence.pdf', 100, 'application/pdf'),
        ]);
        $attachment = $pcr->attachments()->firstOrFail();

        $response = $this->actingAs($admin)->get(route('admin.professional-collection.attachments.download', [$pcr, $attachment]));

        $response->assertOk();
    }

    public function test_terminal_request_hides_action_forms(): void
    {
        [, , , , $pcr] = $this->makeRequest(status: 'closed');

        $response = $this->actingAs($this->platformAdmin())->get("/admin/professional-collection/{$pcr->id}");

        $response->assertOk();
        $response->assertDontSee('Update Status');
        $response->assertDontSee('Close Request');
    }
}
