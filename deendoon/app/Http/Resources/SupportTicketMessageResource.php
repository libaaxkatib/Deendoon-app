<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class SupportTicketMessageResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'support_ticket_id' => $this->support_ticket_id,
            'sender_user_id' => $this->sender_user_id,
            'sender_name' => $this->whenLoaded('sender', fn () => $this->sender?->name),
            'content' => $this->content,
            'created_at' => $this->created_at,
        ];
    }
}
