<?php

namespace App\Services;

use App\Models\User;
use Illuminate\Support\Facades\Log;

/**
 * Sprint 1.2 — Security Hardening. Writes to the dedicated 'security' log
 * channel (config/logging.php), never to `audit_log` — every event here
 * lacks an approved `audit_log.action` slot (06 §6.9's CHECK constraint),
 * unlike login success, logout, and password-reset-completed, which
 * already have one and continue to use AuditLogService as before. Adding
 * a new CHECK constraint value would be a database schema change, out of
 * this sprint's scope — this achieves the same security-visibility goal
 * without touching the schema.
 *
 * Never logs a password, token, or other credential value — only
 * identifiers (email, user id, IP, route) needed to investigate an
 * incident, consistent with 08_Security_and_RBAC.md §12's "credential
 * storage... never logged in plaintext."
 */
class SecurityEventLogger
{
    public function loginFailed(string $email, string $ip): void
    {
        Log::channel('security')->warning('Login failed', [
            'event' => 'login_failed',
            'email' => $email,
            'ip' => $ip,
        ]);
    }

    public function passwordResetRequested(string $email, bool $accountExists): void
    {
        Log::channel('security')->info('Password reset requested', [
            'event' => 'password_reset_requested',
            'email' => $email,
            'account_exists' => $accountExists,
        ]);
    }

    public function tokenRevokedForIdle(string $tokenId, ?string $userId): void
    {
        Log::channel('security')->info('Token revoked for inactivity', [
            'event' => 'token_revoked_idle',
            'token_id' => $tokenId,
            'user_id' => $userId,
        ]);
    }

    public function permissionDenied(?User $user, string $method, string $path): void
    {
        Log::channel('security')->warning('Permission denied', [
            'event' => 'permission_denied',
            'user_id' => $user?->id,
            'tenant_id' => $user?->tenant_id,
            'method' => $method,
            'path' => $path,
        ]);
    }
}
