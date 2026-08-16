<?php

namespace App\Services\Admin;

use App\Models\CollectionCase;
use App\Models\Customer;
use App\Models\Debt;
use App\Models\Payment;
use App\Models\ProfessionalCollectionRequest;
use App\Models\StorageAddon;
use App\Models\SubscriptionChangeRequest;
use App\Models\Tenant;
use App\Models\TenantSubscription;
use App\Services\CollectionRateService;
use App\Services\ReportingService;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Carbon;
use Illuminate\Support\Collection;

/**
 * Admin Panel — Reports & Analytics (Module 6). Every cross-tenant query
 * here explicitly applies `withoutGlobalScope('tenant')` for
 * `Debt`/`Customer`/`Payment`/`CollectionCase` (plain `BelongsToTenant`,
 * fails closed for the Platform Administrator — verified by reading the
 * trait directly, not assumed) at every nesting level. `Tenant`,
 * `TenantSubscription`/`SubscriptionChangeRequest`/`StorageAddon`
 * (`BelongsToTenantOrPlatformAdmin`, already exempts the Platform
 * Administrator), and `ProfessionalCollectionRequest` (hand-scoped, no
 * trait at all) need no such call — see each model's own docblock,
 * confirmed during the Module 6 audit.
 *
 * Financial/report definitions are reused exactly as established by
 * {@see ReportingService}/`AdminDashboardService` — never redefined here:
 * Outstanding Debt and Overdue count/value are always a *current*
 * snapshot (never date-range-filtered — {@see ReportingService::dashboardKpis()}
 * computes them with no period bound either); Total Debt Cases/Value,
 * Amount Recovered, and Recovery Rate ARE date-range-filtered (matching
 * `dashboardKpis()`'s own period-scoped figures). Recovery Rate reuses
 * {@see CollectionRateService::rateFor()} verbatim — the one shared
 * formula. Amount Recovered/Total Collected reuses the same
 * `SUM(payments.amount)` definition throughout.
 *
 * No pagination happens here — every `*Query()` method returns a
 * `Builder` for the caller (`AdminReportController`) to `paginate()` for
 * the detail table or feed unpaginated into an export, per
 * "use database aggregation... avoid loading entire datasets into
 * memory" — every summary figure below is a single aggregate query
 * (`count()`/`sum()`), never a PHP-side loop over loaded rows.
 */
class AdminReportingService
{
    public function __construct(
        private readonly ReportingService $reporting,
        private readonly CollectionRateService $collectionRate,
    ) {}

    /**
     * @return array{0: string, 1: string}
     */
    public function resolveDateRange(?string $period, ?string $dateFrom, ?string $dateTo): array
    {
        return $this->reporting->periodBounds($period ?: 'this_month', $dateFrom, $dateTo);
    }

    public function tenantOptions(): Collection
    {
        return Tenant::orderBy('business_name')->get(['id', 'business_name']);
    }

    /**
     * `payment_method` is tenant-configurable Reference Data (see
     * `reference_data` category `payment_method`), not a fixed enum — so
     * rather than inventing a hardcoded cross-tenant list, this offers
     * only the values genuinely present in payments across all tenants.
     *
     * @return array<int, string>
     */
    public function paymentMethodOptions(): array
    {
        return Payment::withoutGlobalScope('tenant')
            ->whereNotNull('payment_method')
            ->distinct()
            ->orderBy('payment_method')
            ->pluck('payment_method')
            ->all();
    }

    // ==================================================================
    // Debt & Recovery
    // ==================================================================

    /**
     * @param  array<string, mixed>  $filters
     */
    public function debtRecoveryQuery(array $filters): Builder
    {
        return Debt::withoutGlobalScope('tenant')
            ->with(['customer' => fn ($q) => $q->withoutGlobalScope('tenant')
                ->select('id', 'tenant_id', 'name')
                ->with(['tenant:id,business_name'])])
            ->when($filters['tenant_id'] ?? null, fn ($q, $v) => $q->where('tenant_id', $v))
            ->when($filters['status'] ?? null, fn ($q, $v) => $v === 'overdue' ? $q->effectivelyOverdue() : $q->where('debt_status', $v))
            ->when($filters['recovery_stage'] ?? null, fn ($q, $v) => $q->where('recovery_stage', (int) $v))
            ->when($filters['date_from'] ?? null, fn ($q, $v) => $q->whereDate('created_at', '>=', $v))
            ->when($filters['date_to'] ?? null, fn ($q, $v) => $q->whereDate('created_at', '<=', $v));
    }

