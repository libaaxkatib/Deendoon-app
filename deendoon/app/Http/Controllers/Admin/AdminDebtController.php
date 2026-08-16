<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Debt;
use Illuminate\Http\Request;
use Illuminate\View\View;
use Laravel\Sanctum\Guard;

/**
 * Admin Panel — Recovery & Debts (read-only, cross-tenant). No mutating
 * actions here: DebtPolicy remains Business-Owner-only and is
 * deliberately left untouched — authorization for this whole controller
 * is the route group's `can:platform-admin-only` Gate.
 *
 * Correctness note (verified empirically, not assumed): Laravel Sanctum's
 * guard ({@see Guard::__invoke()}) checks
 * `config('sanctum.guard', 'web')` — i.e. the default 'web' guard —
 * BEFORE falling back to a bearer token. So `Auth::guard('sanctum')->user()`
 * DOES resolve to the same Platform Administrator the Admin Panel's
 * session `web` guard authenticated, and BelongsToTenant's scope
 * genuinely fires `WHERE tenant_id IS NULL` (its documented fail-closed
 * behavior for a null-tenant actor) on every `Debt`/`Customer`/`Payment`/
 * `CollectionCase` query — including ones reached only through eager-
 * loaded relations. `withoutGlobalScope('tenant')` must therefore be
 * applied explicitly at EVERY level of the query (top-level and each
 * nested relation closure below), not just the top-level call. `show()`
 * takes a plain string ID rather than implicit Eloquent route-model
 * binding for the same reason — implicit binding's query would also
 * need this same unscoping.
 */
class AdminDebtController extends Controller
{
    /**
     * No PHP enum backs `debts.recovery_stage` (a raw SMALLINT 1-6) —
     * labels per RecoveryStageService's docblock (BRL-031).
     */
    public const RECOVERY_STAGE_LABELS = [
        1 => 'Initial',
        2 => 'Late Reminder',
        3 => 'Phone Follow-up',
        4 => 'Final Notice',
        5 => 'Professional Collection',
        6 => 'Recovered',
    ];

    public const STATUSES = [
        'draft' => 'Draft',
        'pending' => 'Pending',
        'overdue' => 'Overdue',
        'partial_paid' => 'Partially Paid',
        'paid' => 'Paid',
        'cancelled' => 'Cancelled',
        'written_off' => 'Written Off',
    ];

    public function index(Request $request): View
    {
        $debts = Debt::withoutGlobalScope('tenant')
            ->with(['customer' => fn ($query) => $query->withoutGlobalScope('tenant')
                ->select('id', 'tenant_id', 'name')
                ->with(['tenant:id,business_name'])])
            ->when($request->filled('search'), function ($query) use ($request) {
                $term = '%'.mb_strtolower((string) $request->string('search')).'%';
                $query->where(function ($q) use ($term) {
                    $q->whereRaw('LOWER(reference_number) LIKE ?', [$term])
                        ->orWhereHas('customer', fn ($c) => $c->withoutGlobalScope('tenant')
                            ->whereRaw('LOWER(name) LIKE ?', [$term]));
                });
            })
            ->when($request->filled('status'), fn ($query) => $query->where('debt_status', $request->string('status')))
            ->when($request->filled('stage'), fn ($query) => $query->where('recovery_stage', (int) $request->string('stage')))
            ->when($request->boolean('overdue_only'), fn ($query) => $query->effectivelyOverdue())
            ->orderByDesc('created_at')
            ->paginate(20)
            ->withQueryString();

        return view('admin.recovery-debts.index', [
            'title' => 'Recovery & Debts',
            'debts' => $debts,
            'statuses' => self::STATUSES,
            'stages' => self::RECOVERY_STAGE_LABELS,
        ]);
    }

    public function show(string $debt): View
    {
        $debt = Debt::withoutGlobalScope('tenant')
            ->with([
                'customer' => fn ($query) => $query->withoutGlobalScope('tenant')->with('tenant'),
                'payments' => fn ($query) => $query->withoutGlobalScope('tenant')->orderByDesc('payment_date'),
                'collectionCases' => fn ($query) => $query->withoutGlobalScope('tenant')
                    ->orderByDesc('created_at')
                    ->with(['professionalCollectionRequests']),
            ])
            ->findOrFail($debt);

        return view('admin.recovery-debts.show', [
            'title' => 'Recovery & Debts',
            'pageTitle' => $debt->reference_number,
            'debt' => $debt,
            'stages' => self::RECOVERY_STAGE_LABELS,
        ]);
    }
}
