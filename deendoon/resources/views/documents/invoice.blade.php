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

    <h2 style="font-size: 16px;">Invoice {{ $invoice->reference_number }}</h2>
    <div style="font-size: 11px; color: #555; margin-bottom: 10px;">
        Generated {{ $invoice->generated_at->toDayDateTimeString() }}
    </div>

    <table>
        <tr><td class="label">Customer</td><td>{{ $customer->name }}</td></tr>
        <tr><td class="label">Debt Reference</td><td>{{ $debt->reference_number }}</td></tr>
        <tr><td class="label">Amount Billed</td><td>{{ $debt->amount }}</td></tr>
        <tr><td class="label">Due Date</td><td>{{ $debt->due_date->toDateString() }}</td></tr>
        <tr><td class="label">Remaining Balance</td><td>{{ $debt->remaining_balance }}</td></tr>
    </table>
</body>
</html>
