<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class DebtResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'customer_id' => $this->customer_id,
            'reference_number' => $this->reference_number,
            'amount' => $this->amount,
            'due_date' => $this->due_date?->toDateString(),
            'debt_status' => $this->debt_status,
            'remaining_balance' => $this->remaining_balance,
            'recovery_stage' => $this->recovery_stage,
            'notes' => $this->notes,
            'archived_at' => $this->archived_at,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
