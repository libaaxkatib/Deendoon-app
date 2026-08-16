{{-- Shared date preset/custom range + business + report-specific filter form.
     $filterAction: form action URL. $filters: current resolved filter values.
     $periods/$tenants: always provided. $statuses/$riskLevels/$plans/
     $paymentMethods/$stages: optional, only rendered when passed in. --}}
<form method="GET" action="{{ $filterAction }}" class="mb-6 flex flex-wrap items-end gap-3 rounded-xl border border-slate-200 bg-white p-4">
    <div>
        <label class="mb-1 block text-xs font-medium text-slate-500">Date Range</label>
        <select name="period" onchange="document.getElementById('custom-range-{{ $reportSlug }}').classList.toggle('hidden', this.value !== 'custom')"
                class="rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-deendoon-teal focus:outline-none focus:ring-1 focus:ring-deendoon-teal">
            @foreach ($periods as $value => $label)
                <option value="{{ $value }}" @selected($filters['period'] === $value)>{{ $label }}</option>
            @endforeach
        </select>
    </div>

    <div id="custom-range-{{ $reportSlug }}" class="flex items-end gap-2 {{ ($filters['period'] ?? null) === 'custom' ? '' : 'hidden' }}">
        <div>
            <label class="mb-1 block text-xs font-medium text-slate-500">From</label>
            <input type="date" name="date_from" value="{{ $filters['date_from'] }}"
                   class="rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-deendoon-teal focus:outline-none focus:ring-1 focus:ring-deendoon-teal">
        </div>
        <div>
            <label class="mb-1 block text-xs font-medium text-slate-500">To</label>
            <input type="date" name="date_to" value="{{ $filters['date_to'] }}"
                   class="rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-deendoon-teal focus:outline-none focus:ring-1 focus:ring-deendoon-teal">
        </div>
    </div>

    <div>
        <label class="mb-1 block text-xs font-medium text-slate-500">Business</label>
        <select name="tenant_id" class="rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-deendoon-teal focus:outline-none focus:ring-1 focus:ring-deendoon-teal">
            <option value="">All Businesses</option>
            @foreach ($tenants as $tenant)
                <option value="{{ $tenant->id }}" @selected($filters['tenant_id'] === $tenant->id)>{{ $tenant->business_name }}</option>
            @endforeach
        </select>
    </div>

    @isset($statuses)
        <div>
            <label class="mb-1 block text-xs font-medium text-slate-500">Status</label>
            <select name="status" class="rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-deendoon-teal focus:outline-none focus:ring-1 focus:ring-deendoon-teal">
                <option value="">All Statuses</option>
                @foreach ($statuses as $value => $label)
                    <option value="{{ $value }}" @selected($filters['status'] === $value)>{{ $label }}</option>
                @endforeach
            </select>
        </div>
    @endisset

    @isset($riskLevels)
        <div>
            <label class="mb-1 block text-xs font-medium text-slate-500">Risk Level</label>
            <select name="risk_level" class="rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-deendoon-teal focus:outline-none focus:ring-1 focus:ring-deendoon-teal">
                <option value="">All Risk Levels</option>
                @foreach ($riskLevels as $value => $label)
                    <option value="{{ $value }}" @selected($filters['risk_level'] === $value)>{{ $label }}</option>
                @endforeach
            </select>
        </div>
    @endisset

    @isset($stages)
        <div>
            <label class="mb-1 block text-xs font-medium text-slate-500">Recovery Stage</label>
            <select name="recovery_stage" class="rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-deendoon-teal focus:outline-none focus:ring-1 focus:ring-deendoon-teal">
                <option value="">All Stages</option>
                @foreach ($stages as $value => $label)
                    <option value="{{ $value }}" @selected($filters['recovery_stage'] === $value)>{{ $label }}</option>
                @endforeach
            </select>
        </div>
    @endisset

    @isset($paymentMethods)
        <div>
            <label class="mb-1 block text-xs font-medium text-slate-500">Payment Method</label>
            <select name="payment_method" class="rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-deendoon-teal focus:outline-none focus:ring-1 focus:ring-deendoon-teal">
                <option value="">All Methods</option>
                @foreach ($paymentMethods as $method)
                    <option value="{{ $method }}" @selected($filters['payment_method'] === $method)>{{ $method }}</option>
                @endforeach
            </select>
        </div>
    @endisset

    @isset($plans)
        <div>
            <label class="mb-1 block text-xs font-medium text-slate-500">Plan</label>
            <select name="plan_id" class="rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-deendoon-teal focus:outline-none focus:ring-1 focus:ring-deendoon-teal">
                <option value="">All Plans</option>
                @foreach ($plans as $plan)
                    <option value="{{ $plan->id }}" @selected($filters['plan_id'] === $plan->id)>{{ $plan->name }}</option>
                @endforeach
            </select>
        </div>
    @endisset

    <button type="submit" class="rounded-lg bg-deendoon-teal px-4 py-2 text-sm font-semibold text-white hover:bg-deendoon-teal-dark">
        Apply Filters
    </button>
    <a href="{{ $filterAction }}" class="rounded-lg px-4 py-2 text-sm font-medium text-slate-500 hover:text-slate-700">Reset</a>
</form>
