@extends('admin.layout')

@section('content')
    @php
        $fmt = fn ($n) => $n === null ? '—' : number_format($n);
        $pct = fn ($n) => $n === null ? '—' : ($n >= 0 ? '+' : '').rtrim(rtrim(number_format($n, 1), '0'), '.').'%';
        $statuses = ['active' => 'Active', 'suspended' => 'Suspended'];
    @endphp

    @include('admin.reports.partials.filters', [
        'filterAction' => route('admin.reports.business-growth'),
        'reportSlug' => 'business-growth',
        'statuses' => $statuses,
    ])

    @include('admin.reports.partials.export-actions', ['reportSlug' => 'business-growth'])

    <div class="mb-6 grid grid-cols-2 gap-4 sm:grid-cols-4">
        @include('admin.partials.stat-card', ['label' => 'Total Businesses', 'value' => $fmt($summary['total_businesses'])])
        @include('admin.partials.stat-card', ['label' => 'New Businesses', 'value' => $fmt($summary['new_businesses']), 'highlight' => true])
        @include('admin.partials.stat-card', ['label' => 'Active', 'value' => $fmt($summary['active_businesses']), 'tone' => 'success'])
        @include('admin.partials.stat-card', ['label' => 'Suspended', 'value' => $fmt($summary['suspended_businesses']), 'tone' => 'danger'])
    </div>

    <div class="mb-6 grid grid-cols-1 gap-4 lg:grid-cols-2">
        @include('admin.reports.partials.trend-chart', ['trend' => $trend, 'moneyFormat' => false, 'chartTitle' => 'Business Registrations — Trend'])

        <div class="rounded-xl border border-slate-200 bg-white p-5">
            <h3 class="mb-4 text-sm font-semibold text-slate-700">Growth Comparison</h3>
            @if ($summary['previous_period_new_businesses'] === null)
                <p class="text-sm text-slate-400">Select a date range to compare against the prior period.</p>
            @else
                <ul class="space-y-2 text-sm">
                    <li class="flex items-center justify-between">
                        <span class="text-slate-600">New This Period</span>
                        <span class="font-medium text-slate-800">{{ $fmt($summary['new_businesses']) }}</span>
                    </li>
                    <li class="flex items-center justify-between">
                        <span class="text-slate-600">New Previous Period</span>
                        <span class="font-medium text-slate-800">{{ $fmt($summary['previous_period_new_businesses']) }}</span>
                    </li>
                    <li class="flex items-center justify-between border-t border-slate-100 pt-2">
                        <span class="text-slate-600">Change</span>
                        <span class="font-bold {{ ($summary['growth_change_pct'] ?? 0) >= 0 ? 'text-emerald-600' : 'text-red-600' }}">{{ $pct($summary['growth_change_pct']) }}</span>
                    </li>
                </ul>
            @endif
        </div>
    </div>

    <p class="mb-4 text-xs text-slate-400" title="Backend support not built yet">
        Inactive account state: Pending backend support — only Active/Suspended exist today.
    </p>

    <div class="overflow-x-auto rounded-xl border border-slate-200 bg-white">
        <table class="min-w-full divide-y divide-slate-200 text-sm">
            <thead class="bg-slate-50">
                <tr class="text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                    <th class="px-4 py-3">Business Name</th>
                    <th class="px-4 py-3">Status</th>
                    <th class="px-4 py-3">Registered</th>
                    <th class="px-4 py-3"></th>
                </tr>
            </thead>
            <tbody class="divide-y divide-slate-100">
                @forelse ($records as $tenant)
                    <tr class="hover:bg-slate-50">
                        <td class="px-4 py-3 font-medium text-slate-800">{{ $tenant->business_name }}</td>
                        <td class="px-4 py-3 text-slate-600">{{ $statuses[$tenant->status] ?? ucfirst($tenant->status) }}</td>
                        <td class="px-4 py-3 text-slate-500">{{ $tenant->created_at->format('M j, Y') }}</td>
                        <td class="px-4 py-3 text-right">
                            <a href="{{ route('admin.businesses.show', $tenant) }}" class="text-sm font-medium text-deendoon-teal hover:underline">View</a>
                        </td>
                    </tr>
                @empty
                    <tr><td colspan="4" class="px-4 py-8 text-center text-slate-400">No businesses match your filters.</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>

    <div class="mt-4">{{ $records->links() }}</div>
@endsection
