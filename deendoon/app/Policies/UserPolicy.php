<?php

namespace App\Policies;

use App\Models\User;

/**
 * FR-066 Precondition: "Requesting user holds Administration permission
 * (typically Super Admin)." 08_Security_and_RBAC.md §5 explicitly scopes
 * Administration to the Super Admin role (interim model: `admin`) — unlike
 * every other module's generic "authorized user" (admin + sales_finance),
 * 08 line 84 explicitly excludes Operations Manager from Administration's
 * default scope, so this is admin-only, not the usual admin/sales_finance
 * pair.
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
