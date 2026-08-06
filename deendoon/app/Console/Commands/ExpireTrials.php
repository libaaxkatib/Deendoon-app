<?php

namespace App\Console\Commands;

use App\Services\CustomerReadOnlyService;
use App\Services\SubscriptionService;
use Illuminate\Console\Command;

/**
 * Backend Completion Roadmap, Phase 4.3 — Subscription Lifecycle.
 *
 * NOT registered against Illuminate\Console\Scheduling, matching
 * {@see FireDueReminders}'s identical precedent and the same standing
 * Product Owner decision (docs/Performance_Architecture.md: "No queue,
 * no Redis, no Horizon, no background worker, no scheduled task will be
 * introduced as a general architectural change") — this command exists,
 * is fully idempotent, and is covered by tests; an operator (or a
 * future, explicitly-approved cron entry) invokes it directly:
 * `php artisan subscriptions:expire-trials`.
 */
class ExpireTrials extends Command
{
    protected $signature = 'subscriptions:expire-trials';

    protected $description = 'Move every tenant whose Trial has expired to the Free Plan.';

    public function __construct(
        private readonly SubscriptionService $subscriptions,
        private readonly CustomerReadOnlyService $customerReadOnly,
    ) {
        parent::__construct();
    }

    public function handle(): int
    {
        $affectedTenants = $this->subscriptions->expireTrials();

        // "Customer/Storage limits immediately become Free limits" — the
        // orchestrating step SubscriptionService itself cannot perform
        // (it would create a circular dependency on CustomerReadOnlyService,
        // which already depends on SubscriptionService). Storage needs no
        // equivalent call: storage usage is always computed live against
        // the current plan, never a stored/cached flag.
        foreach ($affectedTenants as $tenant) {
            $this->customerReadOnly->recalculate($tenant);
        }

        $this->info("Moved {$affectedTenants->count()} tenant(s) from an expired Trial to the Free Plan.");

        return self::SUCCESS;
    }
}
