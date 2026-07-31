<?php

namespace App\Services;

use App\Models\Customer;
use App\Models\Debt;
use App\Models\Payment;

/**
 * Sprint 17B — implements `Business_Health_Engine_v1.0.md` and the FROZEN
 * `Business_Health_Formula_Specification_v1.0.md` exactly as documented:
 * Weighted Average (Collection Performance 45% / Outstanding Exposure 20%
 * / Portfolio Customer Risk Levels 35%) then a Guardrail ceiling function,
 * mapped to the three FROZEN status bands (`Mobile_UI_V1_Frozen.md` §4.1).
 *
 * Two of the three inputs cannot be computed yet — this is a declared,
 * not a silent, gap (`docs/00_PROJECT_GOVERNANCE.md` §11/§12):
 * - Collection Performance depends on Recovery Rate, whose exact formula
 *   is unresolved (DD-032, `SRS/04_Business_Rules.md`). `ReportingService::
 *   dashboardKpis()` already returns `null` for this same reason —
 *   this service follows that exact precedent rather than inventing one
 *   of the two competing candidate formulas.
 * - Outstanding Exposure's normalization ("against the tenant's own
 *   historical baseline") is only an approved *concept* — no formula was
 *   ever defined, and the Sufficient Historical Activity gate's minimum
 *   completed-Debt-Cycle count is likewise unset.
 *
 * Per Formula Spec §1 ("gated... the whole card, not a partial
 * substitution"), the composite score is Neutral Baseline until both
 * are resolved — this is correct, not a bug, and is exercised explicitly
 * by this class's tests. Only Portfolio Customer Risk Levels is fully
 * computable today, since Risk Level Engine (Sprint 2B) is implemented;
 * it is built and tested now so nothing but the two `null`-returning
 * methods below need to change once DD-032 and the Outstanding Exposure
 * formula are each resolved.
 *
 * No score is ever persisted — recomputed fully from source on every
 * call (Engine doc §12/§13: "Dashboard load" is the only trigger, no
 * cache, no stored value), matching Risk Level's own recompute-from-source
 * guarantee.
 */
class BusinessHealthService
{
    private const WEIGHT_COLLECTION_PERFORMANCE = 0.45;

    private const WEIGHT_OUTSTANDING_EXPOSURE = 0.20;

    private const WEIGHT_PORTFOLIO_RISK_LEVELS = 0.35;

    /** Formula Spec §3 / Engine doc §11 — FROZEN, not configurable. */
    private const HEALTHY_MIN = 80;

    private const NEEDS_ATTENTION_MIN = 50;

    /**
     * Formula Spec §2 / Engine doc §4: the Guardrail's trigger threshold
     * is explicitly deferred to a post-launch Formula Calibration phase —
     * "a named, centrally-defined constant... so it can be calibrated
     * later without touching the Guardrail logic itself." `null` means
     * the mechanism below is fully built but dormant until a Product
     * Owner-approved value is calibrated in here (`docs/
     * 00_PROJECT_GOVERNANCE.md` §10 governs that future change).
     */
    private const CRITICAL_FLOOR = null;

    /** Formula Spec §1 — severity-only, FROZEN Health Contribution Weights. */
    private const HEALTH_CONTRIBUTION_WEIGHTS = [
        'low' => 100,
        'medium' => 50,
        'high' => 0,
    ];

    /**
     * @return array{status: string, score: int|null}
     */
    public function calculate(): array
    {
        if ($this->hasNoRecordedActivity()) {
            return $this->neutralBaseline();
        }

        $collectionPerformance = $this->collectionPerformance();
        $outstandingExposure = $this->outstandingExposure();

        if ($collectionPerformance === null || $outstandingExposure === null) {
            return $this->neutralBaseline();
        }

        $portfolioRiskLevels = $this->portfolioRiskLevelsIndex();

        if ($portfolioRiskLevels === null) {
            return $this->neutralBaseline();
        }

        $rawScore = ($collectionPerformance * self::WEIGHT_COLLECTION_PERFORMANCE)
            + ($outstandingExposure * self::WEIGHT_OUTSTANDING_EXPOSURE)
            + ($portfolioRiskLevels * self::WEIGHT_PORTFOLIO_RISK_LEVELS);

        return $this->applyGuardrails($rawScore, $collectionPerformance, $outstandingExposure, $portfolioRiskLevels);
    }

