<?php

namespace App\Http\Controllers;

use App\Http\Resources\ReceiptResource;
use App\Models\Receipt;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;

/**
 * FR-047: a Receipt is auto-generated only (Module 6, via DocumentService)
 * — never created through this API directly.
 */
class ReceiptController extends Controller
{
    use ApiResponse;

    public function show(Receipt $receipt): JsonResponse
    {
        $this->authorize('view', $receipt);

        return $this->successResponse(new ReceiptResource($receipt));
    }
}
