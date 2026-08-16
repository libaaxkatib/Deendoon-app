<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ $title ?? 'Dashboard' }} — Deendoon Super Admin</title>
    @vite(['resources/css/app.css'])
</head>
<body class="bg-deendoon-bg font-sans text-slate-800 antialiased">
    @include('admin.partials.sidebar')

    <div class="ml-60 flex min-h-screen flex-col">
        <header class="flex h-16 items-center justify-between border-b border-slate-200 bg-white px-6">
            <h1 class="text-xl font-bold">
                <span class="text-deendoon-teal">DEENDOON</span>
                <span class="text-slate-800">— {{ $pageTitle ?? ($title ?? 'Dashboard') }}</span>
            </h1>
            <div class="flex items-center gap-4">
                <button type="button" class="relative rounded-full p-2 text-slate-500 hover:bg-slate-100" title="Notifications">
                    <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.75">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
                    </svg>
                </button>
                <span class="flex h-9 w-9 items-center justify-center rounded-full bg-deendoon-teal/10 text-sm font-semibold text-deendoon-teal">
                    {{ strtoupper(substr(auth()->user()->name ?? 'A', 0, 1)) }}
                </span>
            </div>
        </header>

        <main class="flex-1 px-6 py-6">
            @if (session('status'))
                <div class="mb-4 rounded-lg border border-deendoon-success/30 bg-deendoon-success/10 px-4 py-3 text-sm text-emerald-800">
                    {{ session('status') }}
                </div>
            @endif

            @yield('content')
        </main>

        <footer class="border-t border-slate-200 px-6 py-3 text-center text-xs text-slate-400">
            © {{ now()->year }} DEENDOON. All Rights Reserved. — Super Admin Control Center v1.0.0
        </footer>
    </div>
</body>
</html>
