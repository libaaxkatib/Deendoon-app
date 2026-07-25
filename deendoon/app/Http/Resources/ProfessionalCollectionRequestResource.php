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
            'created_at' => $this->created_at,
            'closed_at' => $this->closed_at,
        ];
    }
}
