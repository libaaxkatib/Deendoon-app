<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <style>
        body { font-family: sans-serif; font-size: 11px; color: #222; }
        h2 { font-size: 15px; }
        table { width: 100%; border-collapse: collapse; margin-top: 10px; }
        th, td { padding: 5px 4px; text-align: left; border-bottom: 1px solid #ddd; }
        th { border-bottom: 2px solid #333; }
    </style>
</head>
<body>
    <h2>{{ $title }}</h2>
    <div style="font-size: 10px; color: #555; margin-bottom: 10px;">Generated {{ now()->toDayDateTimeString() }}</div>

    <table>
        <tr>
            @foreach ($headings as $heading)
                <th>{{ $heading }}</th>
            @endforeach
        </tr>
        @forelse ($rows as $row)
            <tr>
                @foreach ($row as $value)
                    <td>{{ $value }}</td>
                @endforeach
            </tr>
        @empty
            <tr><td colspan="{{ count($headings) }}">No records match these filters.</td></tr>
        @endforelse
    </table>

    @if (! empty($autoPrint))
        <script>window.onload = () => window.print();</script>
    @endif
</body>
</html>
