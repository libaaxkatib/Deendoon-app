<?php

namespace App\Services;

use Illuminate\Database\Eloquent\Builder;

/**
 * DD-032 (Business Owner Backend Completion, Product Owner-approved
 * formula) — the single, shared implementation of Collection Rate
 * (Collected ÷ Became Due, over a period), extracted into its own
 * dependency-free service so both `ReportingService` (Collection
 * Analytics' Collection Rate, dashboardKpis()'s Recovery Rate KPI) and
 * `BusinessHealthService` (Collection Performance input) can reuse it
 * without creating a circular dependency between those two services
 * (`ReportingService` already depends on `BusinessHealthService` to fold
 * `business_health` into `dashboardKpis()`).
 */
class CollectionRateService
{
    public function rateFor(Builder $payments, Builder $debts, string $dateFrom, string $dateTo): float
    {
        $totalCollected = $payments
            ->whereDate('payment_date', '>=', $dateFrom)
            ->whereDate('payment_date', '<=', $dateTo)
            ->sum('amount');

        $totalBecameDue = $debts
            ->whereDate('due_date', '>=', $dateFrom)
            ->whereDate('due_date', '<=', $dateTo)
            ->sum('amount');

        return bccomp((string) $totalBecameDue, '0.00', 2) > 0
            ? round(((float) $totalCollected / (float) $totalBecameDue) * 100, 2)
            : 0.0;
    }
}
