@extends('admin.layout')

@section('content')
    <div class="mb-4 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <form method="GET" action="{{ route('admin.payments.index') }}" class="flex flex-1 flex-wrap gap-2">
            <input type="text" name="search" value="{{ request('search') }}" placeholder="Search debt reference, debtor, or notes..."
                   class="min-w-[240px] flex-1 rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-deendoon-teal focus:outline-none focus:ring-1 focus:ring-deendoon-teal">
            <select name="payment_method" class="rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-deendoon-teal focus:outline-none focus:ring-1 focus:ring-deendoon-teal">
                <option value="">All methods</option>
                @foreach ($paymentMethods as $method)
                    <option value="{{ $method }}" @selected(request('payment_method') === $method)>{{ ucwords(str_replace('_', ' ', $method)) }}</option>
                @endforeach
            </select>
            <input type="date" name="date_from" value="{{ request('date_from') }}"
                   class="rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-deendoon-teal focus:outline-none focus:ring-1 focus:ring-deendoon-teal">
            <input type="date" name="date_to" value="{{ request('date_to') }}"
                   class="rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-deendoon-teal focus:outline-none focus:ring-1 focus:ring-deendoon-teal">
            <button type="submit" class="rounded-lg bg-deendoon-teal px-4 py-2 text-sm font-semibold text-white hover:bg-deendoon-teal-dark">
                Filter
            </button>
            @if (request()->filled('search') || request()->filled('payment_method') || request()->filled('date_from') || request()->filled('date_to'))
                <a href="{{ route('admin.payments.index') }}" class="rounded-lg px-4 py-2 text-sm font-medium text-slate-500 hover:text-slate-700">Clear</a>
            @endif
        </form>
    </div>

    <div class="overflow-x-auto rounded-xl border border-slate-200 bg-white">
        <table class="min-w-full divide-y divide-slate-200 text-sm">
            <thead class="bg-slate-50">
                <tr class="text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                    <th class="px-4 py-3">Payment ID</th>
                    <th class="px-4 py-3">Business</th>
                    <th class="px-4 py-3">Debtor</th>
                    <th class="px-4 py-3">Debt Reference</th>
                    <th class="px-4 py-3">Amount</th>
                    <th class="px-4 py-3">Payment Date</th>
                    <th class="px-4 py-3">Method</th>
                    <th class="px-4 py-3">Status</th>
                    <th class="px-4 py-3"></th>
                </tr>
            </thead>
            <tbody class="divide-y divide-slate-100">
                @forelse ($payments as $payment)
                    <tr class="hover:bg-slate-50">
                        <td class="px-4 py-3 font-mono text-xs text-slate-500">{{ substr($payment->id, 0, 12) }}…</td>
                        <td class="px-4 py-3 text-slate-600">{{ $payment->debt?->customer?->tenant?->business_name ?? '—' }}</td>
                        <td class="px-4 py-3 text-slate-600">{{ $payment->debt?->customer?->name ?? '—' }}</td>
                        <td class="px-4 py-3 text-slate-600">
                            @if ($payment->debt)
                                <a href="{{ route('admin.recovery-debts.show', $payment->debt) }}" class="text-deendoon-teal hover:underline">{{ $payment->debt->reference_number }}</a>
                            @else
                                —
                            @endif
                        </td>
                        <td class="px-4 py-3 font-medium text-slate-800">${{ number_format($payment->amount, 2) }}</td>
                        <td class="px-4 py-3 text-slate-500">{{ $payment->payment_date->format('M j, Y') }}</td>
                        <td class="px-4 py-3 text-slate-600">{{ $payment->payment_method ? ucwords(str_replace('_', ' ', $payment->payment_method)) : '—' }}</td>
                        <td class="px-4 py-3">
                            <span class="inline-flex items-center rounded-full bg-slate-100 px-2.5 py-0.5 text-xs font-medium text-slate-400" title="No payment status field exists in the backend yet">
                                Pending backend support
                            </span>
                        </td>
                        <td class="px-4 py-3 text-right">
                            <a href="{{ route('admin.payments.show', $payment) }}" class="text-sm font-medium text-deendoon-teal hover:underline">View</a>
                        </td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="9" class="px-4 py-8 text-center text-slate-400">No payments match your filters.</td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>

    <div class="mt-4">
        {{ $payments->links() }}
    </div>
@endsection
