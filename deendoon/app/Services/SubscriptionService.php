<?php

namespace App\Services;

use App\Enums\AuditAction;
use App\Models\SubscriptionChangeRequest;
use App\Models\SubscriptionPlan;
use App\Models\Tenant;
use App\Models\TenantSubscription;
use App\Models\User;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Support\Facades\DB;

/**
 * Backend Completion Roadmap, Phase 3.2. Read-only Subscription domain
 * queries only — no writes, no HTTP concerns, no enforcement. Every
 * method here mirrors what Phase 4 (Subscription Enforcement) will
 * eventually gate against, but this service only reports current state;
 * it never changes it.
 *
 * Phase 3.4 adds exactly one write: {@see requestUpgrade()}, the Manual
 * Payment Workflow's request-creation step. It creates a pending
 * SubscriptionChangeRequest only — no approval, activation, or plan
 * change, which remain explicitly out of scope until a later phase.
 *
 * Every method here still filters by `tenant_id` explicitly, even though
 * {@see TenantSubscription} now also carries the automatic
 * BelongsToTenantOrPlatformAdmin scope (Product Owner Decision: Option B).
 * These are complementary, not redundant: the scope's job is structural
 * isolation — an ordinary tenant user can never see another tenant's row,
 * even from code that forgets to filter. This service's job is different
 * — resolving *the specific tenant passed as an argument*, which matters
 * most exactly when the caller is the Platform Administrator reviewing an
 * arbitrary tenant during Manual Payment Review: for that caller the
 * scope applies no filter at all, so without this explicit `tenant_id`
 * match the query would return an arbitrary row, not the requested
 * tenant's row. For an ordinary tenant user the two filters simply agree;
 * if they were ever passed a mismatched tenant by a future bug elsewhere,
 * the combination fails safe (returns nothing) rather than leaking data.
 */
class SubscriptionService
{
    public function __construct(
        private readonly AuditLogService $auditLog,
    ) {}

    public function currentSubscription(Tenant $tenant): ?TenantSubscription
    {
        return TenantSubscription::where('tenant_id', $tenant->id)->first();
    }

    /**
     * Product Owner decision: a tenant with no subscription record at all
     * is treated as being on the Free Plan — resolves the previous
     * ambiguity where {@see customerLimit()} returning null could mean
     * either "unlimited" or "no subscription found." Looked up by name
     * rather than fabricated: if the Free plan itself hasn't been seeded
     * yet in a given environment, this still returns null (a data-
     * availability gap, not a design ambiguity — no numeric value is
     * invented here).
     */
    public function currentPlan(Tenant $tenant): ?SubscriptionPlan
    {
        $subscription = $this->currentSubscription($tenant);

        if ($subscription !== null) {
            return $subscription->plan;
        }

        return SubscriptionPlan::where('name', 'Free')->first();
    }

    /**
     * BRL/Product Owner decisions: 2 (Free), 110 (Small Business), 250
     * (Medium Business), NULL (Corporate — approved "Unlimited
     * customers"). A tenant with no subscription record falls back to the
     * Free Plan's limit via {@see currentPlan()} — no longer ambiguous
     * with "unlimited" (Corporate's null is a real plan value; a missing
     * subscription record is no longer a second, indistinguishable source
     * of null).
     */
    public function customerLimit(Tenant $tenant): ?int
    {
        return $this->currentPlan($tenant)?->customer_limit;
    }

    /**
     * Approved base storage limits: Trial 10GB, Free 10GB, Small Business
     * 25GB, Medium Business 50GB, Corporate 100GB — never null at the
     * schema level (Phase 3.1 migration), so a null return here means the
     * relevant SubscriptionPlan row hasn't been seeded yet, not a
     * business-rule ambiguity. A tenant with no subscription record falls
     * back to the Free Plan's limit via {@see currentPlan()}.
     */
    public function storageLimit(Tenant $tenant): ?int
    {
        return $this->currentPlan($tenant)?->storage_limit;
    }

