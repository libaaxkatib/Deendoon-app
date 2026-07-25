<?php

namespace App\Http\Controllers;

use App\Http\Requests\GenerateStatementRequest;
use App\Http\Resources\StatementResource;
use App\Models\Customer;
use App\Models\Debt;
use App\Services\DocumentService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;

class StatementController extends Controller
{
    use ApiResponse;

    public function __construct(private readonly DocumentService $documents) {}

    public function storeForCustomer(GenerateStatementRequest $request, Customer $customer): JsonResponse
    {
        $this->authorize('generateDocuments', $customer);

        $statement = $this->documents->generateStatement($customer, null, $request->user());

        return $this->successResponse(new StatementResource($statement), 'Statement of Account generated successfully', 201);
    }

    public function storeForDebt(GenerateStatementRequest $request, Debt $debt): JsonResponse
    {
        $this->authorize('generateDocuments', $debt);

        $statement = $this->documents->generateStatement($debt->customer, $debt, $request->user());

        return $this->successResponse(new StatementResource($statement), 'Statement of Account generated successfully', 201);
    }
}
