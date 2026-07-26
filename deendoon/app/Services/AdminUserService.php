<?php

namespace App\Services;

use App\Enums\AuditAction;
use App\Models\User;
use Illuminate\Http\Exceptions\HttpResponseException;

/**
 * FR-066/FR-067. Product Owner rulings applied here:
 * - Initial credentials: administrator sets the password directly.
 * - FR-066 A1 (sole role holder): deactivating the last active user
 *   holding a given role within the tenant is blocked.
 * - FR-067 A1 (multi-role): single role only.
 *
 * `password` is never hashed here — User::casts() already applies
 * Laravel's automatic 'hashed' cast on assignment (see
 * AuthController::register(), which passes the plain value the same
 * way); hashing it again here would double-hash and break login.
 *
 * Sprint 1.2 — Security Hardening: `deactivate()`/`assignRole()` now
 * revoke every active Sanctum token for the affected user —
 * 08_Security_and_RBAC.md §9's "Revoke all tokens: triggered
 * automatically by... role change (FR-067)... and account deactivation
 * (FR-066)" — the same rule already applied to password changes
 * (PasswordResetService::reset()) since Sprint 1.1, closing the one gap
 * the independent audit flagged: this was the *only* place 08 §9's
 * revocation rule was left unenforced.
 */
class AdminUserService
{
    public function __construct(private readonly AuditLogService $auditLog) {}

    public function create(array $data, string $tenantId, User $actor): User
    {
        $user = new User([
            'name' => $data['name'],
            'email' => $data['email'],
            'password' => $data['password'],
        ]);
        $user->tenant_id = $tenantId;
        $user->save();
        $user->assignRole($data['role']);

        $this->auditLog->record(AuditAction::Created, 'user', (string) $user->id, $actor);

        return $user->fresh();
    }

    public function update(User $user, array $data, User $actor): User
    {
        $user->name = $data['name'];
        $user->email = $data['email'];

        if (! empty($data['password'])) {
            $user->password = $data['password'];
        }

        $user->save();

        $this->auditLog->record(AuditAction::Edited, 'user', (string) $user->id, $actor);

        return $user->fresh();
    }

    /**
     * FR-066 A1: blocks deactivating the tenant's sole active `admin`
     * (Super Admin) user. The Product Owner ruling's own stated rationale
     * — "prevents a tenant from locking itself out of administration" —
     * is specific to the role that gates Administration access at all
     * (UserPolicy, `admin-only` Gate); it does not generalize to every
     * role (a tenant's last `sales_finance` or `collection_officer` user
     * is ordinary staff turnover, not an administration lockout).
     */
    public function deactivate(User $user, User $actor): void
    {
        if ($user->hasRole('admin')) {
            $otherActiveAdmins = User::role('admin')
                ->where('tenant_id', $user->tenant_id)
                ->where('id', '!=', $user->id)
                ->exists();

            if (! $otherActiveAdmins) {
                throw new HttpResponseException(response()->json([
                    'success' => false,
                    'message' => 'Cannot deactivate the sole active admin user in this tenant.',
                    'data' => null,
                    'errors' => null,
                ], 409));
            }
        }

        $user->delete();
        $user->tokens()->delete();

        $this->auditLog->record(AuditAction::Archived, 'user', (string) $user->id, $actor);
    }

    public function assignRole(User $user, string $role, User $actor): User
    {
        $user->syncRoles([$role]);
        $user->tokens()->delete();

        $this->auditLog->record(AuditAction::RoleChanged, 'user', (string) $user->id, $actor);

        return $user->fresh();
    }
}
