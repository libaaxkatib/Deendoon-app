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
 * Sprint 2B — implements `Risk_Level_Engine_v1.0.md` (frozen conceptual
 * architecture) and `Risk_Level_Formula_Specification_v1.0.md` (frozen
 * formula, including the three Product Owner revisions: rolling 12-month
 * window for Repeated Missed Commitments, configurable
 * `system_settings.long_outstanding_debt_days`, and no scoring effect for
 * Collection Case closure pending DD-024) exactly as approved.
 *
 * Every number below is recomputed fully from source on every call — never
 * incremented/decremented and nothing is cached — the same guarantee
 * `CustomerBalanceService::recalculate()` already relies on for Outstanding
 * Balance, for the identical reason (Formula Spec §7).
 *
 * `recalculate()` (one Customer) and `recalculateForMany()` (a whole page
 * of Customers, batched into a fixed number of queries) mirror
 * `PromiseToPayService::refreshBrokenPromises()`/
 * `refreshBrokenPromisesForMany()`: two entry points sharing one scoring
 * function (`scoreFor()`), differing only in how the underlying data is
 * fetched — per-customer queries for one, grouped bulk queries for many —
 * so that `DebtController::index()`/`CustomerController::index()` do not
 * re-introduce the exact per-row N+1 that batch already fixed elsewhere.
 */
class RiskLevelService
{
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

        // Every Customer in one batch is already tenant-scoped identically
        // (BelongsToTenant applies the same authenticated-user tenant to
        // every row in the page query this batch is called from), so the
        // configured threshold only ever needs to be looked up once.
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
        $label = $this->labelFor($score);

        if ($customer->risk_level === $label) {
            return;
        }

        $customer->risk_level = $label;
        $customer->save();

        $this->auditLog->record(
            AuditAction::RiskLevelRecalculated,
            'customer',
            $customer->id,
            null,
            "Automatic: Risk Level recalculated to '{$label}' (score {$score})",
            $customer->tenant_id,
        );
    }

    /**
     * Formula Spec §4: PrimarySubtotal + clamp(SecondarySubtotal, -15, +15),
     * then clamp(RawScore, 0, 100). Operates purely on already-fetched
     * Collections so the exact same math backs both the single-Customer
     * and batched entry points.
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

        return max(0, min(100, $primary + $secondary));
    }

    /**
     * Formula Spec §2.1. Broken/Fulfilled Promise to Pay and Debt
     * Recovered are lifetime, per-occurrence counts of terminal states —
     * this is the approved design (§2.1: "layered on top of the individual
     * Broken Promise points already accrued"), distinct from the two
     * pattern-detection events below, which are the ones deliberately kept
     * to a rolling/streak window rather than lifetime history.
     */
    private function primarySubtotal(Collection $debts, Collection $promises, int $longOutstandingDebtDays): int
    {
        $brokenPromises = $promises->where('status', 'broken');
        $fulfilledPromises = $promises->where('status', 'fulfilled');
        $recoveredDebts = $debts->where('debt_status', 'paid')->count();

        $subtotal = ($brokenPromises->count() * 15) - ($fulfilledPromises->count() * 10) - ($recoveredDebts * 20);

        if ($this->hasRepeatedMissedCommitments($brokenPromises)) {
            $subtotal += 20;
        }

        $subtotal += $this->longOutstandingDebtPoints($debts, $longOutstandingDebtDays);

        if ($this->hasSustainedPositiveRepayment($promises)) {
            $subtotal -= 15;
        }

        return $subtotal;
    }

    /**
     * Formula Spec §2.1, Repeated Missed Commitments (Change 1): 3+ Broken
     * Promise to Pay events within the trailing 12 months, re-evaluated
     * fresh every time — no permanent penalty stored. As older broken
     * promises age out of the window the count naturally drops and this
     * stops applying at the very next recalculation.
     *
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
     * Formula Spec §2.1, Sustained Positive Repayment Behavior: the 3 most
     * recently resolved promises (fulfilled or broken) must all be
     * fulfilled — an unbroken streak, not a lifetime count.
     *
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
     * Formula Spec §2.1/§8, Long Outstanding Debt (Change 2): the day-count
     * threshold is read from `system_settings.long_outstanding_debt_days`
     * (per-tenant, default 90) — never hardcoded. Evaluated lazily on every
     * call, per §8.
     *
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
     * Formula Spec §2.2. Collection Case Successfully Closed contributes
     * nothing (Change 3, pending DD-024) and is deliberately absent below.
     * Recovery Stage Advancement is read from `debts.recovery_stage`
     * itself — the source field — rather than a separate event log:
     * `RecoveryStageService::advanceTo()` only ever increases this value,
     * never regresses it, so `recovery_stage - 1` (the stage every Debt
     * starts at) is exactly the number of advancement events for that
     * Debt, recomputed fresh from current state.
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

        return ($recoveryStageAdvancements * 3) + ($casesCreated * 5) + ($pcrSubmitted * 5) - ($pcrRecovered * 5);
    }

    /**
     * Formula Spec §3: even thirds, no asymmetric carve-out.
     */
    private function labelFor(int $score): string
    {
        return match (true) {
            $score <= 33 => 'low',
            $score <= 66 => 'medium',
            default => 'high',
        };
    }
}
