@extends('admin.layout')

@section('content')
    @php
        $fmt = fn ($n) => $n === null ? '—' : number_format($n);
    @endphp

    @include('admin.reports.partials.filters', [
        'filterAction' => route('admin.reports.professional-collection'),
        'reportSlug' => 'professional-collection',
        'statuses' => $statuses,
    ])

    @include('admin.reports.partials.export-actions', ['reportSlug' => 'professional-collection'])

    <div class="mb-6 grid grid-cols-2 gap-4 sm:grid-cols-4">
        @include('admin.partials.stat-card', ['label' => 'Total Requests', 'value' => $fmt($summary['total_requests'])])
        @include('admin.partials.stat-card', ['label' => 'Recovered', 'value' => $fmt($summary['recovered_count']), 'tone' => 'success'])
        @include('admin.partials.stat-card', ['label' => 'Closed', 'value' => $fmt($summary['closed_count'])])
        @include('admin.partials.stat-card', [
            'label' => 'Avg. Recovery Duration',
            'value' => $summary['average_recovery_duration_days'] !== null ? $summary['average_recovery_duration_days'].' days' : null,
            'pending' => $summary['average_recovery_duration_days'] === null,
        ])
    </div>

    <div class="mb-6 grid grid-cols-1 gap-4 lg:grid-cols-2">
        @include('admin.reports.partials.trend-chart', ['trend' => $trend, 'moneyFormat' => false, 'chartTitle' => 'Requests Submitted — Trend'])

        <div class="rounded-xl border border-slate-200 bg-white p-5">
            <h3 class="mb-4 text-sm font-semibold text-slate-700">Status Distribution</h3>
            <ul class="space-y-2 text-sm">
                @forelse ($summary['status_distribution'] as $status => $count)
                    <li class="flex items-center justify-between">
                        <span class="text-slate-600">{{ $statuses[$status] ?? ucfirst($status) }}</span>
                        <span class="font-medium text-slate-800">{{ $fmt($count) }}</span>
                    </li>
                @empty
                    <li class="text-slate-400">No requests match these filters.</li>
                @endforelse
            </ul>
        </div>
    </div>

    <div class="overflow-x-auto rounded-xl border border-slate-200 bg-white">
        <table class="min-w-full divide-y divide-slate-200 text-sm">
            <thead class="bg-slate-50">
                <tr class="text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                    <th class="px-4 py-3">Reference</th>
                    <th class="px-4 py-3">Business</th>
                    <th class="px-4 py-3">Status</th>
                    <th class="px-4 py-3">Requested</th>
                    <th class="px-4 py-3">Closed</th>
                    <th class="px-4 py-3"></th>
                </tr>
            </thead>
            <tbody class="divide-y divide-slate-100">
                @forelse ($records as $pcr)
                    <tr class="hover:bg-slate-50">
                        <td class="px-4 py-3 font-medium text-slate-800">{{ $pcr->reference_number }}</td>
                        <td class="px-4 py-3 text-slate-600">{{ $pcr->collectionCase?->debt?->customer?->tenant?->business_name ?? '—' }}</td>
                        <td class="px-4 py-3 text-slate-600">{{ $statuses[$pcr->status] ?? ucfirst($pcr->status) }}</td>
                        <td class="px-4 py-3 text-slate-500">{{ $pcr->created_at->format('M j, Y') }}</td>
                        <td class="px-4 py-3 text-slate-500">{{ $pcr->closed_at?->format('M j, Y') ?? '—' }}</td>
                        <td class="px-4 py-3 text-right">
                            <a href="{{ route('admin.professional-collection.show', $pcr) }}" class="text-sm font-medium text-deendoon-teal hover:underline">View</a>
                        </td>
                    </tr>
                @empty
                    <tr><td colspan="6" class="px-4 py-8 text-center text-slate-400">No requests match your filters.</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>

    <div class="mt-4">{{ $records->links() }}</div>
@endsection
