<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * Backend v2.1 (docs/Mobile_UI_V1_Frozen.md §6.1, §6.3;
 * docs/Backend_v2.1_REST_API_Specification.md §5) requires the Case List
 * and Case Details screens to render customer name, outstanding amount,
 * risk level, and last-activity time directly on each case — previously
 * only case-internal fields were exposed here, forcing an extra lookup
 * per case. Adds those fields by reading the already-loaded `debt.customer`
 * relationship (see `CollectionCaseController::with(['debt.customer'])`)
 * rather than introducing a new query per case.
 */
class CollectionCaseResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'debt_id' => $this->debt_id,
            'customer_id' => $this->debt?->customer_id,
            'customer_name' => $this->debt?->customer?->name,
            'outstanding_amount' => $this->debt?->remaining_balance,
            'risk_level' => $this->debt?->customer?->risk_level,
            'reference_number' => $this->reference_number,
            'assigned_officer_user_id' => $this->assigned_officer_user_id,
            'case_status' => $this->case_status,
            'closure_outcome' => $this->closure_outcome,
            // Reflects the most recent recorded activity against the case
            // (escalation, assignment, activity, closure all update this
            // timestamp) — see CollectionCaseService, which now touches the
            // case on recordActivity() too, per §6.1's "Last activity" rule.
            'last_activity_at' => $this->updated_at,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
            'closed_at' => $this->closed_at,
        ];
    }
}
