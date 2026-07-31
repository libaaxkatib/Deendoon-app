<?php

namespace App\Policies;

use App\Models\Debt;
use App\Models\User;

/**
 * Version 1 authentication model (RBAC Architecture Amendment, Product
 * Owner Decision, 2026-07-30): the Debt Register is a Business Owner
 * capability (role `admin`) — the only tenant-side account type.
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

    public function create(User $user): bool
    {
        return $this->isAuthorized($user);
    }

    public function update(User $user, Debt $debt): bool
    {
        return $this->isAuthorized($user);
    }

    public function archive(User $user, Debt $debt): bool
    {
        return $this->isAuthorized($user);
    }

    public function restore(User $user, Debt $debt): bool
    {
        return $this->isAuthorized($user);
    }

    public function manageRecovery(User $user, Debt $debt): bool
    {
        return $this->isAuthorized($user);
    }

    public function recordPayment(User $user, Debt $debt): bool
    {
        return $this->isAuthorized($user);
    }

    public function escalate(User $user, Debt $debt): bool
    {
        return $this->isAuthorized($user);
    }

    public function generateDocuments(User $user, Debt $debt): bool
    {
        return $this->isAuthorized($user);
    }

    private function isAuthorized(User $user): bool
    {
        return $user->hasRole('admin');
    }
}
