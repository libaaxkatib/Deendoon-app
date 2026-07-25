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
        $outstanding = $customer->debts()
            ->withTrashed()
            ->whereNotIn('debt_status', ['paid', 'cancelled', 'written_off'])
            ->sum('remaining_balance');

        $customer->outstanding_balance = $outstanding;
        $customer->save();

        // FR-028: Outstanding Balance reaches or exceeds Credit Limit.
        if (bccomp((string) $outstanding, (string) $customer->credit_limit, 2) >= 0) {
            CreditLimitReached::dispatch($customer);
        }
    }
}
