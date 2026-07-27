<?php

namespace App\Enums;

/**
 * Mirrors the reminders.timing_rule CHECK constraint exactly.
 * docs/Mobile_UI_V1_Frozen.md §7.5 — the four timing options.
 */
enum ReminderTimingRule: string
{
    case OneDayBefore = 'one_day_before';
    case SameDay = 'same_day';
    case OneHourBefore = 'one_hour_before';
    case Custom = 'custom';
}
