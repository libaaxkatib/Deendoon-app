<?php

namespace App\Services;

use App\Enums\ReminderTimingRule;
use App\Models\Reminder;
use Illuminate\Support\Carbon;

/**
 * docs/Backend_v2.1_UI_Mapping.md §5 "Smart Reminder Engine" — the backend
 * subsystem behind docs/Mobile_UI_V1_Frozen.md §7.1, §7.3, §7.5, and §7.9's
 * status and timing requirements. Not a UI screen; no endpoint exposes it
 * directly (consumed by ReminderService and the reminder-fire Artisan
 * command instead).
 */
class SmartReminderEngine
{
    /**
     * §7.3: "Today, Upcoming, Overdue, or Completed... transitioning to
     * Completed only through an explicit user action, not automatically
     * upon its due date passing." Today/Upcoming/Overdue are, by
     * definition, a direct function of the due date and are computed here
     * on every read rather than persisted, so they can never drift from
     * the due date they describe.
     */
    public function status(Reminder $reminder): string
    {
        if ($reminder->completed_at !== null) {
            return 'completed';
        }

        $now = Carbon::now();
        $dueDate = $reminder->due_date;

        if ($dueDate->isPast() && ! $dueDate->isToday()) {
            return 'overdue';
        }

        if ($dueDate->isToday()) {
            return $dueDate->lt($now) ? 'overdue' : 'today';
        }

        return 'upcoming';
    }

    public function isOverdue(Reminder $reminder): bool
    {
        return $this->status($reminder) === 'overdue';
    }

    /**
     * §7.5: the moment a reminder's selected timing rule requires its
     * delivery to fire, relative to its own due date.
     */
    public function fireAt(Reminder $reminder): Carbon
    {
        return match ($reminder->timing_rule) {
            ReminderTimingRule::OneDayBefore->value => $reminder->due_date->copy()->subDay(),
            ReminderTimingRule::SameDay->value => $reminder->due_date->copy()->startOfDay(),
            ReminderTimingRule::OneHourBefore->value => $reminder->due_date->copy()->subHour(),
            ReminderTimingRule::Custom->value => $reminder->custom_fire_at ?? $reminder->due_date,
            default => $reminder->due_date,
        };
    }

    /**
     * Used by the reminder-fire command: a reminder is due for delivery
     * once its fire time has arrived, it isn't already Completed, and it
     * hasn't already been dispatched (no Sent Message recorded against it
     * yet) — delivery fires once per reminder, not on every scheduler run.
     */
    public function isDueForDelivery(Reminder $reminder): bool
    {
        if ($reminder->completed_at !== null) {
            return false;
        }

        if ($reminder->sentMessages()->exists()) {
            return false;
        }

        return $this->fireAt($reminder)->lte(Carbon::now());
    }
}
