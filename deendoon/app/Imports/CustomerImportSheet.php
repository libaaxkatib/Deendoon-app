<?php

namespace App\Imports;

use Illuminate\Support\Collection;
use Maatwebsite\Excel\Concerns\ToCollection;
use Maatwebsite\Excel\Concerns\WithHeadingRow;

/**
 * Parses an uploaded customer import spreadsheet. Column headers are
 * matched case-insensitively via WithHeadingRow (e.g. "Credit Limit"
 * becomes the "credit_limit" key) — expected columns are name,
 * primary_phone, secondary_phone (optional), credit_limit, per FR-007's
 * field set and Product Owner Decision 3 (credit_limit required, no
 * automatic default). Fix #23 Decision 11 replaced the single `phone`
 * column with `primary_phone`/`secondary_phone`; a file still using the
 * older `phone` header is deliberately still accepted (handled by
 * CustomerImportController, not here) as the primary phone, rather than
 * breaking every already-distributed import template overnight.
 */
class CustomerImportSheet implements ToCollection, WithHeadingRow
{
    /** @var array<int, array<string, mixed>> */
    public array $rows = [];

    public function collection(Collection $rows): void
    {
        $this->rows = $rows->toArray();
    }
}
