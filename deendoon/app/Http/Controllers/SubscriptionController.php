<?php

namespace App\Http\Controllers;

use App\Http\Requests\StorageAddonRequestRequest;
use App\Http\Requests\SubscriptionUpgradeRequestRequest;
use App\Http\Resources\StorageAddonResource;
use App\Http\Resources\SubscriptionChangeRequestResource;
use App\Http\Resources\SubscriptionPlanResource;
use App\Models\Customer;
use App\Models\StorageAddon;
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
 * Backend Completion Roadmap, Phase 3.3 — Business Owner Subscription
 * APIs only. No Super Admin / Platform endpoints (Manual Payment
 * approval/rejection, Storage approval — Phase 3.4). Every method reads
 * or writes only the authenticated Business Owner's own tenant, never a
 * client-supplied tenant identifier — combined with the Conditional
 * Global Scope on TenantSubscription/SubscriptionChangeRequest/
 * StorageAddon (Phase 3.2), tenant isolation is enforced both
 * structurally (model layer) and explicitly (every query here still
 * filters by the resolved tenant, matching SubscriptionService's own
 * documented defense-in-depth reasoning).
 *
 * No new Service is added in this phase (Phase 3.3's explicit scope is
 * Controllers/Routes/Form Requests/API Resources/Feature Tests only) —
 * the one piece of derived logic this controller needs
 * (Read Only Status = subscription status is 'expired') is computed
 * inline from SubscriptionService::status(), which already exists.
 */
class SubscriptionController extends Controller
{
    use ApiResponse;

    /**
     * Approved Storage Add-on pricing (Product Owner decision) — the
     * server-side source of truth for storage_size/monthly_price;
     * storage_package is the only client-supplied value, validated
     * against these exact 4 keys in StorageAddonRequestRequest.
     *
     * @var array<string, array{size: int, price: float}>
     */
    private const PACKAGES = [
        '10gb' => ['size' => 10, 'price' => 2],
        '25gb' => ['size' => 25, 'price' => 4],
        '50gb' => ['size' => 50, 'price' => 7],
        '100gb' => ['size' => 100, 'price' => 12],
    ];

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
        $usage = $this->documents->storageUsage($tenant->id);

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
            'read_only' => $this->subscriptions->status($tenant) === 'expired',
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

        $changeRequest = new SubscriptionChangeRequest([
            'requested_plan_id' => $request->validated('requested_plan_id'),
            'payment_reference' => $request->validated('payment_reference'),
            'status' => 'pending',
        ]);
        $changeRequest->tenant_id = $tenant->id;
        $changeRequest->current_plan_id = $this->subscriptions->currentPlan($tenant)?->id;
        $changeRequest->save();

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

        $usage = $this->documents->storageUsage($tenant->id);
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

        $package = self::PACKAGES[$request->validated('storage_package')];

        $addon = new StorageAddon([
            'storage_package' => $request->validated('storage_package'),
            'storage_size' => $package['size'],
            'monthly_price' => $package['price'],
            'payment_reference' => $request->validated('payment_reference'),
            'status' => 'pending',
        ]);
        $addon->tenant_id = $tenant->id;
        $addon->save();

        return $this->successResponse(new StorageAddonResource($addon), 'Storage add-on request submitted successfully', 201);
    }
}
