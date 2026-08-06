<?php

namespace App\Console\Commands;

use App\Services\SubscriptionService;
use Illuminate\Console\Command;

/**
 * Backend Completion Roadmap, Phase 4.3 — Subscription Lifecycle.
 *
 * NOT registered against Illuminate\Console\Scheduling — see
 * {@see ExpireTrials}'s identical docblock for the standing Product
 * Owner decision this follows. Invoked directly:
 * `php artisan subscriptions:expire`.
 */
class ExpireSubscriptions extends Command
{
    protected $signature = 'subscriptions:expire';

    protected $description = 'Mark every paid subscription whose current period has ended, and was not renewed, as expired.';

    public function __construct(private readonly SubscriptionService $subscriptions)
    {
        parent::__construct();
    }

    public function handle(): int
    {
        $count = $this->subscriptions->expireSubscriptions();

        $this->info("Expired {$count} subscription(s).");

        return self::SUCCESS;
    }
}
