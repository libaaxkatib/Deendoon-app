<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Customer;
use Illuminate\Http\Request;
use Illuminate\View\View;

/**
 * Admin Panel — Debtors (read-only, cross-tenant). No mutating actions
 * here: CustomerPolicy remains Business-Owner-only and is deliberately
 * left untouched — authorization for this whole controller is the route
 * group's `can:platform-admin-only` Gate.
 *
 * Named after the `Customer` model, matching how `AdminTenantController`
 * is named after `Tenant` even though its UI label is "Businesses".
 *
 * Tenant-scope correctness (same finding as {@see AdminDebtController}):
 * Sanctum's guard checks the default `web` guard before falling back to
 * a bearer token, so a Platform Administrator's session DOES trigger
 * BelongsToTenant's `WHERE tenant_id IS NULL` fail-closed scope on every
 * `Customer`/`Debt` query reached from this controller — including
 * eager-loaded relations. `withoutGlobalScope('tenant')` is applied
 * explicitly at every level; `show()` takes a plain string ID rather
 * than implicit Eloquent route-model binding for the same reason.
 */
class AdminCustomerController extends Controller
{
    public const STATUSES = [
        'active' => 'Active',
        'good_standing' => 'Good Standing',
        'late_payer' => 'Late Payer',
        'high_risk' => 'High Risk',
        'in_collection' => 'In Collection',
        'recovered' => 'Recovered',
        'blocked' => 'Blocked',
    ];

    public const RISK_LEVELS = [
        'high' => 'High',
        'medium' => 'Medium',
        'low' => 'Low',
    ];

    public function index(Request $request): View
    {
        $customers = Customer::withoutGlobalScope('tenant')
            ->with(['tenant:id,business_name'])
            ->when($request->filled('search'), function ($query) use ($request) {
                $term = '%'.mb_strtolower((string) $request->string('search')).'%';
                $query->where(function ($q) use ($term) {
                    $q->whereRaw('LOWER(name) LIKE ?', [$term])
                        ->orWhereRaw('LOWER(phone) LIKE ?', [$term]);
                });
            })
            ->when($request->filled('status'), fn ($query) => $query->where('customer_status', $request->string('status')))
            ->when($request->filled('risk_level'), fn ($query) => $query->where('risk_level', $request->string('risk_level')))
            ->orderBy('name')
            ->paginate(20)
            ->withQueryString();

        return view('admin.debtors.index', [
            'title' => 'Debtors',
            'customers' => $customers,
            'statuses' => self::STATUSES,
            'riskLevels' => self::RISK_LEVELS,
        ]);
    }

    public function show(string $customer): View
    {
        $customer = Customer::withoutGlobalScope('tenant')
            ->with([
                'tenant',
                'debts' => fn ($query) => $query->withoutGlobalScope('tenant')->orderByDesc('created_at'),
            ])
            ->findOrFail($customer);

        return view('admin.debtors.show', [
            'title' => 'Debtors',
            'pageTitle' => $customer->name,
            'customer' => $customer,
            'statuses' => self::STATUSES,
            'stages' => AdminDebtController::RECOVERY_STAGE_LABELS,
            'debtStatuses' => AdminDebtController::STATUSES,
        ]);
    }
}
