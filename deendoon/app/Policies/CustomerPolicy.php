<?php

namespace App\Policies;

use App\Models\Customer;
use App\Models\User;
use App\Services\CustomerReadOnlyService;
use App\Services\SubscriptionService;

/**
 * Version 1 authentication model (RBAC Architecture Amendment, Product
 * Owner Decision, 2026-07-30): exactly two account types exist —
 * Business Owner (Customer Mobile App, role `admin`) and Platform
 * Administrator. Customer Management is a Business Owner capability.
 *
 * Backend Completion Roadmap, Phase 4.1 — Customer Limit Enforcement:
 * `create` additionally blocks once the tenant is already at their
 * plan's effective customer limit (creating one more would exceed it,
 * not just "customers over the limit become read-only" — matching the
 * originally approved Customer Limit Rules: "New customer creation is
 * blocked"). This is a fast, non-atomic pre-check only — it uses
 * {@see SubscriptionService::effectiveCustomerLimit()} (fail-closed: no
 * resolvable plan means limit 0, never unlimited), but the actual
 * race-safe guarantee against concurrent creation requests is
 * {@see CustomerReadOnlyService::assertCanCreateCustomer()},
 * which CustomerController::store() calls inside its transaction.
 * `update`/`archive`/`generateDocuments` additionally block when the
 * specific Customer is already read-only. `view`/`viewAny`/`restore`/
 * `import`/`viewCreditScore` are deliberately untouched — read
 * operations must keep working, and `restore` is deliberately NOT
 * gated on the customer's own `is_read_only` (frozen at archive time,
 * not meaningful to re-check before re-activating them) nor on the
 * plan limit — Product Owner Decision (2026-08-06): restore is always
 * allowed, and CustomerReadOnlyService::recalculate() alone decides
 * whether the restored customer ends up editable or read-only.
 */
class CustomerPolicy
{
    public function __construct(
        private readonly SubscriptionService $subscriptions,
    ) {}

    public function viewAny(User $user): bool
    {
        return $this->isAuthorized($user);
    }

    public function view(User $user, Customer $customer): bool
    {
        return $this->isAuthorized($user);
    }

    public function create(User $user): bool
    {
        if (! $this->isAuthorized($user)) {
            return false;
        }

        $limit = $this->subscriptions->effectiveCustomerLimit($user->tenant);

        if ($limit === null) {
            return true;
        }

        return Customer::where('tenant_id', $user->tenant_id)->count() < $limit;
    }

    public function update(User $user, Customer $customer): bool
    {
        return $this->isAuthorized($user) && ! $customer->is_read_only;
    }

    public function archive(User $user, Customer $customer): bool
    {
        return $this->isAuthorized($user) && ! $customer->is_read_only;
    }

    public function restore(User $user, Customer $customer): bool
    {
        return $this->isAuthorized($user);
    }

    public function import(User $user): bool
    {
        return $this->isAuthorized($user);
    }

    public function viewCreditScore(User $user, Customer $customer): bool
    {
        return $this->isAuthorized($user);
    }

    public function generateDocuments(User $user, Customer $customer): bool
    {
        return $this->isAuthorized($user) && ! $customer->is_read_only;
    }

    private function isAuthorized(User $user): bool
    {
        return $user->hasRole('admin');
    }
}
