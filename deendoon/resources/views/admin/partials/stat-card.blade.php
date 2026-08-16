@php
    $toneClasses = [
        'success' => 'text-deendoon-success',
        'warning' => 'text-deendoon-warning',
        'danger' => 'text-deendoon-danger',
    ];
    $valueClass = $toneClasses[$tone ?? ''] ?? 'text-slate-800';
@endphp
<div class="rounded-xl border {{ ($highlight ?? false) ? 'border-deendoon-teal/40 bg-deendoon-teal/5' : 'border-slate-200 bg-white' }} p-4">
    <p class="text-xs font-medium text-slate-500">
        {{ $label }}
        @if (! empty($sub))
            <span class="text-slate-400">· {{ $sub }}</span>
        @endif
    </p>
    @if (! empty($pending))
        <p class="mt-1 text-sm font-medium text-slate-400" title="Backend support not built yet">Pending backend support</p>
    @else
        <p class="mt-1 text-2xl font-bold {{ $valueClass }}">{{ $value }}</p>
    @endif
</div>
