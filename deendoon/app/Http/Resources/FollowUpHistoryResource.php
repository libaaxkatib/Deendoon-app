<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class FollowUpHistoryResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'debt_id' => $this->debt_id,
            'action_type' => $this->action_type,
            'details' => $this->details,
            'actor_user_id' => $this->actor_user_id,
            'occurred_at' => $this->occurred_at,
        ];
    }
}
