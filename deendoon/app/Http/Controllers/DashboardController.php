<?php

namespace App\Http\Controllers;

use App\Http\Resources\CollectionCaseResource;
use App\Models\CollectionCase;
use App\Services\BusinessHealthService;
use App\Services\ReminderService;
use App\Services\ReportingService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Illuminate\Validation\Rule;

/**
 * docs/Mobile_UI_V1_Frozen.md §4 (Home Dashboard). Sprint 6 —
 * presentation layer only: every KPI/aggregate value is computed by
 * ReportingService (Analytics) or reused as-is from ReminderService/
 * CollectionCaseResource; this controller performs no calculation of its
 * own, per this sprint's Dashboard Consistency Policy. Sprint 17B adds
 * Business Health (§4.1) on the same basis, computed by
 * BusinessHealthService.
 */
class DashboardController extends Controller
{
    use ApiResponse;

    public function __construct(
        private readonly ReportingService $reporting,
        private readonly ReminderService $reminders,
        private readonly BusinessHealthService $businessHealth,
    ) {}

    /**
     * §4.1: "Permissions: Visible to Business Owner" — narrower than
     * `kpis()`'s `view-dashboard` gate, which also admits the Deendoon
     * Platform Administrator's system-wide variant. Business Health has
     * no system-wide equivalent (it measures one tenant's portfolio), so
     * this reuses the existing `admin-only` gate (Business Owner only)
     * rather than defining a new, narrower gate that would duplicate it.
     *
     * Backend Completion Roadmap, Phase 4.4 — Feature & Read-Only
     * Enforcement, Product Owner Decision (2026-08-06, clarification):
     * "Business Health must remain available for all subscription plans,
     * including the Free Plan. Do NOT gate Business Health behind
     * analytics_enabled." `analytics_enabled` gates the Reporting module
     * (`view-analytics`) only — Business Health, `kpis()`,
     * `todaysOverview()`, and `recentCases()` are all explicitly plan-
     * independent. An earlier draft of this method briefly gated this
     * behind `view-analytics`; reverted per this clarification.
     */
    public function businessHealth(): JsonResponse
    {
        Gate::authorize('admin-only');

        return $this->successResponse($this->businessHealth->calculate());
    }

    public function kpis(Request $request): JsonResponse
    {
        Gate::authorize('view-dashboard');

        $request->validate([
            'period' => ['nullable', 'string', Rule::in(['day', 'week', 'month', 'year'])],
        ]);

        $kpis = $this->reporting->dashboardKpis($request->user(), $request->string('period')->value() ?: 'month');

        return $this->successResponse($kpis);
    }

    /**
     * §4.3: "reuses the Reminder Summary data documented in Section 6"
     * (Backend_v2.1_UI_Mapping.md §2) — identical computation
     * ReminderCenterController::summary() already exposes at §7.1, both
     * now calling the same ReminderService::summary() to avoid
     * duplicating the query.
     */
    public function todaysOverview(): JsonResponse
    {
        Gate::authorize('view-dashboard');

        return $this->successResponse($this->reminders->summary());
    }

    /**
     * §4.5: a small, most-recently-active-first preview of cases. No new
     * calculation — orders and limits the same CollectionCase data
     * already fully enriched by CollectionCaseResource in Sprint 2C
     * (customer_name, outstanding_amount, risk_level, last_activity_at).
     */
    public function recentCases(Request $request): JsonResponse
    {
        Gate::authorize('view-dashboard');

        $limit = $request->filled('limit') ? $request->integer('limit') : 5;

        $cases = CollectionCase::with(['debt.customer'])
            ->orderByDesc('updated_at')
            ->limit($limit)
            ->get();

        return $this->successResponse(CollectionCaseResource::collection($cases));
    }
}
