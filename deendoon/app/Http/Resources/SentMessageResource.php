<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class SentMessageResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'reminder_id' => $this->reminder_id,
            'case_id' => $this->case_id,
            'document_type' => $this->document_type,
            'document_id' => $this->document_id,
            'channel' => $this->channel->value,
            'recipient_phone' => $this->recipient_phone,
            'rendered_text' => $this->rendered_text,
            'status' => $this->status,
            'sent_at' => $this->sent_at,
        ];
    }
}
