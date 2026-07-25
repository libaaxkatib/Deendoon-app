<?php

namespace App\Policies;

use App\Models\Customer;
use App\Models\User;

/**
 * Judgment call under the current interim 3-role RBAC (Product Owner
 * Decision 4): Customer Management is granted to admin and sales_finance.
 * The customer role has no defined meaning as a backend actor anywhere in
 * the approved SRS (customers are tracked data, never an authenticated
 * actor in the approved 7-role model), so it is granted none of these
 * abilities. This mapping is not itself specified by any approved
 * document — flagged in the sprint report, not silently assumed.
 */
class CustomerPolicy
{
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
        return $this->isAuthorized($user);
    }

    public function update(User $user, Customer $customer): bool
    {
        return $this->isAuthorized($user);
    }

    public function archive(User $user, Customer $customer): bool
    {
        return $this->isAuthorized($user);
    }

    public function restore(User $user, Customer $customer): bool
    {
        return $this->isAuthorized($user);
    }

    public function import(User $user): bool
    {
        return $this->isAuthorized($user);
    }

    private function isAuthorized(User $user): bool
    {
        return $user->hasAnyRole(['admin', 'sales_finance']);
    }
}
