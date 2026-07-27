<?php

namespace App\Http\Controllers;

use App\Http\Requests\ExportReportRequest;
use App\Http\Resources\CollectionCaseResource;
use App\Http\Resources\CustomerResource;
use App\Http\Resources\DebtResource;
use App\Http\Resources\PaymentResource;
use App\Models\CollectionCase;
use App\Models\Customer;
use App\Models\Debt;
use App\Models\Payment;
use App\Services\ReportExportService;
use App\Services\ReportingService;
use App\Traits\ApiResponse;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Collection as EloquentCollection;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Gate;
use Symfony\Component\HttpFoundation\BinaryFileResponse;
use Symfony\Component\HttpFoundation\Response;

/**
 * FR-054/055/056/057 — read-only reporting over data owned by Modules
 * 2/3/6/7 (Scope Boundary: "never computes new business state... never
 * becomes the system of record"). Every report reuses the existing
 * Resource class already built for its entity (CustomerResource,
 * DebtResource, CollectionCaseResource, PaymentResource) rather than
 * inventing a parallel report-specific shape (BRL-063).
 */
class ReportController extends Controller
{
    use ApiResponse;

    private const CLOSED_DEBT_STATUSES = ['paid', 'cancelled', 'written_off'];

    public function __construct(
        private readonly ReportingService $reporting,
        private readonly ReportExportService $exporter,
    ) {}

    /**
     * FR-054/BRL-060. Buckets are computed over every open Debt matching
     * the applied filters (not just the current page), so bucket totals
     * are always accurate regardless of pagination.
     */
    public function agingAnalysis(Request $request): JsonResponse
    {
        Gate::authorize('view-reports');

        $query = $this->agingAnalysisQuery($request);

        $buckets = $this->reporting->agingBuckets((clone $query)->get());

        $debts = $query->orderBy('due_date')->paginate(perPage: $this->perPage($request));

        $debtsWithBucket = collect($debts->items())->map(function (Debt $debt) {
            $resource = (new DebtResource($debt))->resolve();
            $resource['aging_bucket'] = $this->reporting->assignBucket($debt->due_date);

            return $resource;
        });

        return $this->successResponse([
            'buckets' => $buckets,
            'debts' => $debtsWithBucket,
            'pagination' => $this->paginationMeta($debts),
        ]);
    }

    public function customers(Request $request): JsonResponse
    {
        Gate::authorize('view-reports');

        $customers = $this->customersQuery($request)->orderBy('name')->paginate(perPage: $this->perPage($request));

        return $this->successResponse([
            'customers' => CustomerResource::collection($customers->items()),
            'pagination' => $this->paginationMeta($customers),
        ]);
    }

    public function debts(Request $request): JsonResponse
    {
        Gate::authorize('view-reports');

        $debts = $this->debtsQuery($request)->orderBy('due_date')->paginate(perPage: $this->perPage($request));

        return $this->successResponse([
            'debts' => DebtResource::collection($debts->items()),
            'pagination' => $this->paginationMeta($debts),
        ]);
    }

    public function collectionCases(Request $request): JsonResponse
    {
        Gate::authorize('view-reports');

        $cases = $this->collectionCasesQuery($request)->orderBy('created_at', 'desc')->paginate(perPage: $this->perPage($request));

        return $this->successResponse([
            'collection_cases' => CollectionCaseResource::collection($cases->items()),
            'pagination' => $this->paginationMeta($cases),
        ]);
    }

    public function payments(Request $request): JsonResponse
    {
        Gate::authorize('view-reports');

        $payments = $this->paymentsQuery($request)->orderBy('payment_date', 'desc')->paginate(perPage: $this->perPage($request));

        return $this->successResponse([
            'payments' => PaymentResource::collection($payments->items()),
            'pagination' => $this->paginationMeta($payments),
        ]);
    }

    /**
     * FR-055: Credit Risk data is Customer's own risk_level/credit_score
     * fields (Module 4), not a separate entity — reuses the identical
     * Customer query/Resource as the Customers report, per BRL-063.
     */
    public function creditRisk(Request $request): JsonResponse
    {
        Gate::authorize('view-reports');

        $customers = $this->customersQuery($request)->orderByDesc('credit_score')->paginate(perPage: $this->perPage($request));

        return $this->successResponse([
            'customers' => CustomerResource::collection($customers->items()),
            'pagination' => $this->paginationMeta($customers),
        ]);
    }

