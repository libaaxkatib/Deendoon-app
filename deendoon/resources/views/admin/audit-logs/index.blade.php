@extends('admin.layout')

@section('content')
    <div class="mb-4 flex flex-col gap-3">
        <form method="GET" action="{{ route('admin.audit-logs.index') }}" class="flex flex-1 flex-wrap gap-2">
            <input type="text" name="search" value="{{ request('search') }}" placeholder="Search reason or entity ID..."
                   class="min-w-[240px] flex-1 rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-deendoon-teal focus:outline-none focus:ring-1 focus:ring-deendoon-teal">
            <select name="action" class="rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-deendoon-teal focus:outline-none focus:ring-1 focus:ring-deendoon-teal">
                <option value="">All actions</option>
                @foreach ($actionOptions as $value => $label)
                    <option value="{{ $value }}" @selected(request('action') === $value)>{{ $label }}</option>
                @endforeach
            </select>
            <select name="entity_type" class="rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-deendoon-teal focus:outline-none focus:ring-1 focus:ring-deendoon-teal">
                <option value="">All entity types</option>
                @foreach ($entityTypeOptions as $value => $label)
                    <option value="{{ $value }}" @selected(request('entity_type') === $value)>{{ $label }}</option>
                @endforeach
            </select>
            <select name="tenant_id" class="rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-deendoon-teal focus:outline-none focus:ring-1 focus:ring-deendoon-teal">
                <option value="">All businesses</option>
                @foreach ($tenants as $tenant)
                    <option value="{{ $tenant->id }}" @selected(request('tenant_id') === $tenant->id)>{{ $tenant->business_name }}</option>
                @endforeach
            </select>
            <input type="date" name="date_from" value="{{ request('date_from') }}"
                   class="rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-deendoon-teal focus:outline-none focus:ring-1 focus:ring-deendoon-teal">
            <input type="date" name="date_to" value="{{ request('date_to') }}"
                   class="rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-deendoon-teal focus:outline-none focus:ring-1 focus:ring-deendoon-teal">
            <button type="submit" class="rounded-lg bg-deendoon-teal px-4 py-2 text-sm font-semibold text-white hover:bg-deendoon-teal-dark">
                Filter
            </button>
            @if (request()->anyFilled(['search', 'action', 'entity_type', 'tenant_id', 'date_from', 'date_to']))
                <a href="{{ route('admin.audit-logs.index') }}" class="rounded-lg px-4 py-2 text-sm font-medium text-slate-500 hover:text-slate-700">Clear</a>
            @endif
        </form>
    </div>

    <div class="overflow-x-auto rounded-xl border border-slate-200 bg-white">
        <table class="min-w-full divide-y divide-slate-200 text-sm">
            <thead class="bg-slate-50">
                <tr class="text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                    <th class="px-4 py-3">Business</th>
                    <th class="px-4 py-3">Actor</th>
                    <th class="px-4 py-3">Action</th>
                    <th class="px-4 py-3">Entity Type</th>
                    <th class="px-4 py-3">Reason</th>
                    <th class="px-4 py-3">Occurred At</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-slate-100">
                @forelse ($logs as $log)
                    <tr>
                        <td class="px-4 py-3 text-slate-600">{{ $tenantNames[$log->tenant_id] ?? '—' }}</td>
                        <td class="px-4 py-3 text-slate-600">{{ $log->user_id ? ($userNames[trim($log->user_id)] ?? 'Unknown') : 'System' }}</td>
                        <td class="px-4 py-3">
                            <span class="inline-flex items-center rounded-full bg-deendoon-teal/10 px-2.5 py-0.5 text-xs font-medium text-deendoon-teal">
                                {{ ucwords(str_replace('_', ' ', $log->action)) }}
                            </span>
                        </td>
                        <td class="px-4 py-3 text-slate-600">{{ ucwords(str_replace('_', ' ', $log->entity_type)) }}</td>
                        <td class="max-w-md whitespace-normal break-words px-4 py-3 text-slate-600">{{ $log->reason ?? '—' }}</td>
                        <td class="px-4 py-3 text-slate-500">{{ $log->occurred_at->format('M j, Y g:i A') }}</td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="6" class="px-4 py-8 text-center text-slate-400">No audit log entries match your filters.</td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>

    <div class="mt-4">
        {{ $logs->links() }}
    </div>
@endsection
