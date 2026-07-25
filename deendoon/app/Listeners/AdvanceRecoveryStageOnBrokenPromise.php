<?php

namespace App\Listeners;

use App\Events\PromiseBroken;
use App\Services\RecoveryStageService;

class AdvanceRecoveryStageOnBrokenPromise
{
    public function __construct(
        private readonly RecoveryStageService $recoveryStage,
    ) {}

    public function handle(PromiseBroken $event): void
    {
        $this->recoveryStage->advanceTo(
            debt: $event->promise->debt,
            stage: 4,
            reason: 'Recovery Stage advanced to 4 (Final Notice): Promise to Pay broken',
        );
    }
}
