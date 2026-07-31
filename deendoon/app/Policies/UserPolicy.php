<?php

namespace App\Policies;

use App\Models\User;

/**
 * @deprecated Version 1 authentication model (RBAC Architecture
 * Amendment, Product Owner Decision, 2026-07-30): gates
 * AdminUserController, itself deprecated for the same reason — no second
 * tenant user exists to view/create/update/deactivate/re-role under the
 * one-account-per-tenant model. Left in place pending confirmation of no
 * residual dependency.
 *
 * FR-066 Precondition: "Requesting user holds Administration permission
 * (typically Super Admin)." Administration is scoped to the Business
 * Owner role (`admin`) only.
 */
class UserPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->hasRole('admin');
    }

    public function view(User $user, User $target): bool
    {
        return $user->hasRole('admin') && $user->tenant_id === $target->tenant_id;
    }

    public function create(User $user): bool
    {
        return $user->hasRole('admin');
    }

    public function update(User $user, User $target): bool
    {
        return $user->hasRole('admin') && $user->tenant_id === $target->tenant_id;
    }

    public function deactivate(User $user, User $target): bool
    {
        return $user->hasRole('admin') && $user->tenant_id === $target->tenant_id;
    }

    public function assignRole(User $user, User $target): bool
    {
        return $user->hasRole('admin') && $user->tenant_id === $target->tenant_id;
    }
}