    /**
     * docs/Mobile_UI_V1_Frozen.md §5.4. Defaults to the current calendar
     * month, consistent with dashboardKpis()'s own period defaulting.
     */
    public function collectionAnalytics(Request $request): JsonResponse
    {
        Gate::authorize('view-reports');

        [$dateFrom, $dateTo] = $this->dateRangeOrDefault($request);

        return $this->successResponse($this->reporting->collectionAnalytics($dateFrom, $dateTo));
    }

    /**
     * docs/Mobile_UI_V1_Frozen.md §5.6.
     */
    public function riskDistribution(): JsonResponse
    {
        Gate::authorize('view-reports');

        return $this->successResponse($this->reporting->riskDistribution());
    }

    /**
     * docs/Mobile_UI_V1_Frozen.md §5.3 — `collected_amount` only; see
     * ReportingService::collectionsTrend()'s docblock for why
     * `outstanding_amount`/`risk_concentration` are not implemented here.
     */
    public function collectionsTrend(Request $request): JsonResponse
    {
        Gate::authorize('view-reports');

        $request->validate([
            'dateFrom' => ['required', 'date'],
            'dateTo' => ['required', 'date', 'after_or_equal:dateFrom'],
            'metric' => ['required', 'string', 'in:collected_amount'],
        ]);

        return $this->successResponse(
            $this->reporting->collectionsTrend($request->date('dateFrom')->toDateString(), $request->date('dateTo')->toDateString()),
        );
    }

    /**
     * @return array{0: string, 1: string}
     */
    private function dateRangeOrDefault(Request $request): array
    {
        if ($request->filled('dateFrom') && $request->filled('dateTo')) {
            return [$request->date('dateFrom')->toDateString(), $request->date('dateTo')->toDateString()];
        }

        return [now()->startOfMonth()->toDateString(), now()->toDateString()];
    }

    /**
     * FR-057/BRL-062: exports exactly the same filtered dataset the
     * corresponding GET endpoint would return — unpaginated (a full
     * export, not just the current page) but under the same filters.
     */
    public function export(ExportReportRequest $request, string $reportType): BinaryFileResponse|Response
    {
        Gate::authorize('view-reports');

        [$headings, $rows] = match ($reportType) {
            'aging-analysis' => $this->exportRows(
                $this->agingAnalysisQuery($request)->orderBy('due_date')->get(),
                ['ID', 'Reference Number', 'Amount', 'Remaining Balance', 'Due Date', 'Status', 'Aging Bucket'],
                fn (Debt $debt) => [$debt->id, $debt->reference_number, $debt->amount, $debt->remaining_balance, $debt->due_date->toDateString(), $debt->debt_status, $this->reporting->assignBucket($debt->due_date)],
            ),
            'customers' => $this->exportRows(
                $this->customersQuery($request)->orderBy('name')->get(),
                ['ID', 'Name', 'Phone', 'Status', 'Credit Limit', 'Outstanding Balance', 'Risk Level', 'Credit Score'],
                fn (Customer $c) => [$c->id, $c->name, $c->phone, $c->customer_status, $c->credit_limit, $c->outstanding_balance, $c->risk_level, $c->credit_score],
            ),
            'debts' => $this->exportRows(
                $this->debtsQuery($request)->orderBy('due_date')->get(),
                ['ID', 'Reference Number', 'Amount', 'Remaining Balance', 'Due Date', 'Status', 'Recovery Stage'],
                fn (Debt $d) => [$d->id, $d->reference_number, $d->amount, $d->remaining_balance, $d->due_date->toDateString(), $d->debt_status, $d->recovery_stage],
            ),
            'collection-cases' => $this->exportRows(
                $this->collectionCasesQuery($request)->orderBy('created_at')->get(),
                ['ID', 'Reference Number', 'Debt ID', 'Status', 'Closure Outcome', 'Assigned Officer'],
                fn (CollectionCase $c) => [$c->id, $c->reference_number, $c->debt_id, $c->case_status, $c->closure_outcome, $c->assigned_officer_user_id],
            ),
            'payments' => $this->exportRows(
                $this->paymentsQuery($request)->orderBy('payment_date')->get(),
                ['ID', 'Debt ID', 'Amount', 'Payment Date', 'Payment Method'],
                fn (Payment $p) => [$p->id, $p->debt_id, $p->amount, $p->payment_date->toDateString(), $p->payment_method],
            ),
            'credit-risk' => $this->exportRows(
                $this->customersQuery($request)->orderByDesc('credit_score')->get(),
                ['ID', 'Name', 'Risk Level', 'Credit Score'],
                fn (Customer $c) => [$c->id, $c->name, $c->risk_level, $c->credit_score],
            ),
            default => abort(404),
        };

        return $this->exporter->export($request->validated('format'), $reportType, $headings, $rows);
    }

