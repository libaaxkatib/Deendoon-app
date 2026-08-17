import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/core/storage/biometric_preference_storage.dart';
import 'package:mobile/features/auth/data/auth_repository.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';
import 'package:mobile/features/auth/domain/google_login_result.dart';
import 'package:mobile/features/auth/domain/user.dart';
import 'package:mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:mobile/features/auth/presentation/providers/biometric_lock_provider.dart';
import 'package:mobile/features/customers/data/customer_repository.dart';
import 'package:mobile/features/customers/domain/customer.dart';
import 'package:mobile/features/customers/domain/customer_page.dart';
import 'package:mobile/features/customers/presentation/providers/customer_list_provider.dart';
import 'package:mobile/features/dashboard/data/dashboard_repository.dart';
import 'package:mobile/features/dashboard/domain/business_health.dart';
import 'package:mobile/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockCustomerRepository extends Mock implements CustomerRepository {}

/// Mobile Fix #16: `resetTenantScopedProviders` invalidates 28 keep-alive
/// providers at once. Riverpod eagerly rebuilds a keep-alive (non
/// `.autoDispose`) provider on `invalidate()` even with zero active
/// listeners, so every one of the ~24 providers this test group doesn't
/// care about (reports, subscription, notifications, etc.) also fires a
/// real request through the shared `dioProvider` the instant `login()`/
/// `forceLogout()` runs. Swapping in this fail-fast adapter (instead of
/// mocking two dozen more repositories individually) makes every one of
/// those irrelevant requests reject synchronously, so they can never
/// outlive `scopedContainer` and throw into `addTearDown(dispose)`.
class _FailFastHttpClientAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return Future.error(
      DioException(
        requestOptions: options,
        message: 'Fix #16 test: network disabled',
      ),
    );
  }

  @override
  void close({bool force = false}) {}
}

class _MockDashboardRepository extends Mock implements DashboardRepository {}

const _user = User(id: '1', name: 'Test User', email: 'test@example.com');

const _tenantAUser = User(
  id: '1',
  name: 'Tenant A Owner',
  email: 'a@example.com',
);
const _tenantBUser = User(
  id: '2',
  name: 'Tenant B Owner',
  email: 'b@example.com',
);

const _tenantACustomer = Customer(
  id: '01A',
  name: 'Tenant A Customer',
  phone: '111',
  customerStatus: 'active',
  creditLimit: '0.00',
  outstandingBalance: '0.00',
  remainingCredit: '0.00',
  riskLevel: null,
  creditScore: null,
  creditScoreBand: null,
  archivedAt: null,
);

const _tenantBCustomer = Customer(
  id: '02B',
  name: 'Tenant B Customer',
  phone: '222',
  customerStatus: 'active',
  creditLimit: '0.00',
  outstandingBalance: '0.00',
  remainingCredit: '0.00',
  riskLevel: null,
  creditScore: null,
  creditScoreBand: null,
  archivedAt: null,
);

