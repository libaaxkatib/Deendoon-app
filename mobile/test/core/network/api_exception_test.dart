import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_exception.dart';

DioException _dioException({
  required DioExceptionType type,
  Response<dynamic>? response,
}) {
  return DioException(
    requestOptions: RequestOptions(path: '/customers'),
    type: type,
    response: response,
  );
}

void main() {
  group('ApiException.fromDioException', () {
    test('uses the backend message when the response body has one', () {
      final exception = ApiException.fromDioException(
        _dioException(
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/customers'),
            statusCode: 422,
            data: {
              'success': false,
              'message': 'The given data was invalid.',
              'data': null,
              'errors': {
                'name': ['The name field is required.'],
              },
            },
          ),
        ),
      );

      expect(exception.message, 'The given data was invalid.');
      expect(exception.statusCode, 422);
      expect(exception.fieldErrors, {
        'name': ['The name field is required.'],
      });
    });

    test(
      'connectionError maps to the unchanged "could not reach the server" message',
      () {
        final exception = ApiException.fromDioException(
          _dioException(type: DioExceptionType.connectionError),
        );

        expect(
          exception.message,
          'Could not reach the server. Check your connection and try again.',
        );
      },
    );

    test(
      'connectionTimeout maps to the unchanged "could not reach the server" message',
      () {
        final exception = ApiException.fromDioException(
          _dioException(type: DioExceptionType.connectionTimeout),
        );

        expect(
          exception.message,
          'Could not reach the server. Check your connection and try again.',
        );
      },
    );

    test(
      'receiveTimeout maps to the new server-waking-up message (Mobile Fix #6)',
      () {
        final exception = ApiException.fromDioException(
          _dioException(type: DioExceptionType.receiveTimeout),
        );

        expect(
          exception.message,
          'The server is taking longer than usual to respond — it may be starting up. Please try again in a moment.',
        );
      },
    );

    test(
      'sendTimeout maps to the new server-waking-up message (Mobile Fix #6)',
      () {
        final exception = ApiException.fromDioException(
          _dioException(type: DioExceptionType.sendTimeout),
        );

        expect(
          exception.message,
          'The server is taking longer than usual to respond — it may be starting up. Please try again in a moment.',
        );
      },
    );

    test('an unmapped type falls back to the generic message', () {
      final exception = ApiException.fromDioException(
        _dioException(type: DioExceptionType.cancel),
      );

      expect(exception.message, 'Something went wrong. Please try again.');
    });
  });

  group('ApiException.fieldErrorFor', () {
    test('joins multiple messages for the same key with a newline', () {
      final result = ApiException.fieldErrorFor({
        'email': ['The email has already been taken.', 'The email is invalid.'],
      }, 'email');

      expect(
        result,
        'The email has already been taken.\nThe email is invalid.',
      );
    });

    test('returns a single string value unwrapped', () {
      final result = ApiException.fieldErrorFor({
        'email': 'A single string message.',
      }, 'email');

      expect(result, 'A single string message.');
    });

    test('returns null when the key is absent', () {
      final result = ApiException.fieldErrorFor({
        'email': ['taken'],
      }, 'phone');

      expect(result, isNull);
    });

    test('returns null when fieldErrors itself is null', () {
      expect(ApiException.fieldErrorFor(null, 'email'), isNull);
    });
  });

  group('ApiException.splitConfirmedFieldError', () {
    test(
      'routes a confirmation-mismatch message to confirmationMismatch only',
      () {
        final result = ApiException.splitConfirmedFieldError({
          'password': ['The password confirmation does not match.'],
        }, 'password');

        expect(
          result.confirmationMismatch,
          'The password confirmation does not match.',
        );
        expect(result.other, isNull);
      },
    );

    test('routes a length/strength message to other only', () {
      final result = ApiException.splitConfirmedFieldError({
        'password': ['The password field must be at least 12 characters.'],
      }, 'password');

      expect(
        result.other,
        'The password field must be at least 12 characters.',
      );
      expect(result.confirmationMismatch, isNull);
    });

    test('splits both when Laravel returns both failures for the same key', () {
      final result = ApiException.splitConfirmedFieldError({
        'password': [
          'The password confirmation does not match.',
          'The password field must be at least 12 characters.',
        ],
      }, 'password');

      expect(
        result.confirmationMismatch,
        'The password confirmation does not match.',
      );
      expect(
        result.other,
        'The password field must be at least 12 characters.',
      );
    });

    test('returns both null when the key is absent', () {
      final result = ApiException.splitConfirmedFieldError(null, 'password');

      expect(result.confirmationMismatch, isNull);
      expect(result.other, isNull);
    });
  });
}
