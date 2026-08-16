<?php

namespace App\Console\Commands;

use App\Models\Notification;
use Illuminate\Console\Command;

/**
 * Module 9 — Notifications, retention. Notifications previously
 * accumulated forever with no deletion mechanism; this permanently
 * removes notifications that have been read for more than 90 days.
 * Unread notifications are never pruned, regardless of age — a user has
 * not seen them yet.
 */
class PruneReadNotifications extends Command
{
    protected $signature = 'notifications:prune-read';

    protected $description = 'Permanently delete notifications that have been read for more than 90 days.';

    public function handle(): int
    {
        $deleted = Notification::whereNotNull('read_at')
            ->where('read_at', '<', now()->subDays(90))
            ->delete();

        $this->info("Deleted {$deleted} read notification(s) older than 90 days.");

        return self::SUCCESS;
    }
}
