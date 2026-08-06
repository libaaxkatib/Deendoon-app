<?php

namespace App\Http\Controllers;

use App\Http\Requests\StorageAddonRequestRequest;
use App\Http\Requests\SubscriptionUpgradeRequestRequest;
use App\Http\Resources\StorageAddonResource;
use App\Http\Resources\SubscriptionChangeRequestResource;
use App\Http\Resources\SubscriptionPlanResource;
use App\Models\Customer;
use App\Models\SubscriptionChangeRequest;
use App\Models\SubscriptionPlan;
use App\Services\DocumentService;
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
            $request->validated('payment_reference'),
            $request->user(),
        );

        return $this->successResponse(
            new SubscriptionChangeRequestResource($changeRequest->load(['requestedPlan', 'currentPlan'])),
            'Upgrade request submitted successfully',
            201,
        );
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
}
