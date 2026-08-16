@extends('admin.layout')

@section('content')
    <div class="mb-4 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <form method="GET" action="{{ route('admin.businesses.index') }}" class="flex flex-1 flex-wrap gap-2">
            <input type="text" name="search" value="{{ request('search') }}" placeholder="Search business name..."
                   class="min-w-[220px] flex-1 rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-deendoon-teal focus:outline-none focus:ring-1 focus:ring-deendoon-teal">
            <select name="status" class="rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-deendoon-teal focus:outline-none focus:ring-1 focus:ring-deendoon-teal">
                <option value="">All statuses</option>
                <option value="active" @selected(request('status') === 'active')>Active</option>
                <option value="suspended" @selected(request('status') === 'suspended')>Suspended</option>
            </select>
            <button type="submit" class="rounded-lg bg-deendoon-teal px-4 py-2 text-sm font-semibold text-white hover:bg-deendoon-teal-dark">
                Filter
            </button>
            @if (request()->filled('search') || request()->filled('status'))
                <a href="{{ route('admin.businesses.index') }}" class="rounded-lg px-4 py-2 text-sm font-medium text-slate-500 hover:text-slate-700">Clear</a>
            @endif
        </form>
    </div>

    <div class="overflow-x-auto rounded-xl border border-slate-200 bg-white">
        <table class="min-w-full divide-y divide-slate-200 text-sm">
            <thead class="bg-slate-50">
                <tr class="text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                    <th class="px-4 py-3">Business</th>
                    <th class="px-4 py-3">Users</th>
                    <th class="px-4 py-3">Subscription</th>
                    <th class="px-4 py-3">Status</th>
                    <th class="px-4 py-3">Registered</th>
                    <th class="px-4 py-3"></th>
                </tr>
            </thead>
            <tbody class="divide-y divide-slate-100">
                @forelse ($tenants as $tenant)
                    <tr class="hover:bg-slate-50">
                        <td class="px-4 py-3 font-medium text-slate-800">{{ $tenant->business_name }}</td>
                        <td class="px-4 py-3 text-slate-600">{{ $tenant->users_count }}</td>
                        <td class="px-4 py-3 text-slate-600">{{ $tenant->subscription?->plan?->name ?? '—' }}</td>
                        <td class="px-4 py-3">
                            @if ($tenant->status === 'suspended')
                                <span class="inline-flex items-center rounded-full bg-deendoon-danger/10 px-2.5 py-0.5 text-xs font-medium text-red-700">Suspended</span>
                            @else
                                <span class="inline-flex items-center rounded-full bg-deendoon-success/10 px-2.5 py-0.5 text-xs font-medium text-emerald-700">Active</span>
                            @endif
                        </td>
                        <td class="px-4 py-3 text-slate-500">{{ $tenant->created_at->format('M j, Y') }}</td>
                        <td class="px-4 py-3 text-right">
                            <a href="{{ route('admin.businesses.show', $tenant) }}" class="text-sm font-medium text-deendoon-teal hover:underline">View</a>
                        </td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="6" class="px-4 py-8 text-center text-slate-400">No businesses match your filters.</td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>

    <div class="mt-4">
        {{ $tenants->links() }}
    </div>
@endsection
