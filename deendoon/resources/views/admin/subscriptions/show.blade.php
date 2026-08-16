@extends('admin.layout')

@section('content')
    @php
        $subscriptionTone = [
            'trialing' => 'bg-deendoon-info/10 text-indigo-700',
            'active' => 'bg-deendoon-success/10 text-emerald-700',
            'expired' => 'bg-deendoon-danger/10 text-red-700',
        ];
        $requestTone = [
            'pending' => 'bg-deendoon-warning/10 text-amber-700',
            'approved' => 'bg-deendoon-success/10 text-emerald-700',
            'rejected' => 'bg-deendoon-danger/10 text-red-700',
            'cancelled' => 'bg-slate-100 text-slate-500',
            'active' => 'bg-deendoon-success/10 text-emerald-700',
            'expired' => 'bg-slate-100 text-slate-500',
        ];
        $pendingChangeRequest = $tenant->subscriptionChangeRequests->firstWhere('status', 'pending');
        $pendingStorageAddon = $tenant->storageAddons->firstWhere('status', 'pending');
    @endphp

    <div class="mb-4">
        <a href="{{ route('admin.subscriptions.index') }}" class="text-sm font-medium text-deendoon-teal hover:underline">&larr; Back to Subscriptions</a>
    </div>

    @if ($errors->any())
        <div class="mb-4 rounded-lg border border-deendoon-danger/30 bg-deendoon-danger/10 px-4 py-3 text-sm text-red-700">
            {{ $errors->first() }}
        </div>
    @endif

    <div class="grid grid-cols-1 gap-6 lg:grid-cols-3">
        <div class="space-y-6 lg:col-span-2">
            <div class="rounded-xl border border-slate-200 bg-white p-6">
                <div class="flex flex-wrap items-start justify-between gap-4">
                    <div>
                        <h2 class="text-xl font-bold text-slate-800">
                            <a href="{{ route('admin.businesses.show', $tenant) }}" class="hover:underline">{{ $tenant->business_name }}</a>
                        </h2>
                        <p class="mt-1 text-sm text-slate-500">Current Subscription</p>
                    </div>
                    @if ($tenant->subscription)
                        <span class="inline-flex items-center rounded-full px-3 py-1 text-sm font-medium {{ $subscriptionTone[$tenant->subscription->status] ?? 'bg-slate-100 text-slate-500' }}">
                            {{ $subscriptionStatuses[$tenant->subscription->status] ?? ucfirst($tenant->subscription->status) }}
                        </span>
                    @else
                        <span class="inline-flex items-center rounded-full bg-slate-100 px-3 py-1 text-sm font-medium text-slate-500">No Subscription</span>
                    @endif
                </div>

                @if ($tenant->subscription)
                    <dl class="mt-6 grid grid-cols-1 gap-4 sm:grid-cols-2">
                        <div>
                            <dt class="text-xs font-medium uppercase text-slate-400">Plan</dt>
                            <dd class="text-sm font-medium text-slate-700">{{ $tenant->subscription->plan?->name ?? '—' }}</dd>
                        </div>
                        <div>
                            <dt class="text-xs font-medium uppercase text-slate-400">Monthly Price</dt>
                            <dd class="text-sm font-medium text-slate-700">${{ number_format($tenant->subscription->plan?->monthly_price ?? 0, 2) }}</dd>
                        </div>
                        <div>
                            <dt class="text-xs font-medium uppercase text-slate-400">Started</dt>
                            <dd class="text-sm text-slate-700">{{ $tenant->subscription->started_at?->format('M j, Y') ?? '—' }}</dd>
                        </div>
                        <div>
                            <dt class="text-xs font-medium uppercase text-slate-400">Expires</dt>
                            <dd class="text-sm text-slate-700">{{ $tenant->subscription->expires_at?->format('M j, Y') ?? 'No expiry' }}</dd>
                        </div>
                        @if ($tenant->subscription->status === 'trialing')
                            <div class="sm:col-span-2">
                                <dt class="text-xs font-medium uppercase text-slate-400">Trial Ends</dt>
                                <dd class="text-sm text-slate-700">{{ $tenant->subscription->trial_ends_at?->format('M j, Y') ?? '—' }}</dd>
                            </div>
                        @endif
                    </dl>
                @else
                    <p class="mt-4 text-sm text-slate-400">This tenant has no subscription record.</p>
                @endif
            </div>

            <div class="rounded-xl border border-slate-200 bg-white p-6">
                <h3 class="mb-4 text-sm font-semibold text-slate-700">Subscription Change Request History</h3>
                <div class="overflow-x-auto">
                    <table class="min-w-full divide-y divide-slate-200 text-sm">
                        <thead>
                            <tr class="text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                                <th class="px-3 py-2">Requested Plan</th>
                                <th class="px-3 py-2">From</th>
                                <th class="px-3 py-2">Status</th>
                                <th class="px-3 py-2">Requested</th>
                                <th class="px-3 py-2">Reviewed</th>
                                <th class="px-3 py-2"></th>
                            </tr>
                        </thead>
                        <tbody class="divide-y divide-slate-100">
                            @forelse ($tenant->subscriptionChangeRequests as $request)
                                <tr>
                                    <td class="px-3 py-2 font-medium text-slate-800">{{ $request->requestedPlan?->name ?? '—' }}</td>
                                    <td class="px-3 py-2 text-slate-500">{{ $request->currentPlan?->name ?? '—' }}</td>
                                    <td class="px-3 py-2">
                                        <span class="inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium {{ $requestTone[$request->status] ?? 'bg-slate-100 text-slate-500' }}">
                                            {{ $requestStatuses[$request->status] ?? ucfirst($request->status) }}
                                        </span>
                                    </td>
                                    <td class="px-3 py-2 text-slate-500">{{ $request->requested_at?->format('M j, Y') }}</td>
                                    <td class="px-3 py-2 text-slate-500">{{ $request->reviewed_at?->format('M j, Y') ?? '—' }}</td>
                                    <td class="px-3 py-2 text-right">
                                        @if ($request->status === 'pending')
                                            <button type="button" onclick="document.getElementById('approve-change-request-dialog').showModal()"
                                                    class="mr-2 text-xs font-semibold text-deendoon-success hover:underline">Approve</button>
                                            <button type="button" onclick="document.getElementById('reject-change-request-dialog').showModal()"
                                                    class="text-xs font-semibold text-deendoon-danger hover:underline">Reject</button>
                                        @endif
                                    </td>
                                </tr>
                                @if ($request->status === 'rejected')
                                    <tr>
                                        <td colspan="6" class="bg-slate-50 px-3 py-2 text-xs text-slate-500">
                                            Rejected: {{ $request->reasons->pluck('reason_label')->implode(', ') }}
                                            @if ($request->rejection_reason)
                                                — "{{ $request->rejection_reason }}"
                                            @endif
                                        </td>
                                    </tr>
                                @endif
                            @empty
                                <tr>
                                    <td colspan="6" class="px-3 py-6 text-center text-slate-400">No subscription change requests for this business.</td>
                                </tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>
            </div>

            <div class="rounded-xl border border-slate-200 bg-white p-6">
                <h3 class="mb-4 text-sm font-semibold text-slate-700">Storage Add-on History</h3>
                <div class="overflow-x-auto">
                    <table class="min-w-full divide-y divide-slate-200 text-sm">
                        <thead>
                            <tr class="text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                                <th class="px-3 py-2">Package</th>
                                <th class="px-3 py-2">Price</th>
                                <th class="px-3 py-2">Status</th>
                                <th class="px-3 py-2">Started</th>
                                <th class="px-3 py-2">Expires</th>
                                <th class="px-3 py-2"></th>
                            </tr>
                        </thead>
                        <tbody class="divide-y divide-slate-100">
                            @forelse ($tenant->storageAddons as $addon)
                                <tr>
                                    <td class="px-3 py-2 font-medium text-slate-800">{{ strtoupper($addon->storage_package) }} ({{ $addon->storage_size }} GB)</td>
                                    <td class="px-3 py-2 text-slate-500">${{ number_format($addon->monthly_price, 2) }}/mo</td>
                                    <td class="px-3 py-2">
                                        <span class="inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium {{ $requestTone[$addon->status] ?? 'bg-slate-100 text-slate-500' }}">
                                            {{ $storageAddonStatuses[$addon->status] ?? ucfirst($addon->status) }}
                                        </span>
                                    </td>
                                    <td class="px-3 py-2 text-slate-500">{{ $addon->started_at?->format('M j, Y') ?? '—' }}</td>
                                    <td class="px-3 py-2 text-slate-500">{{ $addon->expires_at?->format('M j, Y') ?? '—' }}</td>
                                    <td class="px-3 py-2 text-right">
                                        @if ($addon->status === 'pending')
                                            <button type="button" onclick="document.getElementById('approve-storage-addon-dialog').showModal()"
                                                    class="mr-2 text-xs font-semibold text-deendoon-success hover:underline">Approve</button>
                                            <button type="button" onclick="document.getElementById('reject-storage-addon-dialog').showModal()"
                                                    class="text-xs font-semibold text-deendoon-danger hover:underline">Reject</button>
                                        @endif
                                    </td>
                                </tr>
                                @if ($addon->status === 'rejected')
                                    <tr>
                                        <td colspan="6" class="bg-slate-50 px-3 py-2 text-xs text-slate-500">
                                            Rejected: {{ $addon->reasons->pluck('reason_label')->implode(', ') }}
                                            @if ($addon->rejection_reason)
                                                — "{{ $addon->rejection_reason }}"
                                            @endif
                                        </td>
                                    </tr>
                                @endif
                            @empty
                                <tr>
                                    <td colspan="6" class="px-3 py-6 text-center text-slate-400">No storage add-on requests for this business.</td>
                                </tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

        <div class="space-y-6">
            @if ($pendingChangeRequest)
                <div class="rounded-xl border border-deendoon-warning/40 bg-deendoon-warning/5 p-6">
                    <h3 class="mb-2 text-sm font-semibold text-slate-700">Pending Plan Change</h3>
                    <p class="text-sm text-slate-600">Requested plan: <span class="font-medium">{{ $pendingChangeRequest->requestedPlan?->name }}</span></p>
                    <p class="mt-1 text-xs text-slate-400">Payment reference: {{ $pendingChangeRequest->payment_reference ?? '—' }}</p>
                    <div class="mt-4 flex gap-3">
                        <button type="button" onclick="document.getElementById('approve-change-request-dialog').showModal()"
                                class="rounded-lg bg-deendoon-success px-4 py-2 text-sm font-semibold text-white hover:opacity-90">Approve</button>
                        <button type="button" onclick="document.getElementById('reject-change-request-dialog').showModal()"
                                class="rounded-lg bg-deendoon-danger px-4 py-2 text-sm font-semibold text-white hover:opacity-90">Reject</button>
                    </div>
                </div>
            @endif

            @if ($pendingStorageAddon)
                <div class="rounded-xl border border-deendoon-warning/40 bg-deendoon-warning/5 p-6">
                    <h3 class="mb-2 text-sm font-semibold text-slate-700">Pending Storage Add-on</h3>
                    <p class="text-sm text-slate-600">Package: <span class="font-medium">{{ strtoupper($pendingStorageAddon->storage_package) }} ({{ $pendingStorageAddon->storage_size }} GB)</span></p>
                    <p class="mt-1 text-xs text-slate-400">Payment reference: {{ $pendingStorageAddon->payment_reference ?? '—' }}</p>
                    <div class="mt-4 flex gap-3">
                        <button type="button" onclick="document.getElementById('approve-storage-addon-dialog').showModal()"
                                class="rounded-lg bg-deendoon-success px-4 py-2 text-sm font-semibold text-white hover:opacity-90">Approve</button>
                        <button type="button" onclick="document.getElementById('reject-storage-addon-dialog').showModal()"
                                class="rounded-lg bg-deendoon-danger px-4 py-2 text-sm font-semibold text-white hover:opacity-90">Reject</button>
                    </div>
                </div>
            @endif
        </div>
    </div>

    @if ($pendingChangeRequest)
        <dialog id="approve-change-request-dialog" class="w-full max-w-sm rounded-xl border border-slate-200 p-0 backdrop:bg-slate-900/50">
            <form method="POST" action="{{ route('admin.subscriptions.change-requests.approve', $pendingChangeRequest) }}" class="p-6">
                @csrf
                <h3 class="text-lg font-bold text-slate-800">Approve plan change to {{ $pendingChangeRequest->requestedPlan?->name }}?</h3>
                <p class="mt-2 text-sm text-slate-500">
                    This immediately activates the {{ $pendingChangeRequest->requestedPlan?->name }} plan for {{ $tenant->business_name }} and updates their existing subscription. The Business Owner will be notified.
                </p>
                <div class="mt-5 flex justify-end gap-3">
                    <button type="button" onclick="document.getElementById('approve-change-request-dialog').close()"
                            class="rounded-lg px-4 py-2 text-sm font-medium text-slate-500 hover:text-slate-700">Cancel</button>
                    <button type="submit" class="rounded-lg bg-deendoon-success px-4 py-2 text-sm font-semibold text-white hover:opacity-90">Confirm Approve</button>
                </div>
            </form>
        </dialog>

        <dialog id="reject-change-request-dialog" class="w-full max-w-sm rounded-xl border border-slate-200 p-0 backdrop:bg-slate-900/50">
            <form method="POST" action="{{ route('admin.subscriptions.change-requests.reject', $pendingChangeRequest) }}" class="p-6">
                @csrf
                <h3 class="text-lg font-bold text-slate-800">Reject plan change request?</h3>
                <p class="mt-2 text-sm text-slate-500">Select at least one reason. The Business Owner will be notified.</p>
                <fieldset class="mt-4 space-y-2">
                    @foreach ($changeRequestRejectionReasons as $reason)
                        <label class="flex items-center gap-2 text-sm text-slate-700">
                            <input type="checkbox" name="reasons[]" value="{{ $reason->value_label }}" class="rounded border-slate-300 text-deendoon-teal focus:ring-deendoon-teal">
                            {{ $reason->value_label }}
                        </label>
                    @endforeach
                </fieldset>
                <label for="change-request-notes" class="mt-4 block text-sm font-medium text-slate-700">Additional comment (optional)</label>
                <textarea name="notes" id="change-request-notes" rows="3" maxlength="2000"
                          class="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-deendoon-teal focus:outline-none focus:ring-1 focus:ring-deendoon-teal"></textarea>
                <div class="mt-5 flex justify-end gap-3">
                    <button type="button" onclick="document.getElementById('reject-change-request-dialog').close()"
                            class="rounded-lg px-4 py-2 text-sm font-medium text-slate-500 hover:text-slate-700">Cancel</button>
                    <button type="submit" class="rounded-lg bg-deendoon-danger px-4 py-2 text-sm font-semibold text-white hover:opacity-90">Confirm Reject</button>
                </div>
            </form>
        </dialog>
    @endif

    @if ($pendingStorageAddon)
        <dialog id="approve-storage-addon-dialog" class="w-full max-w-sm rounded-xl border border-slate-200 p-0 backdrop:bg-slate-900/50">
            <form method="POST" action="{{ route('admin.subscriptions.storage-addons.approve', $pendingStorageAddon) }}" class="p-6">
                @csrf
                <h3 class="text-lg font-bold text-slate-800">Approve this Storage Add-on?</h3>
                <p class="mt-2 text-sm text-slate-500">
                    This immediately activates {{ strtoupper($pendingStorageAddon->storage_package) }} ({{ $pendingStorageAddon->storage_size }} GB) for {{ $tenant->business_name }}. The Business Owner will be notified.
                </p>
                <div class="mt-5 flex justify-end gap-3">
                    <button type="button" onclick="document.getElementById('approve-storage-addon-dialog').close()"
                            class="rounded-lg px-4 py-2 text-sm font-medium text-slate-500 hover:text-slate-700">Cancel</button>
                    <button type="submit" class="rounded-lg bg-deendoon-success px-4 py-2 text-sm font-semibold text-white hover:opacity-90">Confirm Approve</button>
                </div>
            </form>
        </dialog>

        <dialog id="reject-storage-addon-dialog" class="w-full max-w-sm rounded-xl border border-slate-200 p-0 backdrop:bg-slate-900/50">
            <form method="POST" action="{{ route('admin.subscriptions.storage-addons.reject', $pendingStorageAddon) }}" class="p-6">
                @csrf
                <h3 class="text-lg font-bold text-slate-800">Reject this Storage Add-on request?</h3>
                <p class="mt-2 text-sm text-slate-500">Select at least one reason. The Business Owner will be notified.</p>
                <fieldset class="mt-4 space-y-2">
                    @foreach ($storageAddonRejectionReasons as $reason)
                        <label class="flex items-center gap-2 text-sm text-slate-700">
                            <input type="checkbox" name="reasons[]" value="{{ $reason->value_label }}" class="rounded border-slate-300 text-deendoon-teal focus:ring-deendoon-teal">
                            {{ $reason->value_label }}
                        </label>
                    @endforeach
                </fieldset>
                <label for="storage-addon-notes" class="mt-4 block text-sm font-medium text-slate-700">Additional comment (optional)</label>
                <textarea name="notes" id="storage-addon-notes" rows="3" maxlength="2000"
                          class="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-deendoon-teal focus:outline-none focus:ring-1 focus:ring-deendoon-teal"></textarea>
                <div class="mt-5 flex justify-end gap-3">
                    <button type="button" onclick="document.getElementById('reject-storage-addon-dialog').close()"
                            class="rounded-lg px-4 py-2 text-sm font-medium text-slate-500 hover:text-slate-700">Cancel</button>
                    <button type="submit" class="rounded-lg bg-deendoon-danger px-4 py-2 text-sm font-semibold text-white hover:opacity-90">Confirm Reject</button>
                </div>
            </form>
        </dialog>
    @endif
@endsection
