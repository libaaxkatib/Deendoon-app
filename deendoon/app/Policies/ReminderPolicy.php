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
 *
 * Backend Completion Roadmap, Phase 4.1 — Customer Limit Enforcement:
 * `update`/`delete`/`complete`/`send` additionally block when the
 * Reminder's related Customer ({@see Reminder::relatedCustomer()}) is
 * read-only. `create` is deliberately NOT gated here — at creation time
 * there is no Reminder instance yet to resolve a related Customer from;
 * ReminderService::create() checks the same condition on the
 * not-yet-saved instance instead (`implement enforcement inside the
 * proper Service layer`, per this phase's own instruction), throwing
 * AuthorizationException directly rather than forcing this policy's
 * `create(User $user)` signature to accept ad hoc extra parameters the
 * way DebtPolicy::create() does. `view`/`viewAny` are untouched.
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
        return $this->isAuthorized($user) && ! $reminder->relatedCustomer()?->is_read_only;
    }

    public function delete(User $user, Reminder $reminder): bool
    {
        return $this->update($user, $reminder);
    }

    public function complete(User $user, Reminder $reminder): bool
    {
        return $this->isAuthorized($user) && ! $reminder->relatedCustomer()?->is_read_only;
    }

    public function send(User $user, Reminder $reminder): bool
    {
        return $this->isAuthorized($user) && ! $reminder->relatedCustomer()?->is_read_only;
    }

    private function isAuthorized(User $user): bool
    {
        return $user->hasRole('admin');
    }
}
