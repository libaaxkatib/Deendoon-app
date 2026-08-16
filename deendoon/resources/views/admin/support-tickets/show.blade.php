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
        $isClosed = $ticket->status === 'closed';
    @endphp

    <div class="mb-4">
        <a href="{{ route('admin.support-tickets.index') }}" class="text-sm font-medium text-deendoon-teal hover:underline">&larr; Back to Support &amp; Tickets</a>
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
                        <h2 class="text-xl font-bold text-slate-800">{{ $ticket->reference_number }} — {{ $ticket->subject }}</h2>
                        <p class="mt-1 text-sm text-slate-500">Submitted {{ $ticket->created_at->format('M j, Y g:i A') }}</p>
                    </div>
                    <div class="flex items-center gap-2">
                        <span class="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium {{ $priorityTone[$ticket->priority] ?? 'bg-slate-100 text-slate-500' }}">
                            {{ $priorities[$ticket->priority] ?? ucfirst($ticket->priority) }}
                        </span>
                        <span class="inline-flex items-center rounded-full px-3 py-1 text-sm font-medium {{ $statusTone[$ticket->status] ?? 'bg-slate-100 text-slate-500' }}">
                            {{ $statuses[$ticket->status] ?? ucfirst($ticket->status) }}
                        </span>
                    </div>
                </div>

                <dl class="mt-6 grid grid-cols-1 gap-4 sm:grid-cols-2">
                    <div>
                        <dt class="text-xs font-medium uppercase text-slate-400">Business</dt>
                        <dd class="text-sm">
                            @if ($ticket->tenant)
                                <a href="{{ route('admin.businesses.show', $ticket->tenant) }}" class="font-medium text-deendoon-teal hover:underline">{{ $ticket->tenant->business_name }}</a>
                            @else
                                —
                            @endif
                        </dd>
                    </div>
                    <div>
                        <dt class="text-xs font-medium uppercase text-slate-400">Submitted By</dt>
                        <dd class="text-sm text-slate-700">{{ $ticket->submittedBy?->name ?? '—' }}</dd>
                    </div>
                    <div>
                        <dt class="text-xs font-medium uppercase text-slate-400">Category</dt>
                        <dd class="text-sm text-slate-700">{{ $categories[$ticket->category] ?? ucfirst($ticket->category) }}</dd>
                    </div>
                    <div>
                        <dt class="text-xs font-medium uppercase text-slate-400">Reopened</dt>
                        <dd class="text-sm text-slate-700">{{ $ticket->reopened_at?->format('M j, Y g:i A') ?? '—' }}</dd>
                    </div>
                    <div class="sm:col-span-2">
                        <dt class="text-xs font-medium uppercase text-slate-400">Description</dt>
                        <dd class="mt-1 whitespace-pre-line text-sm text-slate-700">{{ $ticket->description }}</dd>
                    </div>
                </dl>

                <div class="mt-6 flex flex-wrap items-center gap-3 border-t border-slate-100 pt-6">
                    @if (! $isClosed)
                        <form method="POST" action="{{ route('admin.support-tickets.status', $ticket) }}" class="flex items-center gap-2">
                            @csrf
                            <select name="status" class="rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-deendoon-teal focus:outline-none focus:ring-1 focus:ring-deendoon-teal">
                                @foreach ($nonTerminalStatuses as $value => $label)
                                    <option value="{{ $value }}" @selected($ticket->status === $value)>{{ $label }}</option>
                                @endforeach
                            </select>
                            <button type="submit" class="rounded-lg bg-deendoon-teal px-4 py-2 text-sm font-semibold text-white hover:bg-deendoon-teal-dark">
                                Update Status
                            </button>
                        </form>
                        <form method="POST" action="{{ route('admin.support-tickets.close', $ticket) }}" onsubmit="return confirm('Close this ticket? The Business Owner will be notified.');">
                            @csrf
                            <button type="submit" class="rounded-lg bg-deendoon-danger px-4 py-2 text-sm font-semibold text-white hover:opacity-90">
                                Close Ticket
                            </button>
                        </form>
                    @else
                        <form method="POST" action="{{ route('admin.support-tickets.reopen', $ticket) }}">
                            @csrf
                            <button type="submit" class="rounded-lg bg-deendoon-teal px-4 py-2 text-sm font-semibold text-white hover:bg-deendoon-teal-dark">
                                Reopen Ticket
                            </button>
                        </form>
                    @endif
                </div>
            </div>

            <div class="rounded-xl border border-slate-200 bg-white p-6">
                <h3 class="mb-4 text-sm font-semibold text-slate-700">Conversation</h3>
                <ul class="max-h-72 space-y-3 overflow-y-auto text-sm">
                    @forelse ($ticket->messages as $message)
                        <li class="rounded-lg bg-slate-50 p-3">
                            <div class="flex items-center justify-between">
                                <span class="font-medium text-slate-700">{{ $message->sender?->name ?? 'Unknown' }}</span>
                                <span class="text-xs text-slate-400">{{ $message->created_at->diffForHumans() }}</span>
                            </div>
                            <p class="mt-1 text-slate-600">{{ $message->content }}</p>
                        </li>
                    @empty
                        <li class="text-slate-400">No replies yet.</li>
                    @endforelse
                </ul>
                @unless ($isClosed)
                    <form method="POST" action="{{ route('admin.support-tickets.messages', $ticket) }}" class="mt-4">
                        @csrf
                        <textarea name="content" rows="2" maxlength="5000" required placeholder="Reply to the business..."
                                  class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-deendoon-teal focus:outline-none focus:ring-1 focus:ring-deendoon-teal"></textarea>
                        <button type="submit" class="mt-2 rounded-lg bg-deendoon-teal px-4 py-2 text-sm font-semibold text-white hover:bg-deendoon-teal-dark">
                            Send Reply
                        </button>
                    </form>
                @else
                    <p class="mt-3 text-xs text-slate-400">This ticket is closed; new replies are not accepted. Reopen it first.</p>
                @endunless
            </div>

            <div class="rounded-xl border border-slate-200 bg-white p-6">
                <h3 class="mb-4 text-sm font-semibold text-slate-700">Attachments</h3>
                <ul class="divide-y divide-slate-100 text-sm">
                    @forelse ($ticket->attachments as $attachment)
                        <li class="flex items-center justify-between py-2">
                            <span class="text-slate-700">{{ $attachment->original_filename }}</span>
                            <a href="{{ route('admin.support-tickets.attachments.download', [$ticket, $attachment]) }}" class="text-xs font-medium text-deendoon-teal hover:underline">Download</a>
                        </li>
                    @empty
                        <li class="py-2 text-slate-400">No attachments uploaded.</li>
                    @endforelse
                </ul>
                @unless ($isClosed)
                    <form method="POST" action="{{ route('admin.support-tickets.attachments.store', $ticket) }}" class="mt-4 flex flex-wrap items-center gap-2" enctype="multipart/form-data">
                        @csrf
                        <input type="file" name="file" required accept=".pdf,.jpg,.jpeg,.png,.doc,.docx" class="text-sm text-slate-500">
                        <button type="submit" class="rounded-lg bg-deendoon-teal px-4 py-2 text-sm font-semibold text-white hover:bg-deendoon-teal-dark">
                            Upload
                        </button>
                    </form>
                @else
                    <p class="mt-3 text-xs text-slate-400">This ticket is closed; attachments are read-only. Reopen it first.</p>
                @endunless
            </div>
        </div>

        <div class="space-y-6">
            @include('admin.support-tickets.partials.contact-links')
        </div>
    </div>
@endsection
