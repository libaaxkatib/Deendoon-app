<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Customer;
use App\Models\Debt;
use App\Models\Payment;
use App\Models\ProfessionalCollectionRequest;
use App\Models\SubscriptionChangeRequest;
use App\Models\SubscriptionPlan;
use App\Models\Tenant;
use App\Services\Admin\AdminReportingService;
use App\Services\ReportExportService;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Collection as EloquentCollection;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;
use Illuminate\View\View;
use Symfony\Component\HttpFoundation\BinaryFileResponse;
use Symfony\Component\HttpFoundation\Response;

/**
 * Admin Panel — Reports & Analytics (Module 6). Thin controller: every
 * figure/query is computed by {@see AdminReportingService}; this class
 * only resolves request filters, picks a view, and — for
 * export/print — reuses the same generic export chain the tenant-facing
 * `ReportController` already established (`ReportExportService`,
 * `App\Exports\ReportExport`, `resources/views/reports/export.blade.php`)
 * rather than inventing a parallel one.
 */
class AdminReportController extends Controller
{
    /**
     * Same safety limit as the tenant-facing `ReportController` — a
     * filtered/full export is rejected rather than silently truncated
     * once it would exceed this many rows, so an export is always
     * complete and trustworthy. Kept as a literal duplicate of that
     * controller's own constant (same env var) rather than extracting a
     * shared helper for a three-line check.
     */
    private const DEFAULT_EXPORT_MAX_ROWS = 20000;

    public function __construct(
        private readonly AdminReportingService $reports,
        private readonly ReportExportService $exporter,
    ) {}

    public function overview(Request $request): View
    {
        $filters = $this->resolveFilters($request);

        return view('admin.reports.overview', [
            'title' => 'Reports & Analytics',
            'pageTitle' => 'Executive Overview',
            'data' => $this->reports->executiveOverview($filters),
        ] + $this->sharedViewData($filters));
    }

    public function debtRecovery(Request $request): View
    {
        $filters = $this->resolveFilters($request);

        return view('admin.reports.debt-recovery', [
            'title' => 'Reports & Analytics',
            'pageTitle' => 'Debt & Recovery Report',
            'summary' => $this->reports->debtRecoverySummary($filters),
            'trend' => $this->reports->debtRecoveryTrend($filters),
            'records' => $this->reports->debtRecoveryQuery($filters)->orderByDesc('created_at')->paginate(20)->withQueryString(),
            'statuses' => AdminDebtController::STATUSES,
            'stages' => AdminDebtController::RECOVERY_STAGE_LABELS,
        ] + $this->sharedViewData($filters));
    }

    public function debtorRisk(Request $request): View
    {
        $filters = $this->resolveFilters($request);

        return view('admin.reports.debtor-risk', [
            'title' => 'Reports & Analytics',
            'pageTitle' => 'Debtor Risk Report',
            'summary' => $this->reports->debtorRiskSummary($filters),
            'records' => $this->reports->debtorRiskQuery($filters)->orderByDesc('created_at')->paginate(20)->withQueryString(),
            'statuses' => AdminCustomerController::STATUSES,
            'riskLevels' => AdminCustomerController::RISK_LEVELS,
        ] + $this->sharedViewData($filters));
    }

    public function payments(Request $request): View
    {
        $filters = $this->resolveFilters($request);

        return view('admin.reports.payments', [
            'title' => 'Reports & Analytics',
            'pageTitle' => 'Payment Report',
            'summary' => $this->reports->paymentSummary($filters),
            'trend' => $this->reports->paymentTrend($filters),
            'records' => $this->reports->paymentQuery($filters)->orderByDesc('payment_date')->paginate(20)->withQueryString(),
            'paymentMethods' => $this->reports->paymentMethodOptions(),
        ] + $this->sharedViewData($filters));
    }

    public function professionalCollection(Request $request): View
    {
        $filters = $this->resolveFilters($request);

        return view('admin.reports.professional-collection', [
            'title' => 'Reports & Analytics',
            'pageTitle' => 'Professional Collection Report',
            'summary' => $this->reports->professionalCollectionSummary($filters),
            'trend' => $this->reports->professionalCollectionTrend($filters),
            'records' => $this->reports->professionalCollectionQuery($filters)->orderByDesc('created_at')->paginate(20)->withQueryString(),
            'statuses' => AdminProfessionalCollectionController::STATUS_LABELS,
        ] + $this->sharedViewData($filters));
    }

