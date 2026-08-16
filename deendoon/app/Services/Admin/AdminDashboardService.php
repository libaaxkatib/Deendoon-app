<?php

namespace App\Services\Admin;

use App\Enums\AuditAction;
use App\Models\AuditLog;
use App\Models\Customer;
use App\Models\Debt;
use App\Models\Payment;
use App\Models\ProfessionalCollectionRequest;
use App\Models\Reminder;
use App\Models\Tenant;
use App\Models\TenantSubscription;
use App\Models\User;
use App\Services\ReportingService;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

/**
 * Admin Panel — Super Admin Dashboard (Product Owner-approved reference
 * design: two sections, "Business & Recovery" and "System / Platform").
 * Every figure here is computed from real data — nothing is hardcoded or
 * sample. Where no backend data source exists yet (documented per-field
 * below), the value is returned as `null` and the view renders an honest
 * "pending backend support" state rather than inventing a number, per
 * the explicit instruction not to remove approved UI for missing data.
 */
class AdminDashboardService
{
    public function __construct(private readonly ReportingService $reporting) {}

    /**
     * @return array<string, mixed>
     */
    public function businessAndRecovery(User $admin): array
    {
        $kpis = $this->reporting->dashboardKpis($admin, 'this_month');

        return [
            'total_businesses' => Tenant::count(),
            'total_debtors' => Customer::withoutGlobalScope('tenant')->count(),
            'total_debt_cases' => Debt::withoutGlobalScope('tenant')->count(),
            'outstanding_debt' => $kpis['total_outstanding_amount'],
            'amount_recovered' => $kpis['total_collected_period'],
            'recovery_rate' => $kpis['recovery_rate'],
            'overdue_debts' => $kpis['total_overdue_debts']['count'],
            'high_risk_debtors' => $kpis['high_risk_customers'],
            'recovery_performance' => $this->recoveryPerformanceByMonth(),
            'recent_activity' => $this->recentActivity(),
            'this_month' => $this->businessAndRecoveryThisMonth(),
            'platform_statistics' => $this->platformStatisticsOverall(),
        ];
    }

    /**
     * @return array<string, mixed>
     */
    public function systemAndPlatform(): array
    {
        $newRegistrationsThisMonth = Tenant::whereMonth('created_at', now()->month)
            ->whereYear('created_at', now()->year)
            ->count();
        $newRegistrationsLastMonth = Tenant::whereMonth('created_at', now()->subMonthNoOverflow()->month)
            ->whereYear('created_at', now()->subMonthNoOverflow()->year)
            ->count();

        return [
            'new_registrations_this_month' => $newRegistrationsThisMonth,
            'new_registrations_vs_last_month_pct' => $this->percentChange($newRegistrationsLastMonth, $newRegistrationsThisMonth),
            'active_accounts' => Tenant::where('status', 'active')->count(),
            'suspended_accounts' => Tenant::where('status', 'suspended')->count(),
            // No third tenant-account state exists yet ("inactive" would
            // need a real definition — e.g. "no login in N days" — which
            // needs login-timestamp tracking that doesn't exist today).
            'inactive_accounts' => null,
            'subscription_overview' => $this->subscriptionOverview(),
            'monthly_recurring_revenue' => $this->monthlyRecurringRevenue(),
            // No time-series event log for "reminder sent" exists (Reminder
            // only stores its own current state, not a sent-history log).
            'system_usage_trend' => null,
            'recent_logins_today' => AuditLog::where('action', 'login')->whereDate('occurred_at', today())->count(),
            // No support-ticket system exists yet (Decision: Support
            // Tickets + Phone + WhatsApp + Email) — module not built.
            'support_requests' => null,
            'system_health' => $this->systemHealth(),
        ];
    }

    private function recoveryPerformanceByMonth(int $months = 5): array
    {
        $rows = [];

        for ($i = $months - 1; $i >= 0; $i--) {
            $month = now()->subMonthsNoOverflow($i);
            $assigned = Debt::withoutGlobalScope('tenant')
                ->whereMonth('created_at', $month->month)
                ->whereYear('created_at', $month->year)
                ->sum('amount');
            $recovered = Payment::withoutGlobalScope('tenant')
                ->whereMonth('payment_date', $month->month)
                ->whereYear('payment_date', $month->year)
                ->sum('amount');

            $rows[] = [
                'label' => $month->format('M'),
                'debt_assigned' => (float) $assigned,
                'amount_recovered' => (float) $recovered,
                'recovery_rate' => $assigned > 0 ? round(($recovered / $assigned) * 100, 1) : 0.0,
            ];
        }

        return $rows;
    }

