<?php

namespace Tests\Unit\Services\Admin;

use App\Models\Announcement;
use App\Models\Notification;
use App\Models\Tenant;
use App\Models\User;
use App\Services\Admin\AnnouncementService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AnnouncementServiceTest extends TestCase
{
    use RefreshDatabase;

    private function businessOwner(Tenant $tenant): User
    {
        $owner = User::factory()->create();
        $owner->tenant()->associate($tenant);
        $owner->save();

        return $owner;
    }

    public function test_send_to_all_notifies_every_tenant_with_users(): void
    {
        $tenantA = Tenant::factory()->create();
        $tenantB = Tenant::factory()->create();
        $ownerA = $this->businessOwner($tenantA);
        $ownerB = $this->businessOwner($tenantB);
        $actor = $ownerA;

        $count = app(AnnouncementService::class)->send('all', [], 'Title', 'Message', $actor);

        $this->assertSame(2, $count);
        $this->assertDatabaseHas('notifications', ['recipient_user_id' => (string) $ownerA->id, 'type' => 'admin_announcement']);
        $this->assertDatabaseHas('notifications', ['recipient_user_id' => (string) $ownerB->id, 'type' => 'admin_announcement']);
    }

    public function test_send_to_selected_only_notifies_chosen_tenants(): void
    {
        $tenantA = Tenant::factory()->create();
        $tenantB = Tenant::factory()->create();
        $ownerA = $this->businessOwner($tenantA);
        $ownerB = $this->businessOwner($tenantB);

        $count = app(AnnouncementService::class)->send('selected', [$tenantA->id], 'Title', 'Message', $ownerA);

        $this->assertSame(1, $count);
        $this->assertDatabaseHas('notifications', ['recipient_user_id' => (string) $ownerA->id, 'type' => 'admin_announcement']);
        $this->assertDatabaseMissing('notifications', ['recipient_user_id' => (string) $ownerB->id, 'type' => 'admin_announcement']);
    }

    public function test_a_tenant_with_no_users_is_skipped(): void
    {
        $emptyTenant = Tenant::factory()->create();

        $count = app(AnnouncementService::class)->send('all', [], 'Title', 'Message', User::factory()->create());

        $this->assertSame(0, $count);
        $this->assertSame(0, Notification::where('tenant_id', $emptyTenant->id)->count());
    }

    public function test_every_recipient_row_from_the_same_send_shares_one_batch_id(): void
    {
        $tenantA = Tenant::factory()->create();
        $tenantB = Tenant::factory()->create();
        $this->businessOwner($tenantA);
        $this->businessOwner($tenantB);

        app(AnnouncementService::class)->send('all', [], 'Title', 'Message', User::factory()->create());

        $batchIds = Notification::where('type', 'admin_announcement')->pluck('related_entity_id')->unique();
        $this->assertCount(1, $batchIds);
    }

    // --- Announcement History (Module 9 follow-up) ---

    public function test_a_successful_send_creates_one_announcement_history_record(): void
    {
        $tenantA = Tenant::factory()->create();
        $tenantB = Tenant::factory()->create();
        $ownerA = $this->businessOwner($tenantA);
        $this->businessOwner($tenantB);
        $actor = User::factory()->create();

        app(AnnouncementService::class)->send('all', [], 'Scheduled maintenance', 'Body text', $actor);

        $this->assertSame(1, Announcement::count());
        $announcement = Announcement::first();
        $this->assertSame('Scheduled maintenance', $announcement->title);
        $this->assertSame('Body text', $announcement->message);
        $this->assertSame('all', $announcement->scope);
        $this->assertSame(2, $announcement->recipient_count);
        $this->assertSame((string) $actor->id, $announcement->sent_by_user_id);
        $this->assertNotNull($announcement->sent_at);

        // Shares the exact batch id used for the Notification/AuditLog rows.
        $batchId = Notification::where('recipient_user_id', (string) $ownerA->id)->value('related_entity_id');
        $this->assertSame($batchId, $announcement->id);
    }

    public function test_a_send_that_reaches_no_recipients_creates_no_announcement_history_record(): void
    {
        Tenant::factory()->create();

        app(AnnouncementService::class)->send('all', [], 'Title', 'Message', User::factory()->create());

        $this->assertSame(0, Announcement::count());
    }

    public function test_selected_scope_is_recorded_on_the_history_record(): void
    {
        $tenantA = Tenant::factory()->create();
        $tenantB = Tenant::factory()->create();
        $ownerA = $this->businessOwner($tenantA);
        $this->businessOwner($tenantB);

        app(AnnouncementService::class)->send('selected', [$tenantA->id], 'Title', 'Message', $ownerA);

        $announcement = Announcement::first();
        $this->assertSame('selected', $announcement->scope);
        $this->assertSame(1, $announcement->recipient_count);
    }

    /**
     * `sent_by_user_id` is CHAR(26) — PostgreSQL's fixed-length char type
     * right-pads short values (e.g. a bigint id like "4") with trailing
     * spaces on SELECT, which broke every lookup keyed on this value
     * (History's "Sent By" always showed "Unknown"). SQLite, the test
     * driver, does not reproduce this padding, so this test simulates the
     * exact stored shape a real PostgreSQL round-trip produces.
     */
    public function test_sent_by_user_id_is_trimmed_even_when_the_stored_value_is_padded(): void
    {
        $announcement = new Announcement;
        $padded = '4'.str_repeat(' ', 25); // exact shape a PostgreSQL CHAR(26) round-trip produces
        $announcement->setRawAttributes(['sent_by_user_id' => $padded]);

        $this->assertSame('4', $announcement->sent_by_user_id);
    }
}
