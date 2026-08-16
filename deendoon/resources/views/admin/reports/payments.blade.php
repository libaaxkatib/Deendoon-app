@extends('admin.layout')

@section('content')
    @php
        $fmt = fn ($n) => $n === null ? '—' : number_format($n);
        $money = fn ($n) => $n === null ? '—' : '$'.number_format($n, 2);
    @endphp

    @include('admin.reports.partials.filters', [
        'filterAction' => route('admin.reports.payments'),
        'reportSlug' => 'payments',
        'paymentMethods' => $paymentMethods,
    ])

    @include('admin.reports.partials.export-actions', ['reportSlug' => 'payments'])

    <div class="mb-6 grid grid-cols-2 gap-4 sm:grid-cols-3">
        @include('admin.partials.stat-card', ['label' => 'Payment Count', 'value' => $fmt($summary['count'])])
        @include('admin.partials.stat-card', ['label' => 'Total Amount', 'value' => $money($summary['total_amount']), 'tone' => 'success'])
    </div>

    <div class="mb-6 grid grid-cols-1 gap-4 lg:grid-cols-2">
        @include('admin.reports.partials.trend-chart', ['trend' => $trend, 'moneyFormat' => true, 'chartTitle' => 'Payment Amount — Trend'])

        <div class="rounded-xl border border-slate-200 bg-white p-5">
            <h3 class="mb-4 text-sm font-semibold text-slate-700">Payment Method Distribution</h3>
            <ul class="space-y-2 text-sm">
                @forelse ($summary['method_distribution'] as $method => $count)
                    <li class="flex items-center justify-between">
                        <span class="text-slate-600">{{ $method }}</span>
                        <span class="font-medium text-slate-800">{{ $fmt($count) }}</span>
                    </li>
                @empty
                    <li class="text-slate-400">No payments match these filters.</li>
                @endforelse
            </ul>
        </div>
    </div>

    <div class="overflow-x-auto rounded-xl border border-slate-200 bg-white">
        <table class="min-w-full divide-y divide-slate-200 text-sm">
            <thead class="bg-slate-50">
                <tr class="text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                    <th class="px-4 py-3">Business</th>
                    <th class="px-4 py-3">Debtor</th>
                    <th class="px-4 py-3">Debt Reference</th>
                    <th class="px-4 py-3">Amount</th>
                    <th class="px-4 py-3">Payment Date</th>
                    <th class="px-4 py-3">Method</th>
                    <th class="px-4 py-3"></th>
                </tr>
            </thead>
            <tbody class="divide-y divide-slate-100">
                @forelse ($records as $payment)
                    <tr class="hover:bg-slate-50">
                        <td class="px-4 py-3 text-slate-600">{{ $payment->debt?->customer?->tenant?->business_name ?? '—' }}</td>
                        <td class="px-4 py-3 text-slate-600">{{ $payment->debt?->customer?->name ?? '—' }}</td>
                        <td class="px-4 py-3 text-slate-600">{{ $payment->debt?->reference_number ?? '—' }}</td>
                        <td class="px-4 py-3 font-medium text-slate-800">{{ $money($payment->amount) }}</td>
                        <td class="px-4 py-3 text-slate-500">{{ $payment->payment_date->format('M j, Y') }}</td>
                        <td class="px-4 py-3 text-slate-600">{{ $payment->payment_method ?? '—' }}</td>
                        <td class="px-4 py-3 text-right">
                            <a href="{{ route('admin.payments.show', $payment) }}" class="text-sm font-medium text-deendoon-teal hover:underline">View</a>
                        </td>
                    </tr>
                @empty
                    <tr><td colspan="7" class="px-4 py-8 text-center text-slate-400">No payments match your filters.</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>

    <div class="mt-4">{{ $records->links() }}</div>
@endsection
