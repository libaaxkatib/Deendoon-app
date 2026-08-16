@extends('admin.layout')

@section('content')
    @php
        $debtStatusTone = [
            'paid' => 'bg-deendoon-success/10 text-emerald-700',
            'partial_paid' => 'bg-deendoon-info/10 text-indigo-700',
            'overdue' => 'bg-deendoon-danger/10 text-red-700',
            'written_off' => 'bg-deendoon-danger/10 text-red-700',
            'cancelled' => 'bg-slate-100 text-slate-500',
            'draft' => 'bg-slate-100 text-slate-500',
            'pending' => 'bg-deendoon-warning/10 text-amber-700',
        ];
        $debt = $payment->debt;
        $customer = $debt?->customer;
        $tenant = $customer?->tenant;
    @endphp

    <div class="mb-4">
        <a href="{{ route('admin.payments.index') }}" class="text-sm font-medium text-deendoon-teal hover:underline">&larr; Back to Payments</a>
    </div>

    <div class="grid grid-cols-1 gap-6 lg:grid-cols-3">
        <div class="space-y-6 lg:col-span-2">
            <div class="rounded-xl border border-slate-200 bg-white p-6">
                <div class="flex flex-wrap items-start justify-between gap-4">
                    <div>
                        <h2 class="text-xl font-bold text-slate-800">${{ number_format($payment->amount, 2) }}</h2>
                        <p class="mt-1 font-mono text-xs text-slate-400">{{ $payment->id }}</p>
                    </div>
                    <span class="inline-flex items-center rounded-full bg-slate-100 px-3 py-1 text-sm font-medium text-slate-400" title="No payment status field exists in the backend yet">
                        Pending backend support
                    </span>
                </div>

                <dl class="mt-6 grid grid-cols-1 gap-4 sm:grid-cols-2">
                    <div>
                        <dt class="text-xs font-medium uppercase text-slate-400">Payment Date</dt>
                        <dd class="text-sm text-slate-700">{{ $payment->payment_date->format('M j, Y') }}</dd>
                    </div>
                    <div>
                        <dt class="text-xs font-medium uppercase text-slate-400">Method</dt>
                        <dd class="text-sm text-slate-700">{{ $payment->payment_method ? ucwords(str_replace('_', ' ', $payment->payment_method)) : '—' }}</dd>
                    </div>
                    @if ($payment->reference_notes)
                        <div class="sm:col-span-2">
                            <dt class="text-xs font-medium uppercase text-slate-400">Notes</dt>
                            <dd class="text-sm text-slate-700">{{ $payment->reference_notes }}</dd>
                        </div>
                    @endif
                </dl>
            </div>

            <div class="rounded-xl border border-slate-200 bg-white p-6">
                <h3 class="mb-4 text-sm font-semibold text-slate-700">Debt</h3>
                @if ($debt)
                    <dl class="grid grid-cols-1 gap-4 sm:grid-cols-2">
                        <div>
                            <dt class="text-xs font-medium uppercase text-slate-400">Reference</dt>
                            <dd class="text-sm">
                                <a href="{{ route('admin.recovery-debts.show', $debt) }}" class="font-medium text-deendoon-teal hover:underline">{{ $debt->reference_number }}</a>
                            </dd>
                        </div>
                        <div>
                            <dt class="text-xs font-medium uppercase text-slate-400">Status</dt>
                            <dd class="text-sm">
                                <span class="inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium {{ $debtStatusTone[$debt->debt_status] ?? 'bg-slate-100 text-slate-500' }}">
                                    {{ $debtStatuses[$debt->debt_status] ?? ucfirst($debt->debt_status) }}
                                </span>
                            </dd>
                        </div>
                        <div>
                            <dt class="text-xs font-medium uppercase text-slate-400">Debt Amount</dt>
                            <dd class="text-sm text-slate-700">${{ number_format($debt->amount, 2) }}</dd>
                        </div>
                        <div>
                            <dt class="text-xs font-medium uppercase text-slate-400">Remaining Balance</dt>
                            <dd class="text-sm text-slate-700">${{ number_format($debt->remaining_balance, 2) }}</dd>
                        </div>
                        <div class="sm:col-span-2">
                            <dt class="text-xs font-medium uppercase text-slate-400">Recovery Stage</dt>
                            <dd class="text-sm text-slate-700">{{ $debt->recovery_stage }}. {{ $stages[$debt->recovery_stage] ?? '—' }}</dd>
                        </div>
                    </dl>
                @else
                    <p class="text-sm text-slate-400">The related debt could not be found.</p>
                @endif
            </div>
        </div>

        <div class="space-y-6">
            <div class="rounded-xl border border-slate-200 bg-white p-6">
                <h3 class="mb-4 text-sm font-semibold text-slate-700">Business</h3>
                @if ($tenant)
                    <p class="text-sm">
                        <a href="{{ route('admin.businesses.show', $tenant) }}" class="font-medium text-deendoon-teal hover:underline">{{ $tenant->business_name }}</a>
                    </p>
                @else
                    <p class="text-sm text-slate-400">—</p>
                @endif
            </div>

            <div class="rounded-xl border border-slate-200 bg-white p-6">
                <h3 class="mb-4 text-sm font-semibold text-slate-700">Debtor</h3>
                @if ($customer)
                    <p class="text-sm">
                        <a href="{{ route('admin.debtors.show', $customer) }}" class="font-medium text-deendoon-teal hover:underline">{{ $customer->name }}</a>
                    </p>
                    <p class="mt-1 text-xs text-slate-400">{{ $customer->phone }}</p>
                @else
                    <p class="text-sm text-slate-400">—</p>
                @endif
            </div>
        </div>
    </div>
@endsection
