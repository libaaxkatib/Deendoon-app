<?php

namespace App\Traits;

use Illuminate\Http\JsonResponse;

trait ApiResponse
{
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
