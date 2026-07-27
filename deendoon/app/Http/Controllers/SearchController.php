<?php

namespace App\Http\Controllers;

use App\Http\Requests\SearchRequest;
use App\Http\Resources\CollectionCaseResource;
use App\Http\Resources\CustomerResource;
use App\Http\Resources\DebtResource;
use App\Http\Resources\DemandLetterResource;
use App\Http\Resources\PaymentResource;
use App\Http\Resources\ReceiptResource;
use App\Http\Resources\StatementResource;
use App\Services\SearchService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;

/**
 * FR-063 — Global Search. Reuses each entity's existing Resource class,
 * consistent with how every other module already shapes its responses.
 *
 * Sprint 7 audit note: this endpoint has no controller-level Gate check
 * by design — SearchService applies per-entity-type RBAC internally
 * (`$user->can('viewAny', ...)` per entity, see that class's docblock),
 * so a role without access to a given entity type gets that field
 * omitted from the response rather than a blanket 403. Confirmed via an
 * existing, still-passing test
 * (`test_customer_role_gets_no_results_for_any_entity_type`) before
 * concluding this was intentional, not a gap.
 */
class SearchController extends Controller
{
    use ApiResponse;

    public function __construct(private readonly SearchService $search) {}

    public function index(SearchRequest $request): JsonResponse
    {
        $results = $this->search->search($request->user(), $request->validated('q'), $request->boolean('includeArchived'));

        return $this->successResponse([
            'customers' => isset($results['customers']) ? CustomerResource::collection($results['customers']) : null,
            'debts' => isset($results['debts']) ? DebtResource::collection($results['debts']) : null,
            'payments' => isset($results['payments']) ? PaymentResource::collection($results['payments']) : null,
            'receipts' => isset($results['receipts']) ? ReceiptResource::collection($results['receipts']) : null,
            'demand_letters' => isset($results['demand_letters']) ? DemandLetterResource::collection($results['demand_letters']) : null,
            'statements' => isset($results['statements']) ? StatementResource::collection($results['statements']) : null,
            'collection_cases' => isset($results['collection_cases']) ? CollectionCaseResource::collection($results['collection_cases']) : null,
        ]);
    }
}
