<?php

namespace App\Http\Controllers\Admin;

use App\Enums\ReferenceDataCategory;
use App\Http\Controllers\Controller;
use App\Http\Requests\ApproveStorageAddonRequestRequest;
use App\Http\Requests\ApproveSubscriptionChangeRequestRequest;
use App\Http\Requests\RejectStorageAddonRequestRequest;
use App\Http\Requests\RejectSubscriptionChangeRequestRequest;
use App\Models\Concerns\BelongsToTenantOrPlatformAdmin;
use App\Models\StorageAddon;
use App\Models\SubscriptionChangeRequest;
use App\Models\SubscriptionPlan;
use App\Models\Tenant;
use App\Services\CustomerReadOnlyService;
use App\Services\ReferenceDataService;
use App\Services\StorageAddonService;
use App\Services\SubscriptionService;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

/**
 * Admin Panel — Subscriptions / Subscription Management & Approval Center.
 * Approve/Reject actions are real writes, but every one of them delegates
 * to the existing, already-tested {@see SubscriptionService}/
 * {@see StorageAddonService} — the exact same methods
 * `SubscriptionController` (the API's Platform Admin Approval Center)
 * already calls. Nothing here duplicates that business logic: activating
 * the requested plan, updating (not duplicating) the tenant's
 * TenantSubscription row, recording the Audit Log entry, and notifying
 * the Business Owner are all handled inside those service methods, not
 * this controller.
 *
 * Tenant-scope note — deliberately different from AdminDebtController/
 * AdminCustomerController/AdminPaymentController: TenantSubscription,
 * SubscriptionChangeRequest, and StorageAddon use
 * {@see BelongsToTenantOrPlatformAdmin}, not plain
 * BelongsToTenant. That trait's scope callback (verified by reading it
 * directly) already returns with no filter at all when the resolved user
 * is the Platform Administrator — so, unlike Debt/Customer/Payment,
 * `withoutGlobalScope('tenant')` is unnecessary here and would misstate
 * what's actually happening. Implicit route-model binding on
 * `SubscriptionChangeRequest`/`StorageAddon` is therefore also safe to
 * use (matching the existing API `SubscriptionController`'s own
 * convention), unlike Debt/Customer where it was deliberately avoided.
 * `Tenant` itself carries no tenant scope at all (it IS the tenant).
 *
 * No new Policy: `SubscriptionChangeRequest`/`StorageAddon` have none
 * today (the API controller gates every Platform Admin method with
 * `Gate::authorize('platform-admin-only')`); this controller relies
 * purely on the route group's `can:platform-admin-only` middleware,
 * matching every other admin controller in this panel.
 */
class AdminSubscriptionController extends Controller
{
    public const SUBSCRIPTION_STATUSES = [
        'trialing' => 'Trialing',
        'active' => 'Active',
        'expired' => 'Expired',
    ];

    public const REQUEST_STATUSES = [
        'pending' => 'Pending',
        'approved' => 'Approved',
        'rejected' => 'Rejected',
        'cancelled' => 'Cancelled',
    ];

    public const STORAGE_ADDON_STATUSES = [
        'pending' => 'Pending',
        'active' => 'Active',
        'expired' => 'Expired',
        'rejected' => 'Rejected',
        'cancelled' => 'Cancelled',
    ];

    public function __construct(
        private readonly SubscriptionService $subscriptions,
        private readonly StorageAddonService $storageAddons,
        private readonly CustomerReadOnlyService $customerReadOnly,
        private readonly ReferenceDataService $referenceData,
    ) {}

    public function index(Request $request): View
    {
        $tenants = Tenant::with(['subscription.plan'])
            ->withCount([
                'subscriptionChangeRequests as pending_change_requests_count' => fn ($query) => $query->where('status', 'pending'),
                'storageAddons as pending_storage_addons_count' => fn ($query) => $query->where('status', 'pending'),
            ])
            ->when($request->filled('search'), fn ($query) => $query->whereRaw(
                'LOWER(business_name) LIKE ?', ['%'.mb_strtolower((string) $request->string('search')).'%']
            ))
            ->when($request->filled('status'), function ($query) use ($request) {
                $status = $request->string('status')->value();
                if ($status === 'no_subscription') {
                    $query->doesntHave('subscription');
                } else {
                    $query->whereHas('subscription', fn ($q) => $q->where('status', $status));
                }
            })
            ->when($request->filled('plan'), fn ($query) => $query->whereHas('subscription', fn ($q) => $q->where('plan_id', $request->string('plan'))))
            ->when($request->boolean('pending_only'), fn ($query) => $query->where(function ($q) {
                $q->whereHas('subscriptionChangeRequests', fn ($r) => $r->where('status', 'pending'))
                    ->orWhereHas('storageAddons', fn ($r) => $r->where('status', 'pending'));
            }))
            ->orderBy('business_name')
            ->paginate(20)
            ->withQueryString();

        return view('admin.subscriptions.index', [
            'title' => 'Subscriptions',
            'tenants' => $tenants,
            'subscriptionStatuses' => self::SUBSCRIPTION_STATUSES,
            'plans' => SubscriptionPlan::orderBy('name')->get(['id', 'name']),
        ]);
    }

