<?php

namespace App\Services;

use App\Enums\NotificationType;
use App\Models\Notification;
use App\Models\SystemSetting;
use App\Models\User;
use Illuminate\Support\Collection;

/**
 * FR-058/BRL-064 — the single, sole write path for Notifications. Every
 * call site is a direct, synchronous consequence of an already-approved
 * event in its owning module (Modules 4/6/7/8, plus Module 5's Promise to
 * Pay Due and manual-reminder flows, plus Module 7's Request updates) —
 * this service never originates a new kind of event on its own.
 *
 * BRL-065 (duplicate/re-trigger suppression) is explicitly unresolved
 * (DD-011) — no general de-duplication is implemented here, matching the
 * precedent already established for `CreditLimitReached`. The one
 * exception (`notifyOnce`) is a narrow, purely mechanical safeguard
 * against a *lazy, repeatedly-polled* check re-creating the same row on
 * every page view for a condition that itself never changes state (see
 * PromiseToPayService::refreshDuePromises) — it does not resolve or
 * pre-empt BRL-065's broader business question.
 */
class NotificationService
{
    /**
     * Built via `new` + explicit property assignment, not `create()` — like
     * every other tenant_id-bearing model in this project, tenant_id is
     * deliberately excluded from Fillable, so passing it through
     * mass-assignment would be silently dropped. That matters here more
     * than at any other call site: BelongsToTenant's creating() hook only
     * back-fills tenant_id from the *currently authenticated* user, which
     * is wrong (or, for the Deendoon Platform Administrator, NULL and
     * therefore a NOT NULL violation) whenever the recipient is someone
     * other than the acting session — exactly the case for every
     * Professional Collection Request notification.
     */
    public function notify(
        string $tenantId,
        string $recipientUserId,
        NotificationType $type,
        string $relatedEntityType,
        string $relatedEntityId,
        ?string $title = null,
        ?string $message = null,
    ): ?Notification {
        if (! $this->isEnabledForTenant($tenantId, $type)) {
            return null;
        }

        $notification = new Notification([
            'recipient_user_id' => $recipientUserId,
            'type' => $type->value,
            'title' => $title,
            'message' => $message,
            'related_entity_type' => $relatedEntityType,
            'related_entity_id' => $relatedEntityId,
        ]);
        $notification->tenant_id = $tenantId;
        $notification->created_at = now();
        $notification->save();

        return $notification;
    }

    /**
     * @param  Collection<int, User>  $recipients
     */
    public function notifyMany(
        string $tenantId,
        Collection $recipients,
        NotificationType $type,
        string $relatedEntityType,
        string $relatedEntityId,
        ?string $title = null,
        ?string $message = null,
    ): void {
        $recipients->each(fn (User $user) => $this->notify($tenantId, (string) $user->id, $type, $relatedEntityType, $relatedEntityId, $title, $message));
    }

    /**
     * Module 9 — a tenant's notification_settings JSON stays null until
     * they explicitly save Settings once (AdminSettingsService only
     * lazily creates a row with unrelated defaults). Failing open on a
     * missing column/key is required, not optional: failing closed would
     * silently stop Reminder/Payment notifications for every tenant that
     * has never touched Settings, a real behavior regression rather than
     * a bugfix. Queried directly rather than via AdminSettingsService to
     * avoid that service's side effect of lazily creating a settings row
     * on every gated notification for a tenant that has none yet.
     */
    private function isEnabledForTenant(string $tenantId, NotificationType $type): bool
    {
        $key = $type->preferenceKey();

        if ($key === null) {
            return true;
        }

        $settings = SystemSetting::withoutGlobalScope('tenant')
            ->where('tenant_id', $tenantId)
            ->value('notification_settings');

        return (bool) ($settings[$key] ?? true);
    }

    /**
     * Guards against the same lazy check re-creating an identical
     * notification on every subsequent request while the underlying
     * condition (e.g., "this Promise's due date is today") has no state
     * transition of its own to naturally stop re-evaluating true.
     */
    public function notifyOnce(
        string $tenantId,
        string $recipientUserId,
        NotificationType $type,
        string $relatedEntityType,
        string $relatedEntityId,
    ): ?Notification {
        $exists = Notification::where('type', $type->value)
            ->where('related_entity_type', $relatedEntityType)
            ->where('related_entity_id', $relatedEntityId)
            ->exists();

        if ($exists) {
            return null;
        }

        return $this->notify($tenantId, $recipientUserId, $type, $relatedEntityType, $relatedEntityId);
    }
}
