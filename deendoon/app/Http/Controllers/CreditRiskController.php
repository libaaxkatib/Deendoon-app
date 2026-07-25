<?php

namespace App\Http\Controllers;

use App\Enums\AuditAction;
use App\Http\Requests\UpdateRiskLevelRequest;
use App\Http\Resources\CustomerResource;
use App\Models\Customer;
use App\Services\AuditLogService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;

/**
 * Module 4 — Credit & Risk Intelligence (FR-026-028).
 *
 * FR-026's scoring engine and FR-028's notification trigger are not
 * implemented here — see the Credit & Risk Module report's "Deferred
 * calculations" section for why. This controller implements only what is
 * genuinely approved and derivable today: reading the current score
 * (FR-026's display aspect) and assigning Risk Level (FR-027).
 */
class CreditRiskController extends Controller
{
    use ApiResponse;

    public function __construct(
        private readonly AuditLogService $auditLog,
    ) {}

    public function creditScore(Customer $customer): JsonResponse
    {
        $this->authorize('viewCreditScore', $customer);

        return $this->successResponse([
            'customer_id' => $customer->id,
            'credit_score' => $customer->credit_score,
            'credit_score_band' => $customer->credit_score_band,
        ]);
    }

    public function updateRiskLevel(UpdateRiskLevelRequest $request, Customer $customer): JsonResponse
    {
        $this->authorize('updateRiskLevel', $customer);

        $riskLevel = $request->validated('risk_level');

        $customer->update(['risk_level' => $riskLevel]);

        $this->auditLog->record(
            AuditAction::Edited,
            'customer',
            $customer->id,
            $request->user(),
            "Risk Level updated to '{$riskLevel}'",
        );

        return $this->successResponse(new CustomerResource($customer->fresh()), 'Risk level updated successfully');
    }
}
