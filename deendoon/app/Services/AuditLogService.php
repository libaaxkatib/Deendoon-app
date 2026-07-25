<?php

namespace App\Services;

use App\Enums\AuditAction;
use App\Models\AuditLog;
use App\Models\User;

class AuditLogService
{
    public function record(
        AuditAction $action,
        string $entityType,
        string $entityId,
        ?User $actor = null,
        ?string $reason = null,
    ): AuditLog {
        return AuditLog::create([
            'tenant_id' => $actor?->tenant_id,
            'user_id' => $actor?->id,
            'action' => $action->value,
            'entity_type' => $entityType,
            'entity_id' => $entityId,
            'reason' => $reason,
            'occurred_at' => now(),
        ]);
    }
}