    public function show(Tenant $tenant): View
    {
        $tenant->load([
            'subscription.plan',
            'subscriptionChangeRequests' => fn ($query) => $query->with(['requestedPlan', 'currentPlan', 'reasons'])->orderByDesc('requested_at'),
            'storageAddons' => fn ($query) => $query->with('reasons')->orderByDesc('created_at'),
        ]);

        return view('admin.subscriptions.show', [
            'title' => 'Subscriptions',
            'pageTitle' => $tenant->business_name,
            'tenant' => $tenant,
            'subscriptionStatuses' => self::SUBSCRIPTION_STATUSES,
            'requestStatuses' => self::REQUEST_STATUSES,
            'storageAddonStatuses' => self::STORAGE_ADDON_STATUSES,
            'changeRequestRejectionReasons' => $this->referenceData->forCategory(null, ReferenceDataCategory::SubscriptionRejectionReason),
            'storageAddonRejectionReasons' => $this->referenceData->forCategory(null, ReferenceDataCategory::StorageRejectionReason),
        ]);
    }

    public function approveChangeRequest(ApproveSubscriptionChangeRequestRequest $request, SubscriptionChangeRequest $subscriptionChangeRequest): RedirectResponse
    {
        try {
            $changeRequest = $this->subscriptions->approve($subscriptionChangeRequest, $request->user());
        } catch (HttpResponseException $e) {
            return $this->backWithServiceError($e);
        }

        // Approving a plan change alters the tenant's effective customer
        // limit — recalculated here, matching the exact orchestration the
        // API's SubscriptionController::approveChangeRequest() already
        // performs after calling SubscriptionService::approve().
        $this->customerReadOnly->recalculate($changeRequest->tenant, $request->user());

        return redirect()->route('admin.subscriptions.show', $changeRequest->tenant_id)
            ->with('status', 'Subscription Change Request approved — the tenant\'s subscription has been updated.');
    }

    public function rejectChangeRequest(RejectSubscriptionChangeRequestRequest $request, SubscriptionChangeRequest $subscriptionChangeRequest): RedirectResponse
    {
        try {
            $changeRequest = $this->subscriptions->reject(
                $subscriptionChangeRequest,
                $request->validated('reasons'),
                $request->validated('notes'),
                $request->user(),
            );
        } catch (HttpResponseException $e) {
            return $this->backWithServiceError($e);
        }

        return redirect()->route('admin.subscriptions.show', $changeRequest->tenant_id)
            ->with('status', 'Subscription Change Request rejected.');
    }

    public function approveStorageAddon(ApproveStorageAddonRequestRequest $request, StorageAddon $storageAddon): RedirectResponse
    {
        try {
            $addon = $this->storageAddons->approve($storageAddon, $request->user());
        } catch (HttpResponseException $e) {
            return $this->backWithServiceError($e);
        }

        return redirect()->route('admin.subscriptions.show', $addon->tenant_id)
            ->with('status', 'Storage Add-on request approved.');
    }

    public function rejectStorageAddon(RejectStorageAddonRequestRequest $request, StorageAddon $storageAddon): RedirectResponse
    {
        try {
            $addon = $this->storageAddons->reject(
                $storageAddon,
                $request->validated('reasons'),
                $request->validated('notes'),
                $request->user(),
            );
        } catch (HttpResponseException $e) {
            return $this->backWithServiceError($e);
        }

        return redirect()->route('admin.subscriptions.show', $addon->tenant_id)
            ->with('status', 'Storage Add-on request rejected.');
    }

    /**
     * SubscriptionService/StorageAddonService signal an already-reviewed
     * or invalid-transition request via `HttpResponseException` wrapping
     * a JSON 409 (the shape the API controller returns directly) — the
     * Blade panel converts that into a friendly redirect-back with an
     * error message instead of surfacing a raw JSON body.
     */
    private function backWithServiceError(HttpResponseException $e): RedirectResponse
    {
        $message = $e->getResponse()->getData(true)['message'] ?? 'This request could not be processed.';

        return back()->withErrors(['action' => $message]);
    }
}
