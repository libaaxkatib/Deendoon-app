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
            'tenant_id' => $this->tenant_id,
            'tenant_name' => $this->whenLoaded('tenant', fn () => $this->tenant->business_name),
            'requested_plan' => new SubscriptionPlanResource($this->whenLoaded('requestedPlan')),
            'current_plan' => new SubscriptionPlanResource($this->whenLoaded('currentPlan')),
            'payment_reference' => $this->payment_reference,
            'payment_phone' => $this->payment_phone,
            'status' => $this->status,
            'requested_at' => $this->requested_at,
            'reviewed_by' => $this->reviewed_by,
            'reviewed_at' => $this->reviewed_at,
            'rejection_reason' => $this->rejection_reason,
            'rejection_reasons' => $this->whenLoaded('reasons', fn () => $this->reasons->pluck('reason_label')->values()),
        ];
    }
}