    /**
     * Every {@see AuditAction} case, mapped to a human-readable
     * phrase for the Recent Activity feed — a raw DB action token (e.g.
     * `credit_score_recalculated`) must never reach this UI. `:entity` is
     * replaced with the humanized `entity_type` where the phrase's meaning
     * depends on it (see {@see activityLabel()}); most actions don't need
     * it since the phrase is already unambiguous on its own.
     *
     * @var array<string, string>
     */
    private const ACTION_LABELS = [
        'created' => 'New :entity Recorded',
        'edited' => ':entity Updated',
        'archived' => ':entity Archived',
        'restored' => ':entity Restored',
        'status_changed' => ':entity Status Changed',
        'reminder_sent' => 'Reminder Sent',
        'payment_added' => 'Payment Recorded',
        'collection_requested' => 'Collection Requested',
        'login' => 'User Signed In',
        'logout' => 'User Signed Out',
        'role_changed' => 'Role Changed',
        'credit_limit_changed' => 'Credit Limit Changed',
        'credit_score_recalculated' => 'Credit Score Recalculated',
        'demand_letter_generated' => 'Demand Letter Generated',
        'receipt_generated' => 'Receipt Generated',
        'statement_generated' => 'Statement Generated',
        'invoice_generated' => 'Invoice Generated',
        'recovery_stage_override' => 'Recovery Stage Manually Updated',
        'professional_collection_request_submitted' => 'Professional Collection Request Submitted',
        'professional_collection_request_status_changed' => 'Professional Collection Request Updated',
        'risk_level_recalculated' => 'Risk Level Recalculated',
        'subscription_upgrade_requested' => 'Subscription Upgrade Requested',
        'storage_addon_requested' => 'Storage Add-on Requested',
        'trial_expired' => 'Trial Expired',
        'subscription_expired' => 'Subscription Expired',
        'trial_provisioned' => 'Trial Provisioned',
        'customer_read_only_recalculated' => 'Customer Read-Only Status Recalculated',
        'subscription_change_request_status_changed' => 'Subscription Change Request Updated',
        'storage_addon_status_changed' => 'Storage Add-on Status Updated',
    ];

    /**
     * @return array<int, array{action: string, business: ?string, occurred_at: Carbon}>
     */
    private function recentActivity(int $limit = 8): array
    {
        return AuditLog::with('tenant')
            ->orderByDesc('occurred_at')
            ->limit($limit)
            ->get()
            ->map(fn (AuditLog $log) => [
                'action' => $this->activityLabel($log),
                'business' => $log->tenant?->business_name,
                'occurred_at' => $log->occurred_at,
            ])
            ->all();
    }

    /**
     * Humanizes an audit entry into a display phrase. Never returns a raw
     * DB token: `entity_type` is free-form (no enum backs it), so it's
     * title-cased generically rather than matched against a fixed list —
     * covers entity types not yet in use with no maintenance burden.
     */
    private function activityLabel(AuditLog $log): string
    {
        $entity = ucwords(str_replace('_', ' ', $log->entity_type));
        $template = self::ACTION_LABELS[$log->action] ?? ucwords(str_replace('_', ' ', $log->action));

        return str_replace(':entity', $entity, $template);
    }

    private function businessAndRecoveryThisMonth(): array
    {
        $month = now()->month;
        $year = now()->year;

        $debtRegistered = (float) Debt::withoutGlobalScope('tenant')
            ->whereMonth('created_at', $month)->whereYear('created_at', $year)
            ->sum('amount');
        $amountRecovered = (float) Payment::withoutGlobalScope('tenant')
            ->whereMonth('payment_date', $month)->whereYear('payment_date', $year)
            ->sum('amount');

        return [
            'new_businesses' => Tenant::whereMonth('created_at', $month)->whereYear('created_at', $year)->count(),
            'new_debtors' => Customer::withoutGlobalScope('tenant')
                ->whereMonth('created_at', $month)->whereYear('created_at', $year)->count(),
            'new_debt_cases' => Debt::withoutGlobalScope('tenant')
                ->whereMonth('created_at', $month)->whereYear('created_at', $year)->count(),
            'debt_registered' => $debtRegistered,
            'amount_recovered' => $amountRecovered,
            'recovery_rate' => $debtRegistered > 0 ? round(($amountRecovered / $debtRegistered) * 100, 1) : 0.0,
            'professional_collection_requests' => ProfessionalCollectionRequest::whereMonth('created_at', $month)
                ->whereYear('created_at', $year)->count(),
            'cases_recovered' => ProfessionalCollectionRequest::where('status', 'recovered')
                ->whereMonth('updated_at', $month)->whereYear('updated_at', $year)->count(),
        ];
    }

