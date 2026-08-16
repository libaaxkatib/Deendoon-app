<?php

namespace Tests\Feature\Admin;

use App\Models\SupportTicket;
use App\Models\Tenant;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Database\Seeders\SubscriptionPlanSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class AdminSupportTicketManagementTest extends TestCase
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
     * @return array{0: Tenant, 1: User, 2: SupportTicket}
     */
    private function makeTicket(string $businessName = 'Hodan Trading', array $attrs = []): array
    {
        $tenant = Tenant::factory()->create(['business_name' => $businessName]);
        $owner = $this->businessOwner($tenant);
        $ticket = SupportTicket::factory()->create(array_merge([
            'tenant_id' => $tenant->id,
            'reference_number' => 'SUP-'.str_pad((string) random_int(1, 999999), 6, '0', STR_PAD_LEFT),
            'submitted_by_user_id' => $owner->id,
        ], $attrs));

        return [$tenant, $owner, $ticket];
    }

    public function test_platform_administrator_can_view_tickets_across_tenants(): void
    {
        [, , $ticketA] = $this->makeTicket('Hodan Trading', ['subject' => 'Cannot login']);
        [, , $ticketB] = $this->makeTicket('Barwaqo Imports', ['subject' => 'Payment failed']);

        $response = $this->actingAs($this->platformAdmin())->get('/admin/support-tickets');

        $response->assertOk();
        $response->assertSee($ticketA->reference_number);
        $response->assertSee($ticketB->reference_number);
        $response->assertSee('Hodan Trading');
        $response->assertSee('Barwaqo Imports');
    }

    public function test_a_business_owner_is_forbidden_from_the_admin_panel(): void
    {
        [$tenant, $owner] = $this->makeTicket();

        $this->actingAs($owner)->get('/admin/support-tickets')->assertForbidden();
    }

    public function test_guest_is_redirected_to_admin_login(): void
    {
        $this->get('/admin/support-tickets')->assertRedirect(route('admin.login'));
    }

    public function test_list_can_be_searched_by_reference_number(): void
    {
        [, , $ticketA] = $this->makeTicket('Hodan Trading', ['reference_number' => 'SUP-000123']);
        [, , $ticketB] = $this->makeTicket('Barwaqo Imports', ['reference_number' => 'SUP-999999']);

        $response = $this->actingAs($this->platformAdmin())->get('/admin/support-tickets?search=000123');

        $response->assertOk();
        $response->assertSee($ticketA->reference_number);
        $response->assertDontSee($ticketB->reference_number);
    }

    public function test_list_can_be_filtered_by_status(): void
    {
        [, , $ticketA] = $this->makeTicket('Hodan Trading', ['status' => 'in_progress']);
        [, , $ticketB] = $this->makeTicket('Barwaqo Imports', ['status' => 'open']);

        $response = $this->actingAs($this->platformAdmin())->get('/admin/support-tickets?status=in_progress');

        $response->assertOk();
        $response->assertSee($ticketA->reference_number);
        $response->assertDontSee($ticketB->reference_number);
    }

    public function test_list_can_be_filtered_by_priority(): void
    {
        [, , $ticketA] = $this->makeTicket('Hodan Trading', ['priority' => 'urgent']);
        [, , $ticketB] = $this->makeTicket('Barwaqo Imports', ['priority' => 'low']);

        $response = $this->actingAs($this->platformAdmin())->get('/admin/support-tickets?priority=urgent');

        $response->assertOk();
        $response->assertSee($ticketA->reference_number);
        $response->assertDontSee($ticketB->reference_number);
    }

    public function test_list_can_be_filtered_by_category(): void
    {
        [, , $ticketA] = $this->makeTicket('Hodan Trading', ['category' => 'payment_billing']);
        [, , $ticketB] = $this->makeTicket('Barwaqo Imports', ['category' => 'account']);

        $response = $this->actingAs($this->platformAdmin())->get('/admin/support-tickets?category=payment_billing');

        $response->assertOk();
        $response->assertSee($ticketA->reference_number);
        $response->assertDontSee($ticketB->reference_number);
    }

    public function test_list_can_be_filtered_by_business(): void
    {
        [$tenantA, , $ticketA] = $this->makeTicket('Hodan Trading');
        [, , $ticketB] = $this->makeTicket('Barwaqo Imports');

        $response = $this->actingAs($this->platformAdmin())->get('/admin/support-tickets?tenant_id='.$tenantA->id);

        $response->assertOk();
        $response->assertSee($ticketA->reference_number);
        $response->assertDontSee($ticketB->reference_number);
    }

    public function test_detail_page_shows_business_subject_and_description(): void
    {
        [$tenant, , $ticket] = $this->makeTicket('Hodan Trading', ['subject' => 'Cannot generate demand letter', 'description' => 'The PDF fails to download.']);

        $response = $this->actingAs($this->platformAdmin())->get("/admin/support-tickets/{$ticket->id}");

        $response->assertOk();
        $response->assertSee('Hodan Trading');
        $response->assertSee('Cannot generate demand letter');
        $response->assertSee('The PDF fails to download.');
        $response->assertSee(route('admin.businesses.show', $tenant), false);
    }

    public function test_platform_administrator_can_transition_status(): void
    {
        [, , $ticket] = $this->makeTicket(attrs: ['status' => 'open']);

        $response = $this->actingAs($this->platformAdmin())
            ->post(route('admin.support-tickets.status', $ticket), ['status' => 'in_progress']);

        $response->assertRedirect(route('admin.support-tickets.show', $ticket));
        $this->assertSame('in_progress', $ticket->fresh()->status);
    }

    public function test_an_invalid_status_transition_is_rejected_with_a_friendly_error(): void
    {
        [, , $ticket] = $this->makeTicket(attrs: ['status' => 'open']);

        $response = $this->actingAs($this->platformAdmin())
            ->post(route('admin.support-tickets.status', $ticket), ['status' => 'resolved']);

        $response->assertRedirect();
        $response->assertSessionHasErrors('action');
        $this->assertSame('open', $ticket->fresh()->status);
    }

    public function test_platform_administrator_can_close_a_ticket(): void
    {
        [, , $ticket] = $this->makeTicket(attrs: ['status' => 'in_progress']);

        $response = $this->actingAs($this->platformAdmin())
            ->post(route('admin.support-tickets.close', $ticket));

        $response->assertRedirect(route('admin.support-tickets.show', $ticket));
        $this->assertSame('closed', $ticket->fresh()->status);
        $this->assertNotNull($ticket->fresh()->closed_at);
    }

    public function test_closing_an_already_closed_ticket_shows_a_friendly_error(): void
    {
        [, , $ticket] = $this->makeTicket(attrs: ['status' => 'closed']);

        $response = $this->actingAs($this->platformAdmin())
            ->post(route('admin.support-tickets.close', $ticket));

        $response->assertSessionHasErrors('action');
    }

    public function test_platform_administrator_can_reopen_a_closed_ticket(): void
    {
        [, , $ticket] = $this->makeTicket(attrs: ['status' => 'closed']);

        $response = $this->actingAs($this->platformAdmin())
            ->post(route('admin.support-tickets.reopen', $ticket));

        $response->assertRedirect(route('admin.support-tickets.show', $ticket));
        $this->assertSame('open', $ticket->fresh()->status);
    }

    public function test_platform_administrator_can_post_a_reply_and_it_is_visible(): void
    {
        [, , $ticket] = $this->makeTicket(attrs: ['status' => 'open']);
        $admin = $this->platformAdmin();

        $this->actingAs($admin)->post(route('admin.support-tickets.messages', $ticket), [
            'content' => 'Please provide a screenshot.',
        ]);

        $response = $this->actingAs($admin)->get("/admin/support-tickets/{$ticket->id}");
        $response->assertOk();
        $response->assertSee('Please provide a screenshot.');
    }

    public function test_platform_administrator_can_upload_an_attachment(): void
    {
        [, , $ticket] = $this->makeTicket(attrs: ['status' => 'open']);

        $response = $this->actingAs($this->platformAdmin())
            ->post(route('admin.support-tickets.attachments.store', $ticket), [
                'file' => UploadedFile::fake()->create('evidence.pdf', 100, 'application/pdf'),
            ]);

        $response->assertRedirect(route('admin.support-tickets.show', $ticket));
        $this->assertDatabaseHas('support_ticket_attachments', [
            'support_ticket_id' => $ticket->id,
            'original_filename' => 'evidence.pdf',
        ]);
    }

    public function test_attachment_can_be_downloaded(): void
    {
        [, , $ticket] = $this->makeTicket(attrs: ['status' => 'open']);
        $admin = $this->platformAdmin();
        $this->actingAs($admin)->post(route('admin.support-tickets.attachments.store', $ticket), [
            'file' => UploadedFile::fake()->create('evidence.pdf', 100, 'application/pdf'),
        ]);
        $attachment = $ticket->attachments()->firstOrFail();

        $response = $this->actingAs($admin)->get(route('admin.support-tickets.attachments.download', [$ticket, $attachment]));

        $response->assertOk();
    }

    public function test_closed_ticket_hides_reply_and_status_forms(): void
    {
        [, , $ticket] = $this->makeTicket(attrs: ['status' => 'closed']);

        $response = $this->actingAs($this->platformAdmin())->get("/admin/support-tickets/{$ticket->id}");

        $response->assertOk();
        $response->assertDontSee('Update Status');
        $response->assertDontSee('Close Ticket');
        $response->assertSee('Reopen Ticket');
    }

    public function test_contact_links_use_the_approved_zero_cost_channels(): void
    {
        [, , $ticket] = $this->makeTicket();

        $response = $this->actingAs($this->platformAdmin())->get("/admin/support-tickets/{$ticket->id}");

        $response->assertOk();
        $response->assertSee('tel:615178666', false);
        $response->assertSee('https://wa.me/252615514692', false);
        $response->assertSee('mailto:deendoonapp@gmail.com', false);
    }

    public function test_empty_state_is_shown_when_no_tickets_match(): void
    {
        $response = $this->actingAs($this->platformAdmin())->get('/admin/support-tickets?search=nonexistent');

        $response->assertOk();
        $response->assertSee('No support tickets match your filters.');
    }
}
