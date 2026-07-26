<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * FR-066/FR-067's administrative view of a User — distinct from the
 * shared `UserResource` (Auth's login/register response), which
 * TenantTest::test_login_response_does_not_expose_tenant_id deliberately
 * keeps minimal. Administration legitimately needs tenant_id/role/
 * archived_at; Auth's own response contract is untouched.
 */
class AdminUserResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'role' => $this->roles->pluck('name')->first(),
            'tenant_id' => $this->tenant_id,
            'status' => $this->status,
            'archived_at' => $this->archived_at,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