    private function platformStatisticsOverall(): array
    {
        return [
            'total_businesses' => Tenant::count(),
            'total_debtors' => Customer::withoutGlobalScope('tenant')->count(),
            'total_debt_cases' => Debt::withoutGlobalScope('tenant')->count(),
            'total_debt_value' => (float) Debt::withoutGlobalScope('tenant')->sum('amount'),
            'total_recovered' => (float) Payment::withoutGlobalScope('tenant')->sum('amount'),
            'total_active_users' => User::where('status', 'active')->count(),
            'total_documents' => null, // 4 separate document tables (Receipt/DemandLetter/Statement/Invoice) — see note below.
            'total_reminders' => Reminder::withoutGlobalScope('tenant')->count(),
            'total_payments' => Payment::withoutGlobalScope('tenant')->count(),
            'total_professional_collection_requests' => ProfessionalCollectionRequest::count(),
        ];
    }

    private function subscriptionOverview(): array
    {
        $rows = TenantSubscription::query()
            ->join('subscription_plans', 'subscription_plans.id', '=', 'tenant_subscriptions.plan_id')
            ->selectRaw('subscription_plans.name as plan_name, subscription_plans.monthly_price as monthly_price, count(*) as tenant_count')
            ->groupBy('subscription_plans.name', 'subscription_plans.monthly_price')
            ->orderByDesc('tenant_count')
            ->get();

        $total = (int) $rows->sum('tenant_count');

        return [
            'total' => $total,
            'plans' => $rows->map(fn ($row) => [
                'name' => $row->plan_name,
                'monthly_price' => (float) $row->monthly_price,
                'count' => (int) $row->tenant_count,
                'percentage' => $total > 0 ? round(($row->tenant_count / $total) * 100, 1) : 0.0,
            ])->all(),
        ];
    }

    private function monthlyRecurringRevenue(): float
    {
        return (float) TenantSubscription::query()
            ->join('subscription_plans', 'subscription_plans.id', '=', 'tenant_subscriptions.plan_id')
            ->where('tenant_subscriptions.status', 'active')
            ->sum('subscription_plans.monthly_price');
    }

    /**
     * Basic V1 (Product Owner decision — expandable later). Live checks,
     * not hardcoded "Operational" labels for Database/File Storage;
     * Application/API remain honestly hardcoded `true` — no real check
     * backs them yet (see the module's own docblock for why).
     *
     * Visibility widened to `public` (Module 8 — System Management) so
     * `AdminSystemController` can reuse this exact array shape on its own
     * System Health page instead of duplicating it — no behavior change,
     * the Dashboard's own use of it is untouched.
     *
     * @return array<int, array{name: string, operational: bool}>
     */
    public function systemHealth(): array
    {
        $databaseOk = $this->checkDatabase();
        $storageOk = $this->checkFileStorage();

        return [
            ['name' => 'Application', 'operational' => true],
            ['name' => 'Database', 'operational' => $databaseOk],
            ['name' => 'API', 'operational' => true],
            ['name' => 'File Storage', 'operational' => $storageOk],
        ];
    }

    private function checkDatabase(): bool
    {
        try {
            DB::connection()->getPdo();

            return true;
        } catch (\Throwable) {
            return false;
        }
    }

    private function checkFileStorage(): bool
    {
        try {
            return Storage::disk('local')->exists('');
        } catch (\Throwable) {
            return false;
        }
    }

    private function percentChange(int $previous, int $current): ?float
    {
        if ($previous === 0) {
            return $current > 0 ? 100.0 : 0.0;
        }

        return round((($current - $previous) / $previous) * 100, 1);
    }
}
