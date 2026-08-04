import 'calendar_entry.dart';

/// Mirrors `CalendarController::index`'s top-level response shape exactly:
/// `{from, to, entries}`. `from`/`to` echo back the effective date range
/// the backend actually queried (either the caller's `from`/`to` query
/// params, or the current month when omitted).
class CalendarData {
  final String from;
  final String to;
  final List<CalendarEntry> entries;

  const CalendarData({required this.from, required this.to, required this.entries});

  factory CalendarData.fromJson(Map<String, dynamic> json) => CalendarData(
        from: json['from'] as String,
        to: json['to'] as String,
        entries: (json['entries'] as List<dynamic>)
            .map((e) => CalendarEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
