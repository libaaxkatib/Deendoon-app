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
 * Business Owner Backend Completion (pre-Phase 5), Product Owner-approved
 * decision: Collection Performance and Outstanding Exposure are both now
 * implemented, adaptively — no minimum-history gate hides the whole card.
 * A tenant sees a real score from their very first recorded activity, with
 * a `confidence` indicator (`limited_history`/`established`) alongside it
 * rather than `neutral_baseline`/`null` while data is still sparse. See
 * collectionPerformance()/outstandingExposure() for each formula and
 * confidenceFor() for the threshold.
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

    /** Outstanding Exposure's rolling historical baseline window. */
    private const EXPOSURE_BASELINE_DAYS = 365;

    /**
     * Product Owner-approved threshold (Business Owner Backend
     * Completion, pre-Phase 5): fewer completed Debt Cycles than this
     * marks the score `limited_history` rather than `established` — a
     * label only, never a gate.
     */
    private const ESTABLISHED_HISTORY_MIN_CYCLES = 5;

    private const CLOSED_DEBT_STATUSES = ['paid', 'cancelled', 'written_off'];

    public function __construct(
        private readonly CollectionRateService $collectionRate,
    ) {}

    /**
     * @return array{status: string, score: int|null, confidence?: string}
     */
    public function calculate(): array
    {
        if ($this->hasNoRecordedActivity()) {
            return $this->neutralBaseline();
        }

        $collectionPerformance = $this->collectionPerformance();
        $outstandingExposure = $this->outstandingExposure();
        $portfolioRiskLevels = $this->portfolioRiskLevelsIndex();

        if ($portfolioRiskLevels === null) {
            return $this->neutralBaseline();
        }

        $rawScore = ($collectionPerformance * self::WEIGHT_COLLECTION_PERFORMANCE)
            + ($outstandingExposure * self::WEIGHT_OUTSTANDING_EXPOSURE)
            + ($portfolioRiskLevels * self::WEIGHT_PORTFOLIO_RISK_LEVELS);

        $result = $this->applyGuardrails($rawScore, $collectionPerformance, $outstandingExposure, $portfolioRiskLevels);
        $result['confidence'] = $this->confidenceFor();

        return $result;
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
     * DD-032 (Business Owner Backend Completion, Product Owner-approved
     * formula): reuses the exact same Collected ÷ Became Due calculation
     * as `ReportingService`'s Collection Rate/Recovery Rate — computed
     * all-time (this tenant's full history to date), since Business
     * Health has no period selector of its own. Clamped [0, 100] before
     * entering the weighted average, since the raw formula can exceed 100
     * whenever a period collects more than became due within it (e.g.
     * paying down older debt).
     */
    private function collectionPerformance(): float
    {
        $rate = $this->collectionRate->rateFor(
            Payment::query(),
            Debt::query(),
            self::allTimeStart(),
            now()->toDateString(),
        );

        return max(0.0, min(100.0, $rate));
    }

    /**
     * `Business_Health_Formula_Specification_v1.0.md` §1's approved
     * *concept* ("normalized against the tenant's own historical
     * baseline"), made concrete (Business Owner Backend Completion,
     * pre-Phase 5, Product Owner-approved formula):
     *
     * Baseline = Total Credit Extended in the trailing
     * EXPOSURE_BASELINE_DAYS (365) days — the tenant's own recent lending
     * volume, not their entire lifetime history, so a long-established
     * business isn't permanently biased toward an excellent score.
     * Current = current Total Outstanding Balance (open Debts only, the
     * same "open" definition CustomerBalanceService/ReportingService
     * already use).
     * Ratio = Current ÷ Baseline. Score = (1 − Ratio) × 100, clamped
     * [0, 100] — 100 means nothing is outstanding relative to the
     * tenant's own recent lending; 0 means outstanding exposure meets or
     * exceeds a full trailing year of new lending.
     *
     * Two degenerate cases where Baseline is 0 (no debts created in the
     * trailing window): if there's also nothing currently outstanding,
     * exposure is trivially zero regardless of baseline (Score 100); if
     * there IS outstanding exposure with zero recent lending to normalize
     * it against, that is itself the worst-case signal (Score 0), not an
     * undefined result.
     */
    private function outstandingExposure(): float
    {
        $current = (float) Debt::whereNotIn('debt_status', self::CLOSED_DEBT_STATUSES)->sum('remaining_balance');

        if (bccomp((string) $current, '0.00', 2) === 0) {
            return 100.0;
        }

        $baseline = (float) Debt::where('created_at', '>=', now()->subDays(self::EXPOSURE_BASELINE_DAYS))->sum('amount');

        if (bccomp((string) $baseline, '0.00', 2) === 0) {
            return 0.0;
        }

        $ratio = $current / $baseline;

        return max(0.0, min(100.0, (1 - $ratio) * 100));
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

    /**
     * Product Owner-approved label (Business Owner Backend Completion,
     * pre-Phase 5): a `confidence` indicator, never a gate — the score
     * above is always the real, currently-computed value regardless of
     * this result.
     */
    private function confidenceFor(): string
    {
        $completedCycles = Debt::whereIn('debt_status', self::CLOSED_DEBT_STATUSES)->count();

        return $completedCycles >= self::ESTABLISHED_HISTORY_MIN_CYCLES ? 'established' : 'limited_history';
    }

    /**
     * A practical "beginning of time" sentinel for an all-time date range
     * — Deendoon has no data predating this, so it is equivalent to no
     * lower bound at all without adding nullable-date branching to
     * CollectionRateService::rateFor()'s signature.
     */
    private static function allTimeStart(): string
    {
        return '2000-01-01';
    }
}
