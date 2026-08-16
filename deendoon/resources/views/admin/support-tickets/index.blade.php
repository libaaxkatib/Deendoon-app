@extends('admin.layout')

@section('content')
    @php
        $statusTone = [
            'open' => 'bg-deendoon-info/10 text-indigo-700',
            'in_progress' => 'bg-deendoon-warning/10 text-amber-700',
            'resolved' => 'bg-deendoon-success/10 text-emerald-700',
            'closed' => 'bg-slate-100 text-slate-500',
        ];
        $priorityTone = [
            'low' => 'bg-slate-100 text-slate-500',
            'medium' => 'bg-deendoon-info/10 text-indigo-700',
            'high' => 'bg-deendoon-warning/10 text-amber-700',
            'urgent' => 'bg-deendoon-danger/10 text-red-700',
        ];
    @endphp

    <div class="mb-4 flex flex-col gap-3">
        <form method="GET" action="{{ route('admin.support-tickets.index') }}" class="flex flex-1 flex-wrap gap-2">
            <input type="text" name="search" value="{{ request('search') }}" placeholder="Search reference, subject, or business..."
                   class="min-w-[240px] flex-1 rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-deendoon-teal focus:outline-none focus:ring-1 focus:ring-deendoon-teal">
            <select name="tenant_id" class="rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-deendoon-teal focus:outline-none focus:ring-1 focus:ring-deendoon-teal">
                <option value="">All Businesses</option>
                @foreach ($tenants as $tenant)
                    <option value="{{ $tenant->id }}" @selected(request('tenant_id') === $tenant->id)>{{ $tenant->business_name }}</option>
                @endforeach
            </select>
            <select name="status" class="rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-deendoon-teal focus:outline-none focus:ring-1 focus:ring-deendoon-teal">
                <option value="">All statuses</option>
                @foreach ($statuses as $value => $label)
                    <option value="{{ $value }}" @selected(request('status') === $value)>{{ $label }}</option>
                @endforeach
            </select>
            <select name="priority" class="rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-deendoon-teal focus:outline-none focus:ring-1 focus:ring-deendoon-teal">
                <option value="">All priorities</option>
                @foreach ($priorities as $value => $label)
                    <option value="{{ $value }}" @selected(request('priority') === $value)>{{ $label }}</option>
                @endforeach
            </select>
            <select name="category" class="rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-deendoon-teal focus:outline-none focus:ring-1 focus:ring-deendoon-teal">
                <option value="">All categories</option>
                @foreach ($categories as $value => $label)
                    <option value="{{ $value }}" @selected(request('category') === $value)>{{ $label }}</option>
                @endforeach
            </select>
            <input type="date" name="date_from" value="{{ request('date_from') }}"
                   class="rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-deendoon-teal focus:outline-none focus:ring-1 focus:ring-deendoon-teal">
            <input type="date" name="date_to" value="{{ request('date_to') }}"
                   class="rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-deendoon-teal focus:outline-none focus:ring-1 focus:ring-deendoon-teal">
            <button type="submit" class="rounded-lg bg-deendoon-teal px-4 py-2 text-sm font-semibold text-white hover:bg-deendoon-teal-dark">
                Filter
            </button>
            @if (request()->anyFilled(['search', 'tenant_id', 'status', 'priority', 'category', 'date_from', 'date_to']))
                <a href="{{ route('admin.support-tickets.index') }}" class="rounded-lg px-4 py-2 text-sm font-medium text-slate-500 hover:text-slate-700">Clear</a>
            @endif
        </form>
    </div>

    <div class="overflow-x-auto rounded-xl border border-slate-200 bg-white">
        <table class="min-w-full divide-y divide-slate-200 text-sm">
            <thead class="bg-slate-50">
                <tr class="text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                    <th class="px-4 py-3">Reference</th>
                    <th class="px-4 py-3">Business</th>
                    <th class="px-4 py-3">Subject</th>
                    <th class="px-4 py-3">Category</th>
                    <th class="px-4 py-3">Priority</th>
                    <th class="px-4 py-3">Status</th>
                    <th class="px-4 py-3">Created</th>
                    <th class="px-4 py-3"></th>
                </tr>
            </thead>
            <tbody class="divide-y divide-slate-100">
                @forelse ($tickets as $ticket)
                    <tr class="hover:bg-slate-50">
                        <td class="px-4 py-3 font-medium text-slate-800">{{ $ticket->reference_number }}</td>
                        <td class="px-4 py-3 text-slate-600">{{ $ticket->tenant?->business_name ?? '—' }}</td>
                        <td class="px-4 py-3 text-slate-600">{{ $ticket->subject }}</td>
                        <td class="px-4 py-3 text-slate-600">{{ $categories[$ticket->category] ?? ucfirst($ticket->category) }}</td>
                        <td class="px-4 py-3">
                            <span class="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium {{ $priorityTone[$ticket->priority] ?? 'bg-slate-100 text-slate-500' }}">
                                {{ $priorities[$ticket->priority] ?? ucfirst($ticket->priority) }}
                            </span>
                        </td>
                        <td class="px-4 py-3">
                            <span class="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium {{ $statusTone[$ticket->status] ?? 'bg-slate-100 text-slate-500' }}">
                                {{ $statuses[$ticket->status] ?? ucfirst($ticket->status) }}
                            </span>
                        </td>
                        <td class="px-4 py-3 text-slate-500">{{ $ticket->created_at->format('M j, Y') }}</td>
                        <td class="px-4 py-3 text-right">
                            <a href="{{ route('admin.support-tickets.show', $ticket) }}" class="text-sm font-medium text-deendoon-teal hover:underline">View</a>
                        </td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="8" class="px-4 py-8 text-center text-slate-400">No support tickets match your filters.</td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>

    <div class="mt-4">
        {{ $tickets->links() }}
    </div>
@endsection