    /**
     * @param  array<string, mixed>  $filters
     * @return array<string, mixed>
     */
    public function debtRecoverySummary(array $filters): array
    {
        $periodQuery = $this->debtRecoveryQuery($filters);
        $snapshotQuery = $this->debtRecoveryQuery(['tenant_id' => $filters['tenant_id'] ?? null]);

        $totalCases = (clone $periodQuery)->count();
        $totalValue = (float) (clone $periodQuery)->sum('amount');
        $outstanding = (float) (clone $snapshotQuery)->whereNotIn('debt_status', ['paid', 'cancelled', 'written_off'])->sum('remaining_balance');
        $overdueCount = (clone $snapshotQuery)->effectivelyOverdue()->count();
        $overdueValue = (float) (clone $snapshotQuery)->effectivelyOverdue()->sum('remaining_balance');

        [$dateFrom, $dateTo] = [$filters['date_from'] ?? null, $filters['date_to'] ?? null];
        $recovered = 0.0;
        $recoveryRate = 0.0;
        if ($dateFrom && $dateTo) {
            $payments = Payment::withoutGlobalScope('tenant')->when($filters['tenant_id'] ?? null, fn ($q, $v) => $q->where('tenant_id', $v));
            $debts = Debt::withoutGlobalScope('tenant')->when($filters['tenant_id'] ?? null, fn ($q, $v) => $q->where('tenant_id', $v));
            $recovered = (float) (clone $payments)->whereDate('payment_date', '>=', $dateFrom)->whereDate('payment_date', '<=', $dateTo)->sum('amount');
            $recoveryRate = $this->collectionRate->rateFor(clone $payments, clone $debts, $dateFrom, $dateTo);
        }

        $statusDistribution = (clone $periodQuery)->selectRaw('debt_status, count(*) as total')->groupBy('debt_status')->pluck('total', 'debt_status');
        $stageDistribution = (clone $periodQuery)->selectRaw('recovery_stage, count(*) as total')->groupBy('recovery_stage')->pluck('total', 'recovery_stage');

        return [
            'total_cases' => $totalCases,
            'total_value' => $totalValue,
            'outstanding_debt' => $outstanding,
            'amount_recovered' => $recovered,
            'recovery_rate' => $recoveryRate,
            'overdue_count' => $overdueCount,
            'overdue_value' => $overdueValue,
            'status_distribution' => $statusDistribution,
            'stage_distribution' => $stageDistribution,
        ];
    }

    /**
     * @param  array<string, mixed>  $filters
     * @return array<int, array{label: string, value: float}>
     */
    public function debtRecoveryTrend(array $filters): array
    {
        [$dateFrom, $dateTo] = [$filters['date_from'] ?? null, $filters['date_to'] ?? null];
        if (! $dateFrom || ! $dateTo) {
            return [];
        }

        $query = Payment::withoutGlobalScope('tenant')->when($filters['tenant_id'] ?? null, fn ($q, $v) => $q->where('tenant_id', $v));

        return $this->periodSeries($query, 'payment_date', $dateFrom, $dateTo, 'sum', 'amount');
    }

    // ==================================================================
    // Debtor Risk
    // ==================================================================

    /**
     * @param  array<string, mixed>  $filters
     */
    public function debtorRiskQuery(array $filters): Builder
    {
        return Customer::withoutGlobalScope('tenant')
            ->with(['tenant:id,business_name'])
            ->when($filters['tenant_id'] ?? null, fn ($q, $v) => $q->where('tenant_id', $v))
            ->when($filters['status'] ?? null, fn ($q, $v) => $q->where('customer_status', $v))
            ->when($filters['risk_level'] ?? null, fn ($q, $v) => $q->where('risk_level', $v))
            ->when($filters['date_from'] ?? null, fn ($q, $v) => $q->whereDate('created_at', '>=', $v))
            ->when($filters['date_to'] ?? null, fn ($q, $v) => $q->whereDate('created_at', '<=', $v));
    }

