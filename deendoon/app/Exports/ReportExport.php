<?php

namespace App\Exports;

use Illuminate\Support\Collection;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\WithHeadings;

/**
 * FR-057/BRL-062 — one generic, reusable export shape (rows already
 * resolved to plain arrays by the calling Resource, plus a matching
 * headings list) serves every report type. Avoids six near-duplicate
 * Export classes for what is structurally the same concern.
 */
class ReportExport implements FromCollection, WithHeadings
{
    /**
     * @param  Collection<int, array<string, mixed>>  $rows
     * @param  array<int, string>  $headings
     */
    public function __construct(
        private readonly Collection $rows,
        private readonly array $headings,
    ) {}

    public function collection(): Collection
    {
        return $this->rows;
    }

    public function headings(): array
    {
        return $this->headings;
    }
}
