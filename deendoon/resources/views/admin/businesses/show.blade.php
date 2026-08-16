@extends('admin.layout')

@section('content')
    <div class="mb-4">
        <a href="{{ route('admin.businesses.index') }}" class="text-sm font-medium text-deendoon-teal hover:underline">&larr; Back to Businesses</a>
    </div>

    <div class="grid grid-cols-1 gap-6 lg:grid-cols-3">
        <div class="space-y-6 lg:col-span-2">
            <div class="rounded-xl border border-slate-200 bg-white p-6">
                <div class="flex flex-wrap items-start justify-between gap-4">
                    <div>
                        <h2 class="text-xl font-bold text-slate-800">{{ $tenant->business_name }}</h2>
                        <p class="mt-1 text-sm text-slate-500">Registered {{ $tenant->created_at->format('M j, Y') }}</p>
                    </div>
                    @if ($tenant->status === 'suspended')
                        <span class="inline-flex items-center rounded-full bg-deendoon-danger/10 px-3 py-1 text-sm font-medium text-red-700">Suspended</span>
                    @else
                        <span class="inline-flex items-center rounded-full bg-deendoon-success/10 px-3 py-1 text-sm font-medium text-emerald-700">Active</span>
                    @endif
                </div>

                <dl class="mt-6 grid grid-cols-1 gap-4 sm:grid-cols-2">
                    <div>
                        <dt class="text-xs font-medium uppercase text-slate-400">Contact Email</dt>
                        <dd class="text-sm text-slate-700">{{ $tenant->contact_email ?? '—' }}</dd>
                    </div>
                    <div>
                        <dt class="text-xs font-medium uppercase text-slate-400">Contact Phone</dt>
                        <dd class="text-sm text-slate-700">{{ $tenant->contact_phone ?? '—' }}</dd>
                    </div>
                    <div class="sm:col-span-2">
                        <dt class="text-xs font-medium uppercase text-slate-400">Address</dt>
                        <dd class="text-sm text-slate-700">{{ $tenant->address ?? '—' }}</dd>
                    </div>
                    @if ($tenant->status === 'suspended')
                        <div class="sm:col-span-2">
                            <dt class="text-xs font-medium uppercase text-slate-400">Suspended</dt>
                            <dd class="text-sm text-slate-700">
                                {{ $tenant->suspended_at?->format('M j, Y g:i A') }} — {{ $tenant->suspended_reason }}
                            </dd>
                        </div>
                    @endif
                </dl>

                <div class="mt-6 flex gap-3 border-t border-slate-100 pt-6">
                    @if ($tenant->status === 'suspended')
                        <form method="POST" action="{{ route('admin.businesses.activate', $tenant) }}">
                            @csrf
                            <button type="submit" class="rounded-lg bg-deendoon-success px-4 py-2 text-sm font-semibold text-white hover:opacity-90">
                                Reactivate Business
                            </button>
                        </form>
                    @else
                        <button type="button" onclick="document.getElementById('suspend-dialog').showModal()"
                                class="rounded-lg bg-deendoon-danger px-4 py-2 text-sm font-semibold text-white hover:opacity-90">
                            Suspend Business
                        </button>
                    @endif
                </div>
            </div>

            <div class="rounded-xl border border-slate-200 bg-white p-6">
                <h3 class="mb-4 text-sm font-semibold text-slate-700">Users ({{ $tenant->users->count() }})</h3>
                <ul class="divide-y divide-slate-100 text-sm">
                    @forelse ($tenant->users as $user)
                        <li class="flex items-center justify-between py-2">
                            <span class="text-slate-700">{{ $user->name }} <span class="text-slate-400">— {{ $user->email }}</span></span>
                            <span class="text-xs text-slate-400">{{ ucfirst($user->status) }}</span>
                        </li>
                    @empty
                        <li class="py-2 text-slate-400">No users on this account.</li>
                    @endforelse
                </ul>
            </div>

            <div class="rounded-xl border border-slate-200 bg-white p-6">
                <h3 class="mb-4 text-sm font-semibold text-slate-700">Recent Activity</h3>
                <ul class="max-h-72 space-y-3 overflow-y-auto text-sm">
                    @forelse ($activity as $log)
                        <li class="flex items-start justify-between gap-2">
                            <span class="text-slate-700">
                                {{ str_replace('_', ' ', $log->action) }} — {{ $log->entity_type }}
                                @if ($log->reason)
                                    <span class="text-slate-400">({{ $log->reason }})</span>
                                @endif
                            </span>
                            <span class="shrink-0 text-xs text-slate-400">{{ $log->occurred_at->diffForHumans() }}</span>
                        </li>
                    @empty
                        <li class="text-slate-400">No activity recorded yet.</li>
                    @endforelse
                </ul>
            </div>
        </div>

        <div class="space-y-6">
            <div class="rounded-xl border border-slate-200 bg-white p-6">
                <h3 class="mb-4 text-sm font-semibold text-slate-700">Subscription</h3>
                @if ($tenant->subscription)
                    <dl class="space-y-3 text-sm">
                        <div class="flex justify-between">
                            <dt class="text-slate-500">Plan</dt>
                            <dd class="font-medium text-slate-800">{{ $tenant->subscription->plan?->name ?? '—' }}</dd>
                        </div>
                        <div class="flex justify-between">
                            <dt class="text-slate-500">Status</dt>
                            <dd class="font-medium text-slate-800">{{ ucfirst($tenant->subscription->status) }}</dd>
                        </div>
                        <div class="flex justify-between">
                            <dt class="text-slate-500">Monthly Price</dt>
                            <dd class="font-medium text-slate-800">${{ number_format($tenant->subscription->plan?->monthly_price ?? 0) }}</dd>
                        </div>
                    </dl>
                @else
                    <p class="text-sm text-slate-400">No subscription on record.</p>
                @endif
            </div>
        </div>
    </div>

    <dialog id="suspend-dialog" class="w-full max-w-sm rounded-xl border border-slate-200 p-0 backdrop:bg-slate-900/50">
        <form method="POST" action="{{ route('admin.businesses.suspend', $tenant) }}" class="p-6">
            @csrf
            <h3 class="text-lg font-bold text-slate-800">Suspend {{ $tenant->business_name }}?</h3>
            <p class="mt-2 text-sm text-slate-500">
                This immediately blocks this business's access. This action is logged and reversible via "Reactivate".
            </p>
            <label for="reason" class="mt-4 block text-sm font-medium text-slate-700">Reason (required)</label>
            <textarea name="reason" id="reason" rows="3" required maxlength="500"
                      class="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-deendoon-teal focus:outline-none focus:ring-1 focus:ring-deendoon-teal"></textarea>
            <div class="mt-5 flex justify-end gap-3">
                <button type="button" onclick="document.getElementById('suspend-dialog').close()"
                        class="rounded-lg px-4 py-2 text-sm font-medium text-slate-500 hover:text-slate-700">
                    Cancel
                </button>
                <button type="submit" class="rounded-lg bg-deendoon-danger px-4 py-2 text-sm font-semibold text-white hover:opacity-90">
                    Confirm Suspend
                </button>
            </div>
        </form>
    </dialog>
@endsection
