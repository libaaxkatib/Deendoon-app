<?php

namespace App\Services;

use App\Enums\AuditAction;
use App\Mail\PasswordResetMail;
use App\Models\PasswordResetToken;
use App\Models\User;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Str;

/**
 * FR-004 — Forgot Password / Password Reset. Reuses the stock, already-
 * migrated `password_reset_tokens` table and AuditLogService exactly as
 * built for every other module.
 *
 * Security properties, per 08_Security_and_RBAC.md §10:
 * - The plaintext token is a cryptographically random 64-character string
 *   (`Str::random()`, CSPRNG-backed) — only its hash is ever persisted.
 * - Expiry is env-configurable (`PASSWORD_RESET_TOKEN_EXPIRY_MINUTES`,
 *   default 60 — within 08's recommended 15–60 minute window), never
 *   hardcoded.
 * - Single-use: the token row is deleted immediately on a successful
 *   reset (`reset()`), so it cannot be replayed.
 * - Superseded on re-issue: `email` is `password_reset_tokens`' own
 *   primary key, so `requestReset()`'s `updateOrCreate` structurally
 *   replaces any prior token for that email — not merely a convention.
 * - User enumeration: `requestReset()` performs no user-existence check
 *   the caller can observe — it always returns void, with the identical
 *   generic response built by the controller regardless of outcome.
 * - Password change revokes all sessions (08 §9: "Revoke all tokens:
 *   triggered automatically by password change") — `$user->tokens()->
 *   delete()` on a successful reset, the same rule already applied
 *   elsewhere for admin-driven password changes.
 */
class PasswordResetService
{
    private const DEFAULT_EXPIRY_MINUTES = 60;

    public function __construct(private readonly AuditLogService $auditLog) {}

    public function requestReset(string $email): void
    {
        $user = User::where('email', $email)->first();

        if (! $user) {
            return;
        }

        $token = Str::random(64);

        PasswordResetToken::updateOrCreate(
            ['email' => $email],
            ['token' => Hash::make($token), 'created_at' => now()],
        );

        Mail::to($user->email)->send(new PasswordResetMail($user, $token, $this->expiryMinutes()));
    }

    /**
     * Returns false for every failure mode (no token on file, expired,
     * wrong token, or no matching user) without distinguishing which —
     * the same enumeration-safe posture as requestReset().
     */
    public function reset(string $email, string $token, string $password): bool
    {
        $record = PasswordResetToken::where('email', $email)->first();

        if (! $record || $this->isExpired($record->created_at)) {
            return false;
        }

        if (! Hash::check($token, $record->token)) {
            return false;
        }

        $user = User::where('email', $email)->first();

        if (! $user) {
            return false;
        }

        $user->password = $password;
        $user->save();

        $user->tokens()->delete();

        $record->delete();

        $this->auditLog->record(AuditAction::Edited, 'user', (string) $user->id, $user, 'Password reset via forgot-password flow');

        return true;
    }

    private function isExpired(?Carbon $createdAt): bool
    {
        if (! $createdAt) {
            return true;
        }

        return $createdAt->lt(now()->subMinutes($this->expiryMinutes()));
    }

    private function expiryMinutes(): int
    {
        return (int) env('PASSWORD_RESET_TOKEN_EXPIRY_MINUTES', self::DEFAULT_EXPIRY_MINUTES);
    }
}
