<?php

namespace App\Http\Controllers;

use App\Enums\AuditAction;
use App\Enums\FollowUpActionType;
use App\Http\Requests\StoreDebtRequest;
use App\Http\Requests\UpdateDebtRecoveryStageRequest;
use App\Http\Requests\UpdateDebtRequest;
use App\Http\Requests\UpdateDebtStatusRequest;
use App\Http\Resources\DebtResource;
use App\Models\AuditLog;
use App\Models\Customer;
use App\Models\Debt;
use App\Services\AuditLogService;
use App\Services\CustomerBalanceService;
use App\Services\PromiseToPayService;
use App\Services\ReferenceNumberService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class DebtController extends Controller
{
    use ApiResponse;

    /**
     * The exact 8 event types FR-024 names, in order. Only "debt_created"
     * can ever be populated today — the rest depend on Modules 5/6/7,
     * which are not implemented. Genuinely showing them as pending (not
     * inventing data) is what FR-024 A1 itself describes.
     */
    private const TIMELINE_STAGES = [
        'debt_created', 'whatsapp_reminder', 'sms_reminder', 'phone_call',
        'promise_to_pay', 'payment', 'professional_collection', 'recovered',
    ];

    public function __construct(
        private readonly ReferenceNumberService $referenceNumbers,
        private readonly CustomerBalanceService $balances,
        private readonly AuditLogService $auditLog,
        private readonly PromiseToPayService $promiseToPay,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $this->authorize('viewAny', Debt::class);

        $query = Debt::query();

        if ($request->boolean('includeArchived')) {
            $query->withTrashed();
        }

        if ($customerId = $request->string('customer_id')->trim()->value()) {
            $query->where('customer_id', $customerId);
        }

        if ($status = $request->string('status')->trim()->value()) {
            $query->where('debt_status', $status);
        }

        if ($request->filled('dateFrom')) {
            $query->whereDate('due_date', '>=', $request->date('dateFrom'));
        }

        if ($request->filled('dateTo')) {
            $query->whereDate('due_date', '<=', $request->date('dateTo'));
        }

        $debts = $query->orderBy('due_date')->paginate(
            perPage: $request->integer('perPage', 15),
        );

        $debts->getCollection()->each(function (Debt $debt) {
            $this->refreshOverdueStatus($debt);
            $this->promiseToPay->refreshBrokenPromises($debt);
        });

        return $this->successResponse([
            'debts' => DebtResource::collection($debts->items()),
            'pagination' => [
                'current_page' => $debts->currentPage(),
                'per_page' => $debts->perPage(),
                'total' => $debts->total(),
                'last_page' => $debts->lastPage(),
            ],
        ]);
    }

    public function store(StoreDebtRequest $request, Customer $customer): JsonResponse
    {
        $this->authorize('create', Debt::class);

        // BRL-023: evaluated against the balance *before* this Debt is added.
        $prospectiveOutstanding = bcadd((string) $customer->outstanding_balance, (string) $request->validated('amount'), 2);
        $exceedsLimit = bccomp($prospectiveOutstanding, (string) $customer->credit_limit, 2) > 0;

        $debt = DB::transaction(function () use ($request, $customer) {
            $referenceNumber = $this->referenceNumbers->next('debts', $customer->tenant_id, 'DBT');

            $debt = new Debt([
                'customer_id' => $customer->id,
                'reference_number' => $referenceNumber,
                'amount' => $request->validated('amount'),
                'due_date' => $request->validated('due_date'),
                'debt_status' => 'pending',
                'remaining_balance' => $request->validated('amount'),
                'recovery_stage' => 1,
                'notes' => $request->validated('notes'),
            ]);
            $debt->save();

            $this->auditLog->record(AuditAction::Created, 'debt', $debt->id, $request->user());

            $this->balances->recalculate($customer);

            return $debt->refresh();
        });

        return $this->successResponse([
            'debt' => new DebtResource($debt),
            'warning' => $exceedsLimit ? [
                'type' => 'CREDIT_LIMIT_EXCEEDED',
                'message' => 'This customer has exceeded the approved credit limit.',
                'credit_limit' => (string) $customer->credit_limit,
                'projected_outstanding' => $prospectiveOutstanding,
            ] : null,
        ], 'Debt created successfully', 201);
    }

    public function show(Debt $debt): JsonResponse
    {
        $this->authorize('view', $debt);

        $this->refreshOverdueStatus($debt);
        $this->promiseToPay->refreshBrokenPromises($debt);

        return $this->successResponse(new DebtResource($debt->fresh()));
    }

    public function update(UpdateDebtRequest $request, Debt $debt): JsonResponse
    {
        $this->authorize('update', $debt);

        DB::transaction(function () use ($request, $debt) {
            $debt->update([
                'due_date' => $request->validated('due_date'),
                'notes' => $request->validated('notes'),
            ]);

            $this->auditLog->record(AuditAction::Edited, 'debt', $debt->id, $request->user());
        });

        return $this->successResponse(new DebtResource($debt->fresh()), 'Debt updated successfully');
    }

    public function updateStatus(UpdateDebtStatusRequest $request, Debt $debt): JsonResponse
    {
        $this->authorize('update', $debt);

        if (in_array($debt->debt_status, ['paid', 'cancelled', 'written_off'], true)) {
            return $this->errorResponse('This debt is already in a terminal status and cannot be changed.', null, 422);
        }

        DB::transaction(function () use ($request, $debt) {
            $debt->update(['debt_status' => $request->validated('debt_status')]);

            $this->auditLog->record(AuditAction::StatusChanged, 'debt', $debt->id, $request->user());

            $this->balances->recalculate($debt->customer);
        });

        return $this->successResponse(new DebtResource($debt->fresh()), 'Debt status updated successfully');
    }

    public function archive(Request $request, Debt $debt): JsonResponse
    {
        $this->authorize('archive', $debt);

        DB::transaction(function () use ($request, $debt) {
            $debt->delete();

            $this->auditLog->record(AuditAction::Archived, 'debt', $debt->id, $request->user());
        });

        return $this->successResponse(null, 'Debt archived successfully');
    }

    public function restore(Request $request, Debt $debt): JsonResponse
    {
        $this->authorize('restore', $debt);

        DB::transaction(function () use ($request, $debt) {
            $debt->restore();

            $this->auditLog->record(AuditAction::Restored, 'debt', $debt->id, $request->user());
        });

        return $this->successResponse(new DebtResource($debt->fresh()), 'Debt restored successfully');
    }

    /**
     * FR-024: now sourced from follow_up_history for the stages Module 5
     * actually populates (whatsapp/sms/call/promise). "payment" and
     * "professional_collection" remain genuinely pending — Modules 6/7
     * don't exist, so nothing can ever write those action_type values yet.
     * "recovered" has no source at all until Module 6 exists.
     */
    public function timeline(Debt $debt): JsonResponse
    {
        $this->authorize('view', $debt);

        $createdEvent = AuditLog::where('entity_type', 'debt')
            ->where('entity_id', $debt->id)
            ->where('action', AuditAction::Created->value)
            ->first();

        $followUpEventsByType = $debt->followUpHistory()
            ->orderBy('occurred_at')
            ->get()
            ->groupBy('action_type');

        $stageActionMap = [
            'whatsapp_reminder' => FollowUpActionType::ManualWhatsapp->value,
            'sms_reminder' => FollowUpActionType::ManualSms->value,
            'phone_call' => FollowUpActionType::CallLogged->value,
            'promise_to_pay' => FollowUpActionType::PromiseRecorded->value,
            'payment' => FollowUpActionType::PaymentRecorded->value,
            'professional_collection' => FollowUpActionType::Escalated->value,
        ];

        $stages = array_map(function (string $event) use ($createdEvent, $followUpEventsByType, $stageActionMap) {
            if ($event === 'debt_created') {
                return [
                    'event' => $event,
                    'status' => $createdEvent ? 'completed' : 'pending',
                    'occurred_at' => $createdEvent?->occurred_at,
                ];
            }

            if ($event === 'recovered') {
                return ['event' => $event, 'status' => 'pending', 'occurred_at' => null];
            }

            $actionType = $stageActionMap[$event] ?? null;
            $firstMatch = $actionType ? $followUpEventsByType->get($actionType)?->first() : null;

            return [
                'event' => $event,
                'status' => $firstMatch ? 'completed' : 'pending',
                'occurred_at' => $firstMatch?->occurred_at,
            ];
        }, self::TIMELINE_STAGES);

        return $this->successResponse([
            'debt_id' => $debt->id,
            'stages' => $stages,
        ]);
    }

    public function updateRecoveryStage(UpdateDebtRecoveryStageRequest $request, Debt $debt): JsonResponse
    {
        $this->authorize('update', $debt);

        DB::transaction(function () use ($request, $debt) {
            $debt->update(['recovery_stage' => $request->validated('recovery_stage')]);

            $this->auditLog->record(
                AuditAction::RecoveryStageOverride,
                'debt',
                $debt->id,
                $request->user(),
                $request->validated('reason'),
            );
        });

        return $this->successResponse(new DebtResource($debt->fresh()), 'Recovery stage updated successfully');
    }

    /**
     * FR-021 A1: Draft/Pending -> Overdue is automatic once the due date
     * passes. Implemented as a lazy, on-access check rather than a
     * scheduled job — no scheduler/queue infrastructure decision has been
     * made yet (Redis remains deferred), and this keeps the transition
     * correct for anything actually viewed without inventing that
     * decision. See the report's NON-BLOCKING issues.
     */
    private function refreshOverdueStatus(Debt $debt): Debt
    {
        if (in_array($debt->debt_status, ['draft', 'pending'], true) && $debt->due_date->isPast()) {
            $debt->update(['debt_status' => 'overdue']);

            $this->auditLog->record(AuditAction::StatusChanged, 'debt', $debt->id, null, 'Automatic: due date passed');
        }

        return $debt;
    }
}
