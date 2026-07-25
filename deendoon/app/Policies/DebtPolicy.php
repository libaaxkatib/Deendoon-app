<?php

namespace App\Policies;

use App\Models\Debt;
use App\Models\User;

/**
 * Same judgment call as CustomerPolicy, under the current interim 3-role
 * RBAC (Product Owner Decision 4): admin and sales_finance are authorized;
 * customer has no defined meaning as a backend actor anywhere in the
 * approved SRS. Not itself specified by any approved document.
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
        return $user->hasAnyRole(['admin', 'sales_finance']);
    }
}
