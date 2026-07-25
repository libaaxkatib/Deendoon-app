<?php

namespace App\Events;

use App\Models\PromiseToPay;
use Illuminate\Foundation\Events\Dispatchable;

/**
 * FR-031 step 4/BRL-034: promised date passed with no qualifying payment.
 * Approved via follow_up_history.action_type = 'promise_broken'
 * (06_Database_Design.md §6.3). Promoted to a real dispatched event
 * (rather than just a recorded follow_up_history row, like most Module 3
 * lifecycle occurrences) because it has a genuine downstream consequence
 * within this same module — Recovery Stage advancement to Stage 4
 * (BRL-031) — handled by a listener rather than inline coupling.
 *
 * BRL-034's other downstream effect (a Credit Score point deduction) is
 * NOT triggered here: DD-009 (point-value catalog) is unresolved, per the
 * Credit & Risk Module report. No listener performs it.
 */
class PromiseBroken
{
    use Dispatchable;

    public function __construct(
        public readonly PromiseToPay $promise,
    ) {}
}
