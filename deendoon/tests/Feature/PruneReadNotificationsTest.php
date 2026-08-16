<?php

namespace Tests\Feature;

use App\Models\Notification;
use App\Models\Tenant;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Module 9 — Notifications, retention. Tested as a directly-invoked
 * Artisan command, matching FireDueRemindersTest's pattern.
 */
class PruneReadNotificationsTest extends TestCase
{
    use RefreshDatabase;

    private function makeUser(Tenant $tenant): User
    {
        $user = User::factory()->create();
        $user->tenant()->associate($tenant);
        $user->save();

        return $user;
    }

    public function test_it_deletes_read_notifications_older_than_ninety_days(): void
    {
        $tenant = Tenant::factory()->create();
        $user = $this->makeUser($tenant);
        $old = Notification::factory()->for($tenant, 'tenant')->create([
            'recipient_user_id' => (string) $user->id,
            'read_at' => now()->subDays(91),
        ]);

        $this->artisan('notifications:prune-read')->assertExitCode(0);

        $this->assertDatabaseMissing('notifications', ['id' => $old->id]);
    }

    public function test_it_keeps_read_notifications_within_the_retention_window(): void
    {
        $tenant = Tenant::factory()->create();
        $user = $this->makeUser($tenant);
        $recent = Notification::factory()->for($tenant, 'tenant')->create([
            'recipient_user_id' => (string) $user->id,
            'read_at' => now()->subDays(10),
        ]);

        $this->artisan('notifications:prune-read')->assertExitCode(0);

        $this->assertDatabaseHas('notifications', ['id' => $recent->id]);
    }

    public function test_it_keeps_unread_notifications_regardless_of_age(): void
    {
        $tenant = Tenant::factory()->create();
        $user = $this->makeUser($tenant);
        $unread = Notification::factory()->for($tenant, 'tenant')->create([
            'recipient_user_id' => (string) $user->id,
            'read_at' => null,
            'created_at' => now()->subDays(200),
        ]);

        $this->artisan('notifications:prune-read')->assertExitCode(0);

        $this->assertDatabaseHas('notifications', ['id' => $unread->id]);
    }
}
