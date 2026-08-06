<?php

namespace App\Console\Commands;

use App\Services\CustomerReadOnlyService;
use App\Services\SubscriptionService;
use Illuminate\Console\Command;

/**
 * Backend Completion Roadmap, Phase 4.3 — Subscription Lifecycle.
 *
 * NOT registered against Illuminate\Console\Scheduling — see
 * {@see ExpireTrials}'s identical docblock for the standing Product
 * Owner decision this follows. Invoked directly:
 * `php artisan subscriptions:expire`.
 *
 * Backend Completion Roadmap, Phase 4.4 — Feature & Read-Only
 * Enforcement: now also triggers {@see CustomerReadOnlyService::recalculate()}
 * per affected tenant, same orchestration role {@see ExpireTrials} already
 * plays — required because {@see SubscriptionService::effectiveCustomerLimit()}
 * now treats an `expired` subscription as a 0 customer limit.
 */
class ExpireSubscriptions extends Command
{
    protected $signature = 'subscriptions:expire';

    protected $description = 'Mark every paid subscription whose current period has ended, and was not renewed, as expired.';

    public function __construct(
        private readonly SubscriptionService $subscriptions,
        private readonly CustomerReadOnlyService $customerReadOnly,
    ) {
        parent::__construct();
    }

    public function handle(): int
    {
        $affectedTenants = $this->subscriptions->expireSubscriptions();

        foreach ($affectedTenants as $tenant) {
            $this->customerReadOnly->recalculate($tenant);
        }

        $this->info("Expired {$affectedTenants->count()} subscription(s).");

        return self::SUCCESS;
    }
}
