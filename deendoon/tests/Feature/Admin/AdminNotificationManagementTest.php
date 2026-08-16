<?php

namespace Tests\Feature\Admin;

use App\Models\Announcement;
use App\Models\Notification;
use App\Models\Tenant;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Tests\TestCase;

class AdminNotificationManagementTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(RoleSeeder::class);
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

    public function test_guest_is_redirected_to_admin_login(): void
    {
        $this->get('/admin/notifications')->assertRedirect(route('admin.login'));
    }

    public function test_a_business_owner_is_forbidden(): void
    {
        $this->actingAs($this->businessOwner(Tenant::factory()->create()))->get('/admin/notifications')->assertForbidden();
        $this->actingAs($this->businessOwner(Tenant::factory()->create()))->post('/admin/notifications', [])->assertForbidden();
        $this->actingAs($this->businessOwner(Tenant::factory()->create()))->get('/admin/notifications/history')->assertForbidden();
    }

    public function test_guest_is_redirected_to_admin_login_for_history(): void
    {
        $this->get('/admin/notifications/history')->assertRedirect(route('admin.login'));
    }

    public function test_platform_administrator_can_view_the_compose_page(): void
    {
        $tenant = Tenant::factory()->create(['business_name' => 'Hodan Trading']);

        $response = $this->actingAs($this->platformAdmin())->get('/admin/notifications');

        $response->assertOk();
        $response->assertSee('Send System Notice');
        $response->assertSee('Hodan Trading');
    }

    public function test_sending_to_all_businesses_notifies_every_business_owner(): void
    {
        $tenantA = Tenant::factory()->create();
        $tenantB = Tenant::factory()->create();
        $ownerA = $this->businessOwner($tenantA);
        $ownerB = $this->businessOwner($tenantB);

        $response = $this->actingAs($this->platformAdmin())->post('/admin/notifications', [
            'scope' => 'all',
            'title' => 'Scheduled maintenance',
            'message' => 'The platform will be briefly unavailable tonight.',
        ]);

        $response->assertRedirect(route('admin.notifications.index'));
        $this->assertDatabaseHas('notifications', [
            'recipient_user_id' => (string) $ownerA->id, 'type' => 'admin_announcement', 'title' => 'Scheduled maintenance',
        ]);
        $this->assertDatabaseHas('notifications', [
            'recipient_user_id' => (string) $ownerB->id, 'type' => 'admin_announcement', 'title' => 'Scheduled maintenance',
        ]);
    }

    public function test_sending_to_selected_businesses_only_notifies_those_businesses(): void
    {
        $tenantA = Tenant::factory()->create();
        $tenantB = Tenant::factory()->create();
        $ownerA = $this->businessOwner($tenantA);
        $ownerB = $this->businessOwner($tenantB);

        $this->actingAs($this->platformAdmin())->post('/admin/notifications', [
            'scope' => 'selected',
            'tenant_ids' => [$tenantA->id],
            'title' => 'Selected update',
            'message' => 'This only applies to your business.',
        ])->assertRedirect(route('admin.notifications.index'));

        $this->assertDatabaseHas('notifications', ['recipient_user_id' => (string) $ownerA->id, 'type' => 'admin_announcement']);
        $this->assertDatabaseMissing('notifications', ['recipient_user_id' => (string) $ownerB->id, 'type' => 'admin_announcement']);
    }

    public function test_sending_an_announcement_records_an_audit_log_entry_per_tenant(): void
    {
        $tenant = Tenant::factory()->create();
        $this->businessOwner($tenant);
        $admin = $this->platformAdmin();

        $this->actingAs($admin)->post('/admin/notifications', [
            'scope' => 'selected',
            'tenant_ids' => [$tenant->id],
            'title' => 'Selected update',
            'message' => 'This only applies to your business.',
        ])->assertRedirect(route('admin.notifications.index'));

        $this->assertDatabaseHas('audit_log', [
            'tenant_id' => $tenant->id, 'user_id' => (string) $admin->id, 'action' => 'created', 'entity_type' => 'announcement',
        ]);
    }

    public function test_validation_requires_title_and_message(): void
    {
        $response = $this->actingAs($this->platformAdmin())->post('/admin/notifications', ['scope' => 'all']);

        $response->assertSessionHasErrors(['title', 'message']);
    }

    public function test_selected_scope_requires_tenant_ids(): void
    {
        $response = $this->actingAs($this->platformAdmin())->post('/admin/notifications', [
            'scope' => 'selected', 'title' => 'Title', 'message' => 'Message',
        ]);

        $response->assertSessionHasErrors('tenant_ids');
    }

    public function test_a_tenant_with_no_users_is_skipped_without_error(): void
    {
        Tenant::factory()->create();

        $response = $this->actingAs($this->platformAdmin())->post('/admin/notifications', [
            'scope' => 'all', 'title' => 'Title', 'message' => 'Message',
        ]);

        $response->assertRedirect(route('admin.notifications.index'));
        $this->assertSame(0, Notification::where('type', 'admin_announcement')->count());
    }

    // --- Announcement History (Module 9 follow-up) ---

    public function test_history_shows_an_honest_empty_state_when_nothing_has_been_sent(): void
    {
        $response = $this->actingAs($this->platformAdmin())->get('/admin/notifications/history');

        $response->assertOk();
        $response->assertSee('No System Notices have been sent yet.');
    }

    public function test_a_sent_announcement_appears_in_history_with_its_real_fields(): void
    {
        $tenantA = Tenant::factory()->create();
        $tenantB = Tenant::factory()->create();
        $this->businessOwner($tenantA);
        $this->businessOwner($tenantB);
        $admin = $this->platformAdmin();

        $this->actingAs($admin)->post('/admin/notifications', [
            'scope' => 'all',
            'title' => 'Scheduled maintenance',
            'message' => 'The platform will be briefly unavailable tonight.',
        ])->assertRedirect(route('admin.notifications.index'));

        $response = $this->actingAs($admin)->get('/admin/notifications/history');

        $response->assertOk();
        $response->assertSee('Scheduled maintenance');
        $response->assertSee('The platform will be briefly unavailable tonight.');
        $response->assertSee('All Businesses');
        $response->assertSee($admin->name);
        $this->assertSame(2, Announcement::first()->recipient_count);
    }

    public function test_a_selected_scope_announcement_shows_the_correct_scope_and_count_in_history(): void
    {
        $tenantA = Tenant::factory()->create();
        $tenantB = Tenant::factory()->create();
        $this->businessOwner($tenantA);
        $this->businessOwner($tenantB);

        $this->actingAs($this->platformAdmin())->post('/admin/notifications', [
            'scope' => 'selected',
            'tenant_ids' => [$tenantA->id],
            'title' => 'Selected update',
            'message' => 'This only applies to your business.',
        ])->assertRedirect(route('admin.notifications.index'));

        $response = $this->actingAs($this->platformAdmin())->get('/admin/notifications/history');

        $response->assertOk();
        $response->assertSee('Selected Businesses');
        $response->assertDontSee('All Businesses');
        $this->assertSame(1, Announcement::first()->recipient_count);
    }

    public function test_history_is_paginated(): void
    {
        Announcement::factory()->count(21)->create();

        $response = $this->actingAs($this->platformAdmin())->get('/admin/notifications/history');

        $response->assertOk();
        $response->assertSee('Next');
    }

    public function test_existing_notification_endpoints_remain_unaffected_by_history(): void
    {
        $tenant = Tenant::factory()->create();
        $this->businessOwner($tenant);

        // History is an additive read-only page — sending still behaves
        // exactly as before, and the compose page still loads.
        $response = $this->actingAs($this->platformAdmin())->get('/admin/notifications');

        $response->assertOk();
        $response->assertSee('Send System Notice');
        $response->assertSee('System Notice History');
    }

    /**
     * `sent_by_user_id` is CHAR(26); PostgreSQL pads short stored values
     * (e.g. a bigint id) with trailing spaces on SELECT. Inserted directly
     * via the query builder (bypassing the model's trimming accessor) to
     * reproduce exactly what a real PostgreSQL row looks like — SQLite,
     * the test driver, never pads CHAR columns, so the normal
     * factory/Eloquent-create path can't reproduce this on its own.
     */
    public function test_history_displays_the_real_sender_even_when_the_stored_id_is_padded(): void
    {
        $admin = $this->platformAdmin();
        DB::table('announcements')->insert([
            'id' => (string) Str::ulid(),
            'title' => 'Padded id regression',
            'message' => 'Message',
            'scope' => 'all',
            'recipient_count' => 1,
            'sent_by_user_id' => $admin->id.str_repeat(' ', 26 - strlen((string) $admin->id)),
            'sent_at' => now(),
        ]);

        $response = $this->actingAs($admin)->get('/admin/notifications/history');

        $response->assertOk();
        $response->assertSee($admin->name);
        $response->assertDontSee('Unknown');
    }

    // --- Terminology (Send Announcement -> Send System Notice) ---

    public function test_the_compose_page_uses_system_notice_terminology(): void
    {
        $response = $this->actingAs($this->platformAdmin())->get('/admin/notifications');

        $response->assertOk();
        $response->assertSee('Send System Notice');
        $response->assertSee('System Notice History');
        $response->assertDontSee('Send Announcement');
        $response->assertDontSee('Announcement History');
    }

    public function test_the_history_page_uses_system_notice_terminology(): void
    {
        $response = $this->actingAs($this->platformAdmin())->get('/admin/notifications/history');

        $response->assertOk();
        $response->assertSee('System Notice History');
        $response->assertSee('No System Notices have been sent yet.');
        $response->assertSee('Send a System Notice');
        $response->assertDontSee('Announcement History');
        $response->assertDontSee('No announcements have been sent yet.');
    }

    public function test_the_sent_confirmation_message_uses_system_notice_terminology(): void
    {
        $tenant = Tenant::factory()->create();
        $this->businessOwner($tenant);

        $response = $this->actingAs($this->platformAdmin())->post('/admin/notifications', [
            'scope' => 'all', 'title' => 'Title', 'message' => 'Message',
        ]);

        $response->assertRedirect(route('admin.notifications.index'));
        $response->assertSessionHas('status', 'System Notice sent to 1 business owner(s).');
    }

    /**
     * Terminology is UI wording only — the underlying `notifications.type`
     * value, the `announcements` table name, and the AnnouncementService/
     * Announcement class names are unchanged. This locks that in.
     */
    public function test_the_underlying_type_and_table_are_unchanged_by_the_terminology_rename(): void
    {
        $tenant = Tenant::factory()->create();
        $this->businessOwner($tenant);

        $this->actingAs($this->platformAdmin())->post('/admin/notifications', [
            'scope' => 'all', 'title' => 'Title', 'message' => 'Message',
        ])->assertRedirect(route('admin.notifications.index'));

        $this->assertDatabaseHas('notifications', ['type' => 'admin_announcement']);
        $this->assertDatabaseHas('audit_log', ['entity_type' => 'announcement']);
        $this->assertSame(1, Announcement::count());
    }
}
