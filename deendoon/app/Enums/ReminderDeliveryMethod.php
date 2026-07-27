<?php

namespace App\Enums;

/**
 * Not a database CHECK constraint — reminders.delivery_methods stores a
 * JSON array of these values (a reminder may select more than one, per
 * docs/Mobile_UI_V1_Frozen.md §7.5's "four independently selectable
 * options"), so this enum governs validation only, not a single-column
 * constraint.
 */
enum ReminderDeliveryMethod: string
{
    case InApp = 'in_app';
    case Push = 'push';
    case WhatsApp = 'whatsapp';
    case Sms = 'sms';
}
