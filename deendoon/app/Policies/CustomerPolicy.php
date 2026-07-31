<?php

namespace App\Policies;

use App\Models\Customer;
use App\Models\User;

/**
 * Version 1 authentication model (RBAC Architecture Amendment, Product
 * Owner Decision, 2026-07-30): exactly two account types exist —
 * Business Owner (Customer Mobile App, role `admin`) and Platform
 * Administrator. Customer Management is a Business Owner capability.
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

    public function viewCreditScore(User $user, Customer $customer): bool
    {
        return $this->isAuthorized($user);
    }

    public function generateDocuments(User $user, Customer $customer): bool
    {
        return $this->isAuthorized($user);
    }

    private function isAuthorized(User $user): bool
    {
        return $user->hasRole('admin');
    }
}
