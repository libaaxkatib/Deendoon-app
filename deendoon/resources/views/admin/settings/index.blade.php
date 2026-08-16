@extends('admin.layout')

@section('content')
    <div class="mb-4 flex justify-end">
        <a href="{{ route('admin.settings.create') }}" class="rounded-lg bg-deendoon-teal px-4 py-2 text-sm font-semibold text-white hover:bg-deendoon-teal-dark">
            New Plan
        </a>
    </div>

    <div class="overflow-x-auto rounded-xl border border-slate-200 bg-white">
        <table class="min-w-full divide-y divide-slate-200 text-sm">
            <thead class="bg-slate-50">
                <tr class="text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                    <th class="px-4 py-3">Name</th>
                    <th class="px-4 py-3">Monthly Price</th>
                    <th class="px-4 py-3">Customer Limit</th>
                    <th class="px-4 py-3">Storage Limit</th>
                    <th class="px-4 py-3">Analytics</th>
                    <th class="px-4 py-3">Status</th>
                    <th class="px-4 py-3">Actions</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-slate-100">
                @forelse ($plans as $plan)
                    <tr>
                        <td class="px-4 py-3 font-medium text-slate-700">{{ $plan->name }}</td>
                        <td class="px-4 py-3 text-slate-600">${{ number_format($plan->monthly_price, 2) }}</td>
                        <td class="px-4 py-3 text-slate-600">{{ $plan->customer_limit ?? 'Unlimited' }}</td>
                        <td class="px-4 py-3 text-slate-600">{{ $plan->storage_limit }} GB</td>
                        <td class="px-4 py-3 text-slate-600">{{ $plan->analytics_enabled ? 'Yes' : 'No' }}</td>
                        <td class="px-4 py-3">
                            <span class="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium {{ $plan->active ? 'bg-deendoon-success/10 text-emerald-700' : 'bg-slate-100 text-slate-500' }}">
                                {{ $plan->active ? 'Active' : 'Inactive' }}
                            </span>
                        </td>
                        <td class="px-4 py-3">
                            <div class="flex items-center gap-3">
                                <a href="{{ route('admin.settings.edit', $plan) }}" class="text-deendoon-teal hover:underline">Edit</a>
                                @if ($plan->active)
                                    <form method="POST" action="{{ route('admin.settings.deactivate', $plan) }}">
                                        @csrf
                                        <button type="submit" class="text-slate-500 hover:underline">Deactivate</button>
                                    </form>
                                @else
                                    <form method="POST" action="{{ route('admin.settings.activate', $plan) }}">
                                        @csrf
                                        <button type="submit" class="text-deendoon-teal hover:underline">Activate</button>
                                    </form>
                                @endif
                            </div>
                        </td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="7" class="px-4 py-8 text-center text-slate-400">No subscription plans yet.</td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>
@endsection
