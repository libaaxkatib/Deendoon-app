<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;

/**
 * Generates per-tenant sequential business-facing identifiers
 * (DBT-000001, and — per 06_Database_Design.md Principle 5 — the same
 * pattern future modules will need for RCT-/DL-/COL-/PCR-/ST- numbers).
 * Row-locked within a transaction to avoid a race between two concurrent
 * creates for the same tenant producing the same number.
 */
class ReferenceNumberService
{
    public function next(string $table, string $tenantId, string $prefix, int $padLength = 6): string
    {
        return DB::transaction(function () use ($table, $tenantId, $prefix, $padLength) {
            $existing = DB::table($table)
                ->where('tenant_id', $tenantId)
                ->where('reference_number', 'like', $prefix.'-%')
                ->lockForUpdate()
                ->pluck('reference_number');

            $max = $existing
                ->map(fn (string $reference): int => (int) str_replace($prefix.'-', '', $reference))
                ->max() ?? 0;

            return sprintf('%s-%0'.$padLength.'d', $prefix, $max + 1);
        });
    }
}
