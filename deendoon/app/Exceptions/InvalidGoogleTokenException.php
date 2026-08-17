<?php

namespace App\Exceptions;

use App\Services\GoogleIdTokenVerifier;
use Exception;

/**
 * Mobile Fix #22 — Google Login. Thrown by {@see GoogleIdTokenVerifier}
 * for every rejection reason (bad signature, expired, wrong issuer, wrong
 * audience, malformed token) — deliberately a single exception type with a
 * generic caller-facing message, the same enumeration-safe posture already
 * used by AuthController::login()'s "Invalid credentials" and
 * PasswordResetService's reset()/changePassword() (never reveal exactly
 * which validation step failed).
 */
class InvalidGoogleTokenException extends Exception
{
    public function __construct(string $reason)
    {
        // $reason is for logs/debugging only, never rendered into an HTTP
        // response — see AuthController::googleLogin()'s catch block.
        parent::__construct($reason);
    }
}
