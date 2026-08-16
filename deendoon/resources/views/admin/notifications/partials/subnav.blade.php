@php
    $notificationsNavItems = [
        ['route' => 'admin.notifications.index', 'label' => 'Send System Notice'],
        ['route' => 'admin.notifications.history', 'label' => 'System Notice History'],
    ];
@endphp
<div class="mb-6 flex flex-wrap gap-2 border-b border-slate-200 pb-3">
    @foreach ($notificationsNavItems as $item)
        <a href="{{ route($item['route']) }}"
           class="rounded-lg px-3 py-1.5 text-sm font-medium transition
                  {{ request()->routeIs($item['route']) ? 'bg-deendoon-teal/10 text-deendoon-teal' : 'text-slate-500 hover:bg-slate-100 hover:text-slate-700' }}">
            {{ $item['label'] }}
        </a>
    @endforeach
</div>
