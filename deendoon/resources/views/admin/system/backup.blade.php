@extends('admin.layout')

@section('content')
    @include('admin.system.partials.subnav')

    <div class="rounded-xl border border-slate-200 bg-white p-6">
        <h3 class="mb-2 text-sm font-semibold text-slate-700">Database Backup</h3>
        <p class="mb-4 text-sm text-slate-500">
            Creates an on-demand SQL dump of the database and downloads it immediately. Nothing is stored on the server after the download — no automated schedule, no cloud/off-site copy.
        </p>

        @if ($errors->any())
            <div class="mb-4 rounded-lg border border-deendoon-danger/30 bg-deendoon-danger/10 px-4 py-3 text-sm text-red-700">
                {{ $errors->first() }}
            </div>
        @endif

        <form method="POST" action="{{ route('admin.system.backup.create') }}">
            @csrf
            <button type="submit" class="rounded-lg bg-deendoon-teal px-4 py-2 text-sm font-semibold text-white hover:bg-deendoon-teal-dark">
                Create &amp; Download Backup
            </button>
        </form>
    </div>
@endsection
