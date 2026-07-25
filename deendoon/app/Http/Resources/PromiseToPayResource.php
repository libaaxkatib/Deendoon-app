<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PromiseToPayResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'debt_id' => $this->debt_id,
            'promised_date' => $this->promised_date?->toDateString(),
            'status' => $this->status,
            'created_by_user_id' => $this->created_by_user_id,
            'created_at' => $this->created_at,
            'resolved_at' => $this->resolved_at,
        ];
    }
}
