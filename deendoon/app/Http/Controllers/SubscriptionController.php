<?php

namespace App\Http\Controllers;

use App\Enums\ReferenceDataCategory;
use App\Http\Requests\ApproveStorageAddonRequestRequest;
use App\Http\Requests\ApproveSubscriptionChangeRequestRequest;
use App\Http\Requests\RejectStorageAddonRequestRequest;
use App\Http\Requests\RejectSubscriptionChangeRequestRequest;
use App\Http\Requests\StorageAddonRequestRequest;
use App\Http\Requests\SubscriptionUpgradeRequestRequest;
use App\Http\Resources\ReferenceDataResource;
use App\Http\Resources\StorageAddonResource;
use App\Http\Resources\SubscriptionChangeRequestResource;
use App\Http\Resources\SubscriptionPlanResource;
use App\Models\Customer;
use App\Models\StorageAddon;
use App\Models\SubscriptionChangeRequest;
use App\Models\SubscriptionPlan;
use App\Services\CustomerReadOnlyService;
use App\Services\DocumentService;
use App\Services\PlatformPaymentSettingsService;
use App\Services\ReferenceDataService;
use App\Services\StorageAddonService;
use App\Services\SubscriptionService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

/**
 * Backend Completion Roadmap, Phase 3.3/3.4 — Business Owner Subscription
 * APIs + Manual Payment Workflow. No Super Admin / Platform endpoints
 * (approval, rejection, activation — a later phase). Every method reads
 * or writes only the authenticated Business Owner's own tenant, never a
 * client-supplied tenant identifier — combined with the Conditional
 * Global Scope on TenantSubscription/SubscriptionChangeRequest/
 * StorageAddon (Phase 3.2), tenant isolation is enforced both
 * structurally (model layer) and explicitly (every query here still
 * filters by the resolved tenant, matching SubscriptionService's own
 * documented defense-in-depth reasoning).
 *
 * Phase 3.4 moved request-creation (duplicate-pending check, transaction,
 * audit logging) into SubscriptionService::requestUpgrade()/
 * StorageAddonService::requestAddon() — this controller now only
 * validates the HTTP request and delegates.
 */
class SubscriptionController extends Controller
{
    use ApiResponse;

    public function __construct(
        private readonly SubscriptionService $subscriptions,
        private readonly StorageAddonService $storageAddons,
        private readonly DocumentService $documents,
        private readonly ReferenceDataService $referenceData,
        private readonly CustomerReadOnlyService $customerReadOnly,
        private readonly PlatformPaymentSettingsService $paymentSettings,
    ) {}

    public function show(Request $request): JsonResponse
    {
        Gate::authorize('admin-only');
        $tenant = $request->user()->tenant;

        $subscription = $this->subscriptions->currentSubscription($tenant);
        $plan = $this->subscriptions->currentPlan($tenant);
        $usage = $this->documents->storageUsage($tenant);

        return $this->successResponse([
            'plan' => $plan ? new SubscriptionPlanResource($plan) : null,
            'plan_name' => $plan?->name,
            'plan_price' => $plan?->monthly_price,
            'trial_status' => [
                'on_trial' => $this->subscriptions->isOnTrial($tenant),
                'trial_ends_at' => $subscription?->trial_ends_at,
            ],
            'started_at' => $subscription?->started_at,
            'expires_at' => $subscription?->expires_at,
            'subscription_status' => $this->subscriptions->status($tenant),
            // Customer::count() is auto-scoped to the authenticated
            // Business Owner's own tenant via BelongsToTenant — this
            // controller is admin-only-gated, so the actor here always
            // has a tenant_id (never the Platform Administrator).
            'customer_usage' => Customer::count(),
            'customer_limit' => $this->subscriptions->customerLimit($tenant),
            'storage_usage_bytes' => $usage['used_bytes'],
            'storage_limit' => $this->storageAddons->totalStorageAllowance($tenant),
            'analytics_enabled' => $this->subscriptions->analyticsEnabled($tenant),
            // Backend Completion Roadmap (Phase 4.5 — Final Verification
            // fix): previously `status($tenant) === 'expired'` — checked
            // only subscription status, completely missing the
            // customer-count-driven read-only case (Phase 4.1), which can
            // be true on a perfectly `active` subscription (e.g. a Free
            // Plan tenant over its 2-customer limit after ExpireTrials
            // ran). Reuses the exact enforcement mechanism directly — the
            // real, persisted `is_read_only` flag every Policy already
            // checks — rather than recomputing a second, parallel
            // definition of "read only."
            'read_only' => Customer::where('tenant_id', $tenant->id)->where('is_read_only', true)->exists(),
        ]);
    }

    public function plans(): JsonResponse
    {
        Gate::authorize('admin-only');

        $plans = SubscriptionPlan::where('active', true)->orderBy('monthly_price')->get();

        return $this->successResponse(SubscriptionPlanResource::collection($plans));
    }

