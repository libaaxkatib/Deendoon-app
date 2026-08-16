<?php

namespace App\Services;

use App\Models\SecurityEvent;
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
 *
 * Module 8 — System Management: each method now ALSO writes a
 * {@see SecurityEvent} row, in addition to (never instead of) the file
 * channel above — the Admin Panel needs something queryable to list/
 * filter; the file channel remains the operational/ops source of truth
 * unchanged. Exactly the same 4 event shapes already emitted here, no new
 * event type invented.
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

        SecurityEvent::create([
            'event_type' => 'login_failed',
            'email' => $email,
            'ip_address' => $ip,
            'occurred_at' => now(),
        ]);
    }

    public function passwordResetRequested(string $email, bool $accountExists): void
    {
        Log::channel('security')->info('Password reset requested', [
            'event' => 'password_reset_requested',
            'email' => $email,
            'account_exists' => $accountExists,
        ]);

        SecurityEvent::create([
            'event_type' => 'password_reset_requested',
            'email' => $email,
            'account_exists' => $accountExists,
            'occurred_at' => now(),
        ]);
    }

    public function tokenRevokedForIdle(string $tokenId, ?string $userId): void
    {
        Log::channel('security')->info('Token revoked for inactivity', [
            'event' => 'token_revoked_idle',
            'token_id' => $tokenId,
            'user_id' => $userId,
        ]);

        SecurityEvent::create([
            'event_type' => 'token_revoked_idle',
            'token_id' => $tokenId,
            'user_id' => $userId,
            'occurred_at' => now(),
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

        SecurityEvent::create([
            'event_type' => 'permission_denied',
            'user_id' => $user?->id !== null ? (string) $user->id : null,
            'tenant_id' => $user?->tenant_id,
            'method' => $method,
            'path' => $path,
            'occurred_at' => now(),
        ]);
    }
}
