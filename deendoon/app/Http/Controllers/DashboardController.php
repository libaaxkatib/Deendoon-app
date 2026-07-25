<?php

namespace App\Http\Controllers;

use App\Services\ReportingService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Illuminate\Validation\Rule;

class DashboardController extends Controller
{
    use ApiResponse;

    public function __construct(private readonly ReportingService $reporting) {}

    public function kpis(Request $request): JsonResponse
    {
        Gate::authorize('view-dashboard');

        $request->validate([
            'period' => ['nullable', 'string', Rule::in(['day', 'week', 'month', 'year'])],
        ]);

        $kpis = $this->reporting->dashboardKpis($request->user(), $request->string('period')->value() ?: 'month');

        return $this->successResponse($kpis);
    }
}
