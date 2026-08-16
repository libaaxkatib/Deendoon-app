<?php

namespace App\Services;

use App\Enums\AuditAction;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

/**
 * Mobile Play Store Readiness (Fix #3, Part B) — self-service "Close
 * Account" for a Business Owner. Deliberately non-destructive: reuses
 * `User`'s existing SoftDeletes mechanism (archives the user — blocks
 * future login via the model's own default query scope, no new code
 * needed for that) and `Tenant::suspend()` (already used by the Platform
 * Administrator for the same "block access, keep everything" outcome).
 * No tenant-owned record (customers, debts, payments, documents,
 * notifications, subscriptions, support tickets, audit_log) is touched —
 * every foreign key into `tenants`/`users` in this schema has no cascade
 * action, so nothing here could accidentally cascade-delete business
 * data even if it tried to.
 */
class AccountClosureService
{
    public function __construct(private readonly AuditLogService $auditLog) {}

    /**
     * Returns false (no state change made) if the supplied password does
     * not match — the same ownership-proof pattern already used by
     * `PasswordResetService::changePassword()`.
     */
    public function close(User $user, string $password): bool
    {
        if (! Hash::check($password, $user->password)) {
            return false;
        }

        $tenant = $user->tenant;

        $user->tokens()->delete();
        $user->delete();

        $this->auditLog->record(
            AuditAction::Archived,
            'user',
            (string) $user->id,
            $user,
            'Account closed by Business Owner (self-service)',
            $tenant?->id,
        );

        if ($tenant) {
            $tenant->suspend('Closed by Business Owner via self-service account closure');

            $this->auditLog->record(
                AuditAction::StatusChanged,
                'tenant',
                $tenant->id,
                $user,
                'Suspended: Business Owner closed their account (self-service)',
                $tenant->id,
            );
        }

        return true;
    }
}
