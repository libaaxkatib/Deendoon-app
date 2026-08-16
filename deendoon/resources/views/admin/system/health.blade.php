@extends('admin.layout')

@section('content')
    @include('admin.system.partials.subnav')

    <div class="mb-6 rounded-xl border border-slate-200 bg-white p-6">
        <div class="mb-4 flex items-center justify-between">
            <h3 class="text-sm font-semibold text-slate-700">System Health</h3>
            <span class="text-xs text-slate-400">Basic V1</span>
        </div>
        <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
            @foreach ($checks as $check)
                @php $isReal = in_array($check['name'], $realChecks, true); @endphp
                <div class="rounded-lg border border-slate-200 p-4">
                    <div class="flex items-center justify-between">
                        <span class="text-sm font-medium text-slate-700">{{ $check['name'] }}</span>
                        <span class="h-2.5 w-2.5 rounded-full {{ $check['operational'] ? 'bg-deendoon-success' : 'bg-deendoon-danger' }}"></span>
                    </div>
                    <p class="mt-1 text-xs font-medium {{ $check['operational'] ? 'text-emerald-600' : 'text-red-600' }}">
                        {{ $check['operational'] ? 'Operational' : 'Degraded' }}
                    </p>
                    <p class="mt-2 text-[11px] text-slate-400">
                        {{ $isReal ? 'Live check' : 'Not yet backed by a real check' }}
                    </p>
                </div>
            @endforeach
        </div>
        <p class="mt-4 text-xs text-slate-400">
            Database and File Storage are live checks (a real connection ping / disk read). Application and API have no dedicated check yet and are shown as a fixed baseline, not fabricated live data.
        </p>
    </div>

    <div class="rounded-xl border border-slate-200 bg-white p-6">
        <h3 class="mb-4 text-sm font-semibold text-slate-700">Environment</h3>
        <dl class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
            @foreach ($info as $label => $value)
                <div>
                    <dt class="text-xs font-medium uppercase text-slate-400">{{ $label }}</dt>
                    <dd class="text-sm text-slate-700">{{ $value }}</dd>
                </div>
            @endforeach
        </dl>
    </div>
@endsection
