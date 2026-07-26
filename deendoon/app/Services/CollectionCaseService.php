<?php

namespace App\Services;

use App\Enums\AuditAction;
use App\Enums\FollowUpActionType;
use App\Enums\NotificationType;
use App\Models\CollectionCase;
use App\Models\Debt;
use App\Models\User;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Support\Facades\DB;

/**
 * FR-040–046 — Professional Collection's case-management layer over an
 * existing Debt. Reuses ReferenceNumberService (COL- numbering),
 * AuditLogService, FollowUpHistoryService, and RecoveryStageService
 * exactly as already built for Modules 3/5/6 — no logic is duplicated.
 *
 * State-conflict errors are raised via HttpResponseException carrying a
 * pre-built {success,message,data,errors} JSON response, not
 * ValidationException — the project's global exception handler
 * (bootstrap/app.php) hardcodes 422 for every ValidationException
 * regardless of any ->status() override, which would silently downgrade
 * every 409 CONFLICT this module needs (07_API_Design.md §4 explicitly
 * names FR-045 E2 and BRL-078 as 409 examples). HttpResponseException is
 * returned by Laravel's handler unmodified, so the intended status code
 * and envelope both survive.
 */
class CollectionCaseService
{
    public function __construct(
        private readonly ReferenceNumberService $referenceNumbers,
        private readonly AuditLogService $auditLog,
        private readonly FollowUpHistoryService $followUpHistory,
        private readonly RecoveryStageService $recoveryStage,
        private readonly NotificationService $notifications,
    ) {}

    /**
     * BRL-045/FR-040: creates a Collection Case referencing exactly one
     * Debt. FR-040's Main Flow names two alternative triggers — Module 5
     * automatically reaching Recovery Stage 5, or an authorized user
     * manually escalating — but BRL-031's own stage table defines Stage 5
     * as "Entered When: Debt is escalated to a Collection Case," i.e. case
     * creation is the cause and Stage 5 is the effect, the same direction
     * as Stage 6 (Payment reaching Paid, Module 6). There is no other
     * approved mechanism that independently advances a Debt to Stage 5
     * before a case exists. Given that, every call to this method is
     * treated as the "manual escalation" trigger (DD-014 leaves early
     * manual escalation unresolved but does not forbid it), and Stage 5 is
     * advanced as a synchronous consequence — flagged as a NON-BLOCKING
     * SRS circularity in the module report, not silently resolved.
     */
    public function escalate(Debt $debt, User $actor): CollectionCase
    {
        if ($debt->collectionCases()->where('case_status', 'open')->exists()) {
            $this->conflict('This Debt already has an open Collection Case.');
        }

        return DB::transaction(function () use ($debt, $actor) {
            $referenceNumber = $this->referenceNumbers->next('collection_cases', $debt->tenant_id, 'COL');

            $case = new CollectionCase([
                'debt_id' => $debt->id,
                'reference_number' => $referenceNumber,
                'case_status' => 'open',
            ]);
            $case->save();

            $this->auditLog->record(AuditAction::CollectionRequested, 'collection_case', $case->id, $actor);
            $this->followUpHistory->record($debt, FollowUpActionType::Escalated, $actor, null, $case->id);
            $this->recoveryStage->advanceTo($debt, 5, 'Recovery Stage advanced to 5 (Professional Collection): Debt escalated to Collection Case', $actor);

            return $case->refresh();
        });
    }

    public function assign(CollectionCase $case, User $officer, User $actor): void
    {
        $this->assertOpen($case);

        if (! $officer->hasRole('collection_officer') || $officer->tenant_id !== $case->tenant_id) {
            throw new HttpResponseException(response()->json([
                'success' => false,
                'message' => 'The selected user does not hold the Collection Officer role for this tenant.',
                'data' => null,
                'errors' => ['officer_user_id' => ['The selected user does not hold the Collection Officer role for this tenant.']],
            ], 422));
        }

        $case->update(['assigned_officer_user_id' => $officer->id]);

        $this->auditLog->record(AuditAction::Edited, 'collection_case', $case->id, $actor, 'Assigned Officer changed');

        // FR-058: recipient is the newly assigned officer, not the acting
        // user who performed the assignment.
        $this->notifications->notify($case->tenant_id, (string) $officer->id, NotificationType::CollectionAssignment, 'collection_case', $case->id);
    }

    public function recordActivity(CollectionCase $case, ?string $details, User $actor): void
    {
        $this->assertOpen($case);

        $this->followUpHistory->record($case->debt, FollowUpActionType::CollectionActivity, $actor, $details, $case->id);
        $this->auditLog->record(AuditAction::Edited, 'collection_case', $case->id, $actor, 'Collection activity recorded');
    }

    public function close(CollectionCase $case, string $closureOutcome, User $actor): void
    {
        if ($case->case_status === 'closed') {
            $this->conflict('This Collection Case is already closed.');
        }

        $case->update([
            'case_status' => 'closed',
            'closure_outcome' => $closureOutcome,
            'closed_at' => now(),
        ]);

        $this->auditLog->record(AuditAction::StatusChanged, 'collection_case', $case->id, $actor, 'Collection Case closed');
    }

    private function assertOpen(CollectionCase $case): void
    {
        if ($case->case_status !== 'open') {
            $this->conflict('This action is not permitted on a Closed Collection Case.');
        }
    }

    private function conflict(string $message): never
    {
        throw new HttpResponseException(response()->json([
            'success' => false,
            'message' => $message,
            'data' => null,
            'errors' => null,
        ], 409));
    }
}
