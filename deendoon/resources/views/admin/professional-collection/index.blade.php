@extends('admin.layout')

@section('content')
    @php
        $statusTone = [
            'submitted' => 'bg-slate-100 text-slate-500',
            'under_review' => 'bg-deendoon-warning/10 text-amber-700',
            'need_more_information' => 'bg-deendoon-warning/10 text-amber-700',
            'accepted' => 'bg-deendoon-info/10 text-indigo-700',
            'assigned' => 'bg-deendoon-info/10 text-indigo-700',
            'in_progress' => 'bg-deendoon-info/10 text-indigo-700',
            'recovered' => 'bg-deendoon-success/10 text-emerald-700',
            'closed' => 'bg-slate-100 text-slate-500',
        ];
    @endphp

    <div class="mb-4 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <form method="GET" action="{{ route('admin.professional-collection.index') }}" class="flex flex-1 flex-wrap gap-2">
            <input type="text" name="search" value="{{ request('search') }}" placeholder="Search reference, debtor, or debt reference..."
                   class="min-w-[240px] flex-1 rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-deendoon-teal focus:outline-none focus:ring-1 focus:ring-deendoon-teal">
            <select name="status" class="rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-deendoon-teal focus:outline-none focus:ring-1 focus:ring-deendoon-teal">
                <option value="">All statuses</option>
                @foreach ($statuses as $value => $label)
                    <option value="{{ $value }}" @selected(request('status') === $value)>{{ $label }}</option>
                @endforeach
            </select>
            <input type="date" name="date_from" value="{{ request('date_from') }}"
                   class="rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-deendoon-teal focus:outline-none focus:ring-1 focus:ring-deendoon-teal">
            <input type="date" name="date_to" value="{{ request('date_to') }}"
                   class="rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-deendoon-teal focus:outline-none focus:ring-1 focus:ring-deendoon-teal">
            <button type="submit" class="rounded-lg bg-deendoon-teal px-4 py-2 text-sm font-semibold text-white hover:bg-deendoon-teal-dark">
                Filter
            </button>
            @if (request()->filled('search') || request()->filled('status') || request()->filled('date_from') || request()->filled('date_to'))
                <a href="{{ route('admin.professional-collection.index') }}" class="rounded-lg px-4 py-2 text-sm font-medium text-slate-500 hover:text-slate-700">Clear</a>
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
                    <th class="px-4 py-3">Debt Reference</th>
                    <th class="px-4 py-3">Debt Amount</th>
                    <th class="px-4 py-3">Status</th>
                    <th class="px-4 py-3">Request Date</th>
                    <th class="px-4 py-3"></th>
                </tr>
            </thead>
            <tbody class="divide-y divide-slate-100">
                @forelse ($requests as $pcr)
                    @php $debt = $pcr->collectionCase?->debt; @endphp
                    <tr class="hover:bg-slate-50">
                        <td class="px-4 py-3 font-medium text-slate-800">{{ $pcr->reference_number }}</td>
                        <td class="px-4 py-3 text-slate-600">{{ $debt?->customer?->tenant?->business_name ?? '—' }}</td>
                        <td class="px-4 py-3 text-slate-600">{{ $debt?->customer?->name ?? '—' }}</td>
                        <td class="px-4 py-3 text-slate-600">{{ $debt?->reference_number ?? '—' }}</td>
                        <td class="px-4 py-3 text-slate-600">{{ $debt ? '$'.number_format($debt->amount, 2) : '—' }}</td>
                        <td class="px-4 py-3">
                            <span class="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium {{ $statusTone[$pcr->status] ?? 'bg-slate-100 text-slate-500' }}">
                                {{ $statuses[$pcr->status] ?? ucfirst($pcr->status) }}
                            </span>
                        </td>
                        <td class="px-4 py-3 text-slate-500">{{ $pcr->created_at->format('M j, Y') }}</td>
                        <td class="px-4 py-3 text-right">
                            <a href="{{ route('admin.professional-collection.show', $pcr) }}" class="text-sm font-medium text-deendoon-teal hover:underline">View</a>
                        </td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="8" class="px-4 py-8 text-center text-slate-400">No Professional Collection Requests match your filters.</td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>

    <div class="mt-4">
        {{ $requests->links() }}
    </div>
@endsection
