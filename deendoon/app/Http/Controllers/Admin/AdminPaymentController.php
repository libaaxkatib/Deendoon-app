<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Payment;
use Illuminate\Http\Request;
use Illuminate\View\View;

/**
 * Admin Panel — Payments (read-only, cross-tenant). No mutating actions
 * here: `Payment` has no dedicated policy (its authorization piggybacks
 * on `DebtPolicy`, which is Business-Owner-only and deliberately left
 * untouched) — authorization for this whole controller is the route
 * group's `can:platform-admin-only` Gate, same as every other admin
 * controller.
 *
 * `payments` has no status column and no reference-number column (schema
 * verified via `2026_07_30_090000_create_payments_table.php` and the
 * `Payment` model's `#[Fillable]` list — no later migration ever altered
 * this table). The list/detail views show a genuine "Pending backend
 * support" state for status rather than fabricating one; the payment's
 * ULID primary key is shown as its identifier since no separate
 * human-readable reference exists.
 *
 * Tenant-scope correctness (same finding as {@see AdminDebtController}/
 * {@see AdminCustomerController}): Sanctum's guard checks the default
 * `web` guard before falling back to a bearer token, so a Platform
 * Administrator's session DOES trigger BelongsToTenant's
 * `WHERE tenant_id IS NULL` fail-closed scope on every `Payment`/`Debt`/
 * `Customer` query reached from this controller — including eager-loaded
 * relations. `withoutGlobalScope('tenant')` is applied explicitly at
 * every level; `show()` takes a plain string ID rather than implicit
 * Eloquent route-model binding for the same reason.
 */
class AdminPaymentController extends Controller
{
    public function index(Request $request): View
    {
        $payments = Payment::withoutGlobalScope('tenant')
            ->with(['debt' => fn ($query) => $query->withoutGlobalScope('tenant')
                ->select('id', 'tenant_id', 'customer_id', 'reference_number')
                ->with(['customer' => fn ($q) => $q->withoutGlobalScope('tenant')
                    ->select('id', 'tenant_id', 'name')
                    ->with(['tenant:id,business_name'])])])
            ->when($request->filled('search'), function ($query) use ($request) {
                $term = '%'.mb_strtolower((string) $request->string('search')).'%';
                $query->where(function ($q) use ($term) {
                    $q->whereRaw('LOWER(reference_notes) LIKE ?', [$term])
                        ->orWhereHas('debt', fn ($d) => $d->withoutGlobalScope('tenant')
                            ->where(function ($d2) use ($term) {
                                $d2->whereRaw('LOWER(reference_number) LIKE ?', [$term])
                                    ->orWhereHas('customer', fn ($c) => $c->withoutGlobalScope('tenant')
                                        ->whereRaw('LOWER(name) LIKE ?', [$term]));
                            }));
                });
            })
            ->when($request->filled('payment_method'), fn ($query) => $query->where('payment_method', $request->string('payment_method')))
            ->when($request->filled('date_from'), fn ($query) => $query->whereDate('payment_date', '>=', $request->string('date_from')))
            ->when($request->filled('date_to'), fn ($query) => $query->whereDate('payment_date', '<=', $request->string('date_to')))
            ->orderByDesc('created_at')
            ->paginate(20)
            ->withQueryString();

        // Payment method has no fixed enum (a free-form nullable string
        // column) — the filter's option list is built from real values
        // actually present in the data, not an invented fixed set.
        $paymentMethods = Payment::withoutGlobalScope('tenant')
            ->whereNotNull('payment_method')
            ->distinct()
            ->orderBy('payment_method')
            ->pluck('payment_method');

        return view('admin.payments.index', [
            'title' => 'Payments',
            'payments' => $payments,
            'paymentMethods' => $paymentMethods,
        ]);
    }

    public function show(string $payment): View
    {
        $payment = Payment::withoutGlobalScope('tenant')
            ->with(['debt' => fn ($query) => $query->withoutGlobalScope('tenant')
                ->with(['customer' => fn ($q) => $q->withoutGlobalScope('tenant')->with('tenant')])])
            ->findOrFail($payment);

        return view('admin.payments.show', [
            'title' => 'Payments',
            'pageTitle' => 'Payment '.$payment->id,
            'payment' => $payment,
            'debtStatuses' => AdminDebtController::STATUSES,
            'stages' => AdminDebtController::RECOVERY_STAGE_LABELS,
        ]);
    }
}
