<?php

namespace App\Http\Controllers;

use App\Models\Customer;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;

/**
 * Module 4 — Credit & Risk Intelligence (FR-026-028).
 *
 * FR-026's scoring engine is CreditScoreService (Business Owner Backend
 * Completion, pre-Phase 5, Product Owner-approved formula) — recalculated
 * at the same event triggers as Risk Level, never here. This controller
 * implements only Credit Score's read-only display aspect.
 *
 * Risk Level (FR-027) has no controller of its own since Sprint 2B: it is
 * fully system-calculated by RiskLevelService and exposed only for reading
 * via CustomerResource (Customer show/index) — there is no manual
 * assignment endpoint (the former PATCH /customers/{customer}/risk-level
 * was removed, along with UpdateRiskLevelRequest and
 * CustomerPolicy::updateRiskLevel(), as part of that sprint).
 */
class CreditRiskController extends Controller
{
    use ApiResponse;

    public function creditScore(Customer $customer): JsonResponse
    {
        $this->authorize('viewCreditScore', $customer);

        return $this->successResponse([
            'customer_id' => $customer->id,
            'credit_score' => $customer->credit_score,
            'credit_score_band' => $customer->credit_score_band,
        ]);
    }
}
