<?php

namespace App\Http\Resources;

use App\Services\SmartReminderEngine;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * docs/Mobile_UI_V1_Frozen.md §7.4; docs/Backend_v2.1_REST_API_Specification.md
 * §6 — `status` is computed via the Smart Reminder Engine on every read,
 * never a stored column (see the reminders migration's docblock).
 */
class ReminderResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $engine = app(SmartReminderEngine::class);

        return [
            'id' => $this->id,
            'type' => $this->type->value,
            'title' => $this->type->label(),
            'related_entity_type' => $this->related_entity_type,
            'related_entity_id' => $this->related_entity_id,
            'related_case_id' => $this->related_case_id,
            'due_date' => $this->due_date,
            'amount_due' => $this->amount_due,
            'timing_rule' => $this->timing_rule,
            'custom_fire_at' => $this->custom_fire_at,
            'delivery_methods' => $this->delivery_methods,
            'notes' => $this->notes,
            'status' => $engine->status($this->resource),
            'created_by_user_id' => $this->created_by_user_id,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
            'completed_at' => $this->completed_at,
            'checked_in_at' => $this->checked_in_at,
        ];
    }
}