    /**
     * @param  array<string, mixed>  $filters
     * @return array<string, mixed>
     */
    public function debtorRiskSummary(array $filters): array
    {
        $query = $this->debtorRiskQuery($filters);

        $total = (clone $query)->count();
        $riskDistribution = (clone $query)->whereNotNull('risk_level')->selectRaw('risk_level, count(*) as total')->groupBy('risk_level')->pluck('total', 'risk_level');
        $statusDistribution = (clone $query)->selectRaw('customer_status, count(*) as total')->groupBy('customer_status')->pluck('total', 'customer_status');
        $highRisk = (clone $query)->where('risk_level', 'high')->count();

        // Credit Score Band: real column (`credit_score_band`), populated
        // only where a credit score has actually been computed — genuine
        // data, not fabricated; customers with no band yet are excluded
        // from this specific breakdown rather than shown as a fake "0" band.
        $bandDistribution = (clone $query)->whereNotNull('credit_score_band')->selectRaw('credit_score_band, count(*) as total')->groupBy('credit_score_band')->pluck('total', 'credit_score_band');

        return [
            'total_debtors' => $total,
            'high_risk_count' => $highRisk,
            'risk_distribution' => $riskDistribution,
            'status_distribution' => $statusDistribution,
            'credit_score_band_distribution' => $bandDistribution,
        ];
    }

    // ==================================================================
    // Payments
    // ==================================================================

    /**
     * @param  array<string, mixed>  $filters
     */
    public function paymentQuery(array $filters): Builder
    {
        return Payment::withoutGlobalScope('tenant')
            ->with(['debt' => fn ($q) => $q->withoutGlobalScope('tenant')
                ->select('id', 'tenant_id', 'customer_id', 'reference_number')
                ->with(['customer' => fn ($q2) => $q2->withoutGlobalScope('tenant')
                    ->select('id', 'tenant_id', 'name')
                    ->with(['tenant:id,business_name'])])])
            ->when($filters['tenant_id'] ?? null, fn ($q, $v) => $q->where('tenant_id', $v))
            ->when($filters['payment_method'] ?? null, fn ($q, $v) => $q->where('payment_method', $v))
            ->when($filters['date_from'] ?? null, fn ($q, $v) => $q->whereDate('payment_date', '>=', $v))
            ->when($filters['date_to'] ?? null, fn ($q, $v) => $q->whereDate('payment_date', '<=', $v));
    }

    /**
     * @param  array<string, mixed>  $filters
     * @return array<string, mixed>
     */
    public function paymentSummary(array $filters): array
    {
        $query = $this->paymentQuery($filters);

        return [
            'count' => (clone $query)->count(),
            'total_amount' => (float) (clone $query)->sum('amount'),
            'method_distribution' => (clone $query)->whereNotNull('payment_method')->selectRaw('payment_method, count(*) as total')->groupBy('payment_method')->pluck('total', 'payment_method'),
        ];
    }

    /**
     * @param  array<string, mixed>  $filters
     * @return array<int, array{label: string, value: float}>
     */
    public function paymentTrend(array $filters): array
    {
        [$dateFrom, $dateTo] = [$filters['date_from'] ?? null, $filters['date_to'] ?? null];
        if (! $dateFrom || ! $dateTo) {
            return [];
        }

        $query = Payment::withoutGlobalScope('tenant')->when($filters['tenant_id'] ?? null, fn ($q, $v) => $q->where('tenant_id', $v));

        return $this->periodSeries($query, 'payment_date', $dateFrom, $dateTo, 'sum', 'amount');
    }

    // ==================================================================
    // Professional Collection
    // ==================================================================

