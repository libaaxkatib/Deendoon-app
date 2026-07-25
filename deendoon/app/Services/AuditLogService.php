<?php

namespace App\Services;

use App\Enums\AuditAction;
use App\Models\AuditLog;
use App\Models\User;

class AuditLogService
{
    /**
     * $tenantId overrides the actor-derived tenant — needed only for the
     * Deendoon Platform Administrator (tenant_id NULL) acting on a specific
     * tenant's Professional Collection Request (Module 7): without it, the
     * audit entry would be attributed to no tenant at all, and the
     * submitting business would lose visibility into their own Request's
     * history. Every other call site omits it and keeps existing behavior.
     */
    public function record(
        AuditAction $action,
        string $entityType,
        string $entityId,
        ?User $actor = null,
        ?string $reason = null,
        ?string $tenantId = null,
    ): AuditLog {
        return AuditLog::create([
            'tenant_id' => $tenantId ?? $actor?->tenant_id,
            'user_id' => $actor?->id,
            'action' => $action->value,
            'entity_type' => $entityType,
            'entity_id' => $entityId,
            'reason' => $reason,
            'occurred_at' => now(),
        ]);
    }
}
