<?php

namespace App\Services;

use App\Models\SubscriptionPlan;
use App\Models\Tenant;
use App\Models\TenantSubscription;

/**
 * Backend Completion Roadmap, Phase 3.2. Read-only Subscription domain
 * queries only — no writes, no HTTP concerns, no enforcement. Every
 * method here mirrors what Phase 4 (Subscription Enforcement) will
 * eventually gate against, but this service only reports current state;
 * it never changes it.
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
}
