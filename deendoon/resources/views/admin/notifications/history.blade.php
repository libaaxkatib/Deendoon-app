@extends('admin.layout')

@section('content')
    @include('admin.notifications.partials.subnav')

    @if ($announcements->isEmpty())
        <div class="rounded-xl border border-slate-200 bg-white p-10 text-center">
            <p class="text-sm font-medium text-slate-600">No System Notices have been sent yet.</p>
            <p class="mt-1 text-sm text-slate-400">System Notices you send from "Send System Notice" will appear here.</p>
            <a href="{{ route('admin.notifications.index') }}"
               class="mt-4 inline-block rounded-lg bg-deendoon-teal px-4 py-2 text-sm font-semibold text-white hover:bg-deendoon-teal-dark">
                Send a System Notice
            </a>
        </div>
    @else
        <div class="overflow-x-auto rounded-xl border border-slate-200 bg-white">
            <table class="min-w-full divide-y divide-slate-200 text-sm">
                <thead class="bg-slate-50">
                    <tr class="text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                        <th class="px-4 py-3">Title</th>
                        <th class="px-4 py-3">Message</th>
                        <th class="px-4 py-3">Scope</th>
                        <th class="px-4 py-3">Recipients</th>
                        <th class="px-4 py-3">Sent By</th>
                        <th class="px-4 py-3">Sent</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-100">
                    @foreach ($announcements as $announcement)
                        <tr>
                            <td class="px-4 py-3 font-medium text-slate-700">{{ $announcement->title }}</td>
                            <td class="max-w-xs px-4 py-3 text-slate-600" title="{{ $announcement->message }}">
                                {{ Str::limit($announcement->message, 80) }}
                            </td>
                            <td class="px-4 py-3">
                                <span class="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium bg-deendoon-teal/10 text-deendoon-teal">
                                    {{ $announcement->scope === 'all' ? 'All Businesses' : 'Selected Businesses' }}
                                </span>
                            </td>
                            <td class="px-4 py-3 text-slate-600">{{ $announcement->recipient_count }}</td>
                            <td class="px-4 py-3 text-slate-600">{{ $senderNames[$announcement->sent_by_user_id] ?? 'Unknown' }}</td>
                            <td class="px-4 py-3 text-slate-500">{{ $announcement->sent_at->format('M j, Y g:i A') }}</td>
                        </tr>
                    @endforeach
                </tbody>
            </table>
        </div>

        <div class="mt-4">
            {{ $announcements->links() }}
        </div>
    @endif
@endsection
