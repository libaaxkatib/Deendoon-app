<?php

namespace App\Services;

use App\Enums\FollowUpActionType;
use App\Models\Debt;
use App\Models\FollowUpHistory;
use App\Models\User;

/**
 * FR-033: every recovery-related action is logged as a chronological
 * Follow-up History entry, attributed to the initiating user (NULL for
 * system-automated actions).
 */
class FollowUpHistoryService
{
    public function record(
        Debt $debt,
        FollowUpActionType $actionType,
        ?User $actor = null,
        ?string $details = null,
        ?string $collectionCaseId = null,
    ): FollowUpHistory {
        return $debt->followUpHistory()->create([
            'action_type' => $actionType->value,
            'collection_case_id' => $collectionCaseId,
            'details' => $details,
            'actor_user_id' => $actor?->id,
            'occurred_at' => now(),
        ]);
    }
}
