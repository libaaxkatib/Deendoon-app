<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class SubscriptionChangeRequestResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'requested_plan' => new SubscriptionPlanResource($this->whenLoaded('requestedPlan')),
            'current_plan' => new SubscriptionPlanResource($this->whenLoaded('currentPlan')),
            'payment_reference' => $this->payment_reference,
            'status' => $this->status,
            'requested_at' => $this->requested_at,
            'reviewed_at' => $this->reviewed_at,
            'rejection_reason' => $this->rejection_reason,
        ];
    }
}
