<?php

namespace App\Http\Controllers\Admin;

use App\Enums\AuditAction;
use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use App\Models\Tenant;
use App\Services\AuditLogService;
use Illuminate\Foundation\Auth\Access\AuthorizesRequests;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

/**
 * Admin Panel — Business Management (Product Owner decision): full
 * management of every tenant ("Business"), with confirmation required
 * for suspend/activate (destructive/sensitive actions) — confirmation is
 * enforced client-side (Blade confirm dialog) and the action itself is
 * logged to the Audit Trail, matching this project's existing convention
 * for every other admin-side status-changing action (e.g. Subscription/
 * Storage approval).
 */
class AdminTenantController extends Controller
{
    use AuthorizesRequests;

    public function __construct(private readonly AuditLogService $auditLog) {}

    public function index(Request $request): View
    {
        $this->authorize('viewAny', Tenant::class);

        $tenants = Tenant::query()
            ->withCount('users')
            ->with('subscription.plan')
            ->when($request->filled('search'), fn ($query) => $query->whereRaw(
                'LOWER(business_name) LIKE ?', ['%'.mb_strtolower((string) $request->string('search')).'%']
            ))
            ->when($request->filled('status'), fn ($query) => $query->where('status', $request->string('status')))
            ->orderByDesc('created_at')
            ->paginate(20)
            ->withQueryString();

        return view('admin.businesses.index', ['tenants' => $tenants]);
    }

    public function show(Tenant $tenant): View
    {
        $this->authorize('view', $tenant);

        $tenant->load(['users', 'subscription.plan']);

        $activity = AuditLog::where('tenant_id', $tenant->id)
            ->orderByDesc('occurred_at')
            ->limit(20)
            ->get();

        return view('admin.businesses.show', ['tenant' => $tenant, 'activity' => $activity]);
    }

    public function suspend(Request $request, Tenant $tenant): RedirectResponse
    {
        $this->authorize('suspend', $tenant);

        $validated = $request->validate([
            'reason' => ['required', 'string', 'max:500'],
        ]);

        $tenant->suspend($validated['reason']);

        $this->auditLog->record(
            AuditAction::StatusChanged,
            'tenant',
            (string) $tenant->id,
            $request->user(),
            $validated['reason'],
            $tenant->id,
        );

        return back()->with('status', "{$tenant->business_name} has been suspended.");
    }

    public function activate(Request $request, Tenant $tenant): RedirectResponse
    {
        $this->authorize('activate', $tenant);

        $tenant->activate();

        $this->auditLog->record(
            AuditAction::StatusChanged,
            'tenant',
            (string) $tenant->id,
            $request->user(),
            'Reactivated by Platform Administrator',
            $tenant->id,
        );

        return back()->with('status', "{$tenant->business_name} has been reactivated.");
    }
}
