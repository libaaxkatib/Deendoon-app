@extends('admin.layout')

@section('content')
    @php
        $fmt = fn ($n) => $n === null ? '—' : number_format($n);
        $money = fn ($n) => $n === null ? '—' : '$'.number_format($n, 0);
        $pct = fn ($n) => $n === null ? '—' : rtrim(rtrim(number_format($n, 1), '0'), '.').'%';
    @endphp

    @include('admin.reports.partials.filters', ['filterAction' => route('admin.reports.overview'), 'reportSlug' => 'overview'])

    <div class="mb-6 grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-6">
        @include('admin.partials.stat-card', ['label' => 'Total Businesses', 'value' => $fmt($data['total_businesses'])])
        @include('admin.partials.stat-card', ['label' => 'Total Debtors', 'value' => $fmt($data['total_debtors'])])
        @include('admin.partials.stat-card', ['label' => 'Total Debt Cases', 'value' => $fmt($data['total_debt_cases'])])
        @include('admin.partials.stat-card', ['label' => 'Outstanding Debt', 'value' => $money($data['outstanding_debt']), 'tone' => 'danger'])
        @include('admin.partials.stat-card', ['label' => 'Amount Recovered', 'value' => $money($data['amount_recovered']), 'tone' => 'success'])
        @include('admin.partials.stat-card', ['label' => 'Recovery Rate', 'value' => $pct($data['recovery_rate'])])
    </div>

    <div class="mb-6 grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-5">
        @include('admin.partials.stat-card', ['label' => 'New Businesses', 'value' => $fmt($data['new_businesses'])])
        @include('admin.partials.stat-card', ['label' => 'Payments', 'value' => $fmt($data['payment_count'])])
        @include('admin.partials.stat-card', ['label' => 'Payment Total', 'value' => $money($data['payment_total'])])
        @include('admin.partials.stat-card', ['label' => 'Professional Collection Req.', 'value' => $fmt($data['professional_collection_total'])])
        @include('admin.partials.stat-card', ['label' => 'Subscription MRR', 'value' => $money($data['subscription_mrr']), 'tone' => 'success'])
    </div>

    <div class="mb-6">
        @include('admin.reports.partials.trend-chart', ['trend' => $data['debt_trend'], 'moneyFormat' => true, 'chartTitle' => 'Amount Recovered — Trend'])
    </div>

    <div class="rounded-xl border border-slate-200 bg-white p-5">
        <h3 class="mb-4 text-sm font-semibold text-slate-700">Detailed Reports</h3>
        <div class="grid grid-cols-2 gap-3 sm:grid-cols-3">
            <a href="{{ route('admin.reports.debt-recovery') }}" class="rounded-lg border border-slate-200 px-4 py-3 text-sm font-medium text-slate-700 hover:border-deendoon-teal hover:text-deendoon-teal">Debt &amp; Recovery Report</a>
            <a href="{{ route('admin.reports.debtor-risk') }}" class="rounded-lg border border-slate-200 px-4 py-3 text-sm font-medium text-slate-700 hover:border-deendoon-teal hover:text-deendoon-teal">Debtor Risk Report</a>
            <a href="{{ route('admin.reports.payments') }}" class="rounded-lg border border-slate-200 px-4 py-3 text-sm font-medium text-slate-700 hover:border-deendoon-teal hover:text-deendoon-teal">Payment Report</a>
            <a href="{{ route('admin.reports.professional-collection') }}" class="rounded-lg border border-slate-200 px-4 py-3 text-sm font-medium text-slate-700 hover:border-deendoon-teal hover:text-deendoon-teal">Professional Collection Report</a>
            <a href="{{ route('admin.reports.subscriptions') }}" class="rounded-lg border border-slate-200 px-4 py-3 text-sm font-medium text-slate-700 hover:border-deendoon-teal hover:text-deendoon-teal">Subscription Report</a>
            <a href="{{ route('admin.reports.business-growth') }}" class="rounded-lg border border-slate-200 px-4 py-3 text-sm font-medium text-slate-700 hover:border-deendoon-teal hover:text-deendoon-teal">Business Growth Report</a>
        </div>
    </div>
@endsection
