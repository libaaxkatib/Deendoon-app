<?php

namespace App\Services;

use App\Enums\AuditAction;
use App\Enums\FollowUpActionType;
use App\Events\PromiseBroken;
use App\Models\Debt;
use App\Models\PromiseToPay;

/**
 * FR-031 step 4: "On or after the promised date, system evaluates whether
 * the promise was kept (payment recorded, Module 6) or broken." Module 6
 * doesn't exist, so "kept via payment" can never be evaluated — but
 * because zero payments can exist anywhere in the system today, BRL-034's
 * own trigger condition ("promised date passes with no qualifying
 * payment") is unconditionally satisfied for any still-open promise past
 * its date. This applies BRL-034's stated condition to the system's
 * current state; it does not invent a shortcut around it.
 *
 * Implemented as a lazy, on-access check (same pattern as Debt's
 * refreshOverdueStatus) rather than a scheduled job, for the same reason:
 * no scheduler/queue infrastructure decision has been made yet.
 */
class PromiseToPayService
{
    public function __construct(
        private readonly AuditLogService $auditLog,
        private readonly FollowUpHistoryService $followUpHistory,
    ) {}

    public function refreshBrokenPromises(Debt $debt): void
    {
        $debt->promisesToPay()
            ->where('status', 'open')
            ->where('promised_date', '<', now()->toDateString())
            ->get()
            ->each(function (PromiseToPay $promise) use ($debt) {
                $promise->update(['status' => 'broken', 'resolved_at' => now()]);

                $this->followUpHistory->record(
                    $debt,
                    FollowUpActionType::PromiseBroken,
                    null,
                    'Automatic: promised date passed with no qualifying payment',
                );

                $this->auditLog->record(
                    AuditAction::StatusChanged,
                    'promise_to_pay',
                    $promise->id,
                    null,
                    'Automatic: promise broken',
                );

                PromiseBroken::dispatch($promise);
            });
    }
}
