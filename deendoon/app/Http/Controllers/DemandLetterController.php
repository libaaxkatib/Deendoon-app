<?php

namespace App\Http\Controllers;

use App\Enums\DemandLetterTemplate;
use App\Http\Requests\GenerateDemandLetterRequest;
use App\Http\Resources\DemandLetterResource;
use App\Models\Debt;
use App\Services\DocumentService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;

class DemandLetterController extends Controller
{
    use ApiResponse;

    public function __construct(private readonly DocumentService $documents) {}

    public function store(GenerateDemandLetterRequest $request, Debt $debt): JsonResponse
    {
        $this->authorize('generateDocuments', $debt);

        $demandLetter = $this->documents->generateDemandLetter(
            $debt,
            DemandLetterTemplate::from($request->validated('template_type')),
            $request->user(),
        );

        return $this->successResponse(new DemandLetterResource($demandLetter), 'Demand Letter generated successfully', 201);
    }
}
