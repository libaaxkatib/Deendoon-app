<?php

namespace App\Http\Controllers;

use App\Enums\AuditAction;
use App\Enums\FollowUpActionType;
use App\Http\Requests\RecordPromiseToPayRequest;
use App\Http\Resources\PromiseToPayResource;
use App\Models\Debt;
use App\Models\PromiseToPay;
use App\Services\AuditLogService;
use App\Services\FollowUpHistoryService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class PromiseToPayController extends Controller
{
    use ApiResponse;

    public function __construct(
        private readonly FollowUpHistoryService $followUpHistory,
        private readonly AuditLogService $auditLog,
    ) {}

    public function store(RecordPromiseToPayRequest $request, Debt $debt): JsonResponse
    {
        $this->authorize('manageRecovery', $debt);

        $promise = DB::transaction(function () use ($request, $debt) {
            $promise = new PromiseToPay([
                'debt_id' => $debt->id,
                'promised_date' => $request->validated('promised_date'),
                'status' => 'open',
            ]);
            $promise->created_by_user_id = $request->user()->id;
            $promise->save();

            $this->followUpHistory->record($debt, FollowUpActionType::PromiseRecorded, $request->user());

            // No audit_log.action value corresponds to "promise recorded"
            // specifically — 'created' is the closest approved generic action.
            $this->auditLog->record(AuditAction::Created, 'promise_to_pay', $promise->id, $request->user());

            return $promise->refresh();
        });

        return $this->successResponse(new PromiseToPayResource($promise), 'Promise to Pay recorded successfully', 201);
    }

    /**
     * Debt Detail's "Promise to Pay History" (mobile Item 11) — same
     * `view` gate as the analogous `PaymentController::index()`.
     */
    public function index(Debt $debt): JsonResponse
    {
        $this->authorize('view', $debt);

        // Ordered by id (ULID), not created_at: `created_at` is a
        // second-precision DB-default timestamp (useCurrent()), so two
        // promises recorded within the same second would tie under it —
        // ULIDs stay strictly monotonic regardless.
        $promises = $debt->promisesToPay()->orderBy('id', 'desc')->get();

        return $this->successResponse(PromiseToPayResource::collection($promises));
    }

    /**
     * Standalone (not `/debts/{debt}/...`) — mobile Item 14: a reminder's
     * `related_entity_type == 'promise_to_pay'` only carries the Promise's
     * own id, not its parent Debt id, so the client needs a lookup that
     * starts from the Promise alone. `PromiseToPay` has no dedicated
     * Policy (no direct user-facing CRUD beyond create/list, both already
     * scoped through their parent Debt) — authorizes through `$promise->debt`,
     * the same object `Reminder::relatedCustomer()` already resolves
     * through server-side for this exact reminder type.
     */
    public function show(PromiseToPay $promise): JsonResponse
    {
        $this->authorize('view', $promise->debt);

        return $this->successResponse(new PromiseToPayResource($promise));
    }
}
