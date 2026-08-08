<?php

namespace App\Services;

use App\Models\CollectionCase;
use App\Models\Customer;
use App\Models\Debt;
use App\Models\Payment;
use App\Models\User;
use Illuminate\Support\Carbon;
use Illuminate\Support\Collection;

/**
 * FR-053/054 — pure read-only aggregation over data already owned by
 * Modules 2/3/6/7 (BRL-063: Reporting never stores an independent copy or
 * recalculates a value already defined elsewhere). "Open" Debt exclusions
 * reuse the exact definition already established by CustomerBalanceService
 * (debt_status NOT IN paid/cancelled/written_off) rather than inventing a
 * divergent one.
 */
class ReportingService
{
    private const CLOSED_DEBT_STATUSES = ['paid', 'cancelled', 'written_off'];

    public function __construct(
        private readonly BusinessHealthService $businessHealth,
        private readonly CollectionRateService $collectionRate,
    ) {}

    /**
     * BRL-059: the six resolved KPIs. Recovery Rate (DD-032, Business
     * Owner Backend Completion, Product Owner-approved formula) reuses the
     * exact same Collected ÷ Became Due calculation already implemented
     * for collectionAnalytics()'s Collection Rate — see
     * collectionRateFor(), the one shared implementation both call.
     *
     * FR-053: scoped to the user's own tenant, or system-wide for the
     * Deendoon Platform Administrator — the only actor FR-053 itself
     * names as warranting the system-wide variant (BR-042's existing,
     * bounded cross-tenant exception, not a new one). No other report in
     * this module extends that exception.
     *
     * Sprint 17B: `business_health` folds `BusinessHealthService::
     * calculate()`'s result into this same aggregated payload — the exact
     * same computation `GET /dashboard/business-health` (Logical Unit 2)
     * exposes on its own, not a second, divergent calculation.
     */
    public function dashboardKpis(User $user, string $period): array
    {
        $isPlatformAdmin = $user->tenant_id === null && $user->hasRole('deendoon_platform_administrator');

        $debts = $isPlatformAdmin ? Debt::withoutGlobalScope('tenant') : Debt::query();
        $customers = $isPlatformAdmin ? Customer::withoutGlobalScope('tenant') : Customer::query();
        $payments = $isPlatformAdmin ? Payment::withoutGlobalScope('tenant') : Payment::query();
        $cases = $isPlatformAdmin ? CollectionCase::withoutGlobalScope('tenant') : CollectionCase::query();

        [$periodStart, $periodEnd] = $this->periodBounds($period);

        $totalOutstanding = (clone $debts)->whereNotIn('debt_status', self::CLOSED_DEBT_STATUSES)->sum('remaining_balance');
        $totalCollected = (clone $payments)
            ->whereDate('payment_date', '>=', $periodStart)
            ->whereDate('payment_date', '<=', $periodEnd)
            ->sum('amount');
        $recoveryRate = $this->collectionRate->rateFor(clone $payments, clone $debts, $periodStart, $periodEnd);
        // FR-021 (Business Owner Backend Completion): computed via the
        // effective condition, not the raw stored debt_status column, so a
        // Debt that has never been individually viewed (and therefore
        // never had its status lazily flipped to 'overdue') still counts
        // here — see Debt::scopeEffectivelyOverdue().
        $overdueCount = (clone $debts)->effectivelyOverdue()->count();
        $overdueValue = (clone $debts)->effectivelyOverdue()->sum('remaining_balance');
        $customersOverLimit = (clone $customers)->whereColumn('outstanding_balance', '>', 'credit_limit')->count();
        $activeCases = (clone $cases)->where('case_status', '!=', 'closed')->count();

        // docs/Mobile_UI_V1_Frozen.md §4.2 High Risk Customers. Uses the
        // same `where('risk_level', 'high')->count()` predicate as
        // riskDistribution()'s 'high' segment — not a call to that method
        // directly, since riskDistribution() always builds a fresh,
        // auth-scoped Customer query and would silently return 0 for the
        // Platform Administrator's system-wide view instead of respecting
        // the withoutGlobalScope() already resolved above for $customers.
        $highRiskCustomers = (clone $customers)->where('risk_level', 'high')->count();

        return [
            'scope' => $isPlatformAdmin ? 'system' : 'tenant',
            'period' => $period,
            'total_outstanding_amount' => $this->money($totalOutstanding),
            'total_collected_period' => $this->money($totalCollected),
            'recovery_rate' => $recoveryRate,
            // `Mobile_UI_V1_Frozen.md` §4.1: "Visible to Business Owner"
            // only — Business Health has no system-wide definition (it
            // measures one tenant's portfolio), so the Deendoon Platform
            // Administrator's system-wide KPI view omits it entirely
            // rather than computing something meaningless, matching
            // `DashboardController::businessHealth()`'s own `admin-only`
            // restriction (Sprint 17B, Logical Unit 2).
            'business_health' => $isPlatformAdmin ? null : $this->businessHealth->calculate(),
            'high_risk_customers' => $highRiskCustomers,
            'total_overdue_debts' => [
                'count' => $overdueCount,
                'value' => $this->money($overdueValue),
            ],
            'customers_over_credit_limit' => $customersOverLimit,
            'active_collection_cases' => $activeCases,
        ];
    }

