@extends('admin.layout')

@section('content')
    @include('admin.system.partials.subnav')

    @php
        $typeTone = [
            'login_failed' => 'bg-deendoon-danger/10 text-red-700',
            'password_reset_requested' => 'bg-deendoon-info/10 text-indigo-700',
            'token_revoked_idle' => 'bg-deendoon-warning/10 text-amber-700',
            'permission_denied' => 'bg-deendoon-danger/10 text-red-700',
        ];
    @endphp

    <div class="mb-4 flex flex-col gap-3">
        <form method="GET" action="{{ route('admin.system.security-events') }}" class="flex flex-1 flex-wrap gap-2">
            <input type="text" name="search" value="{{ request('search') }}" placeholder="Search email, IP, or path..."
                   class="min-w-[240px] flex-1 rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-deendoon-teal focus:outline-none focus:ring-1 focus:ring-deendoon-teal">
            <select name="event_type" class="rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-deendoon-teal focus:outline-none focus:ring-1 focus:ring-deendoon-teal">
                <option value="">All event types</option>
                @foreach ($eventTypes as $value => $label)
                    <option value="{{ $value }}" @selected(request('event_type') === $value)>{{ $label }}</option>
                @endforeach
            </select>
            <input type="date" name="date_from" value="{{ request('date_from') }}"
                   class="rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-deendoon-teal focus:outline-none focus:ring-1 focus:ring-deendoon-teal">
            <input type="date" name="date_to" value="{{ request('date_to') }}"
                   class="rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-deendoon-teal focus:outline-none focus:ring-1 focus:ring-deendoon-teal">
            <button type="submit" class="rounded-lg bg-deendoon-teal px-4 py-2 text-sm font-semibold text-white hover:bg-deendoon-teal-dark">
                Filter
            </button>
            @if (request()->anyFilled(['search', 'event_type', 'date_from', 'date_to']))
                <a href="{{ route('admin.system.security-events') }}" class="rounded-lg px-4 py-2 text-sm font-medium text-slate-500 hover:text-slate-700">Clear</a>
            @endif
        </form>
    </div>

    <div class="overflow-x-auto rounded-xl border border-slate-200 bg-white">
        <table class="min-w-full divide-y divide-slate-200 text-sm">
            <thead class="bg-slate-50">
                <tr class="text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                    <th class="px-4 py-3">Event</th>
                    <th class="px-4 py-3">Email</th>
                    <th class="px-4 py-3">IP Address</th>
                    <th class="px-4 py-3">Path</th>
                    <th class="px-4 py-3">Occurred</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-slate-100">
                @forelse ($events as $event)
                    <tr>
                        <td class="px-4 py-3">
                            <span class="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium {{ $typeTone[$event->event_type] ?? 'bg-slate-100 text-slate-500' }}">
                                {{ $eventTypes[$event->event_type] ?? ucfirst($event->event_type) }}
                            </span>
                        </td>
                        <td class="px-4 py-3 text-slate-600">{{ $event->email ?? '—' }}</td>
                        <td class="px-4 py-3 text-slate-600">{{ $event->ip_address ?? '—' }}</td>
                        <td class="px-4 py-3 text-slate-600">{{ $event->method ? "{$event->method} {$event->path}" : ($event->path ?? '—') }}</td>
                        <td class="px-4 py-3 text-slate-500">{{ $event->occurred_at->format('M j, Y g:i A') }}</td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="5" class="px-4 py-8 text-center text-slate-400">No security events match your filters.</td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>

    <div class="mt-4">
        {{ $events->links() }}
    </div>
@endsection
