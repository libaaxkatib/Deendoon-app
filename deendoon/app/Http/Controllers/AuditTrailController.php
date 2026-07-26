<?php

namespace App\Http\Controllers;

use App\Http\Resources\AuditLogResource;
use App\Models\AuditLog;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

/**
 * FR-071 — Audit Trail Viewing. Read-only; no write endpoint exists
 * anywhere (BR-030, immutability). Filters per FR-071 Main Flow step 3
 * (user, date range, module/entity, action type) — the same "shared
 * filter architecture" Module 11 (FR-064) already owns, applied here
 * rather than restated as new capability.
 */
class AuditTrailController extends Controller
{
    use ApiResponse;

    public function index(Request $request): JsonResponse
    {
        Gate::authorize('admin-only');

        $query = AuditLog::where('tenant_id', $request->user()->tenant_id);

        if ($userId = $request->string('user_id')->trim()->value()) {
            $query->where('user_id', $userId);
        }

        if ($entityType = $request->string('entity_type')->trim()->value()) {
            $query->where('entity_type', $entityType);
        }

        if ($action = $request->string('action')->trim()->value()) {
            $query->where('action', $action);
        }

        if ($request->filled('dateFrom')) {
            $query->whereDate('occurred_at', '>=', $request->date('dateFrom'));
        }

        if ($request->filled('dateTo')) {
            $query->whereDate('occurred_at', '<=', $request->date('dateTo'));
        }

        $logs = $query->orderBy('occurred_at', 'desc')->paginate(
            perPage: $this->perPage($request),
        );

        return $this->successResponse([
            'audit_trail' => AuditLogResource::collection($logs->items()),
            'pagination' => [
                'current_page' => $logs->currentPage(),
                'per_page' => $logs->perPage(),
                'total' => $logs->total(),
                'last_page' => $logs->lastPage(),
            ],
        ]);
    }
}
