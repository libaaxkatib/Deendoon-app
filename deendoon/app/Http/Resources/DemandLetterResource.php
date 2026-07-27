<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class DemandLetterResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'document_type' => 'demand_letter',
            'debt_id' => $this->debt_id,
            'template_type' => $this->template_type,
            'reference_number' => $this->reference_number,
            'generated_at' => $this->generated_at,
            'file_size' => $this->file_size,
        ];
    }
}
