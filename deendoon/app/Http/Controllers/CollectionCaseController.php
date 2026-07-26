<?php

namespace App\Http\Controllers;

use App\Http\Requests\AssignCollectionCaseRequest;
use App\Http\Requests\CloseCollectionCaseRequest;
use App\Http\Requests\EscalateDebtRequest;
use App\Http\Requests\RecordCollectionActivityRequest;
use App\Http\Requests\UpdateCollectionCaseRequest;
use App\Http\Resources\CollectionCaseResource;
use App\Models\AuditLog;
use App\Models\CollectionCase;
use App\Models\Debt;
use App\Models\User;
use App\Services\CollectionCaseService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CollectionCaseController extends Controller
{
    use ApiResponse;

    public function __construct(private readonly CollectionCaseService $collectionCases) {}

    public function store(EscalateDebtRequest $request, Debt $debt): JsonResponse
    {
        $this->authorize('escalate', $debt);

        $case = $this->collectionCases->escalate($debt, $request->user());

        return $this->successResponse(new CollectionCaseResource($case), 'Debt escalated to Professional Collection successfully', 201);
    }

    public function index(Request $request): JsonResponse
    {
        $this->authorize('viewAny', CollectionCase::class);

        $query = CollectionCase::query();

        if ($status = $request->string('status')->trim()->value()) {
            $query->where('case_status', $status);
        }

        $cases = $query->orderBy('created_at', 'desc')->paginate(
            perPage: $this->perPage($request),
        );

        return $this->successResponse([
            'collection_cases' => CollectionCaseResource::collection($cases->items()),
            'pagination' => [
                'current_page' => $cases->currentPage(),
                'per_page' => $cases->perPage(),
                'total' => $cases->total(),
                'last_page' => $cases->lastPage(),
            ],
        ]);
    }

    public function show(CollectionCase $case): JsonResponse
    {
        $this->authorize('view', $case);

        return $this->successResponse(new CollectionCaseResource($case));
    }

    public function assign(AssignCollectionCaseRequest $request, CollectionCase $case): JsonResponse
    {
        $this->authorize('manage', $case);

        $officer = User::find($request->validated('officer_user_id'));

        if (! $officer) {
            return $this->errorResponse(
                'The selected user does not exist.',
                ['officer_user_id' => ['The selected user does not exist.']],
            );
        }

        $this->collectionCases->assign($case, $officer, $request->user());

        return $this->successResponse(new CollectionCaseResource($case->fresh()), 'Collection Case assigned successfully');
    }

    public function update(UpdateCollectionCaseRequest $request, CollectionCase $case): JsonResponse
    {
        $this->authorize('manage', $case);

        if ($case->case_status !== 'open') {
            return $this->errorResponse('This action is not permitted on a Closed Collection Case.', null, 409);
        }

        return $this->successResponse(new CollectionCaseResource($case), 'Collection Case updated successfully');
    }

    public function recordActivity(RecordCollectionActivityRequest $request, CollectionCase $case): JsonResponse
    {
        $this->authorize('manage', $case);

        $this->collectionCases->recordActivity($case, $request->validated('details'), $request->user());

        return $this->successResponse(new CollectionCaseResource($case->fresh()), 'Collection activity recorded successfully');
    }

    public function close(CloseCollectionCaseRequest $request, CollectionCase $case): JsonResponse
    {
        $this->authorize('manage', $case);

        $this->collectionCases->close($case, $request->validated('closure_outcome'), $request->user());

        return $this->successResponse(new CollectionCaseResource($case->fresh()), 'Collection Case closed successfully');
    }

    public function history(CollectionCase $case): JsonResponse
    {
        $this->authorize('view', $case);

        $activities = $case->debt->followUpHistory()
            ->where('collection_case_id', $case->id)
            ->get()
            ->map(fn ($entry) => [
                'source' => 'follow_up_history',
                'action' => $entry->action_type,
                'details' => $entry->details,
                'actor_user_id' => $entry->actor_user_id,
                'occurred_at' => $entry->occurred_at,
            ]);

        $auditEvents = AuditLog::where('entity_type', 'collection_case')
            ->where('entity_id', $case->id)
            ->get()
            ->map(fn ($entry) => [
                'source' => 'audit_log',
                'action' => $entry->action,
                'details' => $entry->reason,
                'actor_user_id' => $entry->user_id,
                'occurred_at' => $entry->occurred_at,
            ]);

        $history = $activities->concat($auditEvents)->sortBy('occurred_at')->values();

        return $this->successResponse(['collection_case_id' => $case->id, 'history' => $history]);
    }
}