void main() {
  late _MockAuthRepository mockRepository;
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockRepository = _MockAuthRepository();
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(mockRepository)],
    );
    addTearDown(container.dispose);
  });

  group('restoreSession', () {
    test('ends Unauthenticated when nothing is cached', () async {
      when(
        () => mockRepository.readCachedSession(),
      ).thenAnswer((_) async => null);

      await container.read(authProvider.notifier).restoreSession();

      expect(container.read(authProvider), isA<Unauthenticated>());
    });

    test(
      'optimistically restores then ends Authenticated with the rotated token',
      () async {
        const cached = Authenticated(user: _user, token: 'cached-token');
        const rotated = Authenticated(user: _user, token: 'rotated-token');
        when(
          () => mockRepository.readCachedSession(),
        ).thenAnswer((_) async => cached);
        when(
          () => mockRepository.validateAndRotate(),
        ).thenAnswer((_) async => rotated);

        await container.read(authProvider.notifier).restoreSession();

        final state = container.read(authProvider);
        expect(state, isA<Authenticated>());
        expect((state as Authenticated).token, 'rotated-token');
      },
    );

    test(
      'leaves recovery from a failed validation to the Dio interceptor',
      () async {
        const cached = Authenticated(user: _user, token: 'cached-token');
        when(
          () => mockRepository.readCachedSession(),
        ).thenAnswer((_) async => cached);
        when(() => mockRepository.validateAndRotate()).thenThrow(
          const ApiException(message: 'Unauthenticated.', statusCode: 401),
        );

        // In the real app the shared Dio instance's AuthInterceptor observes
        // this same 401 and calls forceLogout() itself (see
        // auth_interceptor_test.dart); this isolated notifier test mocks
        // AuthApi out of the picture entirely, so it only needs to confirm
        // the notifier doesn't throw or clobber state on its own.
        await container.read(authProvider.notifier).restoreSession();

        expect(container.read(authProvider), isA<Authenticated>());
      },
    );
  });

  group('login', () {
    test('ends Authenticated on success', () async {
      const authenticated = Authenticated(user: _user, token: 'live-token');
      when(
        () => mockRepository.login('test@example.com', 'password'),
      ).thenAnswer((_) async => authenticated);

      await container
          .read(authProvider.notifier)
          .login('test@example.com', 'password');

      expect(container.read(authProvider), authenticated);
    });

    test('ends AuthError with the server message on failure', () async {
      when(() => mockRepository.login('test@example.com', 'wrong')).thenThrow(
        const ApiException(message: 'Invalid credentials', statusCode: 401),
      );

      await container
          .read(authProvider.notifier)
          .login('test@example.com', 'wrong');

      final state = container.read(authProvider);
      expect(state, isA<AuthError>());
      expect((state as AuthError).message, 'Invalid credentials');
    });
  });

  group('googleLogin', () {
    test('ends Authenticated on an existing-account result', () async {
      const authenticated = GoogleLoginAuthenticated(
        user: _user,
        token: 'g-token',
      );
      when(
        () => mockRepository.googleLogin('valid-id-token'),
      ).thenAnswer((_) async => authenticated);

      final result = await container
          .read(authProvider.notifier)
          .googleLogin('valid-id-token');

      expect(result, isA<GoogleLoginAuthenticated>());
      final state = container.read(authProvider);
      expect(state, isA<Authenticated>());
      expect((state as Authenticated).token, 'g-token');
    });

    test(
      'leaves state at Unauthenticated (not AuthError) on a registration-required result',
      () async {
        when(() => mockRepository.googleLogin('new-id-token')).thenAnswer(
          (_) async => const GoogleLoginRegistrationRequired(
            email: 'new@example.com',
          ),
        );

        final result = await container
            .read(authProvider.notifier)
            .googleLogin('new-id-token');

        expect(result, isA<GoogleLoginRegistrationRequired>());
        expect(container.read(authProvider), isA<Unauthenticated>());
      },
    );

    test(
      'rethrows ApiException (e.g. invalid token, email collision) and resets state to Unauthenticated',
      () async {
        when(() => mockRepository.googleLogin('bad-token')).thenThrow(
          const ApiException(
            message: 'Invalid or expired Google credential.',
            statusCode: 401,
          ),
        );

        await expectLater(
          () => container.read(authProvider.notifier).googleLogin('bad-token'),
          throwsA(isA<ApiException>()),
        );
        expect(container.read(authProvider), isA<Unauthenticated>());
      },
    );

    test('unlocks a pending biometric lock on an existing-account result', () async {
      container.read(biometricLockProvider.notifier).lock();
      const authenticated = GoogleLoginAuthenticated(
        user: _user,
        token: 'g-token',
      );
      when(
        () => mockRepository.googleLogin('valid-id-token'),
      ).thenAnswer((_) async => authenticated);

      await container
          .read(authProvider.notifier)
          .googleLogin('valid-id-token');

      expect(container.read(biometricLockProvider), isFalse);
    });
  });

  group('completeGoogleRegistration', () {
    test('ends Authenticated on success', () async {
      const authenticated = Authenticated(user: _user, token: 'new-account-token');
      when(
        () => mockRepository.googleRegister(
          idToken: 'valid-id-token',
          businessName: 'Acme Traders',
          phone: null,
        ),
      ).thenAnswer((_) async => authenticated);

      await container.read(authProvider.notifier).completeGoogleRegistration(
        idToken: 'valid-id-token',
        businessName: 'Acme Traders',
      );

      expect(container.read(authProvider), authenticated);
    });

    test('ends AuthError with the server message on failure', () async {
      when(
        () => mockRepository.googleRegister(
          idToken: 'valid-id-token',
          businessName: 'Acme Traders',
          phone: null,
        ),
      ).thenThrow(
        const ApiException(
          message: 'An account for this Google identity already exists.',
          statusCode: 409,
        ),
      );

      await container.read(authProvider.notifier).completeGoogleRegistration(
        idToken: 'valid-id-token',
        businessName: 'Acme Traders',
      );

      final state = container.read(authProvider);
      expect(state, isA<AuthError>());
      expect(
        (state as AuthError).message,
        'An account for this Google identity already exists.',
      );
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

  group('Mobile Fix #17: biometric lock at session boundaries', () {
    test(
      'restoreSession() locks a restored session when biometric login is enabled',
      () async {
        await const BiometricPreferenceStorage().saveEnabled(true);
        const cached = Authenticated(user: _user, token: 'cached-token');
        when(
          () => mockRepository.readCachedSession(),
        ).thenAnswer((_) async => cached);
        when(
          () => mockRepository.validateAndRotate(),
        ).thenAnswer((_) async => cached);

        await container.read(authProvider.notifier).restoreSession();

        expect(container.read(biometricLockProvider), isTrue);
      },
    );

    test(
      'restoreSession() does not lock when biometric login is disabled (the default)',
      () async {
        const cached = Authenticated(user: _user, token: 'cached-token');
        when(
          () => mockRepository.readCachedSession(),
        ).thenAnswer((_) async => cached);
        when(
          () => mockRepository.validateAndRotate(),
        ).thenAnswer((_) async => cached);

        await container.read(authProvider.notifier).restoreSession();

        expect(container.read(biometricLockProvider), isFalse);
      },
    );

    test(
      'restoreSession() does not lock when nothing is cached, even if biometric login is enabled',
      () async {
        await const BiometricPreferenceStorage().saveEnabled(true);
        when(
          () => mockRepository.readCachedSession(),
        ).thenAnswer((_) async => null);

        await container.read(authProvider.notifier).restoreSession();

        expect(container.read(biometricLockProvider), isFalse);
      },
    );

    test(
      'login() unlocks a pending biometric lock — the "Use Password Instead" '
      'fallback resolves through this exact path',
      () async {
        container.read(biometricLockProvider.notifier).lock();
        const authenticated = Authenticated(user: _user, token: 'live-token');
        when(
          () => mockRepository.login('test@example.com', 'password'),
        ).thenAnswer((_) async => authenticated);

        await container
            .read(authProvider.notifier)
            .login('test@example.com', 'password');

        expect(container.read(biometricLockProvider), isFalse);
      },
    );

    test('forceLogout() clears the biometric preference so Tenant B does not '
        'inherit Tenant A\'s biometric setting on the same device', () async {
      await const BiometricPreferenceStorage().saveEnabled(true);
      when(() => mockRepository.logout()).thenAnswer((_) async {});

      await container.read(authProvider.notifier).forceLogout();

      expect(await const BiometricPreferenceStorage().readEnabled(), isFalse);

      // Tenant B's own restoreSession() must not find biometric login
      // enabled just because Tenant A had turned it on.
      const tenantBSession = Authenticated(
        user: _tenantBUser,
        token: 'tenant-b-token',
      );
      when(
        () => mockRepository.readCachedSession(),
      ).thenAnswer((_) async => tenantBSession);
      when(
        () => mockRepository.validateAndRotate(),
      ).thenAnswer((_) async => tenantBSession);

      await container.read(authProvider.notifier).restoreSession();

      expect(container.read(biometricLockProvider), isFalse);
    });

    test('closeAccount() clears the biometric preference', () async {
      await const BiometricPreferenceStorage().saveEnabled(true);
      when(
        () => mockRepository.closeAccount(password: 'correct-password'),
      ).thenAnswer((_) async {});

      await container
          .read(authProvider.notifier)
          .closeAccount('correct-password');

      expect(await const BiometricPreferenceStorage().readEnabled(), isFalse);
    });
  });

  group('Mobile Fix #16: tenant-scoped provider reset at session boundaries', () {
    late _MockCustomerRepository mockCustomerRepository;
    late _MockDashboardRepository mockDashboardRepository;
    late ProviderContainer scopedContainer;

    setUp(() {
      mockCustomerRepository = _MockCustomerRepository();
      mockDashboardRepository = _MockDashboardRepository();
      scopedContainer = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepository),
          customerRepositoryProvider.overrideWithValue(mockCustomerRepository),
          dashboardRepositoryProvider.overrideWithValue(
            mockDashboardRepository,
          ),
          dioProvider.overrideWithValue(
            Dio()..httpClientAdapter = _FailFastHttpClientAdapter(),
          ),
        ],
      );
      addTearDown(scopedContainer.dispose);
    });

    test(
      'Tenant B logging in after Tenant A logs out gets a genuine fresh fetch, '
      'never Tenant A\'s cached customerListProvider/businessHealthProvider data',
      () async {
        when(
          () => mockRepository.login('a@example.com', 'password'),
        ).thenAnswer(
          (_) async =>
              const Authenticated(user: _tenantAUser, token: 'token-a'),
        );
        await scopedContainer
            .read(authProvider.notifier)
            .login('a@example.com', 'password');
        expect(scopedContainer.read(authProvider), isA<Authenticated>());

        // Tenant A's data loads into the global (non-family) providers this
        // fix is meant to protect.
        when(
          () => mockCustomerRepository.fetchCustomers(
            page: 1,
            search: '',
            includeArchived: false,
          ),
        ).thenAnswer(
          (_) async => const CustomerPage(
            customers: [_tenantACustomer],
            currentPage: 1,
            lastPage: 1,
            total: 1,
          ),
        );
        when(() => mockDashboardRepository.fetchBusinessHealth()).thenAnswer(
          (_) async =>
              const BusinessHealth(status: 'neutral_baseline', score: null),
        );

        final tenantACustomers = await scopedContainer.read(
          customerListProvider.future,
        );
        final tenantAHealth = await scopedContainer.read(
          businessHealthProvider.future,
        );
        expect(tenantACustomers.customers, [_tenantACustomer]);
        expect(tenantAHealth.status, 'neutral_baseline');

        // Tenant A logs out.
        when(() => mockRepository.logout()).thenAnswer((_) async {});
        await scopedContainer.read(authProvider.notifier).forceLogout();
        expect(scopedContainer.read(authProvider), isA<Unauthenticated>());

        // Tenant B logs in on the same app process/device.
        when(
          () => mockRepository.login('b@example.com', 'password'),
        ).thenAnswer(
          (_) async =>
              const Authenticated(user: _tenantBUser, token: 'token-b'),
        );
        when(
          () => mockCustomerRepository.fetchCustomers(
            page: 1,
            search: '',
            includeArchived: false,
          ),
        ).thenAnswer(
          (_) async => const CustomerPage(
            customers: [_tenantBCustomer],
            currentPage: 1,
            lastPage: 1,
            total: 1,
          ),
        );
        when(() => mockDashboardRepository.fetchBusinessHealth()).thenAnswer(
          (_) async => const BusinessHealth(status: 'healthy', score: 80),
        );

        await scopedContainer
            .read(authProvider.notifier)
            .login('b@example.com', 'password');
        expect(scopedContainer.read(authProvider), isA<Authenticated>());

        // Tenant B's first read must be a genuine second fetch — proof the
        // reset actually invalidated the cache, not just a stale replay.
        final tenantBCustomers = await scopedContainer.read(
          customerListProvider.future,
        );
        final tenantBHealth = await scopedContainer.read(
          businessHealthProvider.future,
        );

        expect(tenantBCustomers.customers, [_tenantBCustomer]);
        expect(tenantBCustomers.customers, isNot(contains(_tenantACustomer)));
        expect(tenantBHealth.status, 'healthy');
        expect(tenantBHealth.score, 80);

        verify(
          () => mockCustomerRepository.fetchCustomers(
            page: 1,
            search: '',
            includeArchived: false,
          ),
        ).called(2);
        verify(() => mockDashboardRepository.fetchBusinessHealth()).called(2);
      },
    );

    test(
      'a still-mounted listener (simulating a StatefulShellRoute.indexedStack tab kept '
      'alive off-screen) does not cause a stale render or an exception across the '
      'logout/re-login cycle',
      () async {
        when(
          () => mockRepository.login('a@example.com', 'password'),
        ).thenAnswer(
          (_) async =>
              const Authenticated(user: _tenantAUser, token: 'token-a'),
        );
        when(
          () => mockCustomerRepository.fetchCustomers(
            page: 1,
            search: '',
            includeArchived: false,
          ),
        ).thenAnswer(
          (_) async => const CustomerPage(
            customers: [_tenantACustomer],
            currentPage: 1,
            lastPage: 1,
            total: 1,
          ),
        );

        await scopedContainer
            .read(authProvider.notifier)
            .login('a@example.com', 'password');

        // Mirrors an IndexedStack-preserved tab's `ref.watch` — an active
        // subscription that is never disposed just because the tab isn't
        // visible.
        final events = <AsyncValue<CustomerListState>>[];
        scopedContainer.listen(
          customerListProvider,
          (_, next) => events.add(next),
          fireImmediately: true,
        );
        await scopedContainer.read(customerListProvider.future);

        when(() => mockRepository.logout()).thenAnswer((_) async {});
        when(
          () => mockRepository.login('b@example.com', 'password'),
        ).thenAnswer(
          (_) async =>
              const Authenticated(user: _tenantBUser, token: 'token-b'),
        );
        when(
          () => mockCustomerRepository.fetchCustomers(
            page: 1,
            search: '',
            includeArchived: false,
          ),
        ).thenAnswer(
          (_) async => const CustomerPage(
            customers: [_tenantBCustomer],
            currentPage: 1,
            lastPage: 1,
            total: 1,
          ),
        );

        // The whole sequence must complete without throwing (no auth loop,
        // no unhandled exception from the listener reacting mid-invalidate).
        await scopedContainer.read(authProvider.notifier).forceLogout();
        await scopedContainer
            .read(authProvider.notifier)
            .login('b@example.com', 'password');

        final finalState = await scopedContainer.read(
          customerListProvider.future,
        );
        expect(finalState.customers, [_tenantBCustomer]);
        expect(finalState.customers, isNot(contains(_tenantACustomer)));

        // The still-attached listener (the "hidden tab") may see a
        // transient churn of events as each session boundary's eager
        // rebuild runs, but the LAST value it was ever handed — what the
        // tab would actually be rendering right now — must be Tenant B's,
        // never stuck on Tenant A's.
        expect(events.last.valueOrNull?.customers, [_tenantBCustomer]);
      },
    );
  });
}