    private function agingAnalysisQuery(Request $request): Builder
    {
        $query = Debt::query()->whereNotIn('debt_status', self::CLOSED_DEBT_STATUSES);

        if ($customerId = $request->string('customer_id')->trim()->value()) {
            $query->where('customer_id', $customerId);
        }

        if ($request->filled('dateFrom')) {
            $query->whereDate('due_date', '>=', $request->date('dateFrom'));
        }

        if ($request->filled('dateTo')) {
            $query->whereDate('due_date', '<=', $request->date('dateTo'));
        }

        return $query;
    }

    private function customersQuery(Request $request): Builder
    {
        $query = Customer::query();

        if ($request->boolean('includeArchived')) {
            $query->withTrashed();
        }

        if ($status = $request->string('customer_status')->trim()->value()) {
            $query->where('customer_status', $status);
        }

        if ($riskLevel = $request->string('riskLevel')->trim()->value()) {
            $query->where('risk_level', $riskLevel);
        }

        if ($request->filled('creditScoreMin')) {
            $query->where('credit_score', '>=', $request->integer('creditScoreMin'));
        }

        if ($request->filled('creditScoreMax')) {
            $query->where('credit_score', '<=', $request->integer('creditScoreMax'));
        }

        if ($request->filled('outstandingAmountMin')) {
            $query->where('outstanding_balance', '>=', $request->input('outstandingAmountMin'));
        }

        if ($request->filled('outstandingAmountMax')) {
            $query->where('outstanding_balance', '<=', $request->input('outstandingAmountMax'));
        }

        return $query;
    }

    private function debtsQuery(Request $request): Builder
    {
        $query = Debt::query();

        if ($request->boolean('includeArchived')) {
            $query->withTrashed();
        }

        if ($customerId = $request->string('customer_id')->trim()->value()) {
            $query->where('customer_id', $customerId);
        }

        if ($status = $request->string('status')->trim()->value()) {
            $query->where('debt_status', $status);
        }

        if ($request->filled('recoveryStage')) {
            $query->where('recovery_stage', $request->integer('recoveryStage'));
        }

        if ($request->filled('dateFrom')) {
            $query->whereDate('due_date', '>=', $request->date('dateFrom'));
        }

        if ($request->filled('dateTo')) {
            $query->whereDate('due_date', '<=', $request->date('dateTo'));
        }

        if ($request->filled('outstandingAmountMin')) {
            $query->where('remaining_balance', '>=', $request->input('outstandingAmountMin'));
        }

        if ($request->filled('outstandingAmountMax')) {
            $query->where('remaining_balance', '<=', $request->input('outstandingAmountMax'));
        }

        return $query;
    }

    private function collectionCasesQuery(Request $request): Builder
    {
        $query = CollectionCase::query();

        if ($status = $request->string('status')->trim()->value()) {
            $query->where('case_status', $status);
        }

        return $query;
    }

    private function paymentsQuery(Request $request): Builder
    {
        $query = Payment::query();

        if ($debtId = $request->string('debt_id')->trim()->value()) {
            $query->where('debt_id', $debtId);
        }

        if ($request->filled('dateFrom')) {
            $query->whereDate('payment_date', '>=', $request->date('dateFrom'));
        }

        if ($request->filled('dateTo')) {
            $query->whereDate('payment_date', '<=', $request->date('dateTo'));
        }

        return $query;
    }

    /**
     * @return array{0: array<int, string>, 1: Collection<int, array<int, mixed>>}
     */
    private function exportRows(EloquentCollection $records, array $headings, callable $mapper): array
    {
        return [$headings, $records->map($mapper)];
    }

    private function paginationMeta($paginator): array
    {
        return [
            'current_page' => $paginator->currentPage(),
            'per_page' => $paginator->perPage(),
            'total' => $paginator->total(),
            'last_page' => $paginator->lastPage(),
        ];
    }
}
