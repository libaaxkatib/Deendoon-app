<?php

namespace App\Services;

use App\Models\Customer;
use App\Models\Tenant;
use Illuminate\Auth\Access\AuthorizationException;

/**
 * Backend Completion Roadmap, Phase 4.1 — Customer Limit Enforcement.
 * Recompute-from-source, matching the same guarantee already established
 * for RiskLevelService/CustomerBalanceService/BusinessHealthService:
 * `is_read_only` is never incremented/decremented or set incrementally,
 * only fully recalculated from current state on every call.
 *
 * Approved rule: the oldest customers (by `created_at`) up to the
 * tenant's current plan `customer_limit` stay editable; every customer
 * beyond that becomes read-only. Unlimited plans (`customer_limit` is
 * null on a plan that was actually resolved) never mark anyone
 * read-only. "Promotion" of the next-oldest customer after one is
 * archived/deleted is not a separate mechanism — it's an emergent
 * property of recomputing from source: an archived customer is excluded
 * from the ordered query by Customer's own SoftDeletes scope, so the
 * next-oldest active customer naturally qualifies for one of the now-open
 * editable slots on the next call. The same is true of restore: a
 * restored customer re-enters the ordered query and this recomputation
 * alone decides whether it (or some other customer) ends up read-only —
 * restore itself is never blocked (Product Owner Decision, 2026-08-06).
 *
 * Uses {@see SubscriptionService::effectiveCustomerLimit()}, not
 * {@see SubscriptionService::customerLimit()} — Product Owner Decision
 * (2026-08-06): "No subscription record must NEVER be treated as
 * Unlimited. Fail Closed." A tenant with no resolvable plan at all (not
 * even the Free Plan fallback) gets an effective limit of 0, which this
 * class's normal limit-enforcement path (below) already handles
 * correctly: nobody qualifies for an editable slot, so every customer
 * becomes read-only until the environment's Free Plan is (re)seeded.
 *
 * Implemented as 2 bulk UPDATE statements (plus the 1 SELECT that finds
 * the editable IDs) regardless of customer count — never a per-row loop
 * — so this stays a fixed, small number of queries no matter how many
 * customers a tenant has.
 */
class CustomerReadOnlyService
{
    public function __construct(
        private readonly SubscriptionService $subscriptions,
    ) {}

    /**
     * Race-safe recheck for Customer creation. Must be called from
     * inside the same database transaction that will insert the new
     * Customer, before the insert happens. `CustomerPolicy::create()`'s
     * own check runs first, outside any transaction, as a fast,
     * non-atomic pre-check that produces a normal 403 for the common
     * case without opening a transaction for requests that were never
     * going to succeed; it cannot by itself prevent two concurrent
     * requests both passing that check when the tenant is one slot under
     * its limit (Product Owner review, 2026-08-06). This method is the
     * actual guarantee: {@see lockAndGetEffectiveLimit()} takes a
     * `SELECT ... FOR UPDATE` lock on the tenant's own row, which
     * Postgres (production) holds until the caller's transaction commits
     * or rolls back — a second concurrent call for the same tenant
     * blocks until the first finishes, so the count it then reads
     * already reflects the first request's insert. On SQLite (the test
     * suite's driver) `lockForUpdate()` compiles to no additional SQL —
     * SQLite already serializes writers at the database-file level, and
     * tests run single-threaded regardless, so this is a correctness
     * no-op there, not a gap.
     */
    public function assertCanCreateCustomer(Tenant $tenant): void
    {
        $limit = $this->lockAndGetEffectiveLimit($tenant);

        if ($limit !== null && Customer::where('tenant_id', $tenant->id)->count() >= $limit) {
            throw new AuthorizationException('This action is unauthorized.');
        }
    }

    /**
     * Locks the tenant's own row for the remainder of the caller's
     * transaction, then resolves its effective customer limit. Exposed
     * separately (not folded into {@see assertCanCreateCustomer()}) so
     * CustomerImportController's bulk commit can take the lock once for
     * the whole batch and track remaining capacity locally across many
     * rows, instead of re-querying the count for every row.
     */
    public function lockAndGetEffectiveLimit(Tenant $tenant): ?int
    {
        Tenant::where('id', $tenant->id)->lockForUpdate()->first();

        return $this->subscriptions->effectiveCustomerLimit($tenant);
    }

    public function recalculate(Tenant $tenant): void
    {
        $limit = $this->subscriptions->effectiveCustomerLimit($tenant);

        if ($limit === null) {
            Customer::where('tenant_id', $tenant->id)
                ->where('is_read_only', true)
                ->update(['is_read_only' => false]);

            return;
        }

        $editableIds = Customer::where('tenant_id', $tenant->id)
            ->orderBy('created_at')
            ->limit($limit)
            ->pluck('id');

        Customer::where('tenant_id', $tenant->id)
            ->whereIn('id', $editableIds)
            ->update(['is_read_only' => false]);

        Customer::where('tenant_id', $tenant->id)
            ->whereNotIn('id', $editableIds)
            ->update(['is_read_only' => true]);
    }
}
