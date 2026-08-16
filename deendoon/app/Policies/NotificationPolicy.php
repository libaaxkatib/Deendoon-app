<?php

namespace App\Policies;

use App\Models\Notification;
use App\Models\User;

/**
 * Notifications are personal, not role-based (FR-058 E1's role-visibility
 * check is already enforced by the fact that a Notification is only ever
 * created for a specific recipient) — the only authorization question is
 * whether this Notification belongs to the requesting user.
 */
class NotificationPolicy
{
    public function view(User $user, Notification $notification): bool
    {
        return (string) $notification->recipient_user_id === (string) $user->id;
    }

    public function delete(User $user, Notification $notification): bool
    {
        return (string) $notification->recipient_user_id === (string) $user->id;
    }
}
