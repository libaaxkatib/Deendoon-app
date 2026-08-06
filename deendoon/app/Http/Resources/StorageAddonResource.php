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
            'storage_package' => $this->storage_package,
            'storage_size' => $this->storage_size,
            'monthly_price' => $this->monthly_price,
            'payment_reference' => $this->payment_reference,
            'status' => $this->status,
            'started_at' => $this->started_at,
            'expires_at' => $this->expires_at,
        ];
    }
}
