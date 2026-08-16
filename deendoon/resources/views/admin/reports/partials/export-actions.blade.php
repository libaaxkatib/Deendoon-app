{{-- $reportSlug: e.g. 'debt-recovery'. Current-results links carry the
     page's active filters (excluding pagination); All-results links drop
     every filter via ?scope=all, per the approved Export behavior decision. --}}
@php
    $currentQuery = request()->except('page');
    $exportUrl = fn ($format) => route('admin.reports.export', ['report' => $reportSlug, 'format' => $format]).'?'.http_build_query($currentQuery);
    $exportAllUrl = fn ($format) => route('admin.reports.export', ['report' => $reportSlug, 'format' => $format]).'?scope=all';
    $printUrl = route('admin.reports.print', $reportSlug).'?'.http_build_query($currentQuery);
@endphp
<div class="mb-4 flex flex-wrap items-center justify-end gap-4 text-sm">
    <div class="flex items-center gap-2">
        <span class="text-xs font-medium text-slate-500">Export Current:</span>
        <a href="{{ $exportUrl('csv') }}" class="font-medium text-deendoon-teal hover:underline">CSV</a>
        <a href="{{ $exportUrl('excel') }}" class="font-medium text-deendoon-teal hover:underline">Excel</a>
        <a href="{{ $exportUrl('pdf') }}" class="font-medium text-deendoon-teal hover:underline">PDF</a>
    </div>
    <div class="flex items-center gap-2">
        <span class="text-xs font-medium text-slate-500">Export All:</span>
        <a href="{{ $exportAllUrl('csv') }}" class="font-medium text-deendoon-teal hover:underline">CSV</a>
        <a href="{{ $exportAllUrl('excel') }}" class="font-medium text-deendoon-teal hover:underline">Excel</a>
        <a href="{{ $exportAllUrl('pdf') }}" class="font-medium text-deendoon-teal hover:underline">PDF</a>
    </div>
    <a href="{{ $printUrl }}" target="_blank" class="rounded-lg border border-slate-300 px-3 py-1.5 font-medium text-slate-600 hover:bg-slate-50">
        Print
    </a>
</div>