    /**
     * `Mobile_UI_V1_Frozen.md` §4.1 Empty State: "For a tenant with no
     * recorded debts or payments, the score displays a neutral baseline
     * state rather than an artificially computed percentage." Checked
     * first and independently of the two unresolved inputs below, since
     * this condition remains meaningful once DD-032 and the Outstanding
     * Exposure formula are eventually resolved too.
     */
    private function hasNoRecordedActivity(): bool
    {
        return ! Debt::query()->exists() && ! Payment::query()->exists();
    }

    /**
     * DD-032 (Recovery Rate's exact formula) is unresolved — at least two
     * valid definitions exist and neither was ever chosen. Returns `null`
     * rather than an invented value, exactly matching
     * `ReportingService::dashboardKpis()`'s existing, approved precedent
     * for this identical dependency.
     */
    private function collectionPerformance(): ?float
    {
        return null;
    }

    /**
     * `Business_Health_Formula_Specification_v1.0.md` §1 approves only the
     * *concept* ("normalized against the tenant's own historical
     * baseline") — no normalization formula was ever defined, and the
     * Sufficient Historical Activity minimum (completed Debt Cycle count)
     * that gates it is also unset. Returns `null` rather than inventing
     * either.
     */
    private function outstandingExposure(): ?float
    {
        return null;
    }

    /**
     * Formula Spec §1: "severity-weighted distribution index over the
     * tenant's Customer Risk Level classifications... weighted by Health
     * Contribution Weights: Low = 100, Medium = 50, High = 0." Fully
     * approved and fully computable today — Risk Level Engine (Sprint 2B)
     * keeps every Customer's `risk_level` current. Mirrors
     * `ReportingService::riskDistribution()`'s existing query shape
     * (auth-scoped via `BelongsToTenant`, no explicit tenant filter
     * needed). Returns `null` only when there are no classified
     * customers to average — `04_Business_Rules.md` BRL-028 defines the
     * three classification labels this reads.
     */
    private function portfolioRiskLevelsIndex(): ?float
    {
        $riskLevels = Customer::query()->whereNotNull('risk_level')->pluck('risk_level');

        if ($riskLevels->isEmpty()) {
            return null;
        }

        $total = $riskLevels->sum(fn (string $riskLevel): int => self::HEALTH_CONTRIBUTION_WEIGHTS[$riskLevel] ?? 0);

        return $total / $riskLevels->count();
    }

    /**
     * Formula Spec §4 / Engine doc §4: a pure ceiling function. May only
     * read the 3 already-normalized inputs and cap the score toward At
     * Risk — never raise it, never read anything else. `CRITICAL_FLOOR`
     * being `null` (uncalibrated) means this is structurally present but
     * always a no-op today, matching the mechanism-now/calibrate-later
     * instruction in Formula Spec §2.
     *
     * @return array{status: string, score: int}
     */
    private function applyGuardrails(float $rawScore, float $collectionPerformance, float $outstandingExposure, float $portfolioRiskLevels): array
    {
        if (self::CRITICAL_FLOOR !== null) {
            $inputs = [$collectionPerformance, $outstandingExposure, $portfolioRiskLevels];

            foreach ($inputs as $input) {
                if ($input <= self::CRITICAL_FLOOR) {
                    // Guardrail Ceiling — Engine doc §4: a live reference
                    // to the At Risk band's upper bound, never a
                    // separately hardcoded number.
                    $guardrailCeiling = self::NEEDS_ATTENTION_MIN - 1;

                    return ['status' => 'at_risk', 'score' => (int) round(min($rawScore, $guardrailCeiling))];
                }
            }
        }

        return ['status' => $this->statusFor($rawScore), 'score' => (int) round($rawScore)];
    }

    /** Formula Spec §3 — FROZEN band thresholds. */
    private function statusFor(float $score): string
    {
        return match (true) {
            $score >= self::HEALTHY_MIN => 'healthy',
            $score >= self::NEEDS_ATTENTION_MIN => 'needs_attention',
            default => 'at_risk',
        };
    }

    /**
     * @return array{status: string, score: null}
     */
    private function neutralBaseline(): array
    {
        return ['status' => 'neutral_baseline', 'score' => null];
    }
}
