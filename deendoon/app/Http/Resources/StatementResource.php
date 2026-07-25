<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class StatementResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'document_type' => 'statement',
            'customer_id' => $this->customer_id,
            'debt_id' => $this->debt_id,
            'reference_number' => $this->reference_number,
            'generated_at' => $this->generated_at,
        ];
    }
}
