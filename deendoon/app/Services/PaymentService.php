<?php

namespace App\Services;

use App\Enums\AuditAction;
use App\Enums\FollowUpActionType;
use App\Enums\NotificationType;
use App\Models\Debt;
use App\Models\Payment;
use App\Models\User;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Support\Facades\DB;

/**
 * FR-034/036/037/038/039 — Payment Tracking is the sole owner of Debt
 * financial-state transitions (Module 6, Scope Boundary). Orchestrates
 * every approved downstream consequence of recording a payment, in one
 * transaction:
 * - Debt remaining balance + status (BRL-039).
 * - Customer Outstanding Balance / Remaining Credit, via the existing
 *   CustomerBalanceService (FR-036) — unchanged, reused as-is.
 * - Follow-up History + Audit Trail (FR-034, BRL-037).
 * - Promise to Pay fulfillment (BRL-032), via the existing
 *   PromiseToPayService.
 * - Recovery Stage 6 — Recovered (BRL-031), via the existing
 *   RecoveryStageService, entered only when the Debt reaches Paid.
 * - Receipt Generation (FR-038/FR-047), via DocumentService (Module 8) —
 *   generates the real Receipt entity, PDF, and `RCT-` numbering.
 *   DocumentService itself never rolls back on generation failure (FR-047
 *   E1), so this call is fire-and-forget from Payment Recording's
 *   perspective.
 * - Payment Received Notification (FR-058), via NotificationService
 *   (Module 10) — recorded synchronously in the same transaction.
 *
 * DD-016/DD-017 (Business Owner Backend Completion, pre-Phase 5,
 * Product Owner-approved decision): both are now resolved. A payment
 * against a Debt already in a terminal status (Paid/Cancelled/Written
 * Off) is rejected (422), and a payment amount exceeding the Debt's
 * current remaining_balance is rejected (422) rather than accepted and
 * capped — every recorded Payment's `amount` must equal what was
 * genuinely applied to that Debt. Refund/credit-balance handling is
 * explicitly out of scope until designed as its own feature.
 */
class PaymentService
{
    private const TERMINAL_DEBT_STATUSES = ['paid', 'cancelled', 'written_off'];

    public function __construct(
        private readonly AuditLogService $auditLog,
        private readonly FollowUpHistoryService $followUpHistory,
        private readonly CustomerBalanceService $balances,
        private readonly PromiseToPayService $promiseToPay,
        private readonly RecoveryStageService $recoveryStage,
        private readonly DocumentService $documents,
        private readonly NotificationService $notifications,
        private readonly RiskLevelService $riskLevel,
        private readonly CreditScoreService $creditScore,
    ) {}

    /**
     * @param  array{amount: string|float, payment_date: string, payment_method?: ?string, reference_notes?: ?string}  $data
     */
    public function record(Debt $debt, array $data, User $actor): Payment
    {
        if (in_array($debt->debt_status, self::TERMINAL_DEBT_STATUSES, true)) {
            $this->reject('This Debt has already reached a terminal status (Paid, Cancelled, or Written Off) and cannot receive further payments.');
        }

        if (bccomp((string) $data['amount'], (string) $debt->remaining_balance, 2) > 0) {
            $this->reject('This payment amount exceeds the Debt\'s remaining balance.');
        }

        return DB::transaction(function () use ($debt, $data, $actor) {
            $payment = new Payment([
                'debt_id' => $debt->id,
                'amount' => $data['amount'],
                'payment_date' => $data['payment_date'],
                'payment_method' => $data['payment_method'] ?? null,
                'reference_notes' => $data['reference_notes'] ?? null,
            ]);
            $payment->recorded_by_user_id = $actor->id;
            $payment->save();

            $this->auditLog->record(AuditAction::PaymentAdded, 'debt', $debt->id, $actor);
            $this->followUpHistory->record($debt, FollowUpActionType::PaymentRecorded, $actor);

            $this->recalculateDebt($debt);
            $this->balances->recalculate($debt->customer);
            $this->promiseToPay->evaluateFulfillment($debt, $payment->payment_date->toDateString());

            // Risk Level Engine (Sprint 2B): Fulfilled Promise to Pay, Debt
            // Recovered/Paid in Full, Sustained Positive Repayment Behavior,
            // and Long Outstanding Debt (remaining_balance may have just
            // reached 0) are all re-evaluated together here, once, after
            // every side effect of this payment has already been applied.
            $this->riskLevel->recalculate($debt->customer);
            // Credit Score (FR-026, Business Owner Backend Completion):
            // always recalculated at the exact same trigger points as Risk
            // Level.
            $this->creditScore->recalculate($debt->customer);

            $this->documents->generateReceipt($payment);

            // FR-058/BR-007: "Payment Received" — recipient is the user who
            // recorded the payment (the only real actor available here).
            $this->notifications->notify($debt->tenant_id, (string) $actor->id, NotificationType::PaymentReceived, 'payment', $payment->id);

            return $payment->refresh();
        });
    }

    /**
     * BRL-039: `0 < cumulative < amount` → Partial Paid; `cumulative >=
     * amount` → Paid. The Status Changed event is attributed to "System"
     * (no actor), matching FR-037 step 4's literal text — distinct from
     * the Payment Added event, which is attributed to the recording user
     * (FR-034 step 6). Recovery Stage 6 is entered only on an actual
     * transition into Paid, never re-fired for a later payment that keeps
     * the Debt at Paid (RecoveryStageService already no-ops below the
     * current stage regardless, but this also avoids a redundant audit
     * entry for a status that hasn't changed).
     */
    private function recalculateDebt(Debt $debt): void
    {
        $totalPaid = (string) $debt->payments()->sum('amount');
        $remaining = bcsub((string) $debt->amount, $totalPaid, 2);
        $previousStatus = $debt->debt_status;
        $newStatus = bccomp($totalPaid, (string) $debt->amount, 2) >= 0 ? 'paid' : 'partial_paid';

        $debt->update([
            'remaining_balance' => $remaining,
            'debt_status' => $newStatus,
        ]);

        if ($newStatus === $previousStatus) {
            return;
        }

        $this->auditLog->record(AuditAction::StatusChanged, 'debt', $debt->id, null, 'Automatic: payment recorded');

        if ($newStatus === 'paid') {
            $this->recoveryStage->advanceTo($debt, 6, 'Recovery Stage advanced to 6 (Recovered): Debt reached Paid status');
        }
    }

    /**
     * Matches DebtController::updateStatus()'s existing convention for a
     * rejected terminal-state/business-rule violation: 422, not 409 —
     * this is a request the client should not retry as-is, not a
     * transient conflict.
     */
    private function reject(string $message): never
    {
        throw new HttpResponseException(response()->json([
            'success' => false,
            'message' => $message,
            'data' => null,
            'errors' => null,
        ], 422));
    }
}
