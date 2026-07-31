<?php

namespace App\Policies;

use App\Models\Invoice;
use App\Models\User;

/**
 * Version 1 authentication model (RBAC Architecture Amendment, Product
 * Owner Decision, 2026-07-30): Documents are a Business Owner capability
 * (role `admin`).
 */
class InvoicePolicy
{
    public function viewAny(User $user): bool
    {
        return $this->isAuthorized($user);
    }

    public function view(User $user, Invoice $invoice): bool
    {
        return $this->isAuthorized($user);
    }

    private function isAuthorized(User $user): bool
    {
        return $user->hasRole('admin');
    }
}
