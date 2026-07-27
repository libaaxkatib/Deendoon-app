<?php

namespace App\Services;

use App\Enums\MessageChannel;
use App\Models\MessageTemplate;
use App\Models\Reminder;
use App\Models\SentMessage;
use App\Models\User;
use App\Services\Delivery\InternalSmsChannel;
use App\Services\Delivery\InternalWhatsAppChannel;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Support\Facades\DB;

/**
 * docs/Mobile_UI_V1_Frozen.md §7.7, §7.8 — renders a template against a
 * Reminder and dispatches it via the requested channel, recording a Sent
 * Message. Scoped to Reminder-sourced sends for this sprint; Document
 * Share (§8.8) reuses this same service once the Documents module sprint
 * builds that flow — not added here to avoid reaching into an unrelated
 * module ahead of its own sprint.
 */
class MessageDeliveryService
{
    public function __construct(
        private readonly MessageRenderingService $rendering,
        private readonly InternalWhatsAppChannel $whatsApp,
        private readonly InternalSmsChannel $sms,
    ) {}

    public function sendReminder(Reminder $reminder, MessageTemplate $template, MessageChannel $channel, User $actor): SentMessage
    {
        $rendered = $this->rendering->renderForReminder($template, $reminder);

        if (empty($rendered['recipient_phone'])) {
            throw new HttpResponseException(response()->json([
                'success' => false,
                'message' => 'This customer has no phone number on file to send a message to.',
                'data' => null,
                'errors' => ['recipient_phone' => ['No recipient phone number is available.']],
            ], 422));
        }

        return DB::transaction(function () use ($reminder, $template, $channel, $actor, $rendered) {
            $status = match ($channel) {
                MessageChannel::WhatsApp => $this->whatsApp->deliver($rendered['recipient_phone'], $rendered['rendered_text']),
                MessageChannel::Sms => $this->sms->deliver($rendered['recipient_phone'], $rendered['rendered_text']),
            };

            $sentMessage = new SentMessage([
                'template_id' => $template->id,
                'reminder_id' => $reminder->id,
                'channel' => $channel->value,
                'recipient_phone' => $rendered['recipient_phone'],
                'rendered_text' => $rendered['rendered_text'],
                'status' => $status,
                'sent_by_user_id' => (string) $actor->id,
            ]);
            $sentMessage->save();

            return $sentMessage;
        });
    }
}
