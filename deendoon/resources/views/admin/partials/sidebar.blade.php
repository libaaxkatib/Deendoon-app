@php
    $navItems = [
        ['route' => 'admin.dashboard', 'label' => 'Dashboard', 'icon' => 'home'],
        ['route' => 'admin.businesses.index', 'label' => 'Businesses', 'icon' => 'building', 'matches' => 'admin.businesses.*'],
        ['route' => 'admin.recovery-debts.index', 'label' => 'Recovery & Debts', 'icon' => 'currency', 'matches' => 'admin.recovery-debts.*'],
        ['route' => 'admin.debtors.index', 'label' => 'Debtors', 'icon' => 'users', 'matches' => 'admin.debtors.*'],
        ['route' => 'admin.payments.index', 'label' => 'Payments', 'icon' => 'card', 'matches' => 'admin.payments.*'],
        ['route' => 'admin.subscriptions.index', 'label' => 'Subscriptions', 'icon' => 'stack', 'matches' => 'admin.subscriptions.*'],
        ['route' => 'admin.payment-requests.index', 'label' => 'Payment Requests', 'icon' => 'card', 'matches' => 'admin.payment-requests.*'],
        ['route' => 'admin.professional-collection.index', 'label' => 'Professional Collection', 'icon' => 'briefcase', 'matches' => 'admin.professional-collection.*'],
        ['route' => 'admin.reports.overview', 'label' => 'Reports & Analytics', 'icon' => 'chart', 'matches' => 'admin.reports.*'],
        ['route' => 'admin.support-tickets.index', 'label' => 'Support & Tickets', 'icon' => 'support', 'matches' => 'admin.support-tickets.*'],
        ['route' => 'admin.system.health', 'label' => 'System Management', 'icon' => 'cog', 'matches' => 'admin.system.*'],
        ['route' => 'admin.notifications.index', 'label' => 'Notifications', 'icon' => 'bell', 'matches' => 'admin.notifications.*'],
        ['route' => 'admin.audit-logs.index', 'label' => 'Audit Logs', 'icon' => 'clipboard'],
        ['route' => 'admin.settings.index', 'label' => 'Settings', 'icon' => 'settings', 'matches' => 'admin.settings.*'],
    ];

    $icons = [
        'home' => 'M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6',
        'building' => 'M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2M5 21h2m0 0h10M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 9v-4a1 1 0 011-1h0a1 1 0 011 1v4',
        'currency' => 'M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V6m0 10v2m9-6a9 9 0 11-18 0 9 9 0 0118 0z',
        'users' => 'M17 20h5v-2a4 4 0 00-3-3.87M9 20H4v-2a4 4 0 013-3.87m6-1.13a4 4 0 10-4-4 4 4 0 004 4zm6 0a4 4 0 10-1-7.874',
        'card' => 'M3 10h18M7 15h1m4 0h1m-7 4h12a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z',
        'stack' => 'M4 6h16M4 12h16M4 18h7',
        'briefcase' => 'M21 13.255A23.931 23.931 0 0112 15c-3.183 0-6.22-.62-9-1.745M16 6V4a2 2 0 00-2-2h-4a2 2 0 00-2 2v2m-4 6h16a1 1 0 011 1v7a2 2 0 01-2 2H5a2 2 0 01-2-2v-7a1 1 0 011-1z',
        'chart' => 'M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z',
        'support' => 'M18.364 5.636l-3.536 3.536m0 5.656l3.536 3.536M5.636 5.636l3.536 3.536m0 5.656l-3.536 3.536M22 12h-6m-8 0H2m10 8v-6m0-8V2',
        'cog' => 'M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z',
        'bell' => 'M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9',
        'clipboard' => 'M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4',
        'settings' => 'M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z',
    ];
@endphp
<aside class="fixed inset-y-0 left-0 flex w-60 flex-col bg-deendoon-navy text-white">
    <div class="flex items-center gap-2 px-5 py-6">
        <img src="{{ asset('images/deendoon-logo.png') }}" alt="Deendoon" class="h-9 w-9" onerror="this.style.display='none'">
        <span class="text-lg font-bold tracking-wide text-deendoon-teal">DEENDOON</span>
    </div>

    <div class="mx-4 mb-4 flex items-center gap-2 rounded-lg bg-white/5 px-3 py-2 text-sm text-white/70">
        <span class="flex h-6 w-6 items-center justify-center rounded-full bg-deendoon-teal/20 text-deendoon-teal">◎</span>
        Super Admin Control Center
    </div>

    <nav class="flex-1 space-y-0.5 overflow-y-auto px-3 pb-4">
        @foreach ($navItems as $item)
            @php
                $active = request()->routeIs($item['matches'] ?? $item['route']);
            @endphp
            <a href="{{ route($item['route']) }}"
               class="flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition
                      {{ $active ? 'bg-deendoon-teal/15 text-deendoon-teal' : 'text-white/70 hover:bg-white/5 hover:text-white' }}">
                <svg class="h-4.5 w-4.5 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.75">
                    <path stroke-linecap="round" stroke-linejoin="round" d="{{ $icons[$item['icon']] }}" />
                </svg>
                {{ $item['label'] }}
            </a>
        @endforeach
    </nav>

    <div class="border-t border-white/10 px-4 py-4">
        <div class="mb-3 flex items-center gap-2">
            <span class="flex h-8 w-8 items-center justify-center rounded-full bg-deendoon-teal/20 text-sm font-semibold text-deendoon-teal">
                {{ strtoupper(substr(auth()->user()->name ?? 'A', 0, 1)) }}
            </span>
            <div class="min-w-0">
                <p class="truncate text-sm font-medium">{{ auth()->user()->name ?? 'Super Admin' }}</p>
                <p class="flex items-center gap-1 text-xs text-white/50">
                    <span class="h-1.5 w-1.5 rounded-full bg-deendoon-success"></span> Online
                </p>
            </div>
        </div>
        <form method="POST" action="{{ route('admin.logout') }}">
            @csrf
            <button type="submit" class="flex w-full items-center gap-2 rounded-lg px-3 py-2 text-sm text-white/70 hover:bg-white/5 hover:text-white">
                <svg class="h-4.5 w-4.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.75">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M17 16l4-4m0 0l-4-4m4 4H7m6 5v1a3 3 0 01-3 3H6a3 3 0 01-3-3V6a3 3 0 013-3h4a3 3 0 013 3v1" />
                </svg>
                Logout
            </button>
        </form>
    </div>
</aside>
