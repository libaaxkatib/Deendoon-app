@extends('admin.layout')

@section('content')
    @php
        $statusTone = [
            'paid' => 'success',
            'partial_paid' => 'info',
            'overdue' => 'danger',
            'written_off' => 'danger',
            'cancelled' => 'muted',
            'draft' => 'muted',
            'pending' => 'warning',
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
        <form method="GET" action="{{ route('admin.recovery-debts.index') }}" class="flex flex-1 flex-wrap gap-2">
            <input type="text" name="search" value="{{ request('search') }}" placeholder="Search reference or debtor name..."
                   class="min-w-[220px] flex-1 rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-deendoon-teal focus:outline-none focus:ring-1 focus:ring-deendoon-teal">
            <select name="status" class="rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-deendoon-teal focus:outline-none focus:ring-1 focus:ring-deendoon-teal">
                <option value="">All statuses</option>
                @foreach ($statuses as $value => $label)
                    <option value="{{ $value }}" @selected(request('status') === $value)>{{ $label }}</option>
                @endforeach
            </select>
            <select name="stage" class="rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-deendoon-teal focus:outline-none focus:ring-1 focus:ring-deendoon-teal">
                <option value="">All recovery stages</option>
                @foreach ($stages as $value => $label)
                    <option value="{{ $value }}" @selected((string) request('stage') === (string) $value)>{{ $value }}. {{ $label }}</option>
                @endforeach
            </select>
            <label class="flex items-center gap-2 rounded-lg border border-slate-300 px-3 py-2 text-sm text-slate-600">
                <input type="checkbox" name="overdue_only" value="1" @checked(request()->boolean('overdue_only'))
                       class="rounded border-slate-300 text-deendoon-teal focus:ring-deendoon-teal">
                Overdue only
            </label>
            <button type="submit" class="rounded-lg bg-deendoon-teal px-4 py-2 text-sm font-semibold text-white hover:bg-deendoon-teal-dark">
                Filter
            </button>
            @if (request()->filled('search') || request()->filled('status') || request()->filled('stage') || request()->filled('overdue_only'))
                <a href="{{ route('admin.recovery-debts.index') }}" class="rounded-lg px-4 py-2 text-sm font-medium text-slate-500 hover:text-slate-700">Clear</a>
            @endif
        </form>
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
                    <th class="px-4 py-3">Due Date</th>
                    <th class="px-4 py-3"></th>
                </tr>
            </thead>
            <tbody class="divide-y divide-slate-100">
                @forelse ($debts as $debt)
                    <tr class="hover:bg-slate-50">
                        <td class="px-4 py-3 font-medium text-slate-800">{{ $debt->reference_number }}</td>
                        <td class="px-4 py-3 text-slate-600">{{ $debt->customer?->tenant?->business_name ?? '—' }}</td>
                        <td class="px-4 py-3 text-slate-600">{{ $debt->customer?->name ?? '—' }}</td>
                        <td class="px-4 py-3 text-slate-600">${{ number_format($debt->amount, 2) }}</td>
                        <td class="px-4 py-3 text-slate-600">${{ number_format($debt->remaining_balance, 2) }}</td>
                        <td class="px-4 py-3">
                            <span class="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium {{ $toneClasses[$statusTone[$debt->debt_status] ?? 'muted'] }}">
                                {{ $statuses[$debt->debt_status] ?? ucfirst($debt->debt_status) }}
                            </span>
                        </td>
                        <td class="px-4 py-3 text-slate-500">{{ $debt->recovery_stage }}. {{ $stages[$debt->recovery_stage] ?? '—' }}</td>
                        <td class="px-4 py-3 text-slate-500">{{ $debt->due_date->format('M j, Y') }}</td>
                        <td class="px-4 py-3 text-right">
                            <a href="{{ route('admin.recovery-debts.show', $debt) }}" class="text-sm font-medium text-deendoon-teal hover:underline">View</a>
                        </td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="9" class="px-4 py-8 text-center text-slate-400">No debts match your filters.</td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>

    <div class="mt-4">
        {{ $debts->links() }}
    </div>
@endsection
