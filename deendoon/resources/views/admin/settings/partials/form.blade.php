@if ($errors->any())
    <div class="mb-4 rounded-lg border border-deendoon-danger/30 bg-deendoon-danger/10 px-4 py-3 text-sm text-red-700">
        <ul class="list-inside list-disc">
            @foreach ($errors->all() as $error)
                <li>{{ $error }}</li>
            @endforeach
        </ul>
    </div>
@endif

<div class="mb-4">
    <label for="name" class="mb-1 block text-sm font-medium text-slate-700">Plan Name</label>
    <input type="text" id="name" name="name" maxlength="50" value="{{ old('name', $plan->name ?? '') }}"
           class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm">
</div>

<div class="mb-4">
    <label for="monthly_price" class="mb-1 block text-sm font-medium text-slate-700">Monthly Price</label>
    <input type="number" step="0.01" min="0" id="monthly_price" name="monthly_price" value="{{ old('monthly_price', $plan->monthly_price ?? '') }}"
           class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm">
</div>

<div class="mb-4">
    <label for="customer_limit" class="mb-1 block text-sm font-medium text-slate-700">Customer Limit</label>
    <input type="number" min="1" id="customer_limit" name="customer_limit" value="{{ old('customer_limit', $plan->customer_limit ?? '') }}"
           placeholder="Leave blank for unlimited"
           class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm">
</div>

<div class="mb-4">
    <label for="storage_limit" class="mb-1 block text-sm font-medium text-slate-700">Storage Limit (GB)</label>
    <input type="number" min="1" id="storage_limit" name="storage_limit" value="{{ old('storage_limit', $plan->storage_limit ?? '') }}"
           class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm">
</div>

<div class="mb-4">
    <label class="flex items-center gap-2 text-sm text-slate-700">
        <input type="checkbox" name="analytics_enabled" value="1" @checked(old('analytics_enabled', $plan->analytics_enabled ?? true))>
        Analytics Enabled
    </label>
</div>
