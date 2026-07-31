<?php

namespace App\Http\Controllers;

use App\Http\Requests\AssignUserRoleRequest;
use App\Http\Requests\CreateUserRequest;
use App\Http\Requests\UpdateUserRequest;
use App\Http\Resources\AdminUserResource;
use App\Models\User;
use App\Services\AdminUserService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * @deprecated Version 1 authentication model (RBAC Architecture
 * Amendment, Product Owner Decision, 2026-07-30): the Customer Mobile
 * App has exactly one account per tenant (the Business Owner) — there is
 * no second tenant user for this controller to administer. Left in place
 * and functional (not removed) pending confirmation of no residual
 * dependency; scheduled for removal in a future cleanup pass. Do not
 * build new functionality against this controller.
 *
 * FR-066/FR-067 — User Administration and Role & Permission Management.
 * Every action is scoped to the requesting administrator's own tenant
 * (UserPolicy); the Deendoon Platform Administrator is never modeled by
 * this controller.
 */
class AdminUserController extends Controller
{
    use ApiResponse;

    public function __construct(private readonly AdminUserService $users) {}

    public function index(Request $request): JsonResponse
    {
        $this->authorize('viewAny', User::class);

        $query = User::where('tenant_id', $request->user()->tenant_id)->with('roles');

        if ($request->boolean('includeArchived')) {
            $query->withTrashed();
        }

        $users = $query->orderBy('name')->paginate(
            perPage: $this->perPage($request),
        );

        return $this->successResponse([
            'users' => AdminUserResource::collection($users->items()),
            'pagination' => [
                'current_page' => $users->currentPage(),
                'per_page' => $users->perPage(),
                'total' => $users->total(),
                'last_page' => $users->lastPage(),
            ],
        ]);
    }

    public function store(CreateUserRequest $request): JsonResponse
    {
        $this->authorize('create', User::class);

        $user = $this->users->create($request->validated(), $request->user()->tenant_id, $request->user());

        return $this->successResponse(new AdminUserResource($user), 'User created successfully', 201);
    }

    public function show(User $user): JsonResponse
    {
        $this->authorize('view', $user);

        return $this->successResponse(new AdminUserResource($user));
    }

    public function update(UpdateUserRequest $request, User $user): JsonResponse
    {
        $this->authorize('update', $user);

        $updated = $this->users->update($user, $request->validated(), $request->user());

        return $this->successResponse(new AdminUserResource($updated), 'User updated successfully');
    }

    public function deactivate(Request $request, User $user): JsonResponse
    {
        $this->authorize('deactivate', $user);

        $this->users->deactivate($user, $request->user());

        return $this->successResponse(null, 'User deactivated successfully');
    }

    public function updateRole(AssignUserRoleRequest $request, User $user): JsonResponse
    {
        $this->authorize('assignRole', $user);

        $updated = $this->users->assignRole($user, $request->validated('role'), $request->user());

        return $this->successResponse(new AdminUserResource($updated), 'Role updated successfully');
    }
}
