<?php

namespace App\Http\Controllers;

use App\Enums\AuditAction;
use App\Enums\FollowUpActionType;
use App\Http\Requests\CloseCollectionCaseRequest;
use App\Http\Requests\EscalateDebtRequest;
use App\Http\Requests\RecordCollectionActivityRequest;
use App\Http\Requests\UpdateCollectionCaseRequest;
use App\Http\Requests\UploadCollectionCaseAttachmentRequest;
use App\Http\Resources\CollectionCaseAttachmentResource;
use App\Http\Resources\CollectionCaseResource;
use App\Models\AuditLog;
use App\Models\CollectionCase;
use App\Models\Debt;
use App\Services\AuditLogService;
use App\Services\CollectionCaseService;
use App\Services\DocumentService;
use App\Traits\ApiResponse;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CollectionCaseController extends Controller
{
    use ApiResponse;

    public function __construct(
        private readonly CollectionCaseService $collectionCases,
        private readonly AuditLogService $auditLog,
        private readonly DocumentService $documents,
    ) {}

    public function store(EscalateDebtRequest $request, Debt $debt): JsonResponse
    {
        $this->authorize('escalate', $debt);

        $case = $this->collectionCases->escalate($debt, $request->user());

        return $this->successResponse(new CollectionCaseResource($case), 'Debt escalated to Professional Collection successfully', 201);
    }

    /**
     * Backend v2.1 (docs/Mobile_UI_V1_Frozen.md §6.1, §6.2): the Case List's
     * four tabs. `status` continues to accept a raw case_status value
     * unchanged, for any existing caller relying on it; `tab` is additive.
     */
    private const TAB_ALL = 'all';

    private const TAB_HIGH_RISK = 'high_risk';

    private const TAB_FOLLOW_UP = 'follow_up';

    private const TAB_PROMISE_DUE = 'promise_due';

    /**
     * `customer_id` (added for the Customer Detail screen's "Cases" list)
     * filters to cases whose Debt belongs to that customer, composable with
     * `status`/`tab` the same way they already compose with each other.
     */
    public function index(Request $request): JsonResponse
    {
        $this->authorize('viewAny', CollectionCase::class);

        $query = CollectionCase::with(['debt.customer']);

        if ($status = $request->string('status')->trim()->value()) {
            $query->where('case_status', $status);
        }

        if ($customerId = $request->string('customer_id')->trim()->value()) {
            $query->whereHas('debt', fn (Builder $q) => $q->where('customer_id', $customerId));
        }

        $this->applyTabFilter($query, $request->string('tab')->trim()->value());

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

        $case->loadMissing(['debt.customer']);

        return $this->successResponse(new CollectionCaseResource($case));
    }

    /**
     * Debt Detail's "Related Case" (mobile Item 12) — the most recent
     * Collection Case for this Debt (open if one exists, per
     * `CollectionCaseService::escalate()`'s "one open case per debt" rule;
     * otherwise the most recently closed one). 404 when none exists yet —
     * a real "no case" state, not a fabricated relationship.
     */
    public function forDebt(Debt $debt): JsonResponse
    {
        $this->authorize('view', $debt);

        // Ordered by id (ULID), not created_at: `created_at` is a
        // second-precision DB-default timestamp, so two cases created
        // within the same second (e.g. closed then immediately re-opened)
        // would tie under it — ULIDs stay strictly monotonic regardless.
        $case = $debt->collectionCases()->orderBy('id', 'desc')->first();

        if ($case === null) {
            return $this->errorResponse('This debt has no collection case.', null, 404);
        }

        $case->loadMissing(['debt.customer']);

        return $this->successResponse(new CollectionCaseResource($case));
    }

    public function update(UpdateCollectionCaseRequest $request, CollectionCase $case): JsonResponse
    {
        $this->authorize('manage', $case);

        $this->collectionCases->updateDetails($case, $request->validated('notes'), $request->user());

        return $this->successResponse(new CollectionCaseResource($case->fresh()), 'Collection Case updated successfully');
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

    /**
     * Final Product Completion Roadmap, P1.6 — generic file attachments on
     * a Collection Case. `attachmentsStore` reuses `manage` — the same
     * ability every other Case mutation (activities, close, notes) is
     * gated by, no case-status restriction, matching `CollectionCasePolicy::
     * manage`'s role + Customer-read-only-only gate exactly.
     */
    public function attachmentsIndex(CollectionCase $case): JsonResponse
    {
        $this->authorize('view', $case);

        return $this->successResponse(
            CollectionCaseAttachmentResource::collection($case->attachments()->orderBy('created_at')->get()),
        );
    }

    public function attachmentsStore(UploadCollectionCaseAttachmentRequest $request, CollectionCase $case): JsonResponse
    {
        $this->authorize('manage', $case);

        $attachment = DB::transaction(function () use ($request, $case) {
            $stored = $this->documents->storeUploadedFile($request->file('file'), $case->tenant, 'collection_case_attachments');

            $attachment = $case->attachments()->create([
                'uploaded_by_user_id' => $request->user()->id,
                'file_path' => $stored['path'],
                'original_filename' => $stored['original_filename'],
                'mime_type' => $stored['mime_type'],
                'file_size' => $stored['size'],
                'description' => $request->validated('description'),
            ]);

            $this->auditLog->record(AuditAction::Created, 'collection_case_attachment', $attachment->id, $request->user());

            return $attachment;
        });

        return $this->successResponse(new CollectionCaseAttachmentResource($attachment), 'Attachment uploaded successfully', 201);
    }

    /**
     * docs/Mobile_UI_V1_Frozen.md §6.2 Business Rules, applied exactly:
     * High Risk = customer classified High Risk; Promise Due = an open,
     * unfulfilled Promise to Pay; Follow Up = an active, ongoing follow-up
     * requirement — at least one recorded follow-up activity that has not
     * yet resulted in payment, closure, or an open Promise to Pay. "Not
     * yet resulted in payment" is read as the debt not yet being fully
     * Paid (BRL "Open Debt" definition already used everywhere else in
     * this project), not as zero partial payments — a partially-paid debt
     * still has an active follow-up requirement.
     */
    private function applyTabFilter(Builder $query, ?string $tab): void
    {
        match ($tab) {
            self::TAB_HIGH_RISK => $query->whereHas(
                'debt.customer',
                fn ($q) => $q->where('risk_level', 'high'),
            ),
            self::TAB_PROMISE_DUE => $query->whereHas(
                'debt.promisesToPay',
                fn ($q) => $q->where('status', 'open'),
            ),
            self::TAB_FOLLOW_UP => $query
                ->where('case_status', 'open')
                ->whereHas(
                    'debt.followUpHistory',
                    fn ($q) => $q->where('action_type', FollowUpActionType::CollectionActivity->value),
                )
                ->whereHas('debt', fn ($q) => $q->where('debt_status', '!=', 'paid'))
                ->whereDoesntHave(
                    'debt.promisesToPay',
                    fn ($q) => $q->where('status', 'open'),
                ),
            self::TAB_ALL, null, '' => null,
            default => null,
        };
    }
}
