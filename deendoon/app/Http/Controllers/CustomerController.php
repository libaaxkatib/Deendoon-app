<?php

namespace App\Http\Controllers;

use App\Enums\AuditAction;
use App\Http\Requests\CheckCustomerDuplicateRequest;
use App\Http\Requests\StoreCustomerRequest;
use App\Http\Requests\UpdateCustomerCreditLimitRequest;
use App\Http\Requests\UpdateCustomerRequest;
use App\Http\Requests\UpdateCustomerStatusRequest;
use App\Http\Resources\CustomerResource;
use App\Models\Customer;
use App\Services\AuditLogService;
use App\Services\CustomerDuplicateDetectionService;
use App\Services\CustomerReadOnlyService;
use App\Services\RiskLevelService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CustomerController extends Controller
{
    use ApiResponse;

    public function __construct(
        private readonly CustomerDuplicateDetectionService $duplicateDetection,
        private readonly AuditLogService $auditLog,
        private readonly RiskLevelService $riskLevel,
        private readonly CustomerReadOnlyService $customerReadOnly,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $this->authorize('viewAny', Customer::class);

        $query = Customer::query();

        if ($request->boolean('includeArchived')) {
            $query->withTrashed();
        }

        if ($search = $request->string('search')->trim()->value()) {
            $searchTerm = '%'.mb_strtolower($search).'%';
            $query->where(function ($inner) use ($searchTerm) {
                $inner->whereRaw('LOWER(name) LIKE ?', [$searchTerm])
                    ->orWhereRaw('LOWER(phone) LIKE ?', [$searchTerm]);
            });
        }

        if ($status = $request->string('status')->trim()->value()) {
            $query->where('customer_status', $status);
        }

        if ($riskLevel = $request->string('riskLevel')->trim()->value()) {
            $query->where('risk_level', $riskLevel);
        }

        if ($request->filled('creditScoreMin')) {
            $query->where('credit_score', '>=', $request->integer('creditScoreMin'));
        }

        if ($request->filled('creditScoreMax')) {
            $query->where('credit_score', '<=', $request->integer('creditScoreMax'));
        }

        $customers = $query->orderBy('name')->paginate(
            perPage: $this->perPage($request),
        );

        // Risk Level Engine (Sprint 2B), Formula Spec §8: lazy, on-access
        // recalculation (Long Outstanding Debt's time-based check has no
        // discrete triggering write) for every Customer actually viewed.
        // Batched (fixed query count regardless of page size) — see
        // RiskLevelService::recalculateForMany()'s docblock.
        $this->riskLevel->recalculateForMany(collect($customers->items()));

        return $this->successResponse([
            'customers' => CustomerResource::collection($customers->items()),
            'pagination' => [
                'current_page' => $customers->currentPage(),
                'per_page' => $customers->perPage(),
                'total' => $customers->total(),
                'last_page' => $customers->lastPage(),
            ],
        ]);
    }

    public function store(StoreCustomerRequest $request): JsonResponse
    {
        $this->authorize('create', Customer::class);

        $duplicate = $this->duplicateDetection->findPotentialDuplicate(
            tenantId: $request->user()->tenant_id,
            name: $request->validated('name'),
            phone: $request->validated('phone'),
        );

        $customer = DB::transaction(function () use ($request) {
            // Backend Completion Roadmap (Phase 4.1, Product Owner
            // review 2026-08-06): the authoritative, lock-protected
            // recheck — CustomerPolicy::create()'s check above is only a
            // fast, non-atomic pre-check and cannot by itself prevent
            // two concurrent requests both slipping past it.
            $this->customerReadOnly->assertCanCreateCustomer($request->user()->tenant);

            $customer = Customer::create([
                'name' => $request->validated('name'),
                'phone' => $request->validated('phone'),
                'customer_status' => 'active',
                'credit_limit' => $request->validated('credit_limit'),
            ]);

            $this->auditLog->record(
                action: AuditAction::Created,
                entityType: 'customer',
                entityId: $customer->id,
                actor: $request->user(),
            );

            // outstanding_balance is deliberately not fillable (it must never be
            // settable, even internally); refresh so the response reflects the
            // database DEFAULT rather than the in-memory pre-insert value.
            return $customer->refresh();
        });

        // Backend Completion Roadmap (Phase 4.1): a new customer changes
        // the tenant's customer count, which can change who is read-only.
        $this->customerReadOnly->recalculate($request->user()->tenant);

        return $this->successResponse([
            'customer' => new CustomerResource($customer->fresh()),
            'warning' => $duplicate ? $this->duplicateWarning($duplicate) : null,
        ], 'Customer created successfully', 201);
    }

    public function show(Customer $customer): JsonResponse
    {
        $this->authorize('view', $customer);

        $this->riskLevel->recalculate($customer);

        return $this->successResponse(new CustomerResource($customer));
    }

    public function update(UpdateCustomerRequest $request, Customer $customer): JsonResponse
    {
        $this->authorize('update', $customer);

        $identifyingFieldsChanged = $customer->name !== $request->validated('name')
            || $customer->phone !== $request->validated('phone');

        $creditLimitChanged = bccomp((string) $customer->credit_limit, (string) $request->validated('credit_limit'), 2) !== 0;

        $duplicate = $identifyingFieldsChanged
            ? $this->duplicateDetection->findPotentialDuplicate(
                tenantId: $customer->tenant_id,
                name: $request->validated('name'),
                phone: $request->validated('phone'),
                excludeCustomerId: $customer->id,
            )
            : null;

        DB::transaction(function () use ($request, $customer, $creditLimitChanged) {
            $customer->update([
                'name' => $request->validated('name'),
                'phone' => $request->validated('phone'),
                'credit_limit' => $request->validated('credit_limit'),
            ]);

            $this->auditLog->record(
                action: $creditLimitChanged ? AuditAction::CreditLimitChanged : AuditAction::Edited,
                entityType: 'customer',
                entityId: $customer->id,
                actor: $request->user(),
            );
        });

        return $this->successResponse([
            'customer' => new CustomerResource($customer->fresh()),
            'warning' => $duplicate ? $this->duplicateWarning($duplicate) : null,
        ], 'Customer updated successfully');
    }

    public function archive(Request $request, Customer $customer): JsonResponse
    {
        $this->authorize('archive', $customer);

        DB::transaction(function () use ($request, $customer) {
            $customer->delete();

            $this->auditLog->record(
                action: AuditAction::Archived,
                entityType: 'customer',
                entityId: $customer->id,
                actor: $request->user(),
            );
        });

        // Backend Completion Roadmap (Phase 4.1): archiving an editable
        // customer must promote the next-oldest read-only customer — an
        // emergent property of full recalculation (the archived customer
        // is now excluded from the ordered query by its own soft-delete
        // scope), not a separate "find and promote" mechanism.
        $this->customerReadOnly->recalculate($request->user()->tenant);

        return $this->successResponse(null, 'Customer archived successfully');
    }

    public function restore(Request $request, Customer $customer): JsonResponse
    {
        $this->authorize('restore', $customer);

        DB::transaction(function () use ($request, $customer) {
            $customer->restore();

            $this->auditLog->record(
                action: AuditAction::Restored,
                entityType: 'customer',
                entityId: $customer->id,
                actor: $request->user(),
            );
        });

        // Backend Completion Roadmap (Phase 4.1): a restored customer
        // re-enters the active count and may itself become read-only
        // (or push another customer into read-only) depending on where
        // it lands in created_at order relative to the current limit.
        $this->customerReadOnly->recalculate($request->user()->tenant);

        return $this->successResponse(new CustomerResource($customer->fresh()), 'Customer restored successfully');
    }

    public function updateStatus(UpdateCustomerStatusRequest $request, Customer $customer): JsonResponse
    {
        $this->authorize('update', $customer);

        DB::transaction(function () use ($request, $customer) {
            $customer->update([
                'customer_status' => $request->validated('customer_status'),
            ]);

            $this->auditLog->record(
                action: AuditAction::StatusChanged,
                entityType: 'customer',
                entityId: $customer->id,
                actor: $request->user(),
            );
        });

        return $this->successResponse(new CustomerResource($customer->fresh()), 'Customer status updated successfully');
    }

    public function creditProfile(Customer $customer): JsonResponse
    {
        $this->authorize('view', $customer);

        return $this->successResponse(new CustomerResource($customer));
    }

    public function updateCreditLimit(UpdateCustomerCreditLimitRequest $request, Customer $customer): JsonResponse
    {
        $this->authorize('update', $customer);

        DB::transaction(function () use ($request, $customer) {
            $customer->update([
                'credit_limit' => $request->validated('credit_limit'),
            ]);

            $this->auditLog->record(
                action: AuditAction::CreditLimitChanged,
                entityType: 'customer',
                entityId: $customer->id,
                actor: $request->user(),
            );
        });

        return $this->successResponse(new CustomerResource($customer->fresh()), 'Credit limit updated successfully');
    }

    public function checkDuplicate(CheckCustomerDuplicateRequest $request): JsonResponse
    {
        $this->authorize('viewAny', Customer::class);

        $duplicate = $this->duplicateDetection->findPotentialDuplicate(
            tenantId: $request->user()->tenant_id,
            name: $request->validated('name'),
            phone: $request->validated('phone'),
        );

        return $this->successResponse([
            'duplicate_found' => (bool) $duplicate,
            'warning' => $duplicate ? $this->duplicateWarning($duplicate) : null,
        ]);
    }

    /**
     * @return array<string, mixed>
     */
    private function duplicateWarning(Customer $duplicate): array
    {
        return [
            'type' => 'POSSIBLE_DUPLICATE_CUSTOMER',
            'message' => 'This customer may already exist.',
            'matched_customer_id' => $duplicate->id,
        ];
    }
}
