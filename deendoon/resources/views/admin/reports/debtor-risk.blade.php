@extends('admin.layout')

@section('content')
    @php
        $fmt = fn ($n) => $n === null ? '—' : number_format($n);
        $money = fn ($n) => $n === null ? '—' : '$'.number_format($n, 2);
    @endphp

    @include('admin.reports.partials.filters', [
        'filterAction' => route('admin.reports.debtor-risk'),
        'reportSlug' => 'debtor-risk',
        'statuses' => $statuses,
        'riskLevels' => $riskLevels,
    ])

    @include('admin.reports.partials.export-actions', ['reportSlug' => 'debtor-risk'])

    <div class="mb-6 grid grid-cols-2 gap-4 sm:grid-cols-3">
        @include('admin.partials.stat-card', ['label' => 'Total Debtors', 'value' => $fmt($summary['total_debtors'])])
        @include('admin.partials.stat-card', ['label' => 'High-Risk Debtors', 'value' => $fmt($summary['high_risk_count']), 'tone' => 'danger'])
    </div>

    <div class="mb-6 grid grid-cols-1 gap-4 lg:grid-cols-3">
        <div class="rounded-xl border border-slate-200 bg-white p-5">
            <h3 class="mb-4 text-sm font-semibold text-slate-700">Risk Distribution</h3>
            <ul class="space-y-2 text-sm">
                @forelse ($summary['risk_distribution'] as $level => $count)
                    <li class="flex items-center justify-between">
                        <span class="text-slate-600">{{ $riskLevels[$level] ?? ucfirst($level) }}</span>
                        <span class="font-medium text-slate-800">{{ $fmt($count) }}</span>
                    </li>
                @empty
                    <li class="text-slate-400">No risk data for these filters.</li>
                @endforelse
            </ul>
        </div>

        <div class="rounded-xl border border-slate-200 bg-white p-5">
            <h3 class="mb-4 text-sm font-semibold text-slate-700">Customer Status Distribution</h3>
            <ul class="space-y-2 text-sm">
                @forelse ($summary['status_distribution'] as $status => $count)
                    <li class="flex items-center justify-between">
                        <span class="text-slate-600">{{ $statuses[$status] ?? ucfirst($status) }}</span>
                        <span class="font-medium text-slate-800">{{ $fmt($count) }}</span>
                    </li>
                @empty
                    <li class="text-slate-400">No debtors match these filters.</li>
                @endforelse
            </ul>
        </div>

        <div class="rounded-xl border border-slate-200 bg-white p-5">
            <h3 class="mb-4 text-sm font-semibold text-slate-700">Credit Score Band</h3>
            @if ($summary['credit_score_band_distribution']->isEmpty())
                <p class="text-sm text-slate-400" title="Backend support not built yet">Pending backend support — no credit scores computed for these filters yet.</p>
            @else
                <ul class="space-y-2 text-sm">
                    @foreach ($summary['credit_score_band_distribution'] as $band => $count)
                        <li class="flex items-center justify-between">
                            <span class="text-slate-600">{{ ucfirst($band) }}</span>
                            <span class="font-medium text-slate-800">{{ $fmt($count) }}</span>
                        </li>
                    @endforeach
                </ul>
            @endif
        </div>
    </div>

    <div class="overflow-x-auto rounded-xl border border-slate-200 bg-white">
        <table class="min-w-full divide-y divide-slate-200 text-sm">
            <thead class="bg-slate-50">
                <tr class="text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                    <th class="px-4 py-3">Name</th>
                    <th class="px-4 py-3">Business</th>
                    <th class="px-4 py-3">Status</th>
                    <th class="px-4 py-3">Risk Level</th>
                    <th class="px-4 py-3">Credit Score</th>
                    <th class="px-4 py-3">Outstanding Balance</th>
                    <th class="px-4 py-3"></th>
                </tr>
            </thead>
            <tbody class="divide-y divide-slate-100">
                @forelse ($records as $customer)
                    <tr class="hover:bg-slate-50">
                        <td class="px-4 py-3 font-medium text-slate-800">{{ $customer->name }}</td>
                        <td class="px-4 py-3 text-slate-600">{{ $customer->tenant?->business_name ?? '—' }}</td>
                        <td class="px-4 py-3 text-slate-600">{{ $statuses[$customer->customer_status] ?? ucfirst($customer->customer_status) }}</td>
                        <td class="px-4 py-3 text-slate-600">{{ $riskLevels[$customer->risk_level] ?? ($customer->risk_level ?? '—') }}</td>
                        <td class="px-4 py-3 text-slate-600">{{ $customer->credit_score ?? '—' }}</td>
                        <td class="px-4 py-3 text-slate-600">{{ $money($customer->outstanding_balance) }}</td>
                        <td class="px-4 py-3 text-right">
                            <a href="{{ route('admin.debtors.show', $customer) }}" class="text-sm font-medium text-deendoon-teal hover:underline">View</a>
                        </td>
                    </tr>
                @empty
                    <tr><td colspan="7" class="px-4 py-8 text-center text-slate-400">No debtors match your filters.</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>

    <div class="mt-4">{{ $records->links() }}</div>
@endsection
