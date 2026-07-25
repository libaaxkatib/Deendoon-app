<?php

namespace App\Services;

use App\Enums\AuditAction;
use App\Enums\FollowUpActionType;
use App\Models\Debt;
use App\Models\Payment;
use App\Models\User;
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
 * - Receipt Generation *metadata* only (FR-038): an audit-trail event
 *   recording that generation was triggered. The actual Receipt entity
 *   (PDF, `RCT-` numbering, `receipts` table) is owned by Module 8 —
 *   Documents, which does not exist yet; nothing here fabricates it.
 *
 * Deliberately NOT implemented (see the module report):
 * - Crediting Module 4 (Credit & Risk) with an on-time/late/partial
 *   classification for scoring — Module 4's scoring computation itself
 *   remains deferred (DD-008/DD-009), so there is no consumer to classify
 *   for, and no approved enum slot to store the classification distinctly.
 * - Overpayment capping/rejection — DD-016 is unresolved; `amount` is only
 *   validated as positive (BRL-037), matching `06`'s and `07`'s explicit
 *   posture that this endpoint "succeeds unconditionally" for now.
 * - Payment against Paid/Cancelled/Written Off Debts is not blocked beyond
 *   the Archived check — DD-017 is unresolved (see the module report for
 *   the exact SRS inconsistency between BRL-037's text and DD-017/BRL-041).
 */
class PaymentService
{
    public function __construct(
        private readonly AuditLogService $auditLog,
        private readonly FollowUpHistoryService $followUpHistory,
        private readonly CustomerBalanceService $balances,
        private readonly PromiseToPayService $promiseToPay,
        private readonly RecoveryStageService $recoveryStage,
    ) {}

    /**
     * @param  array{amount: string|float, payment_date: string, payment_method?: ?string, reference_notes?: ?string}  $data
     */
    public function record(Debt $debt, array $data, User $actor): Payment
    {
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

            $this->auditLog->record(AuditAction::ReceiptGenerated, 'payment', $payment->id);

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
}
