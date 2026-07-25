<?php

namespace App\Http\Controllers;

use App\Http\Resources\FollowUpHistoryResource;
use App\Models\Debt;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;

/**
 * FR-033: read-only, chronological Follow-up History log for a Debt. No
 * independent creation path — entries are written only as a side effect
 * of the actions in FR-029-031 (ReminderController, PromiseToPayController).
 */
class FollowUpHistoryController extends Controller
{
    use ApiResponse;

    public function index(Debt $debt): JsonResponse
    {
        $this->authorize('view', $debt);

        $history = $debt->followUpHistory()->orderBy('occurred_at', 'desc')->get();

        return $this->successResponse(FollowUpHistoryResource::collection($history));
    }
}
