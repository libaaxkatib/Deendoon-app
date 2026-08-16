@extends('admin.layout')

@section('content')
    @include('admin.notifications.partials.subnav')

    <div class="rounded-xl border border-slate-200 bg-white p-6">
        <h3 class="mb-2 text-sm font-semibold text-slate-700">Send System Notice</h3>
        <p class="mb-4 text-sm text-slate-500">
            Send a System Notice to Business Owners. It appears in their Notification Center — no push, email, SMS, or WhatsApp is sent.
        </p>

        @if ($errors->any())
            <div class="mb-4 rounded-lg border border-deendoon-danger/30 bg-deendoon-danger/10 px-4 py-3 text-sm text-red-700">
                <ul class="list-inside list-disc">
                    @foreach ($errors->all() as $error)
                        <li>{{ $error }}</li>
                    @endforeach
                </ul>
            </div>
        @endif

        <form method="POST" action="{{ route('admin.notifications.store') }}">
            @csrf

            <div class="mb-4">
                <span class="mb-2 block text-sm font-medium text-slate-700">Recipients</span>
                <label class="mb-2 flex items-center gap-2 text-sm text-slate-700">
                    <input type="radio" name="scope" value="all" id="scope-all" onchange="deendoonToggleScope()" {{ old('scope', 'all') === 'all' ? 'checked' : '' }}>
                    All businesses
                </label>
                <label class="flex items-center gap-2 text-sm text-slate-700">
                    <input type="radio" name="scope" value="selected" id="scope-selected" onchange="deendoonToggleScope()" {{ old('scope') === 'selected' ? 'checked' : '' }}>
                    Selected businesses
                </label>
            </div>

            <div class="mb-4" id="tenant-picker">
                <input type="text" id="tenant-filter" oninput="deendoonFilterTenants()" placeholder="Filter businesses…"
                       class="mb-2 w-full rounded-lg border border-slate-300 px-3 py-2 text-sm">
                <div class="max-h-64 overflow-y-auto rounded-lg border border-slate-200 p-3">
                    @foreach ($tenants as $tenant)
                        <label class="tenant-option flex items-center gap-2 py-1 text-sm text-slate-700" data-name="{{ mb_strtolower($tenant->business_name) }}">
                            <input type="checkbox" name="tenant_ids[]" value="{{ $tenant->id }}"
                                   {{ in_array($tenant->id, old('tenant_ids', []), true) ? 'checked' : '' }}>
                            {{ $tenant->business_name }}
                            <span class="text-xs text-slate-400">({{ $tenant->status }})</span>
                        </label>
                    @endforeach
                </div>
            </div>

            <div class="mb-4">
                <label for="title" class="mb-1 block text-sm font-medium text-slate-700">Title</label>
                <input type="text" id="title" name="title" maxlength="255" value="{{ old('title') }}"
                       class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm">
            </div>

            <div class="mb-4">
                <label for="message" class="mb-1 block text-sm font-medium text-slate-700">Message</label>
                <textarea id="message" name="message" rows="4" maxlength="2000"
                          class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm">{{ old('message') }}</textarea>
            </div>

            <button type="submit" class="rounded-lg bg-deendoon-teal px-4 py-2 text-sm font-semibold text-white hover:bg-deendoon-teal-dark">
                Send System Notice
            </button>
        </form>
    </div>

    <script>
        function deendoonToggleScope() {
            const selected = document.getElementById('scope-selected').checked;
            document.getElementById('tenant-picker').style.display = selected ? '' : 'none';
        }

        function deendoonFilterTenants() {
            const term = document.getElementById('tenant-filter').value.trim().toLowerCase();
            document.querySelectorAll('.tenant-option').forEach((option) => {
                option.style.display = option.dataset.name.includes(term) ? '' : 'none';
            });
        }

        deendoonToggleScope();
    </script>
@endsection
