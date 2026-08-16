@extends('admin.layout')

@section('content')
    @php
        $statusTone = [
            'active' => 'success',
            'good_standing' => 'success',
            'late_payer' => 'warning',
            'high_risk' => 'danger',
            'in_collection' => 'danger',
            'recovered' => 'info',
            'blocked' => 'muted',
        ];
        $riskTone = [
            'high' => 'danger',
            'medium' => 'warning',
            'low' => 'success',
        ];
        $toneClasses = [
            'success' => 'bg-deendoon-success/10 text-emerald-700',
            'warning' => 'bg-deendoon-warning/10 text-amber-700',
            'danger' => 'bg-deendoon-danger/10 text-red-700',
            'info' => 'bg-deendoon-info/10 text-indigo-700',
            'muted' => 'bg-slate-100 text-slate-500',
        ];
    @endphp

    <div class="mb-4 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <form method="GET" action="{{ route('admin.debtors.index') }}" class="flex flex-1 flex-wrap gap-2">
            <input type="text" name="search" value="{{ request('search') }}" placeholder="Search name or phone..."
                   class="min-w-[220px] flex-1 rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-deendoon-teal focus:outline-none focus:ring-1 focus:ring-deendoon-teal">
            <select name="status" class="rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-deendoon-teal focus:outline-none focus:ring-1 focus:ring-deendoon-teal">
                <option value="">All statuses</option>
                @foreach ($statuses as $value => $label)
                    <option value="{{ $value }}" @selected(request('status') === $value)>{{ $label }}</option>
                @endforeach
            </select>
            <select name="risk_level" class="rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-deendoon-teal focus:outline-none focus:ring-1 focus:ring-deendoon-teal">
                <option value="">All risk levels</option>
                @foreach ($riskLevels as $value => $label)
                    <option value="{{ $value }}" @selected(request('risk_level') === $value)>{{ $label }}</option>
                @endforeach
            </select>
            <button type="submit" class="rounded-lg bg-deendoon-teal px-4 py-2 text-sm font-semibold text-white hover:bg-deendoon-teal-dark">
                Filter
            </button>
            @if (request()->filled('search') || request()->filled('status') || request()->filled('risk_level'))
                <a href="{{ route('admin.debtors.index') }}" class="rounded-lg px-4 py-2 text-sm font-medium text-slate-500 hover:text-slate-700">Clear</a>
            @endif
        </form>
    </div>

    <div class="overflow-x-auto rounded-xl border border-slate-200 bg-white">
        <table class="min-w-full divide-y divide-slate-200 text-sm">
            <thead class="bg-slate-50">
                <tr class="text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                    <th class="px-4 py-3">Debtor</th>
                    <th class="px-4 py-3">Phone</th>
                    <th class="px-4 py-3">Business</th>
                    <th class="px-4 py-3">Status</th>
                    <th class="px-4 py-3">Risk</th>
                    <th class="px-4 py-3">Outstanding</th>
                    <th class="px-4 py-3">Credit Limit</th>
                    <th class="px-4 py-3">Credit Score</th>
                    <th class="px-4 py-3"></th>
                </tr>
            </thead>
            <tbody class="divide-y divide-slate-100">
                @forelse ($customers as $customer)
                    <tr class="hover:bg-slate-50">
                        <td class="px-4 py-3 font-medium text-slate-800">{{ $customer->name }}</td>
                        <td class="px-4 py-3 text-slate-600">{{ $customer->phone }}</td>
                        <td class="px-4 py-3 text-slate-600">{{ $customer->tenant?->business_name ?? '—' }}</td>
                        <td class="px-4 py-3">
                            <span class="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium {{ $toneClasses[$statusTone[$customer->customer_status] ?? 'muted'] }}">
                                {{ $statuses[$customer->customer_status] ?? ucfirst($customer->customer_status) }}
                            </span>
                        </td>
                        <td class="px-4 py-3">
                            @if ($customer->risk_level)
                                <span class="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium {{ $toneClasses[$riskTone[$customer->risk_level] ?? 'muted'] }}">
                                    {{ $riskLevels[$customer->risk_level] ?? ucfirst($customer->risk_level) }}
                                </span>
                            @else
                                <span class="text-slate-400">—</span>
                            @endif
                        </td>
                        <td class="px-4 py-3 text-slate-600">${{ number_format($customer->outstanding_balance, 2) }}</td>
                        <td class="px-4 py-3 text-slate-600">${{ number_format($customer->credit_limit, 2) }}</td>
                        <td class="px-4 py-3 text-slate-600">{{ $customer->credit_score ?? '—' }}</td>
                        <td class="px-4 py-3 text-right">
                            <a href="{{ route('admin.debtors.show', $customer) }}" class="text-sm font-medium text-deendoon-teal hover:underline">View</a>
                        </td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="9" class="px-4 py-8 text-center text-slate-400">No debtors match your filters.</td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>

    <div class="mt-4">
        {{ $customers->links() }}
    </div>
@endsection
