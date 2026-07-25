<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <style>
        body { font-family: sans-serif; font-size: 13px; color: #222; }
        table { width: 100%; border-collapse: collapse; margin: 10px 0; }
        td, th { padding: 6px 4px; text-align: left; }
        th { border-bottom: 1px solid #999; }
        .label { color: #555; width: 40%; }
        h3 { font-size: 13px; margin-top: 20px; }
    </style>
</head>
<body>
    @include('documents.partials.branding')

    <h2 style="font-size: 16px;">Statement of Account {{ $statement->reference_number }}</h2>
    <div style="font-size: 11px; color: #555; margin-bottom: 10px;">
        Generated {{ $statement->generated_at->toDayDateTimeString() }}
    </div>

    <table>
        <tr><td class="label">Customer</td><td>{{ $customer->name }}</td></tr>
        <tr><td class="label">Credit Limit</td><td>{{ $customer->credit_limit }}</td></tr>
        <tr><td class="label">Outstanding Balance</td><td>{{ $customer->outstanding_balance }}</td></tr>
    </table>

    <h3>Debts</h3>
    <table>
        <tr><th>Reference</th><th>Amount</th><th>Remaining Balance</th><th>Status</th><th>Due Date</th></tr>
        @forelse ($debts as $debt)
            <tr>
                <td>{{ $debt->reference_number }}</td>
                <td>{{ $debt->amount }}</td>
                <td>{{ $debt->remaining_balance }}</td>
                <td>{{ $debt->debt_status }}</td>
                <td>{{ $debt->due_date->toDateString() }}</td>
            </tr>
        @empty
            <tr><td colspan="5">No debts on record.</td></tr>
        @endforelse
    </table>

    <h3>Payments</h3>
    <table>
        <tr><th>Debt Reference</th><th>Amount</th><th>Date</th></tr>
        @forelse ($payments as $payment)
            <tr>
                <td>{{ $payment->debt->reference_number }}</td>
                <td>{{ $payment->amount }}</td>
                <td>{{ $payment->payment_date->toDateString() }}</td>
            </tr>
        @empty
            <tr><td colspan="3">No payments on record.</td></tr>
        @endforelse
    </table>
</body>
</html>
