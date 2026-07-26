<?php

namespace App\Http\Controllers;

use App\Enums\AuditAction;
use App\Http\Requests\LoginRequest;
use App\Http\Requests\RegisterRequest;
use App\Http\Resources\UserResource;
use App\Models\User;
use App\Services\AuditLogService;
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
 */
class AuthController extends Controller
{
    use ApiResponse;

    public function __construct(private readonly AuditLogService $auditLog) {}

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
}
