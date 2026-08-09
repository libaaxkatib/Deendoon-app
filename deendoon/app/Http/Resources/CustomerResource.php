<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class CustomerResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'phone' => $this->phone,
            'address' => $this->address,
            'customer_status' => $this->customer_status,
            'credit_limit' => $this->credit_limit,
            'outstanding_balance' => $this->outstanding_balance,
            'remaining_credit' => $this->remaining_credit,
            'risk_level' => $this->risk_level,
            'credit_score' => $this->credit_score,
            'credit_score_band' => $this->credit_score_band,
            'is_read_only' => $this->is_read_only,
            'archived_at' => $this->archived_at,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
