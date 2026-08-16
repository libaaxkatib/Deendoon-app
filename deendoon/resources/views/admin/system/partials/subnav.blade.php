@php
    $systemNavItems = [
        ['route' => 'admin.system.health', 'label' => 'System Health'],
        ['route' => 'admin.system.platform-administrators', 'label' => 'Platform Administrator'],
        ['route' => 'admin.system.security-events', 'label' => 'Security Events'],
        ['route' => 'admin.system.backup', 'label' => 'Database Backup'],
        ['route' => 'admin.system.scheduler', 'label' => 'Scheduler / Automated Jobs'],
    ];
@endphp
<div class="mb-6 flex flex-wrap gap-2 border-b border-slate-200 pb-3">
    @foreach ($systemNavItems as $item)
        <a href="{{ route($item['route']) }}"
           class="rounded-lg px-3 py-1.5 text-sm font-medium transition
                  {{ request()->routeIs($item['route']) ? 'bg-deendoon-teal/10 text-deendoon-teal' : 'text-slate-500 hover:bg-slate-100 hover:text-slate-700' }}">
            {{ $item['label'] }}
        </a>
    @endforeach
</div>
