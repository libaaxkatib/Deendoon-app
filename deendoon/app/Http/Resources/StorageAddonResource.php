<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class StorageAddonResource extends JsonResource
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
            'storage_package' => $this->storage_package,
            'storage_size' => $this->storage_size,
            'monthly_price' => $this->monthly_price,
            'payment_reference' => $this->payment_reference,
            'status' => $this->status,
            'started_at' => $this->started_at,
            'expires_at' => $this->expires_at,
            'approved_by' => $this->approved_by,
            'approved_at' => $this->approved_at,
            'rejection_reason' => $this->rejection_reason,
            'rejection_reasons' => $this->whenLoaded('reasons', fn () => $this->reasons->pluck('reason_label')->values()),
        ];
    }
}
