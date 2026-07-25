<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <style>
        body { font-family: sans-serif; font-size: 13px; color: #222; }
        table { width: 100%; border-collapse: collapse; margin-top: 10px; }
        td, th { padding: 6px 4px; text-align: left; }
        th { border-bottom: 1px solid #999; }
        .label { color: #555; width: 40%; }
    </style>
</head>
<body>
    @include('documents.partials.branding')

    <h2 style="font-size: 16px;">Receipt {{ $receipt->reference_number }}</h2>
    <div style="font-size: 11px; color: #555; margin-bottom: 10px;">
        Generated {{ $receipt->generated_at->toDayDateTimeString() }}
    </div>

    <table>
        <tr><td class="label">Customer</td><td>{{ $customer->name }}</td></tr>
        <tr><td class="label">Debt Reference</td><td>{{ $debt->reference_number }}</td></tr>
        <tr><td class="label">Amount Paid</td><td>{{ $payment->amount }}</td></tr>
        <tr><td class="label">Payment Date</td><td>{{ $payment->payment_date->toDateString() }}</td></tr>
        <tr><td class="label">Payment Method</td><td>{{ $payment->payment_method ?? '—' }}</td></tr>
        <tr><td class="label">Reference Notes</td><td>{{ $payment->reference_notes ?? '—' }}</td></tr>
    </table>
</body>
</html>
