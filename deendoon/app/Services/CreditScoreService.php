<?php

namespace App\Services;

use App\Enums\AuditAction;
use App\Models\CollectionCase;
use App\Models\Customer;
use App\Models\Debt;
use App\Models\ProfessionalCollectionRequest;
use App\Models\PromiseToPay;
use Illuminate\Support\Carbon;
use Illuminate\Support\Collection;

/**
 * FR-026 (Business Owner Backend Completion, Product Owner-approved
 * formula): Credit Score is a deliberate, exact sign-inversion of
 * RiskLevelService's already-approved point values — the same qualifying
 * events, opposite direction, plus a neutral starting baseline (70) since
 * a Credit Score with no history yet should not read as "0" the way an
 * un-scored Risk Level naturally does. Per explicit Product Owner
 * instruction, no additional scoring event was introduced beyond what
 * RiskLevelService already tracks — Credit Score and Risk Level are
 * always derived from the same underlying customer behavior.
 *
 * Recomputed fully from source on every call, mirroring
 * RiskLevelService's own recompute-from-source guarantee — never
 * incremented/decremented, nothing cached.
 */
class CreditScoreService
{
    private const BASELINE = 70;

    private const SECONDARY_CAP = 15;

    public function __construct(
        private readonly AuditLogService $auditLog,
        private readonly AdminSettingsService $settings,
    ) {}

    public function recalculate(Customer $customer): void
    {
        $debts = $customer->debts()->withTrashed()->get();
        $debtIds = $debts->pluck('id');

        $promises = PromiseToPay::whereIn('debt_id', $debtIds)->get();

        $cases = CollectionCase::whereIn('debt_id', $debtIds)->get();
        $caseIds = $cases->pluck('id');

        $requests = ProfessionalCollectionRequest::whereIn('collection_case_id', $caseIds)->get();

        $days = $this->settings->systemSettingsFor($customer->tenant_id)->long_outstanding_debt_days;

        $this->apply($customer, $this->scoreFor($debts, $promises, $cases, $requests, $days));
    }

    /**
     * @param  Collection<int, Customer>  $customers
     */
    public function recalculateForMany(Collection $customers): void
    {
        if ($customers->isEmpty()) {
            return;
        }

        $customerIds = $customers->pluck('id');

        $debts = Debt::withTrashed()->whereIn('customer_id', $customerIds)->get();
        $debtsByCustomer = $debts->groupBy('customer_id');
        $debtIds = $debts->pluck('id');

        $promises = PromiseToPay::whereIn('debt_id', $debtIds)->get();
        $promisesByDebt = $promises->groupBy('debt_id');

        $cases = CollectionCase::whereIn('debt_id', $debtIds)->get();
        $casesByDebt = $cases->groupBy('debt_id');

        $requests = ProfessionalCollectionRequest::whereIn('collection_case_id', $cases->pluck('id'))->get();
        $requestsByCase = $requests->groupBy('collection_case_id');

        $days = $this->settings->systemSettingsFor($customers->first()->tenant_id)->long_outstanding_debt_days;

        foreach ($customers as $customer) {
            $customerDebts = $debtsByCustomer->get($customer->id, collect());
            $customerCases = $customerDebts->pluck('id')->flatMap(fn ($debtId) => $casesByDebt->get($debtId, collect()));
            $customerPromises = $customerDebts->pluck('id')->flatMap(fn ($debtId) => $promisesByDebt->get($debtId, collect()));
            $customerRequests = $customerCases->pluck('id')->flatMap(fn ($caseId) => $requestsByCase->get($caseId, collect()));

            $this->apply($customer, $this->scoreFor($customerDebts, $customerPromises, $customerCases, $customerRequests, $days));
        }
    }

    private function apply(Customer $customer, int $score): void
    {
        $band = $this->bandFor($score);

        if ($customer->credit_score === $score && $customer->credit_score_band === $band) {
            return;
        }

        $customer->credit_score = $score;
        $customer->credit_score_band = $band;
        $customer->save();

        $this->auditLog->record(
            AuditAction::CreditScoreRecalculated,
            'customer',
            $customer->id,
            null,
            "Automatic: Credit Score recalculated to {$score} ('{$band}')",
            $customer->tenant_id,
        );
    }

