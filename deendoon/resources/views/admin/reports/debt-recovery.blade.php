@extends('admin.layout')

@section('content')
    @php
        $fmt = fn ($n) => $n === null ? '—' : number_format($n);
        $money = fn ($n) => $n === null ? '—' : '$'.number_format($n, 2);
        $pct = fn ($n) => $n === null ? '—' : rtrim(rtrim(number_format($n, 1), '0'), '.').'%';
    @endphp

    @include('admin.reports.partials.filters', [
        'filterAction' => route('admin.reports.debt-recovery'),
        'reportSlug' => 'debt-recovery',
        'statuses' => $statuses,
        'stages' => $stages,
    ])

    @include('admin.reports.partials.export-actions', ['reportSlug' => 'debt-recovery'])

    <div class="mb-6 grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-6">
        @include('admin.partials.stat-card', ['label' => 'Total Debt Cases', 'value' => $fmt($summary['total_cases'])])
        @include('admin.partials.stat-card', ['label' => 'Total Debt Value', 'value' => $money($summary['total_value'])])
        @include('admin.partials.stat-card', ['label' => 'Outstanding Debt', 'value' => $money($summary['outstanding_debt']), 'tone' => 'danger'])
        @include('admin.partials.stat-card', ['label' => 'Amount Recovered', 'value' => $money($summary['amount_recovered']), 'tone' => 'success'])
        @include('admin.partials.stat-card', ['label' => 'Recovery Rate', 'value' => $pct($summary['recovery_rate'])])
        @include('admin.partials.stat-card', ['label' => 'Overdue Cases', 'value' => $fmt($summary['overdue_count']).' / '.$money($summary['overdue_value']), 'tone' => 'warning'])
    </div>

    <div class="mb-6 grid grid-cols-1 gap-4 lg:grid-cols-2">
        @include('admin.reports.partials.trend-chart', ['trend' => $trend, 'moneyFormat' => true, 'chartTitle' => 'Amount Recovered — Trend'])

        <div class="rounded-xl border border-slate-200 bg-white p-5">
            <h3 class="mb-4 text-sm font-semibold text-slate-700">Debt Status Distribution</h3>
            <ul class="space-y-2 text-sm">
                @forelse ($summary['status_distribution'] as $status => $count)
                    <li class="flex items-center justify-between">
                        <span class="text-slate-600">{{ $statuses[$status] ?? ucfirst($status) }}</span>
                        <span class="font-medium text-slate-800">{{ $fmt($count) }}</span>
                    </li>
                @empty
                    <li class="text-slate-400">No debts match these filters.</li>
                @endforelse
            </ul>
        </div>
    </div>

    <div class="mb-6 rounded-xl border border-slate-200 bg-white p-5">
        <h3 class="mb-4 text-sm font-semibold text-slate-700">Recovery Stage Distribution</h3>
        <div class="grid grid-cols-3 gap-3 sm:grid-cols-6">
            @foreach ($stages as $value => $label)
                @include('admin.partials.mini-stat', ['label' => $label, 'value' => $fmt($summary['stage_distribution'][$value] ?? 0)])
            @endforeach
        </div>
    </div>

    <div class="overflow-x-auto rounded-xl border border-slate-200 bg-white">
        <table class="min-w-full divide-y divide-slate-200 text-sm">
            <thead class="bg-slate-50">
                <tr class="text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                    <th class="px-4 py-3">Reference</th>
                    <th class="px-4 py-3">Business</th>
                    <th class="px-4 py-3">Debtor</th>
                    <th class="px-4 py-3">Amount</th>
                    <th class="px-4 py-3">Remaining</th>
                    <th class="px-4 py-3">Status</th>
                    <th class="px-4 py-3">Stage</th>
                    <th class="px-4 py-3"></th>
                </tr>
            </thead>
            <tbody class="divide-y divide-slate-100">
                @forelse ($records as $debt)
                    <tr class="hover:bg-slate-50">
                        <td class="px-4 py-3 font-medium text-slate-800">{{ $debt->reference_number }}</td>
                        <td class="px-4 py-3 text-slate-600">{{ $debt->customer?->tenant?->business_name ?? '—' }}</td>
                        <td class="px-4 py-3 text-slate-600">{{ $debt->customer?->name ?? '—' }}</td>
                        <td class="px-4 py-3 text-slate-600">{{ $money($debt->amount) }}</td>
                        <td class="px-4 py-3 text-slate-600">{{ $money($debt->remaining_balance) }}</td>
                        <td class="px-4 py-3 text-slate-600">{{ $statuses[$debt->debt_status] ?? ucfirst($debt->debt_status) }}</td>
                        <td class="px-4 py-3 text-slate-600">{{ $stages[$debt->recovery_stage] ?? $debt->recovery_stage }}</td>
                        <td class="px-4 py-3 text-right">
                            <a href="{{ route('admin.recovery-debts.show', $debt) }}" class="text-sm font-medium text-deendoon-teal hover:underline">View</a>
                        </td>
                    </tr>
                @empty
                    <tr><td colspan="8" class="px-4 py-8 text-center text-slate-400">No debts match your filters.</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>

    <div class="mt-4">{{ $records->links() }}</div>
@endsection
