@extends('admin.layout')

@section('content')
    @include('admin.system.partials.subnav')

    <div class="rounded-xl border border-slate-200 bg-white p-6">
        <h3 class="mb-2 text-sm font-semibold text-slate-700">Scheduler / Automated Jobs</h3>
        <p class="mb-4 text-xs text-slate-400">
            Registered directly from Laravel's own scheduler (<code class="rounded bg-slate-100 px-1 py-0.5">bootstrap/app.php</code>) — this list reflects what is actually wired, not a static description.
        </p>
        <div class="overflow-x-auto rounded-lg border border-slate-200">
            <table class="min-w-full divide-y divide-slate-200 text-sm">
                <thead class="bg-slate-50">
                    <tr class="text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                        <th class="px-4 py-3">Command</th>
                        <th class="px-4 py-3">Schedule (cron expression)</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-100">
                    @forelse ($events as $event)
                        <tr>
                            <td class="px-4 py-3 font-medium text-slate-800">{{ $event['command'] }}</td>
                            <td class="px-4 py-3 text-slate-600">
                                <code class="rounded bg-slate-100 px-1.5 py-0.5 text-xs">{{ $event['expression'] }}</code>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="2" class="px-4 py-8 text-center text-slate-400">No scheduled jobs are registered.</td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
        <p class="mt-4 text-xs text-slate-400">
            Requires a single external <code class="rounded bg-slate-100 px-1 py-0.5">* * * * * php artisan schedule:run</code> cron entry on the server to actually tick these — this page shows what's registered, not live server cron status.
        </p>
    </div>
@endsection
