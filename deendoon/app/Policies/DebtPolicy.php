<?php

namespace App\Policies;

use App\Models\Customer;
use App\Models\Debt;
use App\Models\User;

/**
 * Version 1 authentication model (RBAC Architecture Amendment, Product
 * Owner Decision, 2026-07-30): the Debt Register is a Business Owner
 * capability (role `admin`) — the only tenant-side account type.
 *
 * Backend Completion Roadmap, Phase 4.1 — Customer Limit Enforcement:
 * a read-only Customer's related Debts must also become read-only
 * (approved Protected Records rule), so every write ability here except
 * `create` checks `$debt->customer->is_read_only`. `create` has no Debt
 * instance yet, so the controller passes the target Customer explicitly
 * (`$this->authorize('create', [Debt::class, $customer])`) for this
 * policy to check instead. `view`/`viewAny` are untouched — read
 * operations must keep working.
 */
class DebtPolicy
{
    public function viewAny(User $user): bool
    {
        return $this->isAuthorized($user);
    }

    public function view(User $user, Debt $debt): bool
    {
        return $this->isAuthorized($user);
    }

    public function create(User $user, ?Customer $customer = null): bool
    {
        return $this->isAuthorized($user) && ($customer === null || ! $customer->is_read_only);
    }

    public function update(User $user, Debt $debt): bool
    {
        return $this->isAuthorized($user) && ! $debt->customer->is_read_only;
    }

    public function archive(User $user, Debt $debt): bool
    {
        return $this->isAuthorized($user) && ! $debt->customer->is_read_only;
    }

    public function restore(User $user, Debt $debt): bool
    {
        return $this->isAuthorized($user) && ! $debt->customer->is_read_only;
    }

    public function manageRecovery(User $user, Debt $debt): bool
    {
        return $this->isAuthorized($user) && ! $debt->customer->is_read_only;
    }

    public function recordPayment(User $user, Debt $debt): bool
    {
        return $this->isAuthorized($user) && ! $debt->customer->is_read_only;
    }

    public function escalate(User $user, Debt $debt): bool
    {
        return $this->isAuthorized($user) && ! $debt->customer->is_read_only;
    }

    public function generateDocuments(User $user, Debt $debt): bool
    {
        return $this->isAuthorized($user) && ! $debt->customer->is_read_only;
    }

    private function isAuthorized(User $user): bool
    {
        return $user->hasRole('admin');
    }
}
