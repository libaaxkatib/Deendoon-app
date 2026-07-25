<?php

namespace App\Events;

use App\Models\Customer;
use Illuminate\Foundation\Events\Dispatchable;

/**
 * FR-028: "System generates a Credit Limit Reached event and passes it to
 * the Reminder Engine." This is the trigger only — FR-028 itself states
 * delivery/display belongs to Module 10 (Notifications & Calendar), which
 * does not exist yet. No listener is registered; nothing consumes this
 * event today.
 *
 * DD-011 (re-trigger/suppression policy) is unresolved in
 * 04_Business_Rules.md, so this is dispatched every time a balance
 * recalculation results in a qualifying state, without attempting to
 * suppress repeat firings while the condition remains true — inventing a
 * de-duplication rule here would be deciding DD-011, not implementing it.
 */
class CreditLimitReached
{
    use Dispatchable;

    public function __construct(
        public readonly Customer $customer,
    ) {}
}
