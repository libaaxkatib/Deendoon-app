<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <style>
        body { font-family: sans-serif; font-size: 13px; color: #222; }
        table { width: 100%; border-collapse: collapse; margin: 10px 0; }
        td, th { padding: 6px 4px; text-align: left; }
        .label { color: #555; width: 40%; }
        .body-text { margin: 16px 0; line-height: 1.5; }
    </style>
</head>
<body>
    @include('documents.partials.branding')

    <h2 style="font-size: 16px;">{{ $templateLabel }} — {{ $demandLetter->reference_number }}</h2>
    <div style="font-size: 11px; color: #555; margin-bottom: 10px;">
        Generated {{ $demandLetter->generated_at->toDayDateTimeString() }}
    </div>

    <p>Dear {{ $customer->name }},</p>

    {{--
        Placeholder body text only — Legal Notice wording (and, by the same
        reasoning, the other three templates') is explicitly out of SRS
        scope (Module 8 Open Item 7: "would typically require legal review
        outside SRS scope"). Not final content; functional placeholder
        pending that review.
    --}}
    <div class="body-text">{{ $bodyText }}</div>

    <table>
        <tr><td class="label">Debt Reference</td><td>{{ $debt->reference_number }}</td></tr>
        <tr><td class="label">Amount</td><td>{{ $debt->amount }}</td></tr>
        <tr><td class="label">Remaining Balance</td><td>{{ $debt->remaining_balance }}</td></tr>
        <tr><td class="label">Due Date</td><td>{{ $debt->due_date->toDateString() }}</td></tr>
    </table>
</body>
</html>