    /**
     * @param  array<string, mixed>  $filters
     */
    public function professionalCollectionQuery(array $filters): Builder
    {
        return ProfessionalCollectionRequest::with([
            'collectionCase' => fn ($q) => $q->withoutGlobalScope('tenant')
                ->with(['debt' => fn ($q2) => $q2->withoutGlobalScope('tenant')
                    ->with(['customer' => fn ($q3) => $q3->withoutGlobalScope('tenant')->with('tenant')])]),
        ])
            ->when($filters['tenant_id'] ?? null, fn ($q, $v) => $q->where('tenant_id', $v))
            ->when($filters['status'] ?? null, fn ($q, $v) => $q->where('status', $v))
            ->when($filters['date_from'] ?? null, fn ($q, $v) => $q->whereDate('created_at', '>=', $v))
            ->when($filters['date_to'] ?? null, fn ($q, $v) => $q->whereDate('created_at', '<=', $v));
    }

    /**
     * @param  array<string, mixed>  $filters
     * @return array<string, mixed>
     */
    public function professionalCollectionSummary(array $filters): array
    {
        $query = $this->professionalCollectionQuery($filters);

        $total = (clone $query)->count();
        $statusDistribution = (clone $query)->selectRaw('status, count(*) as total')->groupBy('status')->pluck('total', 'status');
        $recovered = (int) ($statusDistribution['recovered'] ?? 0);
        $closed = (int) ($statusDistribution['closed'] ?? 0);

        // Recovery duration (closed_at - created_at): only meaningful now
        // that closed_at genuinely persists (Module 5 fix). Averaged in
        // PHP over the (typically small) set of already-closed requests
        // matching the filters — not a per-row loop over the full dataset.
        $closedRequests = (clone $query)->whereIn('status', ['recovered', 'closed'])->whereNotNull('closed_at')->get(['created_at', 'closed_at']);
        $averageDurationDays = $closedRequests->isNotEmpty()
            ? round($closedRequests->avg(fn ($r) => $r->created_at->diffInDays($r->closed_at)), 1)
            : null;

        return [
            'total_requests' => $total,
            'status_distribution' => $statusDistribution,
            'recovered_count' => $recovered,
            'closed_count' => $closed,
            'average_recovery_duration_days' => $averageDurationDays,
        ];
    }

    /**
     * @param  array<string, mixed>  $filters
     * @return array<int, array{label: string, value: float}>
     */
    public function professionalCollectionTrend(array $filters): array
    {
        [$dateFrom, $dateTo] = [$filters['date_from'] ?? null, $filters['date_to'] ?? null];
        if (! $dateFrom || ! $dateTo) {
            return [];
        }

        $query = ProfessionalCollectionRequest::when($filters['tenant_id'] ?? null, fn ($q, $v) => $q->where('tenant_id', $v));

        return $this->periodSeries($query, 'created_at', $dateFrom, $dateTo, 'count');
    }

    // ==================================================================
    // Subscriptions
    // ==================================================================

    /**
     * Detail table = Subscription Change Request history (the closest
     * "activity" record for this report — TenantSubscription itself is
     * one row per tenant, not a time series of changes).
     *
     * @param  array<string, mixed>  $filters
     */
    public function subscriptionQuery(array $filters): Builder
    {
        return SubscriptionChangeRequest::with(['tenant:id,business_name', 'requestedPlan', 'currentPlan'])
            ->when($filters['tenant_id'] ?? null, fn ($q, $v) => $q->where('tenant_id', $v))
            ->when($filters['status'] ?? null, fn ($q, $v) => $q->where('status', $v))
            ->when($filters['plan_id'] ?? null, fn ($q, $v) => $q->where('requested_plan_id', $v))
            ->when($filters['date_from'] ?? null, fn ($q, $v) => $q->whereDate('requested_at', '>=', $v))
            ->when($filters['date_to'] ?? null, fn ($q, $v) => $q->whereDate('requested_at', '<=', $v));
    }

