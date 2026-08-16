<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Sign In — Deendoon Super Admin</title>
    @vite(['resources/css/app.css'])
</head>
<body class="flex min-h-screen items-center justify-center bg-deendoon-navy font-sans">
    <div class="w-full max-w-sm rounded-2xl bg-white p-8 shadow-xl">
        <div class="mb-6 text-center">
            <img src="{{ asset('images/deendoon-logo.png') }}" alt="Deendoon" class="mx-auto mb-3 h-14 w-14" onerror="this.style.display='none'">
            <h1 class="text-2xl font-bold"><span class="text-deendoon-teal">DEENDOON</span></h1>
            <p class="mt-1 text-sm text-slate-500">Super Admin Control Center</p>
        </div>

        @if ($errors->any())
            <div class="mb-4 rounded-lg border border-deendoon-danger/30 bg-deendoon-danger/10 px-4 py-3 text-sm text-red-700">
                {{ $errors->first() }}
            </div>
        @endif

        <form method="POST" action="{{ route('admin.login') }}" class="space-y-4">
            @csrf
            <div>
                <label for="email" class="mb-1 block text-sm font-medium text-slate-700">Email</label>
                <input type="email" name="email" id="email" value="{{ old('email') }}" required autofocus
                       class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-deendoon-teal focus:outline-none focus:ring-1 focus:ring-deendoon-teal">
            </div>
            <div>
                <label for="password" class="mb-1 block text-sm font-medium text-slate-700">Password</label>
                <input type="password" name="password" id="password" required
                       class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-deendoon-teal focus:outline-none focus:ring-1 focus:ring-deendoon-teal">
            </div>
            <label class="flex items-center gap-2 text-sm text-slate-600">
                <input type="checkbox" name="remember" class="rounded border-slate-300 text-deendoon-teal focus:ring-deendoon-teal">
                Remember me
            </label>
            <button type="submit"
                    class="w-full rounded-lg bg-deendoon-teal py-2.5 text-sm font-semibold text-white transition hover:bg-deendoon-teal-dark">
                Sign In
            </button>
        </form>
    </div>
</body>
</html>