    /**
     * Approved: Free Plan does not include the Analytics Dashboard; Small
     * Business, Medium Business, and Corporate do. A tenant with no
     * subscription record falls back to the Free Plan via
     * {@see currentPlan()}, so this correctly resolves to false for them
     * either way; still returns false (not null) if even the Free Plan
     * row itself hasn't been seeded — a fail-closed default.
     */
    public function analyticsEnabled(Tenant $tenant): bool
    {
        return (bool) $this->currentPlan($tenant)?->analytics_enabled;
    }

    /**
     * Raw `tenant_subscriptions.status` ('trialing'/'active'/'expired'),
     * or null if the tenant has no subscription record at all.
     */
    public function status(Tenant $tenant): ?string
    {
        return $this->currentSubscription($tenant)?->status;
    }

    /**
     * True only when the subscription is both marked 'trialing' AND its
     * trial window hasn't elapsed yet. Deliberately does not reconcile a
     * 'trialing' status whose `trial_ends_at` has already passed into any
     * other state — the trial-expiration transition itself (auto-
     * downgrade to Free) is scheduled-job business logic, explicitly out
     * of scope for this phase (read-only only).
     */
    public function isOnTrial(Tenant $tenant): bool
    {
        $subscription = $this->currentSubscription($tenant);

        return $subscription !== null
            && $subscription->status === 'trialing'
            && $subscription->trial_ends_at !== null
            && $subscription->trial_ends_at->isFuture();
    }

    /**
     * Manual Payment Workflow, step 3-4: Business Owner submits
     * requested_plan_id + payment_reference; system creates a pending
     * SubscriptionChangeRequest. No approval, no activation, no plan
     * change — those remain a later phase's responsibility.
     *
     * Rejects (409) only when a *pending* request already exists for this
     * tenant (Product Owner confirmation: approved and rejected requests
     * never block a new one) — mirroring
     * ProfessionalCollectionRequestService::submit()'s identical "no
     * other active Request already pending" pattern (BRL-078).
     * `current_plan_id` is a server-derived snapshot via
     * {@see currentPlan()}, never client-supplied.
     *
     * The audit entry's `reason` carries `requested_plan_id` and
     * `payment_reference` (tenant_id is already the audit_log row's own
     * dedicated column) — audit_log has no separate metadata/JSON column,
     * so this reuses the existing `reason` field, matching how other
     * services already pack contextual detail into it (e.g.
     * RiskLevelService's recalculation reason), per the Product Owner's
     * requirement that this be sufficient for future Super Admin
     * auditing.
     */
    public function requestUpgrade(Tenant $tenant, string $requestedPlanId, string $paymentReference, User $actor): SubscriptionChangeRequest
    {
        return DB::transaction(function () use ($tenant, $requestedPlanId, $paymentReference, $actor) {
            if (SubscriptionChangeRequest::where('tenant_id', $tenant->id)->where('status', 'pending')->exists()) {
                $this->conflict('A pending Subscription Change Request already exists for this tenant.');
            }

            $changeRequest = new SubscriptionChangeRequest([
                'requested_plan_id' => $requestedPlanId,
                'payment_reference' => $paymentReference,
                'status' => 'pending',
            ]);
            $changeRequest->tenant_id = $tenant->id;
            $changeRequest->current_plan_id = $this->currentPlan($tenant)?->id;
            $changeRequest->save();

            $this->auditLog->record(
                AuditAction::SubscriptionUpgradeRequested,
                'subscription_change_request',
                $changeRequest->id,
                $actor,
                "requested_plan_id={$requestedPlanId}; payment_reference={$paymentReference}",
                $tenant->id,
            );

            return $changeRequest->refresh();
        });
    }

    private function conflict(string $message): never
    {
        throw new HttpResponseException(response()->json([
            'success' => false,
            'message' => $message,
            'data' => null,
            'errors' => null,
        ], 409));
    }
}
