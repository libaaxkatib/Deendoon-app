<?php

namespace App\Services;

use App\Events\CreditLimitReached;
use App\Models\Customer;

/**
 * BRL-022: Customer Outstanding Balance = Sum(Remaining Balance across all
 * of the Customer's open Debts) — "open" meaning not Paid, Cancelled, or
 * Written Off. Archived-but-non-terminal Debts still count (BRL-022 Notes;
 * DD-007 leaves whether that's ultimately correct unresolved, so this
 * takes the more inclusive, explicitly-stated reading rather than
 * guessing narrower). Recomputed from source on every call rather than
 * incremented/decremented, to avoid drift.
 */
class CustomerBalanceService
{
    public function recalculate(Customer $customer): void
    {
        $wasOverLimit = bccomp((string) $customer->outstanding_balance, (string) $customer->credit_limit, 2) >= 0;

        $outstanding = $customer->debts()
            ->withTrashed()
            ->whereNotIn('debt_status', ['paid', 'cancelled', 'written_off'])
            ->sum('remaining_balance');

        $customer->outstanding_balance = $outstanding;
        $customer->save();

        // FR-028: Outstanding Balance reaches or exceeds Credit Limit. Fires
        // only on the transition into over-limit (matches FR-028 Exception
        // E1's "once per qualifying event") — not on every recalculation
        // while the customer remains over-limit, which would otherwise
        // re-fire on every subsequent payment against them. Mirrors the
        // transition-only pattern already used elsewhere in this codebase
        // (e.g. RiskLevelService::apply(), PaymentService::recalculateDebt()).
        $isOverLimit = bccomp((string) $outstanding, (string) $customer->credit_limit, 2) >= 0;
        if (! $wasOverLimit && $isOverLimit) {
            CreditLimitReached::dispatch($customer);
        }
    }
}
