<?php

namespace App\Traits;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

trait ApiResponse
{
    /**
     * 07_API_Design.md §8: "Maximum value [for perPage]: same open item as
     * above" — the API's own maximum-page-size question is explicitly left
     * to "a sensible implementation default." This is that default: bounds
     * an otherwise-unbounded client-supplied `perPage` without changing
     * behavior for any request already within a reasonable range (the
     * existing default of 15 is untouched).
     */
    protected function perPage(Request $request, int $default = 15, int $max = 100): int
    {
        return max(1, min($request->integer('perPage', $default), $max));
    }

    protected function successResponse(mixed $data = null, string $message = '', int $statusCode = 200): JsonResponse
    {
        return $this->buildResponse(
            success: true,
            message: $message,
            data: $data,
            errors: null,
            statusCode: $statusCode,
        );
    }

    protected function errorResponse(string $message, mixed $errors = null, int $statusCode = 422): JsonResponse
    {
        return $this->buildResponse(
            success: false,
            message: $message,
            data: null,
            errors: $errors,
            statusCode: $statusCode,
        );
    }

    private function buildResponse(bool $success, string $message, mixed $data, mixed $errors, int $statusCode): JsonResponse
    {
        return response()->json([
            'success' => $success,
            'message' => $message,
            'data' => $data,
            'errors' => $errors,
        ], $statusCode);
    }
}