    /**
     * BRL-060: bucket = days between due_date and today, using Remaining
     * Balance (not original amount). $debts must already exclude
     * Paid/Cancelled/Written Off (closed or zero exposure).
     *
     * @param  Collection<int, Debt>  $debts
     * @return array<string, array{count: int, total_remaining_balance: string}>
     */
    public function agingBuckets(Collection $debts): array
    {
        $buckets = [
            'current' => ['count' => 0, 'total_remaining_balance' => '0.00'],
            '1_30' => ['count' => 0, 'total_remaining_balance' => '0.00'],
            '31_60' => ['count' => 0, 'total_remaining_balance' => '0.00'],
            '61_90' => ['count' => 0, 'total_remaining_balance' => '0.00'],
            'over_90' => ['count' => 0, 'total_remaining_balance' => '0.00'],
        ];

        $today = Carbon::today();

        foreach ($debts as $debt) {
            $bucket = $this->assignBucket($debt->due_date, $today);
            $buckets[$bucket]['count']++;
            $buckets[$bucket]['total_remaining_balance'] = bcadd($buckets[$bucket]['total_remaining_balance'], (string) $debt->remaining_balance, 2);
        }

        return $buckets;
    }

    public function assignBucket(string|Carbon $dueDate, ?Carbon $today = null): string
    {
        $today ??= Carbon::today();
        $due = Carbon::parse($dueDate)->startOfDay();

        if ($due->greaterThanOrEqualTo($today)) {
            return 'current';
        }

        $daysPastDue = $due->diffInDays($today);

        return match (true) {
            $daysPastDue <= 30 => '1_30',
            $daysPastDue <= 60 => '31_60',
            $daysPastDue <= 90 => '61_90',
            default => 'over_90',
        };
    }

    /**
     * docs/Mobile_UI_V1_Frozen.md §5.4 — the three explicitly-defined
     * formulas: Collection Rate = collected ÷ amount that became due in
     * the period (CollectionRateService::rateFor(), the same
     * implementation dashboardKpis()'s Recovery Rate KPI and
     * BusinessHealthService's Collection Performance input now reuse
     * under DD-032's Product Owner-approved decision — one formula, not
     * three competing ones); Total Collected = sum of period payments
     * (identical computation to dashboardKpis()'s total_collected_period —
     * reused, not recomputed independently); Average Days = mean days
     * between a debt's due date and the date it was fully paid, for debts
     * paid within the period.
     *
     * @return array{collection_rate: float, total_collected: string, average_days: float|null}
     */
    public function collectionAnalytics(string $dateFrom, string $dateTo): array
    {
        $totalCollected = Payment::whereDate('payment_date', '>=', $dateFrom)
            ->whereDate('payment_date', '<=', $dateTo)
            ->sum('amount');

        return [
            'collection_rate' => $this->collectionRate->rateFor(Payment::query(), Debt::query(), $dateFrom, $dateTo),
            'total_collected' => $this->money($totalCollected),
            'average_days' => $this->averageDaysToPay($dateFrom, $dateTo),
        ];
    }

