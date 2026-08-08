<?php

namespace App\Services;

use App\Enums\AuditAction;
use App\Models\Debt;
use App\Models\User;

/**
 * BRL-031's stage table drives every call site: Stage 2 (Late Reminder —
 * Overdue + a subsequent reminder), Stage 3 (Phone Follow-up — a Call is
 * logged), Stage 4 (Final Notice — a Promise is broken), Stage 6
 * (Recovered — Debt reaches Paid status, Module 6). Stage 5 (Professional
 * Collection) requires Module 7 and is not reachable through this service.
 *
 * No audit_log.action value exists for an automatic stage change — only
 * `recovery_stage_override` exists, and FR-025 describes that as
 * specifically manual. Rather than invent a new action value, this reuses
 * the existing `status_changed` action with a descriptive reason, the
 * same pattern already used for Risk Level changes. Flagged as a
 * NON-BLOCKING SRS gap in the report, not silently resolved.
 */
class RecoveryStageService
{
    public function __construct(
        private readonly AuditLogService $auditLog,
        private readonly RiskLevelService $riskLevel,
        private readonly CreditScoreService $creditScore,
    ) {}

    public function advanceTo(Debt $debt, int $stage, string $reason, ?User $actor = null): void
    {
        if ($debt->recovery_stage >= $stage) {
            return;
        }

        $debt->update(['recovery_stage' => $stage]);

        $this->auditLog->record(AuditAction::StatusChanged, 'debt', $debt->id, $actor, $reason);

        // Risk Level Engine (Sprint 2B): Recovery Stage Advancement.
        $this->riskLevel->recalculate($debt->customer);
        // Credit Score (FR-026, Business Owner Backend Completion): always
        // recalculated at the exact same trigger points as Risk Level.
        $this->creditScore->recalculate($debt->customer);
    }
}
