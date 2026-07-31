<?php

namespace App\Policies;

use App\Models\Reminder;
use App\Models\User;

/**
 * Version 1 authentication model (RBAC Architecture Amendment, Product
 * Owner Decision, 2026-07-30): the Reminder Center is a Business Owner
 * capability (role `admin`) — the only tenant-side account type. The
 * distinct Sales & Finance Staff / Collections Staff roles this policy
 * previously mapped to no longer exist as authentication roles.
 */
class ReminderPolicy
{
    public function viewAny(User $user): bool
    {
        return $this->isAuthorized($user);
    }

    public function view(User $user, Reminder $reminder): bool
    {
        return $this->isAuthorized($user);
    }

    public function create(User $user): bool
    {
        return $this->isAuthorized($user);
    }

    /**
     * Under Version 1's one-account-per-tenant model, the tenant's single
     * Business Owner account is always both the only possible actor and
     * the only possible creator of any Reminder in that tenant, so the
     * former creator-or-manager distinction has no remaining case where it
     * would differ from a plain role check.
     */
    public function update(User $user, Reminder $reminder): bool
    {
        return $this->isAuthorized($user);
    }

    public function delete(User $user, Reminder $reminder): bool
    {
        return $this->update($user, $reminder);
    }

    public function complete(User $user, Reminder $reminder): bool
    {
        return $this->isAuthorized($user);
    }

    public function send(User $user, Reminder $reminder): bool
    {
        return $this->isAuthorized($user);
    }

    private function isAuthorized(User $user): bool
    {
        return $user->hasRole('admin');
    }
}