    /**
     * @param  array<string, mixed>  $filters
     * @return array<string, mixed>
     */
    public function subscriptionSummary(array $filters): array
    {
        $planDistribution = TenantSubscription::query()
            ->when($filters['tenant_id'] ?? null, fn ($q, $v) => $q->where('tenant_id', $v))
            ->join('subscription_plans', 'subscription_plans.id', '=', 'tenant_subscriptions.plan_id')
            ->selectRaw('subscription_plans.name as plan_name, count(*) as total')
            ->groupBy('subscription_plans.name')
            ->pluck('total', 'plan_name');

        $statusDistribution = TenantSubscription::query()
            ->when($filters['tenant_id'] ?? null, fn ($q, $v) => $q->where('tenant_id', $v))
            ->selectRaw('status, count(*) as total')->groupBy('status')->pluck('total', 'status');

        $changeQuery = $this->subscriptionQuery($filters);
        $approvals = (clone $changeQuery)->where('status', 'approved')->count();
        $rejections = (clone $changeQuery)->where('status', 'rejected')->count();
        $pending = (clone $changeQuery)->where('status', 'pending')->count();

        $storageAddonQuery = StorageAddon::when($filters['tenant_id'] ?? null, fn ($q, $v) => $q->where('tenant_id', $v))
            ->when($filters['date_from'] ?? null, fn ($q, $v) => $q->whereDate('created_at', '>=', $v))
            ->when($filters['date_to'] ?? null, fn ($q, $v) => $q->whereDate('created_at', '<=', $v));
        $storageAddonsRequested = (clone $storageAddonQuery)->count();
        $storageAddonsActive = (clone $storageAddonQuery)->where('status', 'active')->count();

        $mrr = (float) TenantSubscription::query()
            ->when($filters['tenant_id'] ?? null, fn ($q, $v) => $q->where('tenant_id', $v))
            ->join('subscription_plans', 'subscription_plans.id', '=', 'tenant_subscriptions.plan_id')
            ->where('tenant_subscriptions.status', 'active')
            ->sum('subscription_plans.monthly_price');

        return [
            'plan_distribution' => $planDistribution,
            'status_distribution' => $statusDistribution,
            'change_requests_approved' => $approvals,
            'change_requests_rejected' => $rejections,
            'change_requests_pending' => $pending,
            'storage_addons_requested' => $storageAddonsRequested,
            'storage_addons_active' => $storageAddonsActive,
            'monthly_recurring_revenue' => $mrr,
        ];
    }

    // ==================================================================
    // Business Growth
    // ==================================================================

    /**
     * @param  array<string, mixed>  $filters
     */
    public function businessGrowthQuery(array $filters): Builder
    {
        return Tenant::query()
            ->when($filters['status'] ?? null, fn ($q, $v) => $q->where('status', $v))
            ->when($filters['date_from'] ?? null, fn ($q, $v) => $q->whereDate('created_at', '>=', $v))
            ->when($filters['date_to'] ?? null, fn ($q, $v) => $q->whereDate('created_at', '<=', $v));
    }

    /**
     * @param  array<string, mixed>  $filters
     * @return array<string, mixed>
     */
    public function businessGrowthSummary(array $filters): array
    {
        $totalBusinesses = Tenant::count();
        $newInPeriod = (clone $this->businessGrowthQuery($filters))->count();
        $active = Tenant::where('status', 'active')->count();
        $suspended = Tenant::where('status', 'suspended')->count();

        [$dateFrom, $dateTo] = [$filters['date_from'] ?? null, $filters['date_to'] ?? null];
        $previousPeriodCount = null;
        if ($dateFrom && $dateTo) {
            $days = Carbon::parse($dateFrom)->diffInDays(Carbon::parse($dateTo)) + 1;
            $previousStart = Carbon::parse($dateFrom)->subDays($days)->toDateString();
            $previousEnd = Carbon::parse($dateFrom)->subDay()->toDateString();
            $previousPeriodCount = Tenant::whereDate('created_at', '>=', $previousStart)->whereDate('created_at', '<=', $previousEnd)->count();
        }

        return [
            'total_businesses' => $totalBusinesses,
            'new_businesses' => $newInPeriod,
            'active_businesses' => $active,
            'suspended_businesses' => $suspended,
            // No third tenant-account state exists yet (matches the
            // Dashboard's own established "inactive_accounts" gap) — never
            // fabricated here either.
            'inactive_businesses' => null,
            'previous_period_new_businesses' => $previousPeriodCount,
            'growth_change_pct' => ($previousPeriodCount !== null && $previousPeriodCount > 0)
                ? round((($newInPeriod - $previousPeriodCount) / $previousPeriodCount) * 100, 1)
                : null,
        ];
    }

