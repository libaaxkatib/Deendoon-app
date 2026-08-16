import 'package:dio/dio.dart';

/// Wraps a failed API call using this backend's standard error envelope
/// (`App\Traits\ApiResponse::errorResponse`): `{success:false, message, data:null, errors}`.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? fieldErrors;

  const ApiException({
    required this.message,
    this.statusCode,
    this.fieldErrors,
  });

  factory ApiException.fromDioException(DioException e) {
    final statusCode = e.response?.statusCode;
    final body = e.response?.data;

    if (body is Map<String, dynamic>) {
      final message = body['message'];
      final errors = body['errors'];
      return ApiException(
        message: message is String && message.isNotEmpty
            ? message
            : 'Something went wrong. Please try again.',
        statusCode: statusCode,
        fieldErrors: errors is Map<String, dynamic> ? errors : null,
      );
    }

    return ApiException(
      message: _messageForType(e.type),
      statusCode: statusCode,
    );
  }

  /// Mobile Fix #6: `receiveTimeout`/`sendTimeout` are a distinct failure
  /// mode from `connectionError`/`connectionTimeout` — the connection to
  /// the backend (hosted on Render's free tier) succeeded, but the
  /// response didn't arrive in time, which is exactly what a cold-start
  /// wake-up looks like. Worded to tell the user to simply wait and
  /// retry, rather than implying a real connectivity failure.
  static String _messageForType(DioExceptionType type) {
    switch (type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
        return 'Could not reach the server. Check your connection and try again.';
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'The server is taking longer than usual to respond — it may be starting up. Please try again in a moment.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  /// Combines the generic top-level `message` with any field-specific
  /// validation errors from the `errors` map (Laravel keeps them
  /// separate: `message` is a generic "The given data was invalid.",
  /// `errors` has the actual per-field reasons like "The email has
  /// already been taken."). Auth forms show a single error `Text`
  /// widget rather than per-field inline errors, so this is what they
  /// display instead of the uninformative generic message alone.
  String get detailedMessage {
    if (fieldErrors == null || fieldErrors!.isEmpty) return message;
    final details = fieldErrors!.values
        .expand((v) => v is List ? v.map((e) => e.toString()) : [v.toString()])
        .join('\n');
    return details.isEmpty ? message : details;
  }

  @override
  String toString() => message;

  /// The joined backend validation message(s) for a single [key] within a
  /// `fieldErrors`-shaped map (Laravel returns one or more strings per
  /// field), or null if there is none. Shared by every form that maps
  /// `errors` onto individual `TextFormField`/`PasswordField` widgets
  /// instead of the combined [detailedMessage] block (Mobile Fix #10) —
  /// takes the raw map rather than requiring an [ApiException] instance so
  /// it also works with [fieldErrors] carried on `AuthError` (see
  /// `auth_state.dart`).
  static String? fieldErrorFor(Map<String, dynamic>? fieldErrors, String key) {
    final value = fieldErrors?[key];
    if (value == null) return null;
    final messages =
        (value is List ? value.map((e) => e.toString()) : [value.toString()])
            .where((m) => m.isNotEmpty);
    if (messages.isEmpty) return null;
    return messages.join('\n');
  }

  /// Laravel's `confirmed` rule always attaches a "confirmation does not
  /// match" failure to the base field key (e.g. `password`), never to a
  /// separate `password_confirmation` key — and, since Laravel doesn't
  /// stop on first failure, that can arrive alongside an unrelated rule's
  /// message (e.g. minimum length) under the very same key. Splits the
  /// two so a form with a value field and its confirmation field can show
  /// the mismatch message on both (Mobile Fix #10, Decision 1) and any
  /// other rule's message on the value field only. Detected by matching
  /// Laravel's own stable default wording for the `confirmed` rule
  /// ("...confirmation does not match.") rather than guessing.
  static ({String? confirmationMismatch, String? other})
  splitConfirmedFieldError(Map<String, dynamic>? fieldErrors, String key) {
    final value = fieldErrors?[key];
    if (value == null) return (confirmationMismatch: null, other: null);
    final messages =
        (value is List ? value.map((e) => e.toString()) : [value.toString()])
            .where((m) => m.isNotEmpty);
    final mismatch = messages.where(
      (m) => m.toLowerCase().contains('confirmation'),
    );
    final other = messages.where(
      (m) => !m.toLowerCase().contains('confirmation'),
    );
    return (
      confirmationMismatch: mismatch.isEmpty ? null : mismatch.join('\n'),
      other: other.isEmpty ? null : other.join('\n'),
    );
  }
}
