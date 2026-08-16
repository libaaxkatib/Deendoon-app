{{-- $trend: array<{label,value}>. $moneyFormat: bool, formats the tooltip/axis as currency. --}}
<div class="rounded-xl border border-slate-200 bg-white p-5">
    <h3 class="mb-4 text-sm font-semibold text-slate-700">{{ $chartTitle ?? 'Trend' }}</h3>
    @if (empty($trend))
        <p class="text-sm text-slate-400">Select a date range to see the trend.</p>
    @else
        @php $maxVal = max(1, collect($trend)->max('value')); @endphp
        <div class="flex h-40 items-end gap-1 overflow-x-auto">
            @foreach ($trend as $point)
                <div class="flex min-w-[1.25rem] flex-1 flex-col items-center gap-1">
                    <div class="flex h-32 w-full items-end justify-center">
                        <div class="w-2.5 rounded-t bg-deendoon-teal/70"
                             style="height: {{ max(2, ($point['value'] / $maxVal) * 100) }}%"
                             title="{{ $point['label'] }}: {{ ($moneyFormat ?? false) ? '$'.number_format($point['value'], 0) : number_format($point['value']) }}"></div>
                    </div>
                    <span class="whitespace-nowrap text-[10px] text-slate-400">{{ $point['label'] }}</span>
                </div>
            @endforeach
        </div>
    @endif
</div>
