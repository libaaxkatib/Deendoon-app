<?php

namespace App\Http\Controllers;

use App\Enums\AuditAction;
use App\Http\Requests\CheckCustomerDuplicateRequest;
use App\Http\Requests\StoreCustomerRequest;
use App\Http\Requests\UpdateCustomerCreditLimitRequest;
use App\Http\Requests\UpdateCustomerRequest;
use App\Http\Requests\UpdateCustomerStatusRequest;
use App\Http\Requests\UploadCustomerAttachmentRequest;
use App\Http\Resources\CustomerAttachmentResource;
use App\Http\Resources\CustomerResource;
use App\Models\Customer;
use App\Policies\CustomerAttachmentPolicy;
use App\Services\AdminSettingsService;
use App\Services\AuditLogService;
use App\Services\CreditScoreService;
use App\Services\CustomerDuplicateDetectionService;
use App\Services\CustomerPhoneNumberService;
use App\Services\CustomerReadOnlyService;
use App\Services\DocumentService;
use App\Services\RiskLevelService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class CustomerController extends Controller
{
    use ApiResponse;

    public function __construct(
        private readonly CustomerDuplicateDetectionService $duplicateDetection,
        private readonly AuditLogService $auditLog,
        private readonly RiskLevelService $riskLevel,
        private readonly CreditScoreService $creditScore,
        private readonly CustomerReadOnlyService $customerReadOnly,
        private readonly AdminSettingsService $adminSettings,
        private readonly DocumentService $documents,
        private readonly CustomerPhoneNumberService $phoneNumbers,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $this->authorize('viewAny', Customer::class);

        $query = Customer::query()->with('phoneNumbers');

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
        // Credit Score (FR-026, Business Owner Backend Completion): always
        // recalculated at the exact same trigger points as Risk Level —
        // both are derived from the same underlying customer behavior.
        $this->creditScore->recalculateForMany(collect($customers->items()));

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

            // FR-007/BR-034 (Business Owner Backend Completion): when the
            // client omits credit_limit, apply the tenant's configured
            // Default Credit Limit rather than requiring it on every call.
            $creditLimit = $request->has('credit_limit')
                ? $request->validated('credit_limit')
                : $this->adminSettings->systemSettingsFor($request->user()->tenant_id)->default_credit_limit;

            $customer = Customer::create([
                'name' => $request->validated('name'),
                'phone' => $request->validated('phone'),
                'address' => $request->validated('address'),
                'customer_status' => 'active',
                'credit_limit' => $creditLimit,
            ]);

            // Fix #23 — reconciles customer_phone_numbers from either the
            // new `phone_numbers` array or (when absent) the legacy
            // `phone` value alone; also mirrors the primary phone back
            // into $customer->phone, so this always matches what was
            // actually saved.
            $entries = $this->phoneNumbers->normalizeEntries([
                'phone' => $request->validated('phone'),
                'phone_numbers' => $request->input('phone_numbers'),
            ]);
            $this->phoneNumbers->reconcile($customer, $entries);

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
        $this->customerReadOnly->recalculate($request->user()->tenant, $request->user());

        return $this->successResponse([
            'customer' => new CustomerResource($customer->fresh()->load('phoneNumbers')),
            'warning' => $duplicate ? $this->duplicateWarning($duplicate) : null,
        ], 'Customer created successfully', 201);
    }

    public function show(Customer $customer): JsonResponse
    {
        $this->authorize('view', $customer);

        // FR-008 (Business Owner Backend Completion): archived Customers
        // are now viewable here too (route uses withTrashed()), so a
        // Business Owner can review the full record before deciding to
        // restore it. Skip the recalculation side effect for an archived
        // record — reviewing it for a restore decision should not silently
        // mutate its stored state.
        if (! $customer->trashed()) {
            $this->riskLevel->recalculate($customer);
            $this->creditScore->recalculate($customer);
        }

        return $this->successResponse(new CustomerResource($customer->load('phoneNumbers')));
    }

    public function update(UpdateCustomerRequest $request, Customer $customer): JsonResponse
    {
        $this->authorize('update', $customer);

        // Fix #23 — the canonical "new phone" used for both duplicate
        // detection and the actual save is the normalized primary entry,
        // not the raw `phone` field directly: when `phone_numbers` is
        // present it takes precedence (kept internally consistent with
        // whichever entry is marked primary), matching exactly what
        // reconcile() below will actually persist.
        $entries = $this->phoneNumbers->normalizeEntries([
            'phone' => $request->validated('phone'),
            'phone_numbers' => $request->input('phone_numbers'),
        ]);
        $newPrimaryPhone = collect($entries)->firstWhere('is_primary', true)['phone'] ?? $request->validated('phone');

        $identifyingFieldsChanged = $customer->name !== $request->validated('name')
            || $customer->phone !== $newPrimaryPhone;

        $creditLimitChanged = bccomp((string) $customer->credit_limit, (string) $request->validated('credit_limit'), 2) !== 0;

        $duplicate = $identifyingFieldsChanged
            ? $this->duplicateDetection->findPotentialDuplicate(
                tenantId: $customer->tenant_id,
                name: $request->validated('name'),
                phone: $newPrimaryPhone,
                excludeCustomerId: $customer->id,
            )
            : null;

        DB::transaction(function () use ($request, $customer, $creditLimitChanged, $entries, $newPrimaryPhone) {
            $customer->update([
                'name' => $request->validated('name'),
                'phone' => $newPrimaryPhone,
                'address' => $request->validated('address'),
                'credit_limit' => $request->validated('credit_limit'),
            ]);

            $this->phoneNumbers->reconcile($customer, $entries);

            $this->auditLog->record(
                action: $creditLimitChanged ? AuditAction::CreditLimitChanged : AuditAction::Edited,
                entityType: 'customer',
                entityId: $customer->id,
                actor: $request->user(),
            );
        });

        return $this->successResponse([
            'customer' => new CustomerResource($customer->fresh()->load('phoneNumbers')),
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
        $this->customerReadOnly->recalculate($request->user()->tenant, $request->user());

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
        $this->customerReadOnly->recalculate($request->user()->tenant, $request->user());

        return $this->successResponse(new CustomerResource($customer->fresh()->load('phoneNumbers')), 'Customer restored successfully');
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

        return $this->successResponse(new CustomerResource($customer->fresh()->load('phoneNumbers')), 'Customer status updated successfully');
    }

    public function creditProfile(Customer $customer): JsonResponse
    {
        $this->authorize('view', $customer);

        return $this->successResponse(new CustomerResource($customer->load('phoneNumbers')));
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

        return $this->successResponse(new CustomerResource($customer->fresh()->load('phoneNumbers')), 'Credit limit updated successfully');
    }

    /**
     * Final Product Completion Roadmap, P1.6 — generic file attachments on
     * a Customer. Reuses `update`'s ability (same read-only gate as
     * credit-limit/status changes) since this is itself a mutation on the
     * Customer's own record.
     */
    public function attachmentsIndex(Customer $customer): JsonResponse
    {
        $this->authorize('view', $customer);

        return $this->successResponse(
            CustomerAttachmentResource::collection($customer->attachments()->orderBy('created_at')->get()),
        );
    }

    public function attachmentsStore(UploadCustomerAttachmentRequest $request, Customer $customer): JsonResponse
    {
        $this->authorize('update', $customer);

        $attachment = DB::transaction(function () use ($request, $customer) {
            $stored = $this->documents->storeUploadedFile($request->file('file'), $customer->tenant, 'customer_attachments');

            $attachment = $customer->attachments()->create([
                'uploaded_by_user_id' => $request->user()->id,
                'file_path' => $stored['path'],
                'original_filename' => $stored['original_filename'],
                'mime_type' => $stored['mime_type'],
                'file_size' => $stored['size'],
                'description' => $request->validated('description'),
            ]);

            $this->auditLog->record(
                AuditAction::Created,
                'customer_attachment',
                $attachment->id,
                $request->user(),
            );

            return $attachment;
        });

        return $this->successResponse(new CustomerAttachmentResource($attachment), 'Attachment uploaded successfully', 201);
    }

    /**
     * Mobile Fix #4A (Attachment Delete): only the uploader may delete
     * their own attachment, and only while the Customer is not read-only
     * — see {@see CustomerAttachmentPolicy}. The DB row is
     * removed first (inside the transaction, alongside the Audit Trail
     * entry); the file itself is deleted from disk only after that
     * commits, so a failed transaction never leaves an attachment row
     * without its file.
     */
    public function attachmentsDestroy(Request $request, Customer $customer, string $attachment): JsonResponse
    {
        $attachmentModel = $customer->attachments()->findOrFail($attachment);

        $this->authorize('delete', $attachmentModel);

        DB::transaction(function () use ($request, $attachmentModel) {
            $this->auditLog->record(AuditAction::Deleted, 'customer_attachment', $attachmentModel->id, $request->user());

            $attachmentModel->delete();
        });

        Storage::disk('local')->delete($attachmentModel->file_path);

        return $this->successResponse(null, 'Attachment deleted successfully');
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
