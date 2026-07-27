<?php

namespace App\Policies;

use App\Models\Reminder;
use App\Models\User;

/**
 * docs/Backend_v2.1_UI_Mapping.md §10: Reminder Center is granted to
 * Business Owner/Administrator, Sales & Finance Staff, AND Collections
 * Staff — three roles, unlike Customers/Debts/Cases' interim two-role
 * mapping (admin/sales_finance only). Mapped to this project's existing
 * seeded roles exactly as established in Sprint 1: admin, sales_finance,
 * collection_officer.
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
     * docs/Mobile_UI_V1_Frozen.md §7.4: "editing and deletion are
     * restricted to the reminder's creator or a manager-level role."
     * Manager-level is read as admin/sales_finance (this project's only
     * roles above Collections Staff), so a Collections Staff user may
     * update/delete only their own reminders.
     */
    public function update(User $user, Reminder $reminder): bool
    {
        return $user->hasAnyRole(['admin', 'sales_finance'])
            || (string) $user->id === $reminder->created_by_user_id;
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
        return $user->hasAnyRole(['admin', 'sales_finance', 'collection_officer']);
    }
}