    public function changeRequests(Request $request): JsonResponse
    {
        Gate::authorize('admin-only');
        $tenant = $request->user()->tenant;

        $requests = SubscriptionChangeRequest::with(['requestedPlan', 'currentPlan'])
            ->where('tenant_id', $tenant->id)
            ->orderByDesc('requested_at')
            ->paginate($this->perPage($request));

        return $this->successResponse([
            'change_requests' => SubscriptionChangeRequestResource::collection($requests->items()),
            'pagination' => [
                'current_page' => $requests->currentPage(),
                'per_page' => $requests->perPage(),
                'total' => $requests->total(),
                'last_page' => $requests->lastPage(),
            ],
        ]);
    }

    public function upgradeRequest(SubscriptionUpgradeRequestRequest $request): JsonResponse
    {
        Gate::authorize('admin-only');
        $tenant = $request->user()->tenant;

        $changeRequest = $this->subscriptions->requestUpgrade(
            $tenant,
            $request->validated('requested_plan_id'),
            $request->validated('payment_phone'),
            $request->validated('payment_reference'),
            $request->user(),
        );

        return $this->successResponse(
            new SubscriptionChangeRequestResource($changeRequest->load(['requestedPlan', 'currentPlan'])),
            'Upgrade request submitted successfully',
            201,
        );
    }

    /**
     * Manual Mobile-Money Subscription Payment Flow (Product Owner
     * decision): the platform's destination mobile-money number, shown on
     * the "Send Money" step. Read-only, Business-Owner-gated like every
     * other endpoint on this controller — never hardcoded client-side, so
     * the Platform Administrator can change it without an app release.
     */
    public function paymentInfo(): JsonResponse
    {
        Gate::authorize('admin-only');

        return $this->successResponse([
            'destination_mobile_money_number' => $this->paymentSettings->current()?->destination_mobile_money_number,
        ]);
    }

    public function storage(Request $request): JsonResponse
    {
        Gate::authorize('admin-only');
        $tenant = $request->user()->tenant;

        $usage = $this->documents->storageUsage($tenant);
        $usageGb = $usage['used_bytes'] / (1024 ** 3);
        $limitGb = $this->storageAddons->totalStorageAllowance($tenant);

        return $this->successResponse([
            'storage_usage_bytes' => $usage['used_bytes'],
            'storage_usage_gb' => round($usageGb, 2),
            'storage_limit_gb' => $limitGb,
            'purchased_addons' => StorageAddonResource::collection($this->storageAddons->activeAddons($tenant)),
            'remaining_storage_gb' => $limitGb === null ? null : round($limitGb - $usageGb, 2),
        ]);
    }

    public function storageAddonRequest(StorageAddonRequestRequest $request): JsonResponse
    {
        Gate::authorize('admin-only');
        $tenant = $request->user()->tenant;

        $addon = $this->storageAddons->requestAddon(
            $tenant,
            $request->validated('storage_package'),
            $request->validated('payment_reference'),
            $request->user(),
        );

        return $this->successResponse(new StorageAddonResource($addon), 'Storage add-on request submitted successfully', 201);
    }

    /**
     * Subscription Approval + Storage Add-on Approval (Product
     * Owner-approved decision record): the Business Owner cancels their
     * own still-pending Subscription Change Request. Route model binding
     * + SubscriptionChangeRequest's own BelongsToTenantOrPlatformAdmin
     * scope already restrict this to the authenticated tenant's own rows
     * (404 for another tenant's request), so no manual resolve/mask step
     * is needed here, unlike ProfessionalCollectionRequestController.
     */
    public function cancelChangeRequest(Request $request, SubscriptionChangeRequest $subscriptionChangeRequest): JsonResponse
    {
        Gate::authorize('admin-only');

        $changeRequest = $this->subscriptions->cancel($subscriptionChangeRequest, $request->user());

        return $this->successResponse(new SubscriptionChangeRequestResource($changeRequest->load(['requestedPlan', 'currentPlan'])), 'Subscription Change Request cancelled successfully');
    }

    /**
     * Subscription Approval + Storage Add-on Approval (Product
     * Owner-approved decision record): the Business Owner cancels their
     * own still-pending Storage Add-on request.
     */
    public function cancelStorageAddon(Request $request, StorageAddon $storageAddon): JsonResponse
    {
        Gate::authorize('admin-only');

        $addon = $this->storageAddons->cancel($storageAddon, $request->user());

        return $this->successResponse(new StorageAddonResource($addon), 'Storage Add-on request cancelled successfully');
    }

    /**
     * Subscription Approval + Storage Add-on Approval (Product
     * Owner-approved decision record): the Platform Admin Approval Center
     * — every tenant's Subscription Change Requests, optionally filtered
     * by status. StorageAddon/SubscriptionChangeRequest's own
     * BelongsToTenantOrPlatformAdmin scope applies no filter at all for
     * the Deendoon Platform Administrator, so this is a plain query, not a
     * bimodal one like ProfessionalCollectionRequestController::index().
     */
    public function changeRequestApprovalCenter(Request $request): JsonResponse
    {
        Gate::authorize('platform-admin-only');

        $query = SubscriptionChangeRequest::with(['requestedPlan', 'currentPlan', 'tenant']);

        if ($status = $request->string('status')->trim()->value()) {
            $query->where('status', $status);
        }

        $requests = $query->orderByDesc('requested_at')->paginate($this->perPage($request));

        return $this->successResponse([
            'change_requests' => SubscriptionChangeRequestResource::collection($requests->items()),
            'pagination' => [
                'current_page' => $requests->currentPage(),
                'per_page' => $requests->perPage(),
                'total' => $requests->total(),
                'last_page' => $requests->lastPage(),
            ],
        ]);
    }

