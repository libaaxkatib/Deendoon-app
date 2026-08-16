<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ $title }} — Deendoon</title>
    @vite(['resources/css/app.css'])
</head>
<body class="bg-deendoon-bg font-sans text-slate-800 antialiased">
    <div class="mx-auto max-w-3xl px-6 py-10">
        <div class="mb-8 flex items-center gap-2">
            <img src="{{ asset('images/deendoon-logo.png') }}" alt="Deendoon" class="h-9 w-9" onerror="this.style.display='none'">
            <span class="text-lg font-bold tracking-wide text-deendoon-teal">DEENDOON</span>
        </div>

        <h1 class="mb-6 text-2xl font-bold text-slate-800">{{ $title }}</h1>

        <div class="prose prose-slate max-w-none rounded-xl border border-slate-200 bg-white p-8 leading-relaxed">
            @yield('content')
        </div>

        <footer class="mt-8 text-center text-xs text-slate-400">
            © {{ now()->year }} DEENDOON. All Rights Reserved.
        </footer>
    </div>
</body>
</html>
