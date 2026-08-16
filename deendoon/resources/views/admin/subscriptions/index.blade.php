@extends('admin.layout')

@section('content')
    @php
        $statusTone = [
            'trialing' => 'bg-deendoon-info/10 text-indigo-700',
            'active' => 'bg-deendoon-success/10 text-emerald-700',
            'expired' => 'bg-deendoon-danger/10 text-red-700',
        ];
    @endphp

    <div class="mb-4 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <form method="GET" action="{{ route('admin.subscriptions.index') }}" class="flex flex-1 flex-wrap gap-2">
            <input type="text" name="search" value="{{ request('search') }}" placeholder="Search business name..."
                   class="min-w-[220px] flex-1 rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-deendoon-teal focus:outline-none focus:ring-1 focus:ring-deendoon-teal">
            <select name="status" class="rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-deendoon-teal focus:outline-none focus:ring-1 focus:ring-deendoon-teal">
                <option value="">All statuses</option>
                @foreach ($subscriptionStatuses as $value => $label)
                    <option value="{{ $value }}" @selected(request('status') === $value)>{{ $label }}</option>
                @endforeach
                <option value="no_subscription" @selected(request('status') === 'no_subscription')>No Subscription</option>
            </select>
            <select name="plan" class="rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-deendoon-teal focus:outline-none focus:ring-1 focus:ring-deendoon-teal">
                <option value="">All plans</option>
                @foreach ($plans as $plan)
                    <option value="{{ $plan->id }}" @selected(request('plan') === $plan->id)>{{ $plan->name }}</option>
                @endforeach
            </select>
            <label class="flex items-center gap-2 rounded-lg border border-slate-300 px-3 py-2 text-sm text-slate-600">
                <input type="checkbox" name="pending_only" value="1" @checked(request()->boolean('pending_only'))
                       class="rounded border-slate-300 text-deendoon-teal focus:ring-deendoon-teal">
                Pending requests only
            </label>
            <button type="submit" class="rounded-lg bg-deendoon-teal px-4 py-2 text-sm font-semibold text-white hover:bg-deendoon-teal-dark">
                Filter
            </button>
            @if (request()->filled('search') || request()->filled('status') || request()->filled('plan') || request()->filled('pending_only'))
                <a href="{{ route('admin.subscriptions.index') }}" class="rounded-lg px-4 py-2 text-sm font-medium text-slate-500 hover:text-slate-700">Clear</a>
            @endif
        </form>
    </div>

    <div class="overflow-x-auto rounded-xl border border-slate-200 bg-white">
        <table class="min-w-full divide-y divide-slate-200 text-sm">
            <thead class="bg-slate-50">
                <tr class="text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                    <th class="px-4 py-3">Business</th>
                    <th class="px-4 py-3">Plan</th>
                    <th class="px-4 py-3">Billing Cycle</th>
                    <th class="px-4 py-3">Status</th>
                    <th class="px-4 py-3">Current Period</th>
                    <th class="px-4 py-3">Price</th>
                    <th class="px-4 py-3">Pending Requests</th>
                    <th class="px-4 py-3"></th>
                </tr>
            </thead>
            <tbody class="divide-y divide-slate-100">
                @forelse ($tenants as $tenant)
                    @php $subscription = $tenant->subscription; @endphp
                    <tr class="hover:bg-slate-50">
                        <td class="px-4 py-3 font-medium text-slate-800">{{ $tenant->business_name }}</td>
                        <td class="px-4 py-3 text-slate-600">{{ $subscription?->plan?->name ?? '—' }}</td>
                        <td class="px-4 py-3 text-slate-600">{{ $subscription ? 'Monthly' : '—' }}</td>
                        <td class="px-4 py-3">
                            @if ($subscription)
                                <span class="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium {{ $statusTone[$subscription->status] ?? 'bg-slate-100 text-slate-500' }}">
                                    {{ $subscriptionStatuses[$subscription->status] ?? ucfirst($subscription->status) }}
                                </span>
                            @else
                                <span class="inline-flex items-center rounded-full bg-slate-100 px-2.5 py-0.5 text-xs font-medium text-slate-500">No Subscription</span>
                            @endif
                        </td>
                        <td class="px-4 py-3 text-slate-500">
                            @if ($subscription?->started_at)
                                {{ $subscription->started_at->format('M j, Y') }} – {{ $subscription->expires_at?->format('M j, Y') ?? 'No expiry' }}
                            @else
                                —
                            @endif
                        </td>
                        <td class="px-4 py-3 text-slate-600">{{ $subscription?->plan ? '$'.number_format($subscription->plan->monthly_price, 2).'/mo' : '—' }}</td>
                        <td class="px-4 py-3">
                            @if ($tenant->pending_change_requests_count > 0)
                                <span class="mr-1 inline-flex items-center rounded-full bg-deendoon-warning/10 px-2 py-0.5 text-[11px] font-medium text-amber-700">Plan Change</span>
                            @endif
                            @if ($tenant->pending_storage_addons_count > 0)
                                <span class="inline-flex items-center rounded-full bg-deendoon-warning/10 px-2 py-0.5 text-[11px] font-medium text-amber-700">Storage Add-on</span>
                            @endif
                            @if ($tenant->pending_change_requests_count === 0 && $tenant->pending_storage_addons_count === 0)
                                <span class="text-slate-400">—</span>
                            @endif
                        </td>
                        <td class="px-4 py-3 text-right">
                            <a href="{{ route('admin.subscriptions.show', $tenant) }}" class="text-sm font-medium text-deendoon-teal hover:underline">View</a>
                        </td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="8" class="px-4 py-8 text-center text-slate-400">No businesses match your filters.</td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>

    <div class="mt-4">
        {{ $tenants->links() }}
    </div>
@endsection
