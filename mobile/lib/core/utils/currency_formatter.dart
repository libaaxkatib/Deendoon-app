import 'package:intl/intl.dart';

/// Shared monetary display formatting. The backend returns money as plain
/// decimal strings (e.g. `"4967.40"`) everywhere — no existing formatter
/// for this exists anywhere in the app yet, so this is it. Adds a
/// thousand separator for readability (`4,967.40`) without touching the
/// underlying value; never used for calculations, only display.
final _amountFormat = NumberFormat('#,##0.00');

/// Parses a raw decimal string (as returned by the backend) and formats
/// it. Falls back to the original string if it isn't parseable, rather
/// than crashing the screen on unexpected input.
String formatFriendlyAmount(String rawAmount) {
  final parsed = double.tryParse(rawAmount);
  return parsed == null ? rawAmount : _amountFormat.format(parsed);
}
