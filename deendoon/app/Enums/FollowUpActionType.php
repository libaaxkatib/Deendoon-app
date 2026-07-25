<?php

namespace App\Enums;

/**
 * Mirrors the follow_up_history.action_type CHECK constraint
 * (06_Database_Design.md §6.3) exactly. Only a subset is written by
 * modules implemented so far; the rest exist because the database
 * constraint already allows them for modules not yet built.
 */
enum FollowUpActionType: string
{
    case ReminderSent = 'reminder_sent';
    case ManualWhatsapp = 'manual_whatsapp';
    case ManualSms = 'manual_sms';
    case CallLogged = 'call_logged';
    case PromiseRecorded = 'promise_recorded';
    case PromiseFulfilled = 'promise_fulfilled';
    case PromiseBroken = 'promise_broken';
    case PaymentRecorded = 'payment_recorded';
    case CollectionActivity = 'collection_activity';
    case Escalated = 'escalated';
}
