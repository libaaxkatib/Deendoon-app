<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ProfessionalCollectionRequestResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'collection_case_id' => $this->collection_case_id,
            'reference_number' => $this->reference_number,
            'status' => $this->status,
            'submitted_by_user_id' => $this->submitted_by_user_id,
            'actioned_by_user_id' => $this->actioned_by_user_id,
            'reasons' => $this->whenLoaded('reasons', fn () => $this->reasons->pluck('reason_label')->values()),
            'notes' => $this->transfer_notes,
            'requested_services' => $this->whenLoaded('requestedServices', fn () => $this->requestedServices->pluck('service_label')->values()),
            'declaration_accepted_at' => $this->declaration_accepted_at,
            'declaration_accepted_by' => $this->declaration_accepted_by_user_id,
            'created_at' => $this->created_at,
            'closed_at' => $this->closed_at,
        ];
    }
}
