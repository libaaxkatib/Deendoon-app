@extends('admin.layout')

@section('content')
    @php
        $fmt = fn ($n) => $n === null ? '—' : number_format($n);
        $money = fn ($n) => $n === null ? '—' : '$'.number_format($n, 0);
    @endphp

    @include('admin.reports.partials.filters', [
        'filterAction' => route('admin.reports.subscriptions'),
        'reportSlug' => 'subscriptions',
        'statuses' => $requestStatuses,
        'plans' => $plans,
    ])

    @include('admin.reports.partials.export-actions', ['reportSlug' => 'subscriptions'])

    <div class="mb-6 grid grid-cols-2 gap-4 sm:grid-cols-4">
        @include('admin.partials.stat-card', ['label' => 'Monthly Recurring Revenue', 'value' => $money($summary['monthly_recurring_revenue']), 'tone' => 'success'])
        @include('admin.partials.stat-card', ['label' => 'Change Requests Approved', 'value' => $fmt($summary['change_requests_approved'])])
        @include('admin.partials.stat-card', ['label' => 'Change Requests Rejected', 'value' => $fmt($summary['change_requests_rejected']), 'tone' => 'danger'])
        @include('admin.partials.stat-card', ['label' => 'Change Requests Pending', 'value' => $fmt($summary['change_requests_pending']), 'tone' => 'warning'])
    </div>

    <div class="mb-6 grid grid-cols-1 gap-4 lg:grid-cols-3">
        <div class="rounded-xl border border-slate-200 bg-white p-5">
            <h3 class="mb-4 text-sm font-semibold text-slate-700">Plan Distribution</h3>
            <ul class="space-y-2 text-sm">
                @forelse ($summary['plan_distribution'] as $plan => $count)
                    <li class="flex items-center justify-between">
                        <span class="text-slate-600">{{ $plan }}</span>
                        <span class="font-medium text-slate-800">{{ $fmt($count) }}</span>
                    </li>
                @empty
                    <li class="text-slate-400">No active subscriptions.</li>
                @endforelse
            </ul>
        </div>

        <div class="rounded-xl border border-slate-200 bg-white p-5">
            <h3 class="mb-4 text-sm font-semibold text-slate-700">Subscription Status Distribution</h3>
            <ul class="space-y-2 text-sm">
                @forelse ($summary['status_distribution'] as $status => $count)
                    <li class="flex items-center justify-between">
                        <span class="text-slate-600">{{ ucfirst($status) }}</span>
                        <span class="font-medium text-slate-800">{{ $fmt($count) }}</span>
                    </li>
                @empty
                    <li class="text-slate-400">No subscriptions found.</li>
                @endforelse
            </ul>
        </div>

        <div class="rounded-xl border border-slate-200 bg-white p-5">
            <h3 class="mb-4 text-sm font-semibold text-slate-700">Storage Add-ons</h3>
            <ul class="space-y-2 text-sm">
                <li class="flex items-center justify-between">
                    <span class="text-slate-600">Requested (in period)</span>
                    <span class="font-medium text-slate-800">{{ $fmt($summary['storage_addons_requested']) }}</span>
                </li>
                <li class="flex items-center justify-between">
                    <span class="text-slate-600">Currently Active</span>
                    <span class="font-medium text-slate-800">{{ $fmt($summary['storage_addons_active']) }}</span>
                </li>
            </ul>
        </div>
    </div>

    <div class="overflow-x-auto rounded-xl border border-slate-200 bg-white">
        <table class="min-w-full divide-y divide-slate-200 text-sm">
            <thead class="bg-slate-50">
                <tr class="text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                    <th class="px-4 py-3">Business</th>
                    <th class="px-4 py-3">Current Plan</th>
                    <th class="px-4 py-3">Requested Plan</th>
                    <th class="px-4 py-3">Status</th>
                    <th class="px-4 py-3">Requested</th>
                    <th class="px-4 py-3"></th>
                </tr>
            </thead>
            <tbody class="divide-y divide-slate-100">
                @forelse ($records as $changeRequest)
                    <tr class="hover:bg-slate-50">
                        <td class="px-4 py-3 font-medium text-slate-800">{{ $changeRequest->tenant?->business_name ?? '—' }}</td>
                        <td class="px-4 py-3 text-slate-600">{{ $changeRequest->currentPlan?->name ?? '—' }}</td>
                        <td class="px-4 py-3 text-slate-600">{{ $changeRequest->requestedPlan?->name ?? '—' }}</td>
                        <td class="px-4 py-3 text-slate-600">{{ $requestStatuses[$changeRequest->status] ?? ucfirst($changeRequest->status) }}</td>
                        <td class="px-4 py-3 text-slate-500">{{ $changeRequest->requested_at?->format('M j, Y') ?? '—' }}</td>
                        <td class="px-4 py-3 text-right">
                            <a href="{{ route('admin.subscriptions.show', $changeRequest->tenant_id) }}" class="text-sm font-medium text-deendoon-teal hover:underline">View</a>
                        </td>
                    </tr>
                @empty
                    <tr><td colspan="6" class="px-4 py-8 text-center text-slate-400">No subscription changes match your filters.</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>

    <div class="mt-4">{{ $records->links() }}</div>
@endsection
