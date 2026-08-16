@extends('admin.layout')

@section('content')
    @php
        $statusTone = [
            'submitted' => 'bg-slate-100 text-slate-500',
            'under_review' => 'bg-deendoon-warning/10 text-amber-700',
            'need_more_information' => 'bg-deendoon-warning/10 text-amber-700',
            'accepted' => 'bg-deendoon-info/10 text-indigo-700',
            'assigned' => 'bg-deendoon-info/10 text-indigo-700',
            'in_progress' => 'bg-deendoon-info/10 text-indigo-700',
            'recovered' => 'bg-deendoon-success/10 text-emerald-700',
            'closed' => 'bg-slate-100 text-slate-500',
        ];
        $debtStatusTone = [
            'paid' => 'bg-deendoon-success/10 text-emerald-700',
            'partial_paid' => 'bg-deendoon-info/10 text-indigo-700',
            'overdue' => 'bg-deendoon-danger/10 text-red-700',
            'written_off' => 'bg-deendoon-danger/10 text-red-700',
            'cancelled' => 'bg-slate-100 text-slate-500',
            'draft' => 'bg-slate-100 text-slate-500',
            'pending' => 'bg-deendoon-warning/10 text-amber-700',
        ];
        $case = $pcr->collectionCase;
        $debt = $case?->debt;
        $customer = $debt?->customer;
        $tenant = $customer?->tenant;
        $isTerminal = in_array($pcr->status, ['recovered', 'closed'], true);
        $canUploadNow = in_array($pcr->status, ['assigned', 'in_progress'], true);
    @endphp

    <div class="mb-4">
        <a href="{{ route('admin.professional-collection.index') }}" class="text-sm font-medium text-deendoon-teal hover:underline">&larr; Back to Professional Collection</a>
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
                        <h2 class="text-xl font-bold text-slate-800">{{ $pcr->reference_number }}</h2>
                        <p class="mt-1 text-sm text-slate-500">Submitted {{ $pcr->created_at->format('M j, Y') }}</p>
                    </div>
                    <span class="inline-flex items-center rounded-full px-3 py-1 text-sm font-medium {{ $statusTone[$pcr->status] ?? 'bg-slate-100 text-slate-500' }}">
                        {{ $statuses[$pcr->status] ?? ucfirst($pcr->status) }}
                    </span>
                </div>

                <dl class="mt-6 grid grid-cols-1 gap-4 sm:grid-cols-2">
                    <div>
                        <dt class="text-xs font-medium uppercase text-slate-400">Business</dt>
                        <dd class="text-sm">
                            @if ($tenant)
                                <a href="{{ route('admin.businesses.show', $tenant) }}" class="font-medium text-deendoon-teal hover:underline">{{ $tenant->business_name }}</a>
                            @else
                                —
                            @endif
                        </dd>
                    </div>
                    <div>
                        <dt class="text-xs font-medium uppercase text-slate-400">Debtor</dt>
                        <dd class="text-sm">
                            @if ($customer)
                                <a href="{{ route('admin.debtors.show', $customer) }}" class="font-medium text-deendoon-teal hover:underline">{{ $customer->name }}</a>
                            @else
                                —
                            @endif
                        </dd>
                    </div>
                    <div>
                        <dt class="text-xs font-medium uppercase text-slate-400">Debt</dt>
                        <dd class="text-sm">
                            @if ($debt)
                                <a href="{{ route('admin.recovery-debts.show', $debt) }}" class="font-medium text-deendoon-teal hover:underline">{{ $debt->reference_number }}</a>
                                <span class="text-slate-400">— ${{ number_format($debt->amount, 2) }}</span>
                            @else
                                —
                            @endif
                        </dd>
                    </div>
                    <div>
                        <dt class="text-xs font-medium uppercase text-slate-400">Debt Status</dt>
                        <dd class="text-sm">
                            @if ($debt)
                                <span class="inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium {{ $debtStatusTone[$debt->debt_status] ?? 'bg-slate-100 text-slate-500' }}">
                                    {{ ucfirst(str_replace('_', ' ', $debt->debt_status)) }}
                                </span>
                            @else
                                —
                            @endif
                        </dd>
                    </div>
                    @if ($pcr->transfer_notes)
                        <div class="sm:col-span-2">
                            <dt class="text-xs font-medium uppercase text-slate-400">Transfer Notes</dt>
                            <dd class="text-sm text-slate-700">{{ $pcr->transfer_notes }}</dd>
                        </div>
                    @endif
                    <div class="sm:col-span-2">
                        <dt class="text-xs font-medium uppercase text-slate-400">Reason(s) for Transfer</dt>
                        <dd class="mt-1 flex flex-wrap gap-1.5">
                            @forelse ($pcr->reasons as $reason)
                                <span class="inline-flex items-center rounded-full bg-slate-100 px-2.5 py-0.5 text-xs font-medium text-slate-600">{{ $reason->reason_label }}</span>
                            @empty
                                <span class="text-sm text-slate-400">—</span>
                            @endforelse
                        </dd>
                    </div>
                    <div class="sm:col-span-2">
                        <dt class="text-xs font-medium uppercase text-slate-400">Requested Service(s)</dt>
                        <dd class="mt-1 flex flex-wrap gap-1.5">
                            @forelse ($pcr->requestedServices as $service)
                                <span class="inline-flex items-center rounded-full bg-deendoon-teal/10 px-2.5 py-0.5 text-xs font-medium text-deendoon-teal-dark">{{ $service->service_label }}</span>
                            @empty
                                <span class="text-sm text-slate-400">—</span>
                            @endforelse
                        </dd>
                    </div>
                    @if ($pcr->declaration_accepted_at)
                        <div class="sm:col-span-2">
                            <dt class="text-xs font-medium uppercase text-slate-400">Client Declaration</dt>
                            <dd class="text-sm text-slate-700">Accepted {{ $pcr->declaration_accepted_at->format('M j, Y g:i A') }}</dd>
                        </div>
                    @endif
                </dl>

                @unless ($isTerminal)
                    <div class="mt-6 flex flex-wrap items-center gap-3 border-t border-slate-100 pt-6">
                        <form method="POST" action="{{ route('admin.professional-collection.status', $pcr) }}" class="flex items-center gap-2">
                            @csrf
                            <select name="status" class="rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-deendoon-teal focus:outline-none focus:ring-1 focus:ring-deendoon-teal">
                                @foreach ($nonTerminalStatuses as $value => $label)
                                    <option value="{{ $value }}" @selected($pcr->status === $value)>{{ $label }}</option>
                                @endforeach
                            </select>
                            <button type="submit" class="rounded-lg bg-deendoon-teal px-4 py-2 text-sm font-semibold text-white hover:bg-deendoon-teal-dark">
                                Update Status
                            </button>
                        </form>
                        <button type="button" onclick="document.getElementById('close-request-dialog').showModal()"
                                class="rounded-lg bg-deendoon-danger px-4 py-2 text-sm font-semibold text-white hover:opacity-90">
                            Close Request
                        </button>
                    </div>
                @endunless
            </div>

            <div class="rounded-xl border border-slate-200 bg-white p-6">
                <h3 class="mb-4 text-sm font-semibold text-slate-700">Conversation</h3>
                <ul class="max-h-72 space-y-3 overflow-y-auto text-sm">
                    @forelse ($pcr->messages as $message)
                        <li class="rounded-lg bg-slate-50 p-3">
                            <div class="flex items-center justify-between">
                                <span class="font-medium text-slate-700">{{ $message->sender?->name ?? 'Unknown' }}</span>
                                <span class="text-xs text-slate-400">{{ $message->created_at->diffForHumans() }}</span>
                            </div>
                            <p class="mt-1 text-slate-600">{{ $message->content }}</p>
                        </li>
                    @empty
                        <li class="text-slate-400">No messages yet.</li>
                    @endforelse
                </ul>
                @unless ($isTerminal)
                    <form method="POST" action="{{ route('admin.professional-collection.messages', $pcr) }}" class="mt-4">
                        @csrf
                        <textarea name="content" rows="2" maxlength="5000" required placeholder="Write a message to the business..."
                                  class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-deendoon-teal focus:outline-none focus:ring-1 focus:ring-deendoon-teal"></textarea>
                        <button type="submit" class="mt-2 rounded-lg bg-deendoon-teal px-4 py-2 text-sm font-semibold text-white hover:bg-deendoon-teal-dark">
                            Send
                        </button>
                    </form>
                @else
                    <p class="mt-3 text-xs text-slate-400">This request is closed; new messages are not accepted.</p>
                @endunless
            </div>

            <div class="rounded-xl border border-slate-200 bg-white p-6">
                <h3 class="mb-4 text-sm font-semibold text-slate-700">Recovery Timeline</h3>
                <ul class="max-h-72 space-y-3 overflow-y-auto text-sm">
                    @forelse ($pcr->timelineEvents as $event)
                        <li class="rounded-lg bg-slate-50 p-3">
                            <div class="flex items-center justify-between">
                                <span class="font-medium text-slate-700">{{ ucwords(str_replace('_', ' ', $event->event_type->value)) }}</span>
                                <span class="text-xs text-slate-400">{{ $event->occurred_at->format('M j, Y g:i A') }}</span>
                            </div>
                            @if ($event->notes)
                                <p class="mt-1 text-slate-600">{{ $event->notes }}</p>
                            @endif
                            @if ($event->outcome)
                                <p class="mt-1 text-xs text-slate-500">Outcome: {{ $event->outcome }}</p>
                            @endif
                            @if ($event->attachments->isNotEmpty())
                                <div class="mt-2 flex flex-wrap gap-2">
                                    @foreach ($event->attachments as $attachment)
                                        <a href="{{ route('admin.professional-collection.attachments.download', [$pcr, $attachment]) }}" class="text-xs font-medium text-deendoon-teal hover:underline">{{ $attachment->original_filename }}</a>
                                    @endforeach
                                </div>
                            @endif
                        </li>
                    @empty
                        <li class="text-slate-400">No recovery activity logged yet.</li>
                    @endforelse
                </ul>
                @unless ($isTerminal)
                    <form method="POST" action="{{ route('admin.professional-collection.timeline', $pcr) }}" class="mt-4 space-y-2" enctype="multipart/form-data">
                        @csrf
                        <div class="flex flex-wrap gap-2">
                            <select name="event_type" required class="rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-deendoon-teal focus:outline-none focus:ring-1 focus:ring-deendoon-teal">
                                @foreach (\App\Enums\ProfessionalCollectionTimelineEventType::cases() as $case)
                                    <option value="{{ $case->value }}">{{ $timelineEventTypes[$loop->index] }}</option>
                                @endforeach
                            </select>
                            <input type="datetime-local" name="occurred_at" class="rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-deendoon-teal focus:outline-none focus:ring-1 focus:ring-deendoon-teal">
                            <input type="text" name="outcome" maxlength="50" placeholder="Outcome (optional)" class="rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-deendoon-teal focus:outline-none focus:ring-1 focus:ring-deendoon-teal">
                        </div>
                        <textarea name="notes" rows="2" maxlength="2000" placeholder="Notes (optional)"
                                  class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-deendoon-teal focus:outline-none focus:ring-1 focus:ring-deendoon-teal"></textarea>
                        <input type="file" name="attachments[]" multiple accept=".pdf,.jpg,.jpeg,.png,.doc,.docx" class="block w-full text-sm text-slate-500">
                        <button type="submit" class="rounded-lg bg-deendoon-teal px-4 py-2 text-sm font-semibold text-white hover:bg-deendoon-teal-dark">
                            Log Activity
                        </button>
                    </form>
                @endunless
            </div>

            <div class="rounded-xl border border-slate-200 bg-white p-6">
                <h3 class="mb-4 text-sm font-semibold text-slate-700">Existing Documents</h3>
                <ul class="divide-y divide-slate-100 text-sm">
                    @forelse ($linkedDocuments as $type => $documents)
                        @foreach ($documents as $document)
                            <li class="flex items-center justify-between py-2">
                                <span class="text-slate-700">{{ ucwords(str_replace('_', ' ', $type)) }} — {{ $document->reference_number }}</span>
                                <a href="{{ route('admin.professional-collection.documents.download', [$pcr, $type, $document->id]) }}" class="text-xs font-medium text-deendoon-teal hover:underline">Download</a>
                            </li>
                        @endforeach
                    @empty
                        <li class="py-2 text-slate-400">No existing documents linked.</li>
                    @endforelse
                </ul>
            </div>

            <div class="rounded-xl border border-slate-200 bg-white p-6">
                <h3 class="mb-4 text-sm font-semibold text-slate-700">Attachments</h3>
                <ul class="divide-y divide-slate-100 text-sm">
                    @forelse ($pcr->attachments as $attachment)
                        <li class="flex items-center justify-between py-2">
                            <span class="text-slate-700">{{ $attachment->original_filename }}</span>
                            <a href="{{ route('admin.professional-collection.attachments.download', [$pcr, $attachment]) }}" class="text-xs font-medium text-deendoon-teal hover:underline">Download</a>
                        </li>
                    @empty
                        <li class="py-2 text-slate-400">No additional attachments uploaded.</li>
                    @endforelse
                </ul>
                @if ($canUploadNow)
                    <form method="POST" action="{{ route('admin.professional-collection.attachments.store', $pcr) }}" class="mt-4 flex flex-wrap items-center gap-2" enctype="multipart/form-data">
                        @csrf
                        <input type="file" name="file" required accept=".pdf,.jpg,.jpeg,.png,.doc,.docx" class="text-sm text-slate-500">
                        <button type="submit" class="rounded-lg bg-deendoon-teal px-4 py-2 text-sm font-semibold text-white hover:bg-deendoon-teal-dark">
                            Upload
                        </button>
                    </form>
                @elseif (! $isTerminal)
                    <p class="mt-3 text-xs text-slate-400">The Platform Administrator may upload once this request is Assigned or In Progress.</p>
                @endif
            </div>
        </div>
    </div>

    @unless ($isTerminal)
        <dialog id="close-request-dialog" class="w-full max-w-sm rounded-xl border border-slate-200 p-0 backdrop:bg-slate-900/50">
            <form method="POST" action="{{ route('admin.professional-collection.close', $pcr) }}" class="p-6">
                @csrf
                <h3 class="text-lg font-bold text-slate-800">Close {{ $pcr->reference_number }}?</h3>
                <p class="mt-2 text-sm text-slate-500">This is a terminal action — the request becomes read-only afterward. The Business Owner will be notified.</p>
                <fieldset class="mt-4 space-y-2">
                    <label class="flex items-center gap-2 text-sm text-slate-700">
                        <input type="radio" name="outcome" value="recovered" required class="text-deendoon-teal focus:ring-deendoon-teal">
                        Recovered — the debt was successfully recovered
                    </label>
                    <label class="flex items-center gap-2 text-sm text-slate-700">
                        <input type="radio" name="outcome" value="closed" class="text-deendoon-teal focus:ring-deendoon-teal">
                        Closed — unsuccessful, no further recovery action
                    </label>
                </fieldset>
                <div class="mt-5 flex justify-end gap-3">
                    <button type="button" onclick="document.getElementById('close-request-dialog').close()"
                            class="rounded-lg px-4 py-2 text-sm font-medium text-slate-500 hover:text-slate-700">Cancel</button>
                    <button type="submit" class="rounded-lg bg-deendoon-danger px-4 py-2 text-sm font-semibold text-white hover:opacity-90">Confirm Close</button>
                </div>
            </form>
        </dialog>
    @endunless
@endsection
