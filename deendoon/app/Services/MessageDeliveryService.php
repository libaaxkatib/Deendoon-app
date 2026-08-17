<?php

namespace App\Services;

use App\Enums\DocumentType;
use App\Enums\MessageChannel;
use App\Models\CustomerPhoneNumber;
use App\Models\DemandLetter;
use App\Models\Invoice;
use App\Models\MessageTemplate;
use App\Models\Receipt;
use App\Models\Reminder;
use App\Models\SentMessage;
use App\Models\Statement;
use App\Models\User;
use App\Services\Delivery\InternalSmsChannel;
use App\Services\Delivery\InternalWhatsAppChannel;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Support\Facades\DB;

/**
 * docs/Mobile_UI_V1_Frozen.md §7.7, §7.8, §8.8 — renders a template
 * against a Reminder or a generated Document and dispatches it via the
 * requested channel, recording a Sent Message.
 */
class MessageDeliveryService
{
    public function __construct(
        private readonly MessageRenderingService $rendering,
        private readonly InternalWhatsAppChannel $whatsApp,
        private readonly InternalSmsChannel $sms,
    ) {}

    /**
     * Fix #23 Decision 7/8/10: `$phoneNumber` is an already
     * ownership-verified selection (the caller resolved and authorized
     * it — see `ReminderCenterController::send()`/`MessageController`);
     * when omitted, the customer's primary phone (`recipient_phone`,
     * mirrored from `customers.phone`) is used. There is no automatic
     * fallback if the chosen number fails — a distinct, deliberate
     * decision, not an oversight.
     */
    public function sendReminder(Reminder $reminder, MessageTemplate $template, MessageChannel $channel, User $actor, ?CustomerPhoneNumber $phoneNumber = null): SentMessage
    {
        $rendered = $this->rendering->renderForReminder($template, $reminder, $phoneNumber);
        $recipientPhone = $rendered['recipient_phone'];

        if (empty($recipientPhone)) {
            throw new HttpResponseException(response()->json([
                'success' => false,
                'message' => 'This customer has no phone number on file to send a message to.',
                'data' => null,
                'errors' => ['recipient_phone' => ['No recipient phone number is available.']],
            ], 422));
        }

        return DB::transaction(function () use ($reminder, $template, $channel, $actor, $rendered, $recipientPhone) {
            $status = match ($channel) {
                MessageChannel::WhatsApp => $this->whatsApp->deliver($recipientPhone, $rendered['rendered_text']),
                MessageChannel::Sms => $this->sms->deliver($recipientPhone, $rendered['rendered_text']),
            };

            $sentMessage = new SentMessage([
                'template_id' => $template->id,
                'reminder_id' => $reminder->id,
                'channel' => $channel->value,
                'recipient_phone' => $recipientPhone,
                'rendered_text' => $rendered['rendered_text'],
                'status' => $status,
                'sent_by_user_id' => (string) $actor->id,
            ]);
            $sentMessage->save();

            return $sentMessage;
        });
    }

    /**
     * docs/Mobile_UI_V1_Frozen.md §8.8 (Document Share).
     */
    public function sendDocument(Receipt|DemandLetter|Statement|Invoice $document, DocumentType $type, MessageTemplate $template, MessageChannel $channel, User $actor): SentMessage
    {
        $rendered = $this->rendering->renderForDocument($template, $document);

        if (empty($rendered['recipient_phone'])) {
            throw new HttpResponseException(response()->json([
                'success' => false,
                'message' => 'This customer has no phone number on file to share this document with.',
                'data' => null,
                'errors' => ['recipient_phone' => ['No recipient phone number is available.']],
            ], 422));
        }

        return DB::transaction(function () use ($document, $type, $template, $channel, $actor, $rendered) {
            $status = match ($channel) {
                MessageChannel::WhatsApp => $this->whatsApp->deliver($rendered['recipient_phone'], $rendered['rendered_text']),
                MessageChannel::Sms => $this->sms->deliver($rendered['recipient_phone'], $rendered['rendered_text']),
            };

            $sentMessage = new SentMessage([
                'template_id' => $template->id,
                'document_type' => $type->value,
                'document_id' => $document->id,
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
