<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ProfessionalCollectionTimelineEventResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'professional_collection_request_id' => $this->professional_collection_request_id,
            'event_type' => $this->event_type,
            'officer_user_id' => $this->officer_user_id,
            'occurred_at' => $this->occurred_at,
            'notes' => $this->notes,
            'outcome' => $this->outcome,
            'attachments' => ProfessionalCollectionRequestAttachmentResource::collection($this->whenLoaded('attachments')),
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
