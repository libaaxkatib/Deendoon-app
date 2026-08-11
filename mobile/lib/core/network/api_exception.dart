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
      message: e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.connectionTimeout
          ? 'Could not reach the server. Check your connection and try again.'
          : 'Something went wrong. Please try again.',
      statusCode: statusCode,
    );
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
}
