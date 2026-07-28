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

  @override
  String toString() => message;
}
