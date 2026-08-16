@extends('admin.layout')

@section('content')
    @php
        $br = $businessAndRecovery;
        $sp = $systemAndPlatform;
        $fmt = fn ($n) => $n === null ? '—' : number_format($n);
        $money = fn ($n) => $n === null ? '—' : '$'.number_format($n, 0);
        $pct = fn ($n) => $n === null ? '—' : rtrim(rtrim(number_format($n, 1), '0'), '.').'%';
    @endphp

    <div class="grid grid-cols-1 gap-6 xl:grid-cols-5">
        {{-- ============ A. BUSINESS & RECOVERY DASHBOARD ============ --}}
        <div class="space-y-6 xl:col-span-3">
            <h2 class="text-sm font-bold uppercase tracking-wide text-deendoon-teal">A. Business &amp; Recovery Dashboard</h2>

            <div class="grid grid-cols-3 gap-4">
                @include('admin.partials.stat-card', ['label' => 'Total Businesses', 'value' => $fmt($br['total_businesses'])])
                @include('admin.partials.stat-card', ['label' => 'Total Debtors', 'value' => $fmt($br['total_debtors']), 'highlight' => true])
                @include('admin.partials.stat-card', ['label' => 'Total Debt Cases', 'value' => $fmt($br['total_debt_cases'])])
            </div>

            <div class="grid grid-cols-2 gap-4 sm:grid-cols-4">
                @include('admin.partials.stat-card', ['label' => 'Outstanding Debt', 'value' => $money($br['outstanding_debt']), 'tone' => 'danger'])
                @include('admin.partials.stat-card', ['label' => 'Amount Recovered', 'value' => $money($br['amount_recovered']), 'tone' => 'success'])
                @include('admin.partials.stat-card', ['label' => 'Overdue Debts', 'value' => $fmt($br['overdue_debts']), 'tone' => 'warning'])
                @include('admin.partials.stat-card', ['label' => 'High-Risk Debtors', 'value' => $fmt($br['high_risk_debtors']), 'tone' => 'danger'])
            </div>

            <div class="grid grid-cols-1 gap-4 lg:grid-cols-2">
                <div class="rounded-xl border border-slate-200 bg-white p-5">
                    <h3 class="mb-4 text-sm font-semibold text-slate-700">Recovery Performance (Monthly)</h3>
                    @php $maxVal = max(1, collect($br['recovery_performance'])->flatMap(fn ($r) => [$r['debt_assigned'], $r['amount_recovered']])->max()); @endphp
                    <div class="flex h-40 items-end gap-3">
                        @foreach ($br['recovery_performance'] as $row)
                            <div class="flex flex-1 flex-col items-center gap-1">
                                <div class="flex h-32 w-full items-end justify-center gap-0.5">
                                    <div class="w-2.5 rounded-t bg-deendoon-teal/70" style="height: {{ max(2, ($row['debt_assigned'] / $maxVal) * 100) }}%" title="Assigned {{ $money($row['debt_assigned']) }}"></div>
                                    <div class="w-2.5 rounded-t bg-deendoon-gold" style="height: {{ max(2, ($row['amount_recovered'] / $maxVal) * 100) }}%" title="Recovered {{ $money($row['amount_recovered']) }}"></div>
                                </div>
                                <span class="text-xs text-slate-400">{{ $row['label'] }}</span>
                            </div>
                        @endforeach
                    </div>
                    <div class="mt-3 flex gap-4 text-xs text-slate-500">
                        <span class="flex items-center gap-1"><span class="h-2 w-2 rounded-full bg-deendoon-teal/70"></span> Debt Assigned</span>
                        <span class="flex items-center gap-1"><span class="h-2 w-2 rounded-full bg-deendoon-gold"></span> Amount Recovered</span>
                    </div>
                </div>

                <div class="rounded-xl border border-slate-200 bg-white p-5">
                    <div class="mb-3 flex items-center justify-between">
                        <h3 class="text-sm font-semibold text-slate-700">Recent Activity</h3>
                    </div>
                    <ul class="max-h-56 space-y-3 overflow-y-auto text-sm">
                        @forelse ($br['recent_activity'] as $item)
                            <li class="flex items-start justify-between gap-2">
                                <span class="text-slate-700">
                                    {{ $item['action'] }}
                                    @if ($item['business'])
                                        <span class="ml-1 inline-flex items-center rounded-full bg-slate-100 px-2 py-0.5 text-[11px] font-medium text-slate-500">{{ $item['business'] }}</span>
                                    @endif
                                </span>
                                <span class="shrink-0 text-xs text-slate-400">{{ $item['occurred_at']->diffForHumans() }}</span>
                            </li>
                        @empty
                            <li class="text-slate-400">No activity recorded yet.</li>
                        @endforelse
                    </ul>
                </div>
            </div>

            <div class="rounded-xl border border-slate-200 bg-white p-5">
                <h3 class="mb-4 text-sm font-semibold text-slate-700">Business &amp; Recovery Statistics (This Month)</h3>
                <div class="grid grid-cols-3 gap-4 sm:grid-cols-4 lg:grid-cols-7">
                    @include('admin.partials.mini-stat', ['label' => 'New Businesses', 'value' => $fmt($br['this_month']['new_businesses'])])
                    @include('admin.partials.mini-stat', ['label' => 'New Debtors', 'value' => $fmt($br['this_month']['new_debtors'])])
                    @include('admin.partials.mini-stat', ['label' => 'New Debt Cases', 'value' => $fmt($br['this_month']['new_debt_cases'])])
                    @include('admin.partials.mini-stat', ['label' => 'Debt Registered', 'value' => $money($br['this_month']['debt_registered'])])
                    @include('admin.partials.mini-stat', ['label' => 'Amount Recovered', 'value' => $money($br['this_month']['amount_recovered'])])
                    @include('admin.partials.mini-stat', ['label' => 'Recovery Rate', 'value' => $pct($br['this_month']['recovery_rate'])])
                    @include('admin.partials.mini-stat', ['label' => 'Prof. Collection Req.', 'value' => $fmt($br['this_month']['professional_collection_requests'])])
                </div>
            </div>

            <div class="rounded-xl border border-slate-200 bg-white p-5">
                <h3 class="mb-4 text-sm font-semibold text-slate-700">Platform Statistics (Overall)</h3>
                <div class="grid grid-cols-3 gap-4 sm:grid-cols-4 lg:grid-cols-5">
                    @include('admin.partials.mini-stat', ['label' => 'Total Businesses', 'value' => $fmt($br['platform_statistics']['total_businesses'])])
                    @include('admin.partials.mini-stat', ['label' => 'Total Debtors', 'value' => $fmt($br['platform_statistics']['total_debtors'])])
                    @include('admin.partials.mini-stat', ['label' => 'Total Debt Cases', 'value' => $fmt($br['platform_statistics']['total_debt_cases'])])
                    @include('admin.partials.mini-stat', ['label' => 'Total Debt Value', 'value' => $money($br['platform_statistics']['total_debt_value'])])
                    @include('admin.partials.mini-stat', ['label' => 'Total Recovered', 'value' => $money($br['platform_statistics']['total_recovered'])])
                    @include('admin.partials.mini-stat', ['label' => 'Total Active Users', 'value' => $fmt($br['platform_statistics']['total_active_users'])])
                    @include('admin.partials.mini-stat', ['label' => 'Total Documents', 'value' => $fmt($br['platform_statistics']['total_documents']), 'pending' => $br['platform_statistics']['total_documents'] === null])
                    @include('admin.partials.mini-stat', ['label' => 'Total Reminders', 'value' => $fmt($br['platform_statistics']['total_reminders'])])
                    @include('admin.partials.mini-stat', ['label' => 'Total Payments', 'value' => $fmt($br['platform_statistics']['total_payments'])])
                    @include('admin.partials.mini-stat', ['label' => 'Prof. Collection Req.', 'value' => $fmt($br['platform_statistics']['total_professional_collection_requests'])])
                </div>
            </div>
        </div>

        {{-- ============ B. SYSTEM / PLATFORM DASHBOARD ============ --}}
        <div class="space-y-6 xl:col-span-2">
            <h2 class="text-sm font-bold uppercase tracking-wide text-deendoon-teal">B. System / Platform Dashboard</h2>

            <div class="grid grid-cols-2 gap-4">
                @include('admin.partials.stat-card', ['label' => 'New Registrations', 'sub' => 'This Month', 'value' => $fmt($sp['new_registrations_this_month'])])
                @include('admin.partials.stat-card', ['label' => 'Active Accounts', 'value' => $fmt($sp['active_accounts']), 'tone' => 'success'])
            </div>
            <div class="grid grid-cols-2 gap-4">
                @include('admin.partials.stat-card', ['label' => 'Inactive Accounts', 'value' => $fmt($sp['inactive_accounts']), 'pending' => $sp['inactive_accounts'] === null])
                @include('admin.partials.stat-card', ['label' => 'Suspended Accounts', 'value' => $fmt($sp['suspended_accounts']), 'tone' => 'danger'])
            </div>

            <div class="rounded-xl border border-slate-200 bg-white p-5">
                <div class="mb-3 flex items-center justify-between">
                    <h3 class="text-sm font-semibold text-slate-700">Subscription Overview</h3>
                    <a href="{{ route('admin.subscriptions.index') }}" class="text-xs font-medium text-deendoon-teal">View All</a>
                </div>
                @php
                    $plans = $sp['subscription_overview']['plans'];
                    $colors = ['#18C7B6', '#D4AF37', '#6366F1', '#F59E0B', '#EF4444'];
                    $circumference = 2 * M_PI * 40;
                    $offset = 0;
                @endphp
                <div class="flex items-center gap-6">
                    <svg viewBox="0 0 100 100" class="h-28 w-28 shrink-0 -rotate-90">
                        <circle cx="50" cy="50" r="40" fill="none" stroke="#E5E7EB" stroke-width="14" />
                        @foreach ($plans as $i => $plan)
                            @php
                                $dash = $circumference * ($plan['percentage'] / 100);
                            @endphp
                            <circle cx="50" cy="50" r="40" fill="none" stroke="{{ $colors[$i % count($colors)] }}" stroke-width="14"
                                    stroke-dasharray="{{ $dash }} {{ $circumference - $dash }}" stroke-dashoffset="{{ -$offset }}" />
                            @php $offset += $dash; @endphp
                        @endforeach
                    </svg>
                    <div class="flex-1 space-y-1.5 text-sm">
                        @foreach ($plans as $i => $plan)
                            <div class="flex items-center justify-between gap-2">
                                <span class="flex items-center gap-2 text-slate-600">
                                    <span class="h-2.5 w-2.5 rounded-full" style="background: {{ $colors[$i % count($colors)] }}"></span>
                                    {{ $plan['name'] }}
                                </span>
                                <span class="font-medium text-slate-800">{{ $fmt($plan['count']) }} ({{ $pct($plan['percentage']) }})</span>
                            </div>
                        @endforeach
                    </div>
                </div>
                <div class="mt-4 flex items-center justify-between border-t border-slate-100 pt-3 text-sm">
                    <span class="text-slate-500">Monthly Recurring Revenue</span>
                    <span class="font-bold text-slate-800">{{ $money($sp['monthly_recurring_revenue']) }} / month</span>
                </div>
            </div>

            <div class="grid grid-cols-2 gap-4">
                @include('admin.partials.stat-card', ['label' => 'System Usage', 'sub' => 'This Month', 'value' => $fmt($sp['system_usage_trend']), 'pending' => $sp['system_usage_trend'] === null])
                @include('admin.partials.stat-card', ['label' => 'Recent Logins', 'sub' => 'Today', 'value' => $fmt($sp['recent_logins_today'])])
            </div>

            <div class="grid grid-cols-2 gap-4">
                <div class="rounded-xl border border-slate-200 bg-white p-5">
                    <div class="mb-2 flex items-center justify-between">
                        <h3 class="text-sm font-semibold text-slate-700">Support Requests</h3>
                        <a href="{{ route('admin.support-tickets.index') }}" class="text-xs font-medium text-deendoon-teal">View All</a>
                    </div>
                    @if ($sp['support_requests'] === null)
                        <p class="text-xs text-slate-400">Support ticketing is not built yet — planned next increment (Support Tickets + Phone + WhatsApp + Email).</p>
                    @endif
                </div>
                <div class="rounded-xl border border-slate-200 bg-white p-5">
                    <div class="mb-2 flex items-center justify-between">
                        <h3 class="text-sm font-semibold text-slate-700">System Health</h3>
                        <span class="text-xs text-slate-400">Basic V1</span>
                    </div>
                    <ul class="space-y-1.5 text-sm">
                        @foreach ($sp['system_health'] as $check)
                            <li class="flex items-center justify-between">
                                <span class="flex items-center gap-2 text-slate-600">
                                    <span class="h-2 w-2 rounded-full {{ $check['operational'] ? 'bg-deendoon-success' : 'bg-deendoon-danger' }}"></span>
                                    {{ $check['name'] }}
                                </span>
                                <span class="text-xs font-medium {{ $check['operational'] ? 'text-emerald-600' : 'text-red-600' }}">
                                    {{ $check['operational'] ? 'Operational' : 'Degraded' }}
                                </span>
                            </li>
                        @endforeach
                    </ul>
                </div>
            </div>
        </div>
    </div>
@endsection
