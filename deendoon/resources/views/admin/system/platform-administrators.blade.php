@extends('admin.layout')

@section('content')
    @include('admin.system.partials.subnav')

    <div class="rounded-xl border border-slate-200 bg-white p-6">
        <div class="mb-4 flex items-center justify-between">
            <h3 class="text-sm font-semibold text-slate-700">Platform Administrator</h3>
            <span class="rounded-full bg-slate-100 px-2.5 py-0.5 text-xs font-medium text-slate-500">Read-only</span>
        </div>
        <p class="mb-4 text-xs text-slate-400">
            Account creation is intentionally CLI-only (<code class="rounded bg-slate-100 px-1 py-0.5">php artisan admin:create-platform-admin</code>) — there is no Create Admin action here.
        </p>
        <div class="overflow-x-auto rounded-lg border border-slate-200">
            <table class="min-w-full divide-y divide-slate-200 text-sm">
                <thead class="bg-slate-50">
                    <tr class="text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                        <th class="px-4 py-3">Name</th>
                        <th class="px-4 py-3">Email</th>
                        <th class="px-4 py-3">Created</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-100">
                    @forelse ($administrators as $admin)
                        <tr>
                            <td class="px-4 py-3 font-medium text-slate-800">{{ $admin->name }}</td>
                            <td class="px-4 py-3 text-slate-600">{{ $admin->email }}</td>
                            <td class="px-4 py-3 text-slate-500">{{ $admin->created_at?->format('M j, Y') ?? '—' }}</td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="3" class="px-4 py-8 text-center text-slate-400">No Platform Administrator accounts found.</td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>
@endsection
