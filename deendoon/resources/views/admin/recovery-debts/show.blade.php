@extends('admin.layout')

@section('content')
    @php
        $statusTone = [
            'paid' => 'bg-deendoon-success/10 text-emerald-700',
            'partial_paid' => 'bg-deendoon-info/10 text-indigo-700',
            'overdue' => 'bg-deendoon-danger/10 text-red-700',
            'written_off' => 'bg-deendoon-danger/10 text-red-700',
            'cancelled' => 'bg-slate-100 text-slate-500',
            'draft' => 'bg-slate-100 text-slate-500',
            'pending' => 'bg-deendoon-warning/10 text-amber-700',
        ];
        $caseTone = fn ($status) => $status === 'open' ? 'bg-deendoon-warning/10 text-amber-700' : 'bg-slate-100 text-slate-500';
    @endphp

    <div class="mb-4">
        <a href="{{ route('admin.recovery-debts.index') }}" class="text-sm font-medium text-deendoon-teal hover:underline">&larr; Back to Recovery & Debts</a>
    </div>

    <div class="grid grid-cols-1 gap-6 lg:grid-cols-3">
        <div class="space-y-6 lg:col-span-2">
            <div class="rounded-xl border border-slate-200 bg-white p-6">
                <div class="flex flex-wrap items-start justify-between gap-4">
                    <div>
                        <h2 class="text-xl font-bold text-slate-800">{{ $debt->reference_number }}</h2>
                        <p class="mt-1 text-sm text-slate-500">Due {{ $debt->due_date->format('M j, Y') }}</p>
                    </div>
                    <span class="inline-flex items-center rounded-full px-3 py-1 text-sm font-medium {{ $statusTone[$debt->debt_status] ?? 'bg-slate-100 text-slate-500' }}">
                        {{ \App\Http\Controllers\Admin\AdminDebtController::STATUSES[$debt->debt_status] ?? ucfirst($debt->debt_status) }}
                    </span>
                </div>

                <dl class="mt-6 grid grid-cols-1 gap-4 sm:grid-cols-2">
                    <div>
                        <dt class="text-xs font-medium uppercase text-slate-400">Amount</dt>
                        <dd class="text-sm font-medium text-slate-700">${{ number_format($debt->amount, 2) }}</dd>
                    </div>
                    <div>
                        <dt class="text-xs font-medium uppercase text-slate-400">Remaining Balance</dt>
                        <dd class="text-sm font-medium text-slate-700">${{ number_format($debt->remaining_balance, 2) }}</dd>
                    </div>
                    <div>
                        <dt class="text-xs font-medium uppercase text-slate-400">Debtor</dt>
                        <dd class="text-sm text-slate-700">{{ $debt->customer?->name ?? '—' }} <span class="text-slate-400">— {{ $debt->customer?->phone }}</span></dd>
                    </div>
                    <div>
                        <dt class="text-xs font-medium uppercase text-slate-400">Business</dt>
                        <dd class="text-sm text-slate-700">
                            @if ($debt->customer?->tenant)
                                <a href="{{ route('admin.businesses.show', $debt->customer->tenant) }}" class="text-deendoon-teal hover:underline">{{ $debt->customer->tenant->business_name }}</a>
                            @else
                                —
                            @endif
                        </dd>
                    </div>
                    @if ($debt->notes)
                        <div class="sm:col-span-2">
                            <dt class="text-xs font-medium uppercase text-slate-400">Notes</dt>
                            <dd class="text-sm text-slate-700">{{ $debt->notes }}</dd>
                        </div>
                    @endif
                </dl>

                <div class="mt-6 border-t border-slate-100 pt-6">
                    <dt class="mb-2 text-xs font-medium uppercase text-slate-400">Recovery Stage</dt>
                    <div class="flex items-center gap-1">
                        @foreach ($stages as $value => $label)
                            <div class="flex flex-1 flex-col items-center gap-1" title="{{ $value }}. {{ $label }}">
                                <div class="h-2 w-full rounded-full {{ $value <= $debt->recovery_stage ? 'bg-deendoon-teal' : 'bg-slate-200' }}"></div>
                                <span class="text-center text-[10px] leading-tight text-slate-400">{{ $label }}</span>
                            </div>
                        @endforeach
                    </div>
                </div>
            </div>

            <div class="rounded-xl border border-slate-200 bg-white p-6">
                <h3 class="mb-4 text-sm font-semibold text-slate-700">Payment History</h3>
                <ul class="divide-y divide-slate-100 text-sm">
                    @forelse ($debt->payments as $payment)
                        <li class="flex items-center justify-between py-2">
                            <span class="text-slate-700">
                                ${{ number_format($payment->amount, 2) }}
                                @if ($payment->payment_method)
                                    <span class="text-slate-400">via {{ $payment->payment_method }}</span>
                                @endif
                            </span>
                            <span class="text-xs text-slate-400">{{ $payment->payment_date->format('M j, Y') }}</span>
                        </li>
                    @empty
                        <li class="py-2 text-slate-400">No payments recorded yet.</li>
                    @endforelse
                </ul>
            </div>
        </div>

        <div class="space-y-6">
            <div class="rounded-xl border border-slate-200 bg-white p-6">
                <h3 class="mb-4 text-sm font-semibold text-slate-700">Collection Cases</h3>
                @forelse ($debt->collectionCases as $case)
                    <div class="mb-3 rounded-lg bg-slate-50 p-3 text-sm last:mb-0">
                        <div class="flex items-center justify-between">
                            <span class="font-medium text-slate-700">{{ $case->reference_number }}</span>
                            <span class="inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium {{ $caseTone($case->case_status) }}">
                                {{ ucfirst($case->case_status) }}
                            </span>
                        </div>
                        @if ($case->closure_outcome)
                            <p class="mt-1 text-xs text-slate-500">Outcome: {{ $case->closure_outcome }}</p>
                        @endif
                        @php $latestRequest = $case->professionalCollectionRequests->sortByDesc('created_at')->first(); @endphp
                        @if ($latestRequest)
                            <p class="mt-1 text-xs text-slate-500">
                                Professional Collection: <span class="font-medium">{{ str_replace('_', ' ', $latestRequest->status) }}</span>
                            </p>
                        @endif
                    </div>
                @empty
                    <p class="text-sm text-slate-400">No collection case has been opened for this debt.</p>
                @endforelse
            </div>
        </div>
    </div>
@endsection