    /**
     * Subscription Approval + Storage Add-on Approval (Product
     * Owner-approved decision record, Decision 4): the predefined
     * Rejection Reasons the Deendoon Platform Administrator may select
     * from when rejecting a Subscription Change Request. Platform-owned
     * (tenant_id NULL) Reference Data — passing null here (the Platform
     * Administrator's own tenant_id) matches those rows exactly, the same
     * way ReferenceDataService::forCategory() already scopes for any
     * other caller.
     */
    public function changeRequestRejectionReasons(): JsonResponse
    {
        Gate::authorize('platform-admin-only');

        return $this->successResponse(
            ReferenceDataResource::collection($this->referenceData->forCategory(null, ReferenceDataCategory::SubscriptionRejectionReason)),
        );
    }

    public function approveChangeRequest(ApproveSubscriptionChangeRequestRequest $request, SubscriptionChangeRequest $subscriptionChangeRequest): JsonResponse
    {
        Gate::authorize('platform-admin-only');

        $changeRequest = $this->subscriptions->approve($subscriptionChangeRequest, $request->user());

        // Backend Completion Roadmap, Phase 4.1 precedent: approving a
        // plan change alters the tenant's effective customer limit, so
        // read-only status must be recalculated immediately — triggered
        // here, not inside SubscriptionService::approve(), to avoid the
        // same circular dependency CustomerReadOnlyService already has on
        // SubscriptionService (documented on that method).
        $this->customerReadOnly->recalculate($changeRequest->tenant, $request->user());

        return $this->successResponse(new SubscriptionChangeRequestResource($changeRequest->load(['requestedPlan', 'currentPlan'])), 'Subscription Change Request approved successfully');
    }

    public function rejectChangeRequest(RejectSubscriptionChangeRequestRequest $request, SubscriptionChangeRequest $subscriptionChangeRequest): JsonResponse
    {
        Gate::authorize('platform-admin-only');

        $changeRequest = $this->subscriptions->reject(
            $subscriptionChangeRequest,
            $request->validated('reasons'),
            $request->validated('notes'),
            $request->user(),
        );

        return $this->successResponse(new SubscriptionChangeRequestResource($changeRequest->load(['requestedPlan', 'currentPlan', 'reasons'])), 'Subscription Change Request rejected successfully');
    }

    /**
     * Subscription Approval + Storage Add-on Approval (Product
     * Owner-approved decision record): the Platform Admin Approval Center
     * for Storage Add-on requests — same shape as
     * {@see changeRequestApprovalCenter()}.
     */
    public function storageAddonApprovalCenter(Request $request): JsonResponse
    {
        Gate::authorize('platform-admin-only');

        $query = StorageAddon::with('tenant');

        if ($status = $request->string('status')->trim()->value()) {
            $query->where('status', $status);
        }

        $addons = $query->orderByDesc('created_at')->paginate($this->perPage($request));

        return $this->successResponse([
            'storage_addon_requests' => StorageAddonResource::collection($addons->items()),
            'pagination' => [
                'current_page' => $addons->currentPage(),
                'per_page' => $addons->perPage(),
                'total' => $addons->total(),
                'last_page' => $addons->lastPage(),
            ],
        ]);
    }

    public function storageAddonRejectionReasons(): JsonResponse
    {
        Gate::authorize('platform-admin-only');

        return $this->successResponse(
            ReferenceDataResource::collection($this->referenceData->forCategory(null, ReferenceDataCategory::StorageRejectionReason)),
        );
    }

    public function approveStorageAddon(ApproveStorageAddonRequestRequest $request, StorageAddon $storageAddon): JsonResponse
    {
        Gate::authorize('platform-admin-only');

        $addon = $this->storageAddons->approve($storageAddon, $request->user());

        // Backend Completion Roadmap, Phase 4.2 precedent: approving a
        // Storage Add-on alters total storage allowance, not the customer
        // limit — CustomerReadOnlyService is customer-limit-only (its own
        // docblock), so no recalculation call belongs here; storage limit
        // enforcement is checked live on write (Phase 4.2), not via a
        // persisted read-only flag the way customer limit is.
        return $this->successResponse(new StorageAddonResource($addon), 'Storage Add-on request approved successfully');
    }

    public function rejectStorageAddon(RejectStorageAddonRequestRequest $request, StorageAddon $storageAddon): JsonResponse
    {
        Gate::authorize('platform-admin-only');

        $addon = $this->storageAddons->reject(
            $storageAddon,
            $request->validated('reasons'),
            $request->validated('notes'),
            $request->user(),
        );

        return $this->successResponse(new StorageAddonResource($addon->load('reasons')), 'Storage Add-on request rejected successfully');
    }
}
