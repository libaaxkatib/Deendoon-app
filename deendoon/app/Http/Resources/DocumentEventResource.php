<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class DocumentEventResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'document_type' => $this->document_type,
            'document_id' => $this->document_id,
            'event_type' => $this->event_type,
            'user_id' => $this->user_id,
            'occurred_at' => $this->occurred_at,
        ];
    }
}
