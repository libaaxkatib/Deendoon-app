<div class="rounded-lg bg-slate-50 px-3 py-2">
    <p class="text-[11px] font-medium text-slate-500">{{ $label }}</p>
    @if (! empty($pending))
        <p class="text-sm font-semibold text-slate-400" title="Backend support not built yet">Pending</p>
    @else
        <p class="text-sm font-semibold text-slate-800">{{ $value }}</p>
    @endif
</div>
