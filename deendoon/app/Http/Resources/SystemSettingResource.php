<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class SystemSettingResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'default_credit_limit' => $this->default_credit_limit,
            'credit_limit_reminder_enabled' => $this->credit_limit_reminder_enabled,
            'soft_limit_warning_threshold' => $this->soft_limit_warning_threshold,
            'whatsapp_reminder_days' => $this->whatsapp_reminder_days,
            'sms_reminder_days' => $this->sms_reminder_days,
            'call_reminder_days' => $this->call_reminder_days,
            'professional_collection_threshold_days' => $this->professional_collection_threshold_days,
            'notification_settings' => $this->notification_settings,
            'updated_at' => $this->updated_at,
        ];
    }
}
