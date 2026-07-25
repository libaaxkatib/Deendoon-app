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
}
