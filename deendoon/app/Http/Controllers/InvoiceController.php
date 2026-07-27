<?php

namespace App\Http\Controllers;

use App\Http\Requests\GenerateInvoiceRequest;
use App\Http\Resources\InvoiceResource;
use App\Models\Debt;
use App\Services\DocumentService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;

/**
 * Sprint 4.1. Mirrors DemandLetterController exactly: manual generation,
 * authorized via the existing Debt::generateDocuments ability (not a new
 * Invoice-specific ability) — the same reuse DemandLetterController and
 * StatementController already rely on.
 */
class InvoiceController extends Controller
{
    use ApiResponse;

    public function __construct(private readonly DocumentService $documents) {}

    public function store(GenerateInvoiceRequest $request, Debt $debt): JsonResponse
    {
        $this->authorize('generateDocuments', $debt);

        $invoice = $this->documents->generateInvoice($debt, $request->user());

        return $this->successResponse(new InvoiceResource($invoice), 'Invoice generated successfully', 201);
    }
}
