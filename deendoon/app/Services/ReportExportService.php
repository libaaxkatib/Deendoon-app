<?php

namespace App\Services;

use App\Exports\ReportExport;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Support\Collection;
use Maatwebsite\Excel\Excel as ExcelFormat;
use Maatwebsite\Excel\Facades\Excel;
use Symfony\Component\HttpFoundation\BinaryFileResponse;
use Symfony\Component\HttpFoundation\Response;

/**
 * FR-057/BRL-062 — the export reflects exactly the data and filters
 * already applied on screen (the caller passes the same resolved rows the
 * GET endpoint would return); no export-only calculation is introduced.
 * Reuses the two packages already installed for this project (dompdf,
 * Module 8; maatwebsite/excel, Module 2's Customer Import) rather than
 * adding a third.
 */
class ReportExportService
{
    /**
     * @param  array<int, string>  $headings
     * @param  Collection<int, array<string, mixed>>  $rows
     */
    public function export(string $format, string $filename, array $headings, Collection $rows): BinaryFileResponse|Response
    {
        return match ($format) {
            'excel' => Excel::download(new ReportExport($rows, $headings), "{$filename}.xlsx"),
            'csv' => Excel::download(new ReportExport($rows, $headings), "{$filename}.csv", ExcelFormat::CSV),
            'pdf' => Pdf::loadView('reports.export', [
                'title' => $filename,
                'headings' => $headings,
                'rows' => $rows,
            ])->download("{$filename}.pdf"),
        };
    }
}
