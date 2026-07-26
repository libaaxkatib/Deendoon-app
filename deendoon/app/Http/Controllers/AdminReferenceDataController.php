<?php

namespace App\Http\Controllers;

use App\Enums\ReferenceDataCategory;
use App\Http\Requests\UpdateReferenceDataRequest;
use App\Http\Resources\ReferenceDataResource;
use App\Services\ReferenceDataService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

/**
 * FR-070 — Lookup & Reference Data. Category is validated against the
 * three approved values (06 §6.8's CHECK constraint) rather than accepted
 * as free text, since extending it "speculatively" is explicitly
 * disallowed by that constraint's own note.
 */
class AdminReferenceDataController extends Controller
{
    use ApiResponse;

    public function __construct(private readonly ReferenceDataService $referenceData) {}

    public function show(Request $request, string $category): JsonResponse
    {
        Gate::authorize('admin-only');

        $categoryEnum = $this->resolveCategory($category);

        return $this->successResponse(
            ReferenceDataResource::collection($this->referenceData->forCategory($request->user()->tenant_id, $categoryEnum)),
        );
    }

    public function update(UpdateReferenceDataRequest $request, string $category): JsonResponse
    {
        Gate::authorize('admin-only');

        $categoryEnum = $this->resolveCategory($category);

        $values = $this->referenceData->updateCategory(
            $request->user()->tenant_id,
            $categoryEnum,
            $request->validated('values'),
            $request->user(),
        );

        return $this->successResponse(ReferenceDataResource::collection($values), 'Reference Data updated successfully');
    }

    private function resolveCategory(string $category): ReferenceDataCategory
    {
        $categoryEnum = ReferenceDataCategory::tryFrom($category);

        abort_unless($categoryEnum, 404, 'Unknown reference data category.');

        return $categoryEnum;
    }
}