    public function subscriptions(Request $request): View
    {
        $filters = $this->resolveFilters($request);

        return view('admin.reports.subscriptions', [
            'title' => 'Reports & Analytics',
            'pageTitle' => 'Subscription Report',
            'summary' => $this->reports->subscriptionSummary($filters),
            'records' => $this->reports->subscriptionQuery($filters)->orderByDesc('requested_at')->paginate(20)->withQueryString(),
            'requestStatuses' => AdminSubscriptionController::REQUEST_STATUSES,
            'plans' => SubscriptionPlan::orderBy('name')->get(['id', 'name']),
        ] + $this->sharedViewData($filters));
    }

    public function businessGrowth(Request $request): View
    {
        $filters = $this->resolveFilters($request);

        return view('admin.reports.business-growth', [
            'title' => 'Reports & Analytics',
            'pageTitle' => 'Business Growth Report',
            'summary' => $this->reports->businessGrowthSummary($filters),
            'trend' => $this->reports->businessGrowthTrend($filters),
            'records' => $this->reports->businessGrowthQuery($filters)->orderByDesc('created_at')->paginate(20)->withQueryString(),
        ] + $this->sharedViewData($filters));
    }

    /**
     * `?scope=all` exports the complete dataset for the report (every
     * filter dropped except the report's own identity), matching the
     * approved "Export All Results" decision; anything else exports
     * exactly the currently-applied filters ("Export Current Results").
     */
    public function export(Request $request, string $report, string $format): BinaryFileResponse|Response
    {
        abort_unless(in_array($format, ['pdf', 'excel', 'csv'], true), 404);

        $filters = $request->string('scope')->value() === 'all' ? [] : $this->resolveFilters($request);
        $query = $this->reportQuery($report, $filters);

        $this->assertWithinExportLimit($query);

        [$headings, $rows] = $this->exportRowsFor($report, (clone $query)->get());

        return $this->exporter->export($format, $this->reportFilename($report), $headings, $rows);
    }

    public function print(Request $request, string $report): View
    {
        $filters = $this->resolveFilters($request);
        $query = $this->reportQuery($report, $filters);

        $this->assertWithinExportLimit($query);

        [$headings, $rows] = $this->exportRowsFor($report, (clone $query)->get());

        return view('reports.export', [
            'title' => $this->reportTitle($report),
            'headings' => $headings,
            'rows' => $rows,
            'autoPrint' => true,
        ]);
    }

    /**
     * @return array<string, mixed>
     */
    private function resolveFilters(Request $request): array
    {
        [$dateFrom, $dateTo] = $this->reports->resolveDateRange(
            $request->filled('period') ? $request->string('period')->value() : null,
            $request->filled('date_from') ? $request->string('date_from')->value() : null,
            $request->filled('date_to') ? $request->string('date_to')->value() : null,
        );

        return [
            'period' => $request->string('period')->value() ?: 'this_month',
            'date_from' => $dateFrom,
            'date_to' => $dateTo,
            'tenant_id' => $request->string('tenant_id')->value() ?: null,
            'status' => $request->string('status')->value() ?: null,
            'risk_level' => $request->string('risk_level')->value() ?: null,
            'plan_id' => $request->string('plan_id')->value() ?: null,
            'payment_method' => $request->string('payment_method')->value() ?: null,
            'recovery_stage' => $request->filled('recovery_stage') ? (int) $request->string('recovery_stage') : null,
        ];
    }

    /**
     * @return array<string, mixed>
     */
    private function sharedViewData(array $filters): array
    {
        return [
            'filters' => $filters,
            'periods' => [
                'today' => 'Today',
                'this_week' => 'This Week',
                'this_month' => 'This Month',
                'this_quarter' => 'This Quarter',
                'this_year' => 'This Year',
                'last_month' => 'Previous Month',
                'custom' => 'Custom Date Range',
            ],
            'tenants' => $this->reports->tenantOptions(),
        ];
    }

