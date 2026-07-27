<?php

namespace App\Enums;

/**
 * Mirrors the message_templates.channel and sent_messages.channel CHECK
 * constraints exactly. docs/Mobile_UI_V1_Frozen.md §7.7, §7.8.
 */
enum MessageChannel: string
{
    case WhatsApp = 'whatsapp';
    case Sms = 'sms';
}
