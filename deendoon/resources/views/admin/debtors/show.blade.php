@extends('admin.layout')

@section('content')
    @php
        $statusTone = [
            'active' => 'bg-deendoon-success/10 text-emerald-700',
            'good_standing' => 'bg-deendoon-success/10 text-emerald-700',
            'late_payer' => 'bg-deendoon-warning/10 text-amber-700',
            'high_risk' => 'bg-deendoon-danger/10 text-red-700',
            'in_collection' => 'bg-deendoon-danger/10 text-red-700',
            'recovered' => 'bg-deendoon-info/10 text-indigo-700',
            'blocked' => 'bg-slate-100 text-slate-500',
        ];
        $riskTone = [
            'high' => 'bg-deendoon-danger/10 text-red-700',
            'medium' => 'bg-deendoon-warning/10 text-amber-700',
            'low' => 'bg-deendoon-success/10 text-emerald-700',
        ];
        $debtStatusTone = [
            'paid' => 'bg-deendoon-success/10 text-emerald-700',
            'partial_paid' => 'bg-deendoon-info/10 text-indigo-700',
            'overdue' => 'bg-deendoon-danger/10 text-red-700',
            'written_off' => 'bg-deendoon-danger/10 text-red-700',
            'cancelled' => 'bg-slate-100 text-slate-500',
            'draft' => 'bg-slate-100 text-slate-500',
            'pending' => 'bg-deendoon-warning/10 text-amber-700',
        ];
    @endphp

    <div class="mb-4">
        <a href="{{ route('admin.debtors.index') }}" class="text-sm font-medium text-deendoon-teal hover:underline">&larr; Back to Debtors</a>
    </div>

    <div class="grid grid-cols-1 gap-6 lg:grid-cols-3">
        <div class="space-y-6 lg:col-span-2">
            <div class="rounded-xl border border-slate-200 bg-white p-6">
                <div class="flex flex-wrap items-start justify-between gap-4">
                    <div>
                        <h2 class="text-xl font-bold text-slate-800">{{ $customer->name }}</h2>
                        <p class="mt-1 text-sm text-slate-500">{{ $customer->phone }}</p>
                    </div>
                    <span class="inline-flex items-center rounded-full px-3 py-1 text-sm font-medium {{ $statusTone[$customer->customer_status] ?? 'bg-slate-100 text-slate-500' }}">
                        {{ $statuses[$customer->customer_status] ?? ucfirst($customer->customer_status) }}
                    </span>
                </div>

                <dl class="mt-6 grid grid-cols-1 gap-4 sm:grid-cols-2">
                    <div>
                        <dt class="text-xs font-medium uppercase text-slate-400">Address</dt>
                        <dd class="text-sm text-slate-700">{{ $customer->address ?? '—' }}</dd>
                    </div>
                    <div>
                        <dt class="text-xs font-medium uppercase text-slate-400">Business</dt>
                        <dd class="text-sm text-slate-700">
                            @if ($customer->tenant)
                                <a href="{{ route('admin.businesses.show', $customer->tenant) }}" class="text-deendoon-teal hover:underline">{{ $customer->tenant->business_name }}</a>
                            @else
                                —
                            @endif
                        </dd>
                    </div>
                    <div>
                        <dt class="text-xs font-medium uppercase text-slate-400">Risk Level</dt>
                        <dd class="text-sm">
                            @if ($customer->risk_level)
                                <span class="inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium {{ $riskTone[$customer->risk_level] ?? 'bg-slate-100 text-slate-500' }}">
                                    {{ ucfirst($customer->risk_level) }}
                                </span>
                            @else
                                <span class="text-slate-400">—</span>
                            @endif
                        </dd>
                    </div>
                    <div>
                        <dt class="text-xs font-medium uppercase text-slate-400">Credit Score</dt>
                        <dd class="text-sm text-slate-700">
                            {{ $customer->credit_score ?? '—' }}
                            @if ($customer->credit_score_band)
                                <span class="text-slate-400">({{ ucfirst($customer->credit_score_band) }})</span>
                            @endif
                        </dd>
                    </div>
                    <div>
                        <dt class="text-xs font-medium uppercase text-slate-400">Credit Limit</dt>
                        <dd class="text-sm font-medium text-slate-700">${{ number_format($customer->credit_limit, 2) }}</dd>
                    </div>
                    <div>
                        <dt class="text-xs font-medium uppercase text-slate-400">Outstanding Balance</dt>
                        <dd class="text-sm font-medium text-slate-700">${{ number_format($customer->outstanding_balance, 2) }}</dd>
                    </div>
                    <div>
                        <dt class="text-xs font-medium uppercase text-slate-400">Remaining Credit</dt>
                        <dd class="text-sm font-medium text-slate-700">${{ number_format($customer->remaining_credit, 2) }}</dd>
                    </div>
                </dl>
            </div>

            <div class="rounded-xl border border-slate-200 bg-white p-6">
                <h3 class="mb-4 text-sm font-semibold text-slate-700">Debt History</h3>
                <div class="overflow-x-auto">
                    <table class="min-w-full divide-y divide-slate-200 text-sm">
                        <thead>
                            <tr class="text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                                <th class="px-3 py-2">Reference</th>
                                <th class="px-3 py-2">Amount</th>
                                <th class="px-3 py-2">Remaining</th>
                                <th class="px-3 py-2">Status</th>
                                <th class="px-3 py-2">Stage</th>
                                <th class="px-3 py-2">Due Date</th>
                                <th class="px-3 py-2"></th>
                            </tr>
                        </thead>
                        <tbody class="divide-y divide-slate-100">
                            @forelse ($customer->debts as $debt)
                                <tr>
                                    <td class="px-3 py-2 font-medium text-slate-800">{{ $debt->reference_number }}</td>
                                    <td class="px-3 py-2 text-slate-600">${{ number_format($debt->amount, 2) }}</td>
                                    <td class="px-3 py-2 text-slate-600">${{ number_format($debt->remaining_balance, 2) }}</td>
                                    <td class="px-3 py-2">
                                        <span class="inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium {{ $debtStatusTone[$debt->debt_status] ?? 'bg-slate-100 text-slate-500' }}">
                                            {{ $debtStatuses[$debt->debt_status] ?? ucfirst($debt->debt_status) }}
                                        </span>
                                    </td>
                                    <td class="px-3 py-2 text-slate-500">{{ $debt->recovery_stage }}. {{ $stages[$debt->recovery_stage] ?? '—' }}</td>
                                    <td class="px-3 py-2 text-slate-500">{{ $debt->due_date->format('M j, Y') }}</td>
                                    <td class="px-3 py-2 text-right">
                                        <a href="{{ route('admin.recovery-debts.show', $debt) }}" class="text-sm font-medium text-deendoon-teal hover:underline">View</a>
                                    </td>
                                </tr>
                            @empty
                                <tr>
                                    <td colspan="7" class="px-3 py-6 text-center text-slate-400">No debts recorded for this debtor.</td>
                                </tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
@endsection