    /**
     * @param  array<string, mixed>  $filters
     * @return array<int, array{label: string, value: float}>
     */
    public function businessGrowthTrend(array $filters): array
    {
        [$dateFrom, $dateTo] = [$filters['date_from'] ?? null, $filters['date_to'] ?? null];
        if (! $dateFrom || ! $dateTo) {
            return [];
        }

        return $this->periodSeries(Tenant::query(), 'created_at', $dateFrom, $dateTo, 'count');
    }

    // ==================================================================
    // Executive Overview
    // ==================================================================

    /**
     * @param  array<string, mixed>  $filters
     * @return array<string, mixed>
     */
    public function executiveOverview(array $filters): array
    {
        $debt = $this->debtRecoverySummary($filters);
        $debtor = $this->debtorRiskSummary($filters);
        $payment = $this->paymentSummary($filters);
        $pcr = $this->professionalCollectionSummary($filters);
        $subscription = $this->subscriptionSummary($filters);
        $growth = $this->businessGrowthSummary($filters);

        return [
            'total_businesses' => $growth['total_businesses'],
            'new_businesses' => $growth['new_businesses'],
            'total_debtors' => $debtor['total_debtors'],
            'total_debt_cases' => $debt['total_cases'],
            'outstanding_debt' => $debt['outstanding_debt'],
            'amount_recovered' => $debt['amount_recovered'],
            'recovery_rate' => $debt['recovery_rate'],
            'payment_count' => $payment['count'],
            'payment_total' => $payment['total_amount'],
            'professional_collection_total' => $pcr['total_requests'],
            'professional_collection_recovered' => $pcr['recovered_count'],
            'subscription_mrr' => $subscription['monthly_recurring_revenue'],
            'debt_trend' => $this->debtRecoveryTrend($filters),
        ];
    }

    // ==================================================================
    // Shared
    // ==================================================================

    /**
     * Groups a date-column-bearing aggregate by exact date at the SQL
     * level (portable across SQLite/Postgres — no driver-specific date-
     * format function, matching {@see ReportingService::collectionsTrend()}'s
     * own established convention), then re-buckets into monthly totals in
     * PHP when the selected range spans more than ~2 months — a rendering
     * choice (keeping a chart legible for "This Year"/"This Quarter"),
     * not a redefinition of any figure: every underlying sum/count is
     * still the exact same aggregate, just grouped at a coarser interval.
     *
     * @return array<int, array{label: string, value: float}>
     */
    private function periodSeries(Builder $query, string $dateColumn, string $dateFrom, string $dateTo, string $aggregate, ?string $sumColumn = null): array
    {
        $selectExpr = $aggregate === 'sum' ? "SUM({$sumColumn}) as agg_value" : 'COUNT(*) as agg_value';

        $rows = (clone $query)
            ->whereDate($dateColumn, '>=', $dateFrom)
            ->whereDate($dateColumn, '<=', $dateTo)
            ->selectRaw("{$dateColumn} as bucket_date, {$selectExpr}")
            ->groupBy($dateColumn)
            ->get()
            ->mapWithKeys(fn ($row) => [Carbon::parse($row->bucket_date)->toDateString() => (float) $row->agg_value]);

        $start = Carbon::parse($dateFrom)->startOfDay();
        $end = Carbon::parse($dateTo)->startOfDay();

        if ($start->diffInDays($end) <= 62) {
            $series = [];
            $cursor = $start->copy();
            while ($cursor->lte($end)) {
                $series[] = ['label' => $cursor->format('M j'), 'value' => $rows[$cursor->toDateString()] ?? 0.0];
                $cursor->addDay();
            }

            return $series;
        }

        $monthly = [];
        foreach ($rows as $date => $value) {
            $key = Carbon::parse($date)->format('Y-m');
            $monthly[$key] = ($monthly[$key] ?? 0.0) + $value;
        }
        ksort($monthly);

        return collect($monthly)->map(fn ($value, $key) => ['label' => Carbon::parse($key.'-01')->format('M Y'), 'value' => $value])->values()->all();
    }
}
