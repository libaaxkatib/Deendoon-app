<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use App\Models\Tenant;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\View\View;

/**
 * Admin Panel — Audit Logs (Module 10), Platform-Administrator-only,
 * gated by the same `can:platform-admin-only` Gate as every other Admin
 * controller. Read-only: browse/filter/paginate only (Product Owner
 * Decision 2 — no export/print in V1; Decision 3 — no delete/retention
 * controls, matching AuditLog's existing structural immutability).
 *
 * AuditLog carries no tenant-scoping trait (confirmed during the Module
 * 10 audit) — a plain query here is already cross-tenant by default,
 * unlike every other Admin module, which needs an explicit
 * `withoutGlobalScope('tenant')` to see across tenants.
 */
class AdminAuditLogController extends Controller
{
    public function index(Request $request): View
    {
        $logs = AuditLog::query()
            ->when($request->filled('search'), function ($query) use ($request) {
                $term = '%'.mb_strtolower((string) $request->string('search')).'%';
                $query->where(function ($subQuery) use ($term) {
                    $subQuery->whereRaw('LOWER(reason) LIKE ?', [$term])
                        ->orWhereRaw('LOWER(entity_id) LIKE ?', [$term]);
                });
            })
            ->when($request->filled('action'), fn ($query) => $query->where('action', $request->string('action')))
            ->when($request->filled('entity_type'), fn ($query) => $query->where('entity_type', $request->string('entity_type')))
            ->when($request->filled('tenant_id'), fn ($query) => $query->where('tenant_id', $request->string('tenant_id')))
            ->when($request->filled('date_from'), fn ($query) => $query->whereDate('occurred_at', '>=', $request->string('date_from')))
            ->when($request->filled('date_to'), fn ($query) => $query->whereDate('occurred_at', '<=', $request->string('date_to')))
            ->orderByDesc('occurred_at')
            ->paginate(25)
            ->withQueryString();

        $tenantIds = $logs->getCollection()->pluck('tenant_id')->filter()->unique();
        $tenantNames = Tenant::whereIn('id', $tenantIds)->pluck('business_name', 'id');

        // audit_log.user_id is CHAR(26): PostgreSQL right-pads the short
        // bigint-derived users.id it actually stores, up to 26 characters,
        // and returns that padding on SELECT (same issue proven and fixed
        // for Announcement::sentByUserId()). Trimmed here, locally to this
        // controller, rather than on the shared AuditLog model, since that
        // model also backs the separate tenant-facing Audit Trail
        // (AuditTrailController) — out of scope for this module.
        //
        // withTrashed(): an audit entry for an actor who has since been
        // deactivated (User uses SoftDeletes) must still show their real
        // name — the action genuinely happened. A user_id with no row at
        // all (verified live: a small number of pre-existing dev-data
        // entries reference an id that no longer exists in `users`) still
        // correctly falls through to "Unknown" — that is an honest label
        // for a genuinely unresolvable actor, not a bug.
        $userIds = $logs->getCollection()->pluck('user_id')->filter()->map(fn (string $id) => trim($id))->unique();
        $userNames = User::withTrashed()->whereIn('id', $userIds)->get()->keyBy(fn (User $user) => (string) $user->id)->map->name;

        return view('admin.audit-logs.index', [
            'title' => 'Audit Logs',
            'pageTitle' => 'Audit Logs',
            'logs' => $logs,
            'tenantNames' => $tenantNames,
            'userNames' => $userNames,
            'tenants' => Tenant::orderBy('business_name')->get(['id', 'business_name']),
            'actionOptions' => $this->distinctOptions('action'),
            'entityTypeOptions' => $this->distinctOptions('entity_type'),
        ]);
    }

    /**
     * Only actions/entity types actually present in the table are offered
     * as filters — the AuditAction enum allows 29 values platform-wide,
     * but only a subset has ever actually been recorded; the dropdown
     * must not imply events that never happened.
     *
     * @return array<string, string>
     */
    private function distinctOptions(string $column): array
    {
        return AuditLog::query()
            ->distinct()
            ->orderBy($column)
            ->pluck($column)
            ->mapWithKeys(fn (string $value) => [$value => ucwords(str_replace('_', ' ', $value))])
            ->all();
    }
}
