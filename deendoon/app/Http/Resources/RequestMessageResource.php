<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class RequestMessageResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'professional_collection_request_id' => $this->professional_collection_request_id,
            'sender_user_id' => $this->sender_user_id,
            'content' => $this->content,
            'created_at' => $this->created_at,
        ];
    }
}
