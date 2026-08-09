import 'package:intl/intl.dart';

/// Shared user-friendly date/time formatting. The backend returns
/// timestamps as raw ISO 8601 strings (e.g. `2026-08-04T15:23:00.000000Z`)
/// everywhere — this is the one place that turns them into something a
/// user should actually see, so every screen displays dates consistently.
final _friendlyDateTimeFormat = DateFormat('dd MMM yyyy, h:mm a');
final _friendlyDateFormat = DateFormat('dd MMM yyyy');

String formatFriendlyDateTime(DateTime dateTime) => _friendlyDateTimeFormat.format(dateTime.toLocal());

String formatFriendlyDate(DateTime dateTime) => _friendlyDateFormat.format(dateTime.toLocal());

/// Parses a raw ISO 8601 string (as returned by the backend) and formats
/// it. Falls back to the original string if it isn't parseable, rather
/// than crashing the screen on unexpected input.
String formatFriendlyDateTimeFromIso(String iso) {
  final parsed = DateTime.tryParse(iso);
  return parsed == null ? iso : formatFriendlyDateTime(parsed);
}