    /**
     * Score = clamp(70 + PrimarySubtotal + clamp(SecondarySubtotal, -15, +15), 0, 100).
     *
     * @param  Collection<int, Debt>  $debts
     * @param  Collection<int, PromiseToPay>  $promises
     * @param  Collection<int, CollectionCase>  $cases
     * @param  Collection<int, ProfessionalCollectionRequest>  $requests
     */
    private function scoreFor(Collection $debts, Collection $promises, Collection $cases, Collection $requests, int $longOutstandingDebtDays): int
    {
        $primary = $this->primarySubtotal($debts, $promises, $longOutstandingDebtDays);
        $secondary = max(-self::SECONDARY_CAP, min(self::SECONDARY_CAP, $this->secondarySubtotal($debts, $cases, $requests)));

        return max(0, min(100, self::BASELINE + $primary + $secondary));
    }

    /**
     * Exact sign-inversion of RiskLevelService::primarySubtotal()'s
     * already-approved point values: Broken Promise -15, Fulfilled Promise
     * +10, Debt Recovered +20, Repeated Missed Commitments -20, Long
     * Outstanding Debt -12 each, Sustained Positive Repayment +15.
     */
    private function primarySubtotal(Collection $debts, Collection $promises, int $longOutstandingDebtDays): int
    {
        $brokenPromises = $promises->where('status', 'broken');
        $fulfilledPromises = $promises->where('status', 'fulfilled');
        $recoveredDebts = $debts->where('debt_status', 'paid')->count();

        $subtotal = ($brokenPromises->count() * -15) + ($fulfilledPromises->count() * 10) + ($recoveredDebts * 20);

        if ($this->hasRepeatedMissedCommitments($brokenPromises)) {
            $subtotal -= 20;
        }

        $subtotal -= $this->longOutstandingDebtPoints($debts, $longOutstandingDebtDays);

        if ($this->hasSustainedPositiveRepayment($promises)) {
            $subtotal += 15;
        }

        return $subtotal;
    }

    /**
     * @param  Collection<int, PromiseToPay>  $brokenPromises
     */
    private function hasRepeatedMissedCommitments(Collection $brokenPromises): bool
    {
        $twelveMonthsAgo = now()->subMonths(12);

        return $brokenPromises->filter(
            fn (PromiseToPay $promise): bool => $promise->resolved_at !== null && $promise->resolved_at->greaterThanOrEqualTo($twelveMonthsAgo),
        )->count() >= 3;
    }

    /**
     * @param  Collection<int, PromiseToPay>  $promises
     */
    private function hasSustainedPositiveRepayment(Collection $promises): bool
    {
        $lastThree = $promises
            ->whereIn('status', ['fulfilled', 'broken'])
            ->whereNotNull('resolved_at')
            ->sortByDesc(fn (PromiseToPay $promise): Carbon => $promise->resolved_at)
            ->take(3);

        return $lastThree->count() === 3 && $lastThree->every(fn (PromiseToPay $promise): bool => $promise->status === 'fulfilled');
    }

    /**
     * @param  Collection<int, Debt>  $debts
     */
    private function longOutstandingDebtPoints(Collection $debts, int $longOutstandingDebtDays): int
    {
        $cutoff = now()->subDays($longOutstandingDebtDays)->startOfDay();

        $count = $debts->filter(
            fn (Debt $debt): bool => bccomp((string) $debt->remaining_balance, '0', 2) > 0 && $debt->due_date->lessThan($cutoff),
        )->count();

        return $count * 12;
    }

    /**
     * Exact sign-inversion of RiskLevelService::secondarySubtotal()'s
     * already-approved point values: Recovery Stage Advancement -3 each,
     * Collection Case Created -5 each, Professional Collection Request
     * Submitted -5 each, Professional Collection Request Recovered +5 each.
     *
     * @param  Collection<int, Debt>  $debts
     * @param  Collection<int, CollectionCase>  $cases
     * @param  Collection<int, ProfessionalCollectionRequest>  $requests
     */
    private function secondarySubtotal(Collection $debts, Collection $cases, Collection $requests): int
    {
        $recoveryStageAdvancements = $debts->sum(fn (Debt $debt): int => max(0, $debt->recovery_stage - 1));

        $casesCreated = $cases->count();
        $pcrSubmitted = $requests->count();
        $pcrRecovered = $requests->where('status', 'recovered')->count();

        return ($recoveryStageAdvancements * -3) + ($casesCreated * -5) + ($pcrSubmitted * -5) + ($pcrRecovered * 5);
    }

    /**
     * Product Owner-approved bands: 90-100 Excellent, 75-89 Good, 50-74
     * Fair, 0-49 Poor. Lowercase to match the customers_credit_score_band_check
     * CHECK constraint's approved value list.
     */
    private function bandFor(int $score): string
    {
        return match (true) {
            $score >= 90 => 'excellent',
            $score >= 75 => 'good',
            $score >= 50 => 'fair',
            default => 'poor',
        };
    }
}
