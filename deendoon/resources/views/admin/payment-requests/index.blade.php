@extends('admin.layout')

@section('content')
    @php
        $requestTone = [
            'pending' => 'bg-deendoon-warning/10 text-amber-700',
            'approved' => 'bg-deendoon-success/10 text-emerald-700',
            'rejected' => 'bg-deendoon-danger/10 text-red-700',
            'cancelled' => 'bg-slate-100 text-slate-500',
        ];
    @endphp

    <div class="mb-4 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <form method="GET" action="{{ route('admin.payment-requests.index') }}" class="flex flex-1 flex-wrap gap-2">
            <input type="text" name="search" value="{{ request('search') }}" placeholder="Search business name..."
                   class="min-w-[220px] flex-1 rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-deendoon-teal focus:outline-none focus:ring-1 focus:ring-deendoon-teal">
            <select name="status" class="rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-deendoon-teal focus:outline-none focus:ring-1 focus:ring-deendoon-teal">
                <option value="">All statuses</option>
                @foreach ($requestStatuses as $value => $label)
                    <option value="{{ $value }}" @selected(request('status') === $value)>{{ $label }}</option>
                @endforeach
            </select>
            <button type="submit" class="rounded-lg bg-deendoon-teal px-4 py-2 text-sm font-semibold text-white hover:bg-deendoon-teal-dark">
                Filter
            </button>
            @if (request()->filled('search') || request()->filled('status'))
                <a href="{{ route('admin.payment-requests.index') }}" class="rounded-lg px-4 py-2 text-sm font-medium text-slate-500 hover:text-slate-700">Clear</a>
            @endif
        </form>
    </div>

    <div class="overflow-x-auto rounded-xl border border-slate-200 bg-white">
        <table class="min-w-full divide-y divide-slate-200 text-sm">
            <thead class="bg-slate-50">
                <tr class="text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                    <th class="px-4 py-3">Business</th>
                    <th class="px-4 py-3">Requested Plan</th>
                    <th class="px-4 py-3">From</th>
                    <th class="px-4 py-3">Payment Phone</th>
                    <th class="px-4 py-3">Payment Reference</th>
                    <th class="px-4 py-3">Status</th>
                    <th class="px-4 py-3">Requested</th>
                    <th class="px-4 py-3">Reviewed</th>
                    <th class="px-4 py-3"></th>
                </tr>
            </thead>
            <tbody class="divide-y divide-slate-100">
                @forelse ($requests as $request)
                    <tr class="hover:bg-slate-50">
                        <td class="px-4 py-3 font-medium text-slate-800">{{ $request->tenant?->business_name ?? '—' }}</td>
                        <td class="px-4 py-3 text-slate-600">{{ $request->requestedPlan?->name ?? '—' }}</td>
                        <td class="px-4 py-3 text-slate-500">{{ $request->currentPlan?->name ?? '—' }}</td>
                        <td class="px-4 py-3 text-slate-600">{{ $request->payment_phone ?? '—' }}</td>
                        <td class="px-4 py-3 text-slate-600">{{ $request->payment_reference ?? '—' }}</td>
                        <td class="px-4 py-3">
                            <span class="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium {{ $requestTone[$request->status] ?? 'bg-slate-100 text-slate-500' }}">
                                {{ $requestStatuses[$request->status] ?? ucfirst($request->status) }}
                            </span>
                        </td>
                        <td class="px-4 py-3 text-slate-500">{{ $request->requested_at?->format('M j, Y') }}</td>
                        <td class="px-4 py-3 text-slate-500">{{ $request->reviewed_at?->format('M j, Y') ?? '—' }}</td>
                        <td class="px-4 py-3 text-right">
                            <a href="{{ route('admin.subscriptions.show', $request->tenant_id) }}" class="text-sm font-medium text-deendoon-teal hover:underline">View</a>
                        </td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="9" class="px-4 py-8 text-center text-slate-400">No payment requests match your filters.</td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>

    <div class="mt-4">
        {{ $requests->links() }}
    </div>
@endsection
