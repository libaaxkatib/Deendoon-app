<?php

namespace App\Http\Controllers;

use App\Enums\AuditAction;
use App\Http\Requests\ChangePasswordRequest;
use App\Http\Requests\ForgotPasswordRequest;
use App\Http\Requests\LoginRequest;
use App\Http\Requests\RegisterRequest;
use App\Http\Requests\ResetPasswordRequest;
use App\Http\Resources\UserResource;
use App\Models\Tenant;
use App\Models\User;
use App\Services\AuditLogService;
use App\Services\CustomerReadOnlyService;
use App\Services\MessageTemplateService;
use App\Services\PasswordResetService;
use App\Services\SecurityEventLogger;
use App\Services\SubscriptionService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
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
        private readonly SecurityEventLogger $securityLog,
        private readonly MessageTemplateService $messageTemplates,
        private readonly SubscriptionService $subscriptions,
        private readonly CustomerReadOnlyService $customerReadOnly,
    ) {}

    /**
     * Version 1 authentication model (RBAC Architecture Amendment,
     * Product Owner Decision, 2026-07-30): registration creates a new
     * Tenant and its single Business Owner account (role `admin`)
     * together — the only account-creation path for the Customer Mobile
     * App. Wrapped in a transaction since it writes several related rows
     * (default message templates, automatic Trial provisioning — Phase
     * 3.5 — plus the tenant and user themselves).
     */
    public function register(RegisterRequest $request): JsonResponse
    {
        $user = DB::transaction(function () use ($request) {
            $tenant = Tenant::create([
                'business_name' => $request->validated('business_name'),
            ]);

            // Backend Completion Audit (Phase 1): provision the 7 approved
            // default reminder templates for every new tenant, closing the
            // gap where only tenants seeded before this fix had them.
            $this->messageTemplates->provisionDefaults($tenant);

            // Backend Completion Roadmap (Phase 3.5): every new tenant
            // automatically starts on the Trial plan — the Free Plan
            // fallback is only for tenants that genuinely have no
            // subscription record, not the normal path for a new one.
            $this->subscriptions->provisionTrial($tenant);

            // Backend Completion Roadmap (Phase 4.1): every subscription
            // change must trigger recalculation — a no-op here (0
            // customers yet) but keeps the rule uniformly true rather
            // than special-cased for "brand new tenant."
            $this->customerReadOnly->recalculate($tenant);

            $user = new User([
                'name' => $request->validated('name'),
                'email' => $request->validated('email'),
                'password' => $request->validated('password'),
            ]);
            $user->tenant_id = $tenant->id;
            $user->save();
            $user->assignRole('admin');

            $this->auditLog->record(AuditAction::Created, 'user', (string) $user->id, $user);

            return $user->fresh();
        });

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
            $this->securityLog->loginFailed($request->validated('email'), $request->ip());

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
     * Sprint 1 — Backend Foundation (Backend v2.1). Rotates the caller's
     * current Sanctum token for a new one, letting a client stay signed in
     * past the sliding idle window (EnsureTokenIsNotIdle) without asking
     * the user to re-enter credentials. Deliberately reuses the exact
     * token-issuance mechanism and response shape already used by
     * login()/register() (a plain-text token plus the UserResource) rather
     * than introducing a distinct refresh-token type or renaming those
     * endpoints' existing `token` field — Sanctum has no separate
     * refresh-token concept, and this project's approved authentication
     * model is a single bearer token, not an access/refresh pair.
     */
    public function refresh(Request $request): JsonResponse
    {
        $user = $request->user();

        $request->user()->currentAccessToken()->delete();

        $token = $user->createToken('auth_token')->plainTextToken;

        return $this->successResponse([
            'user' => new UserResource($user),
            'token' => $token,
        ], 'Token refreshed successfully');
    }

    /**
     * FR-006 — Role Resolution. Version 1 authentication model (RBAC
     * Architecture Amendment, Product Owner Decision, 2026-07-30): exactly
     * two account types exist, so this returns a single resolved role
     * (`admin` for the Business Owner, `deendoon_platform_administrator`
     * for the Platform Administrator) — no permission array, no
     * multi-role support, per that decision's explicit instruction.
     */
    public function me(Request $request): JsonResponse
    {
        $user = $request->user();

        return $this->successResponse([
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'role' => $user->roles()->value('name'),
        ]);
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

    /**
     * FR-005 — Change Password. The authenticated counterpart to
     * forgotPassword()/resetPassword() (FR-004): proves ownership via the
     * caller's current password instead of a mailed token. Delegates to
     * PasswordResetService for the actual verify/hash/revoke/audit steps,
     * exactly as resetPassword() does.
     */
    public function changePassword(ChangePasswordRequest $request): JsonResponse
    {
        $success = $this->passwordReset->changePassword(
            $request->user(),
            $request->validated('current_password'),
            $request->validated('password'),
        );

        if (! $success) {
            return $this->errorResponse('The current password is incorrect.', null, 422);
        }

        return $this->successResponse(null, 'Password changed successfully');
    }
}
