import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/auth_interceptor.dart';
import 'package:mobile/features/auth/data/auth_repository.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';
import 'package:mobile/features/auth/domain/user.dart';
import 'package:mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

const _user = User(id: '1', name: 'Test User', email: 'test@example.com');

final _interceptorProvider = Provider<AuthInterceptor>((ref) => AuthInterceptor(ref));

/// Captures the [RequestOptions] passed to `next()` without reaching into
/// `_BaseHandler`'s `@protected future` from outside the dio package.
class _CapturingRequestHandler extends RequestInterceptorHandler {
  RequestOptions? captured;

  @override
  void next(RequestOptions requestOptions) {
    captured = requestOptions;
    super.next(requestOptions);
  }
}

/// Deliberately does NOT call `super.next()` — that would complete this
/// handler's internal completer *with an error*, which nothing in an
/// isolated unit test ever consumes, surfacing as an unhandled async error.
/// These tests only care about the interceptor's side effects (forceLogout).
class _CapturingErrorHandler extends ErrorInterceptorHandler {
  DioException? captured;

  @override
  void next(DioException err) {
    captured = err;
  }
}

void main() {
  late _MockAuthRepository mockRepository;
  late ProviderContainer container;
  late AuthInterceptor interceptor;

  setUp(() {
    mockRepository = _MockAuthRepository();
    when(() => mockRepository.logout()).thenAnswer((_) async {});

    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(mockRepository)],
    );
    addTearDown(container.dispose);

    interceptor = container.read(_interceptorProvider);
  });

  RequestOptions optionsWithAuthHeader() => RequestOptions(
        path: '/reminders',
        headers: {'Authorization': 'Bearer old-token'},
      );

  group('onRequest', () {
    test('attaches the bearer token when authenticated', () {
      container.read(authProvider.notifier).state =
          const Authenticated(user: _user, token: 'live-token');

      final options = RequestOptions(path: '/customers');
      final handler = _CapturingRequestHandler();

      interceptor.onRequest(options, handler);

      expect(handler.captured?.headers['Authorization'], 'Bearer live-token');
    });

    test('omits the header when unauthenticated', () {
      container.read(authProvider.notifier).state = const Unauthenticated();

      final options = RequestOptions(path: '/login');
      final handler = _CapturingRequestHandler();

      interceptor.onRequest(options, handler);

      expect(handler.captured?.headers.containsKey('Authorization'), isFalse);
    });
  });

  group('onError', () {
    test('forces logout on a 401 for a request that carried a token while authenticated', () async {
      container.read(authProvider.notifier).state =
          const Authenticated(user: _user, token: 'live-token');

      final error = DioException(
        requestOptions: optionsWithAuthHeader(),
        response: Response(requestOptions: optionsWithAuthHeader(), statusCode: 401),
        type: DioExceptionType.badResponse,
      );

      interceptor.onError(error, _CapturingErrorHandler());
      // forceLogout() is fire-and-forget from onError (never awaited by the
      // interceptor itself), so let its microtasks drain before asserting.
      await Future<void>.delayed(Duration.zero);

      verify(() => mockRepository.logout()).called(1);
      expect(container.read(authProvider), isA<Unauthenticated>());
    });

    test('does not force logout on a 401 from an unauthenticated request (e.g. bad login)', () async {
      container.read(authProvider.notifier).state = const Unauthenticated();

      final error = DioException(
        requestOptions: RequestOptions(path: '/login'),
        response: Response(requestOptions: RequestOptions(path: '/login'), statusCode: 401),
        type: DioExceptionType.badResponse,
      );

      interceptor.onError(error, _CapturingErrorHandler());
      await Future<void>.delayed(Duration.zero);

      verifyNever(() => mockRepository.logout());
      expect(container.read(authProvider), isA<Unauthenticated>());
    });

    test('does not force logout on a non-401 error even when authenticated', () async {
      container.read(authProvider.notifier).state =
          const Authenticated(user: _user, token: 'live-token');

      final error = DioException(
        requestOptions: optionsWithAuthHeader(),
        response: Response(requestOptions: optionsWithAuthHeader(), statusCode: 500),
        type: DioExceptionType.badResponse,
      );

      interceptor.onError(error, _CapturingErrorHandler());
      await Future<void>.delayed(Duration.zero);

      verifyNever(() => mockRepository.logout());
      expect(container.read(authProvider), isA<Authenticated>());
    });
  });
}
