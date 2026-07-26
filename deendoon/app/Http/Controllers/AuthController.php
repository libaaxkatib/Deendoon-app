<?php

namespace App\Http\Controllers;

use App\Enums\AuditAction;
use App\Http\Requests\ForgotPasswordRequest;
use App\Http\Requests\LoginRequest;
use App\Http\Requests\RegisterRequest;
use App\Http\Requests\ResetPasswordRequest;
use App\Http\Resources\UserResource;
use App\Models\User;
use App\Services\AuditLogService;
use App\Services\PasswordResetService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

/**
 * Phase 14 — Production Readiness: login()/logout() now write the
 * `login`/`logout` audit_log rows 08_Security_and_RBAC.md §13 already
 * describes as covered ("the approved event catalog... already includes
 * both authentication events") — both values existed in the CHECK
 * constraint and AuditAction enum since Module 1/10, but nothing wrote
 * them (flagged as a known gap in docs/Domain_Events.md since Module 10).
 * No new action type, column, or business rule — only closing an
 * already-approved, already-flagged gap.
 *
 * Sprint 1.1 — Password Recovery (FR-004): forgotPassword()/resetPassword()
 * delegate entirely to PasswordResetService; see that class's docblock
 * for the security properties (hashing, expiry, single-use, enumeration
 * safety). Both responses are deliberately generic/identical regardless
 * of whether the submitted email exists.
 */
class AuthController extends Controller
{
    use ApiResponse;

    public function __construct(
        private readonly AuditLogService $auditLog,
        private readonly PasswordResetService $passwordReset,
    ) {}

    public function register(RegisterRequest $request): JsonResponse
    {
        $user = User::create([
            'name' => $request->validated('name'),
            'email' => $request->validated('email'),
            'password' => $request->validated('password'),
        ]);

        $token = $user->createToken('auth_token')->plainTextToken;

        return $this->successResponse([
            'user' => new UserResource($user),
            'token' => $token,
        ], 'Registration successful', 201);
    }

    public function login(LoginRequest $request): JsonResponse
    {
        $user = User::where('email', $request->validated('email'))->first();

        if (! $user || ! Hash::check($request->validated('password'), $user->password)) {
            return $this->errorResponse('Invalid credentials', null, 401);
        }

        $token = $user->createToken('auth_token')->plainTextToken;

        $this->auditLog->record(AuditAction::Login, 'user', (string) $user->id, $user);

        return $this->successResponse([
            'user' => new UserResource($user),
            'token' => $token,
        ], 'Login successful');
    }

    public function logout(Request $request): JsonResponse
    {
        $user = $request->user();
        $user->currentAccessToken()->delete();

        $this->auditLog->record(AuditAction::Logout, 'user', (string) $user->id, $user);

        return $this->successResponse(null, 'Logout successful');
    }

    /**
     * FR-004. Always returns the same response whether or not the email
     * belongs to an account — PasswordResetService silently no-ops for an
     * unknown (or deactivated/archived) email rather than signaling that
     * back to the caller.
     */
    public function forgotPassword(ForgotPasswordRequest $request): JsonResponse
    {
        $this->passwordReset->requestReset($request->validated('email'));

        return $this->successResponse(
            null,
            'If an account with that email exists, a password reset link has been sent.',
        );
    }

    /**
     * FR-004. A single generic failure message covers every rejection
     * reason (no token on file, expired, wrong token, unknown email) —
     * distinguishing them in the response would itself leak information
     * an attacker could use to enumerate accounts or probe tokens.
     */
    public function resetPassword(ResetPasswordRequest $request): JsonResponse
    {
        $success = $this->passwordReset->reset(
            $request->validated('email'),
            $request->validated('token'),
            $request->validated('password'),
        );

        if (! $success) {
            return $this->errorResponse('This password reset token is invalid or has expired.', null, 422);
        }

        return $this->successResponse(null, 'Password reset successfully');
    }
}