    private function reportQuery(string $report, array $filters): Builder
    {
        return match ($report) {
            'debt-recovery' => $this->reports->debtRecoveryQuery($filters),
            'debtor-risk' => $this->reports->debtorRiskQuery($filters),
            'payments' => $this->reports->paymentQuery($filters),
            'professional-collection' => $this->reports->professionalCollectionQuery($filters),
            'subscriptions' => $this->reports->subscriptionQuery($filters),
            'business-growth' => $this->reports->businessGrowthQuery($filters),
            default => abort(404),
        };
    }

    /**
     * @param  EloquentCollection<int, mixed>  $records
     * @return array{0: array<int, string>, 1: Collection<int, array<int, mixed>>}
     */
    private function exportRowsFor(string $report, EloquentCollection $records): array
    {
        return match ($report) {
            'debt-recovery' => [
                ['ID', 'Reference Number', 'Business', 'Debtor', 'Amount', 'Remaining Balance', 'Status', 'Recovery Stage', 'Due Date', 'Created At'],
                $records->map(fn (Debt $d) => [
                    $d->id, $d->reference_number, $d->customer?->tenant?->business_name, $d->customer?->name,
                    $d->amount, $d->remaining_balance, $d->debt_status, $d->recovery_stage,
                    $d->due_date?->toDateString(), $d->created_at->toDateString(),
                ]),
            ],
            'debtor-risk' => [
                ['ID', 'Name', 'Business', 'Status', 'Risk Level', 'Credit Score', 'Credit Score Band', 'Outstanding Balance'],
                $records->map(fn (Customer $c) => [
                    $c->id, $c->name, $c->tenant?->business_name, $c->customer_status,
                    $c->risk_level, $c->credit_score, $c->credit_score_band, $c->outstanding_balance,
                ]),
            ],
            'payments' => [
                ['ID', 'Business', 'Debtor', 'Debt Reference', 'Amount', 'Payment Date', 'Payment Method'],
                $records->map(fn (Payment $p) => [
                    $p->id, $p->debt?->customer?->tenant?->business_name, $p->debt?->customer?->name,
                    $p->debt?->reference_number, $p->amount, $p->payment_date->toDateString(), $p->payment_method,
                ]),
            ],
            'professional-collection' => [
                ['ID', 'Reference Number', 'Business', 'Status', 'Created At', 'Closed At'],
                $records->map(fn (ProfessionalCollectionRequest $r) => [
                    $r->id, $r->reference_number, $r->collectionCase?->debt?->customer?->tenant?->business_name,
                    $r->status, $r->created_at->toDateString(), $r->closed_at?->toDateString(),
                ]),
            ],
            'subscriptions' => [
                ['ID', 'Business', 'Current Plan', 'Requested Plan', 'Status', 'Requested At'],
                $records->map(fn (SubscriptionChangeRequest $r) => [
                    $r->id, $r->tenant?->business_name, $r->currentPlan?->name, $r->requestedPlan?->name,
                    $r->status, $r->requested_at?->toDateString(),
                ]),
            ],
            'business-growth' => [
                ['ID', 'Business Name', 'Status', 'Created At'],
                $records->map(fn (Tenant $t) => [$t->id, $t->business_name, $t->status, $t->created_at->toDateString()]),
            ],
            default => abort(404),
        };
    }

    private function reportTitle(string $report): string
    {
        return match ($report) {
            'debt-recovery' => 'Debt & Recovery Report',
            'debtor-risk' => 'Debtor Risk Report',
            'payments' => 'Payment Report',
            'professional-collection' => 'Professional Collection Report',
            'subscriptions' => 'Subscription Report',
            'business-growth' => 'Business Growth Report',
            default => abort(404),
        };
    }

    private function reportFilename(string $report): string
    {
        return $report.'-report';
    }

    private function assertWithinExportLimit(Builder $query): void
    {
        $maxRows = (int) env('REPORT_EXPORT_MAX_ROWS', self::DEFAULT_EXPORT_MAX_ROWS);

        if ((clone $query)->count() > $maxRows) {
            throw new HttpResponseException(back()->withErrors([
                'export' => "This export would include more than {$maxRows} rows. Narrow your filters or date range and try again.",
            ]));
        }
    }
}
