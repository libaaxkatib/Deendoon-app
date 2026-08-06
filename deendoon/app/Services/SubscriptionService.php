<?php

namespace App\Services;

use App\Enums\AuditAction;
use App\Models\SubscriptionChangeRequest;
use App\Models\SubscriptionPlan;
use App\Models\Tenant;
use App\Models\TenantSubscription;
use App\Models\User;
use App\Policies\CustomerPolicy;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

/**
 * Backend Completion Roadmap, Phase 3.2. Read-only Subscription domain
 * queries only — no writes, no HTTP concerns, no enforcement. Every
 * method here mirrors what Phase 4 (Subscription Enforcement) will
 * eventually gate against, but this service only reports current state;
 * it never changes it.
 *
 * Phase 3.4 adds one write, {@see requestUpgrade()} — the Manual Payment
 * Workflow's request-creation step. It creates a pending
 * SubscriptionChangeRequest only — no approval, activation, or plan
 * change, which remain explicitly out of scope until a later phase.
 * Phase 3.5 adds a second, {@see provisionTrial()} — automatic Trial
 * provisioning at registration. Both are still narrowly scoped writes,
 * not the beginning of a general write API on this service.
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
     * Same underlying resolution as {@see customerLimit()}, but fails
     * closed. Product Owner Decision, Phase 4.1 review (2026-08-06): "No
     * subscription record must NEVER be treated as Unlimited. Fail
     * Closed." `customerLimit()` cannot distinguish "a real plan was
     * found and its customer_limit column is null by design" (Trial,
     * Corporate — genuinely unlimited) from "no plan could be resolved at
     * all, not even the Free Plan fallback" (e.g. the Free Plan row
     * hasn't been seeded in this environment) — both return null from
     * that method. This method resolves the ambiguity by inspecting
     * {@see currentPlan()} directly: only a plan that was actually found
     * and explicitly carries a null `customer_limit` is unlimited. If no
     * plan can be resolved at all, this returns 0 — the most restrictive
     * value, blocking new customer creation and marking every existing
     * customer read-only until the environment's Free Plan is (re)seeded
     * — never failing open to "no limit." Used only by the Customer
     * Limit Enforcement call sites; {@see customerLimit()} keeps its
     * original "raw plan value" semantics for reporting endpoints.
     *
     * Backend Completion Roadmap, Phase 4.4 — Feature & Read-Only
     * Enforcement, Product Owner Decision: an `expired` paid subscription
     * also forces this to 0, reusing this exact method (and therefore
     * every downstream consumer — {@see CustomerReadOnlyService::recalculate()},
     * {@see CustomerReadOnlyService::assertCanCreateCustomer()},
     * {@see CustomerPolicy::create()}) with zero changes to
     * any of them — a single source of truth for "how many customers can
     * this tenant edit right now," not a second, parallel enforcement
     * path. Checked ahead of the plan lookup: an expired tenant's
     * `plan_id` is deliberately left untouched by
     * {@see expireSubscriptions()} (no downgrade), so `currentPlan()`
     * would otherwise still report that plan's ordinary limit. A `Free`
     * Plan subscription produced by {@see expireTrials()} is unaffected
     * — its status is `active`, never `expired`.
     */
    public function effectiveCustomerLimit(Tenant $tenant): ?int
    {
        $subscription = $this->currentSubscription($tenant);

        if ($subscription !== null && $subscription->status === 'expired') {
            return 0;
        }

        // Reuses the already-fetched $subscription instead of calling
        // currentPlan($tenant) (which would re-run currentSubscription()
        // a second time) — same Free Plan fallback currentPlan() itself
        // performs, just without the redundant query.
        $plan = $subscription !== null ? $subscription->plan : SubscriptionPlan::where('name', 'Free')->first();

        return $plan === null ? 0 : $plan->customer_limit;
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
     * other state itself — that transition is {@see expireTrials()}'s
     * job (Backend Completion Roadmap, Phase 4.3), invoked via the
     * `subscriptions:expire-trials` Artisan command, not something this
     * read-only method performs as a side effect of being called.
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
     * The `exists()` check alone cannot prevent two concurrent requests
     * from both passing it before either commits (Postgres READ COMMITTED
     * doesn't serialize this) — the database-level partial unique index
     * `subscription_change_requests_one_pending_per_tenant` (Phase 3.5
     * mandatory fix) is the actual safety net; a race that slips past the
     * check is caught here as a UniqueConstraintViolationException and
     * converted to the identical 409 response, so the API behaves the
     * same regardless of which layer caught it.
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

            try {
                $changeRequest->save();
            } catch (UniqueConstraintViolationException) {
                $this->conflict('A pending Subscription Change Request already exists for this tenant.');
            }

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

    /**
     * Phase 3.5 (Product Owner decision): every newly-registered tenant
     * automatically receives a Trial TenantSubscription — the Free Plan
     * fallback in {@see currentPlan()} is only for tenants that genuinely
     * have no subscription record, not the normal path for a new tenant.
     * Called from AuthController::register(), inside the same
     * transaction as tenant/user creation.
     *
     * `expires_at` is set equal to `trial_ends_at`: for a trialing
     * subscription the "current period" *is* the trial, so its own
     * expiry and the trial's expiry are the same date — not separately
     * specified by the approved decision, but the only coherent reading
     * once all 4 requested fields are populated together.
     *
     * `firstOrFail()` deliberately does not fall back or degrade
     * gracefully if the Trial plan row is missing (e.g. the seeder never
     * ran) — matching this exact codebase's existing precedent for
     * `$user->assignRole('admin')` a few lines above this call site in
     * AuthController::register(), which has an identical hard dependency
     * on seeded data and no defensive fallback either.
     *
     * Backend Completion Roadmap, Phase 4.5 — Final Verification fix:
     * `$actor` is now required and the creation is audited
     * ({@see AuditAction::TrialProvisioned}) — this previously wrote no
     * audit entry at all, unlike {@see requestUpgrade()}/
     * {@see StorageAddonService::requestAddon()}, both of which already
     * audit. `$actor` is required, not optional, because the only call
     * site (`AuthController::register()`) always has the newly-created
     * user in scope — matching `requestUpgrade()`'s identical
     * required-actor signature rather than introducing an inconsistent
     * optional one.
     */
    public function provisionTrial(Tenant $tenant, User $actor): TenantSubscription
    {
        $trialPlan = SubscriptionPlan::where('name', 'Trial')->firstOrFail();

        $subscription = new TenantSubscription([
            'plan_id' => $trialPlan->id,
            'status' => 'trialing',
            'started_at' => now(),
            'trial_started_at' => now(),
            'trial_ends_at' => now()->addDays(7),
            'expires_at' => now()->addDays(7),
        ]);
        $subscription->tenant_id = $tenant->id;
        $subscription->save();

        $this->auditLog->record(
            AuditAction::TrialProvisioned,
            'tenant_subscription',
            $subscription->id,
            $actor,
            "plan_id={$trialPlan->id} (Trial); status=trialing",
            $tenant->id,
        );

        return $subscription;
    }

    /**
     * Backend Completion Roadmap, Phase 4.3 — Subscription Lifecycle.
     * Trial → Free Plan: "When Trial expires: Automatically move tenant
     * to Free Plan, Status becomes active, Free Plan becomes current
     * subscription." Invoked from the `subscriptions:expire-trials`
     * Artisan command (Product Owner Decision, 2026-08-06: plain
     * command, no scheduler infrastructure — this codebase has a
     * standing decision against introducing one).
     *
     * "Update subscription dates" (Product Owner Decision, 2026-08-06):
     * `started_at` resets to now, simply recording the date the tenant
     * entered the Free Plan — it is NOT the start of a billing cycle,
     * since the Free Plan has none. `expires_at` is set to null: the
     * Free Plan never expires, so leaving a stale date here would
     * incorrectly make it eligible for {@see expireSubscriptions()} on
     * its next run. `trial_started_at`/`trial_ends_at` are left
     * untouched — historical record of when the trial actually ran, not
     * something this transition should erase.
     *
     * Race-safe and self-idempotent under both sequential and concurrent
     * re-runs, matching Phase 4.1/4.2's `lockForUpdate()` pattern: each
     * candidate row is locked and re-verified inside its own short
     * transaction (bounded lock duration regardless of how many trials
     * expire in one run — deliberately not one giant transaction over
     * every candidate, so a large tenant count doesn't hold one lock for
     * an unbounded time) before being transitioned. A row that fails the
     * re-check (already processed by a concurrent run, or no longer
     * actually expired) is silently skipped, not an error — this is what
     * makes running the command twice a safe no-op the second time.
     *
     * Returns the affected Tenants (not a count) so the calling command
     * can trigger {@see CustomerReadOnlyService::recalculate()} per
     * tenant — "Customer/Storage limits immediately become Free
     * limits" requires it, but this service cannot depend on
     * CustomerReadOnlyService directly (it already depends on
     * SubscriptionService, which would be circular) — same resolution
     * Phase 4.1 used for AuthController::register().
     *
     * @return Collection<int, Tenant>
     */
    public function expireTrials(): Collection
    {
        $freePlan = SubscriptionPlan::where('name', 'Free')->firstOrFail();

        $candidateIds = TenantSubscription::where('status', 'trialing')
            ->where('trial_ends_at', '<=', now())
            ->pluck('id');

        return $candidateIds
            ->map(fn (string $id) => $this->expireOneTrial($id, $freePlan))
            ->filter()
            ->values();
    }

    private function expireOneTrial(string $subscriptionId, SubscriptionPlan $freePlan): ?Tenant
    {
        return DB::transaction(function () use ($subscriptionId, $freePlan) {
            $subscription = TenantSubscription::where('id', $subscriptionId)->lockForUpdate()->first();

            if ($subscription === null || $subscription->status !== 'trialing' || $subscription->trial_ends_at === null || $subscription->trial_ends_at->isFuture()) {
                return null;
            }

            $oldPlanId = $subscription->plan_id;
            $subscription->update([
                'plan_id' => $freePlan->id,
                'status' => 'active',
                'started_at' => now(),
                'expires_at' => null,
            ]);

            $this->auditLog->record(
                AuditAction::TrialExpired,
                'tenant_subscription',
                $subscription->id,
                null,
                "plan_id changed from {$oldPlanId} to {$freePlan->id} (Free Plan); status changed from trialing to active",
                $subscription->tenant_id,
            );

            return $subscription->tenant;
        });
    }

    /**
     * Backend Completion Roadmap, Phase 4.3 — Subscription Lifecycle.
     * Paid subscription → expired: "When subscription expires and
     * renewal has NOT been approved: Status becomes expired. No
     * automatic renewal. No automatic payment. No automatic
     * activation." Only `status` changes — `plan_id` is left exactly as
     * it was (no plan downgrade is specified). Invoked from the
     * `subscriptions:expire` Artisan command.
     *
     * `whereNotNull('expires_at')` is a deliberate, explicit guard, not
     * strictly required by SQL NULL comparison semantics alone (a NULL
     * `expires_at` already never satisfies `<= now()`): it documents the
     * specific thing this must never do — a Free Plan subscription
     * (status 'active', `expires_at` null, per {@see expireTrials()})
     * must never be swept into 'expired' by this method.
     *
     * Same race-safety/idempotency shape as {@see expireTrials()}: one
     * short transaction with a re-verified `lockForUpdate()` per
     * candidate row, not one transaction for the whole batch.
     *
     * Backend Completion Roadmap, Phase 4.4 (Product Owner Decision):
     * now returns the affected Tenants, not a count — {@see effectiveCustomerLimit()}
     * treats an `expired` subscription as a 0 customer limit, so this
     * DOES now need {@see CustomerReadOnlyService::recalculate()} per
     * tenant the way {@see expireTrials()} always has (this method's
     * original Phase 4.3 docblock said otherwise; that was correct only
     * until this phase's enforcement design made subscription status
     * itself affect the effective limit). Mirrors expireTrials()'s exact
     * shape for the same reason: this service cannot depend on
     * CustomerReadOnlyService directly (circular — it already depends on
     * this service), so the calling command orchestrates the trigger.
     *
     * @return Collection<int, Tenant>
     */
    public function expireSubscriptions(): Collection
    {
        $candidateIds = TenantSubscription::where('status', 'active')
            ->whereNotNull('expires_at')
            ->where('expires_at', '<=', now())
            ->pluck('id');

        return $candidateIds
            ->map(fn (string $id) => $this->expireOneSubscription($id))
            ->filter()
            ->values();
    }

    private function expireOneSubscription(string $subscriptionId): ?Tenant
    {
        return DB::transaction(function () use ($subscriptionId) {
            $subscription = TenantSubscription::where('id', $subscriptionId)->lockForUpdate()->first();

            if ($subscription === null || $subscription->status !== 'active' || $subscription->expires_at === null || $subscription->expires_at->isFuture()) {
                return null;
            }

            $subscription->update(['status' => 'expired']);

            $this->auditLog->record(
                AuditAction::SubscriptionExpired,
                'tenant_subscription',
                $subscription->id,
                null,
                'status changed from active to expired',
                $subscription->tenant_id,
            );

            return $subscription->tenant;
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
