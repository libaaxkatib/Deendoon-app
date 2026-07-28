import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/features/auth/data/auth_repository.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';
import 'package:mobile/features/auth/domain/user.dart';
import 'package:mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

const _user = User(id: '1', name: 'Test User', email: 'test@example.com');

void main() {
  late _MockAuthRepository mockRepository;
  late ProviderContainer container;

  setUp(() {
    mockRepository = _MockAuthRepository();
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(mockRepository)],
    );
    addTearDown(container.dispose);
  });

  group('restoreSession', () {
    test('ends Unauthenticated when nothing is cached', () async {
      when(() => mockRepository.readCachedSession()).thenAnswer((_) async => null);

      await container.read(authProvider.notifier).restoreSession();

      expect(container.read(authProvider), isA<Unauthenticated>());
    });

    test('optimistically restores then ends Authenticated with the rotated token', () async {
      const cached = Authenticated(user: _user, token: 'cached-token');
      const rotated = Authenticated(user: _user, token: 'rotated-token');
      when(() => mockRepository.readCachedSession()).thenAnswer((_) async => cached);
      when(() => mockRepository.validateAndRotate()).thenAnswer((_) async => rotated);

      await container.read(authProvider.notifier).restoreSession();

      final state = container.read(authProvider);
      expect(state, isA<Authenticated>());
      expect((state as Authenticated).token, 'rotated-token');
    });

    test('leaves recovery from a failed validation to the Dio interceptor', () async {
      const cached = Authenticated(user: _user, token: 'cached-token');
      when(() => mockRepository.readCachedSession()).thenAnswer((_) async => cached);
      when(() => mockRepository.validateAndRotate())
          .thenThrow(const ApiException(message: 'Unauthenticated.', statusCode: 401));

      // In the real app the shared Dio instance's AuthInterceptor observes
      // this same 401 and calls forceLogout() itself (see
      // auth_interceptor_test.dart); this isolated notifier test mocks
      // AuthApi out of the picture entirely, so it only needs to confirm
      // the notifier doesn't throw or clobber state on its own.
      await container.read(authProvider.notifier).restoreSession();

      expect(container.read(authProvider), isA<Authenticated>());
    });
  });

  group('login', () {
    test('ends Authenticated on success', () async {
      const authenticated = Authenticated(user: _user, token: 'live-token');
      when(() => mockRepository.login('test@example.com', 'password'))
          .thenAnswer((_) async => authenticated);

      await container.read(authProvider.notifier).login('test@example.com', 'password');

      expect(container.read(authProvider), authenticated);
    });

    test('ends AuthError with the server message on failure', () async {
      when(() => mockRepository.login('test@example.com', 'wrong'))
          .thenThrow(const ApiException(message: 'Invalid credentials', statusCode: 401));

      await container.read(authProvider.notifier).login('test@example.com', 'wrong');

      final state = container.read(authProvider);
      expect(state, isA<AuthError>());
      expect((state as AuthError).message, 'Invalid credentials');
    });
  });

  group('forceLogout', () {
    test('clears the session and ends Unauthenticated', () async {
      when(() => mockRepository.logout()).thenAnswer((_) async {});

      await container.read(authProvider.notifier).forceLogout();

      verify(() => mockRepository.logout()).called(1);
      expect(container.read(authProvider), isA<Unauthenticated>());
    });
  });
}