    /**
     * No `paid_at` column exists on `debts`, so "the date it was fully
     * paid" is derived as the most recent payment date recorded against
     * each Paid debt — a debt only reaches 'paid' status once its
     * remaining_balance reaches zero, so its last payment is that date.
     * Uses Eloquent's withMax() (one aggregate query, no N+1) rather than
     * a per-debt lookup.
     */
    private function averageDaysToPay(string $dateFrom, string $dateTo): ?float
    {
        $paidDebts = Debt::where('debt_status', 'paid')
            ->withMax('payments', 'payment_date')
            ->get(['id', 'due_date'])
            ->filter(fn (Debt $debt) => $debt->payments_max_payment_date !== null
                && Carbon::parse($debt->payments_max_payment_date)->betweenIncluded($dateFrom, $dateTo));

        if ($paidDebts->isEmpty()) {
            return null;
        }

        $totalDays = $paidDebts->sum(
            fn (Debt $debt) => Carbon::parse($debt->due_date)->diffInDays(Carbon::parse($debt->payments_max_payment_date), false),
        );

        return round($totalDays / $paidDebts->count(), 1);
    }

    /**
     * docs/Mobile_UI_V1_Frozen.md §5.6 — count and percentage share of
     * active (non-archived) customers per risk classification. Customers
     * with no risk_level assigned yet are excluded from the percentage
     * base — §5.6 describes every active customer as already classified
     * into one of the three segments, so an unclassified customer has
     * nothing defined to be distributed into.
     *
     * @return array{segments: array<int, array{risk_level: string, customer_count: int, percentage: float}>}
     */
    public function riskDistribution(): array
    {
        $classified = Customer::whereNotNull('risk_level')->count();

        $segments = collect(['high', 'medium', 'low'])->map(function (string $level) use ($classified) {
            $count = Customer::where('risk_level', $level)->count();

            return [
                'risk_level' => $level,
                'customer_count' => $count,
                'percentage' => $classified > 0 ? round(($count / $classified) * 100, 2) : 0.0,
            ];
        })->all();

        return ['segments' => $segments];
    }

    /**
     * docs/Mobile_UI_V1_Frozen.md §5.3 — one data point per day across
     * the selected range. Scoped to the `collected_amount` metric only:
     * Payments are immutable historical records (payment_date/amount
     * never change once recorded), so a true day-by-day trend is
     * directly computable. `outstanding_amount` and `risk_concentration`
     * are both current-state-only fields (Debt.remaining_balance,
     * Customer.risk_level) with no point-in-time history retained
     * anywhere in the schema — computing a historical trend for either
     * would require inventing a backfill methodology or new tracking
     * infrastructure, neither of which this sprint is authorized to do.
     *
     * @return array{metric: string, series: array<int, array{date: string, value: string}>}
     */
    public function collectionsTrend(string $dateFrom, string $dateTo): array
    {
        // mapWithKeys, not pluck: Payment's `payment_date` cast turns the
        // raw grouped column into a Carbon instance on hydration, so a
        // plain pluck() key would not match a 'Y-m-d' string lookup below.
        $dailyTotals = Payment::whereDate('payment_date', '>=', $dateFrom)
            ->whereDate('payment_date', '<=', $dateTo)
            ->selectRaw('payment_date, SUM(amount) as total')
            ->groupBy('payment_date')
            ->get()
            ->mapWithKeys(fn ($row) => [Carbon::parse($row->payment_date)->toDateString() => $row->total]);

        $series = [];
        $cursor = Carbon::parse($dateFrom)->startOfDay();
        $end = Carbon::parse($dateTo)->startOfDay();

        while ($cursor->lte($end)) {
            $date = $cursor->toDateString();
            $series[] = ['date' => $date, 'value' => $this->money($dailyTotals[$date] ?? 0)];
            $cursor->addDay();
        }

        return ['metric' => 'collected_amount', 'series' => $series];
    }

    /**
     * BRL-061 (timezone/period boundaries) is unresolved (DD-034) — this
     * uses the application's own default timezone/date arithmetic, the
     * same posture every other date operation in this project already
     * takes, rather than inventing a specific policy.
     *
     * @return array{0: string, 1: string}
     */
    private function periodBounds(string $period): array
    {
        $now = now();

        $start = match ($period) {
            'day' => $now->copy()->startOfDay(),
            'week' => $now->copy()->startOfWeek(),
            'year' => $now->copy()->startOfYear(),
            default => $now->copy()->startOfMonth(),
        };

        return [$start->toDateString(), $now->toDateString()];
    }

    private function money(mixed $sum): string
    {
        return bcadd((string) $sum, '0', 2);
    }
}
