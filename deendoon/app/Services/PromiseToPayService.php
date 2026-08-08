<?php

namespace App\Services;

use App\Enums\AuditAction;
use App\Enums\FollowUpActionType;
use App\Enums\NotificationType;
use App\Events\PromiseBroken;
use App\Models\Debt;
use App\Models\PromiseToPay;
use Illuminate\Support\Collection;

/**
 * FR-031 step 4 / BRL-032: a Promise to Pay is evaluated against whichever
 * of its two outcomes applies first — fulfilled (a qualifying payment is
 * recorded on or before the promised date, Module 6, `evaluateFulfillment`)
 * or broken (the promised date passes with no qualifying payment,
 * `refreshBrokenPromises`). Both are implemented as on-access/on-event
 * checks rather than a scheduled job — no scheduler/queue infrastructure
 * decision has been made yet — `refreshBrokenPromises` lazily on Debt
 * access (same pattern as Debt's `refreshOverdueStatus`), and
 * `evaluateFulfillment` synchronously when Module 6 records a payment.
 *
 * `refreshDuePromises` (Module 10, FR-058/FR-062) adds a third, similarly
 * lazy check: an open Promise whose date is exactly today. Unlike the
 * open→broken/fulfilled transitions, "due today" has no state of its own
 * to naturally stop re-evaluating true across repeated page views within
 * the same day — `NotificationService::notifyOnce` guards against
 * re-creating the same notification on every request.
 *
 * `refreshBrokenPromisesForMany`/`refreshDuePromisesForMany` (Phase 13
 * performance pass) exist solely to let `DebtController::index()` apply
 * the exact same per-promise logic across a whole page of Debts with one
 * query per check instead of one per Debt — the single-Debt methods below
 * remain unchanged for `DebtController::show()` and every other call site.
 * A promise can never match both the "broken" (`promised_date <` today)
 * and "due" (`promised_date =` today) queries at once, so batching across
 * Debts changes nothing about which promises transition or what side
 * effects fire for each — only the number of SELECT queries issued.
 */
class PromiseToPayService
{
    public function __construct(
        private readonly AuditLogService $auditLog,
        private readonly FollowUpHistoryService $followUpHistory,
        private readonly NotificationService $notifications,
        private readonly RiskLevelService $riskLevel,
        private readonly CreditScoreService $creditScore,
    ) {}

    public function refreshBrokenPromises(Debt $debt): void
    {
        $debt->promisesToPay()
            ->where('status', 'open')
            ->where('promised_date', '<', now()->toDateString())
            ->get()
            ->each(fn (PromiseToPay $promise) => $this->markBroken($promise, $debt));
    }

    /**
     * @param  Collection<int, Debt>  $debts
     */
    public function refreshBrokenPromisesForMany(Collection $debts): void
    {
        if ($debts->isEmpty()) {
            return;
        }

        $debtsById = $debts->keyBy('id');

        PromiseToPay::whereIn('debt_id', $debtsById->keys())
            ->where('status', 'open')
            ->where('promised_date', '<', now()->toDateString())
            ->get()
            ->each(fn (PromiseToPay $promise) => $this->markBroken($promise, $debtsById->get($promise->debt_id)));
    }

    private function markBroken(PromiseToPay $promise, Debt $debt): void
    {
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

        // Risk Level Engine (Sprint 2B): Broken Promise to Pay + Repeated
        // Missed Commitments (the rolling 12-month pattern check).
        $this->riskLevel->recalculate($debt->customer);
        // Credit Score (FR-026, Business Owner Backend Completion): always
        // recalculated at the exact same trigger points as Risk Level.
        $this->creditScore->recalculate($debt->customer);
    }

    /**
     * BRL-032: "fulfilled" is any payment that closes *or reduces* the Debt,
     * recorded on or before the promised date — not only a full payoff.
     * Only `open` promises are eligible (no path back from `broken`, which
     * is a resolved terminal state per the approved status enum). Not
     * promoted to a dispatched Event — unlike PromiseBroken (BRL-034), no
     * approved Business Rule ties Promise fulfillment to a further
     * cross-cutting consequence such as Recovery Stage.
     */
    public function evaluateFulfillment(Debt $debt, string $paymentDate): void
    {
        $debt->promisesToPay()
            ->where('status', 'open')
            ->where('promised_date', '>=', $paymentDate)
            ->get()
            ->each(function (PromiseToPay $promise) use ($debt) {
                $promise->update(['status' => 'fulfilled', 'resolved_at' => now()]);

                $this->followUpHistory->record(
                    $debt,
                    FollowUpActionType::PromiseFulfilled,
                    null,
                    'Automatic: qualifying payment recorded on or before the promised date',
                );

                $this->auditLog->record(
                    AuditAction::StatusChanged,
                    'promise_to_pay',
                    $promise->id,
                    null,
                    'Automatic: promise fulfilled',
                );
            });
    }

    /**
     * FR-062 (Calendar) surfaces every open Promise regardless of date;
     * this is specifically FR-058's "Promise to Pay Due" Notification —
     * fired once per Promise, on the day it's due, for whoever created it
     * (PromiseToPay.created_by_user_id — the only real, already-known
     * "interested party," since a Promise has no assigned-officer-style
     * owner field of its own).
     */
    public function refreshDuePromises(Debt $debt): void
    {
        $debt->promisesToPay()
            ->where('status', 'open')
            ->whereDate('promised_date', '=', now()->toDateString())
            ->get()
            ->each(fn (PromiseToPay $promise) => $this->notifyDue($promise, $debt));
    }

    /**
     * @param  Collection<int, Debt>  $debts
     */
    public function refreshDuePromisesForMany(Collection $debts): void
    {
        if ($debts->isEmpty()) {
            return;
        }

        $debtsById = $debts->keyBy('id');

        PromiseToPay::whereIn('debt_id', $debtsById->keys())
            ->where('status', 'open')
            ->whereDate('promised_date', '=', now()->toDateString())
            ->get()
            ->each(fn (PromiseToPay $promise) => $this->notifyDue($promise, $debtsById->get($promise->debt_id)));
    }

    private function notifyDue(PromiseToPay $promise, Debt $debt): void
    {
        $this->notifications->notifyOnce(
            $debt->tenant_id,
            $promise->created_by_user_id,
            NotificationType::PromiseToPayDue,
            'promise_to_pay',
            $promise->id,
        );
    }
}
