import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/biometrics/biometric_auth_service.dart';
import 'package:mobile/core/localization/somali_fallback_delegates.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/core/storage/biometric_preference_storage.dart';
import 'package:mobile/features/auth/data/auth_repository.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';
import 'package:mobile/features/auth/domain/user.dart';
import 'package:mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:mobile/features/auth/presentation/providers/biometric_lock_provider.dart';
import 'package:mobile/features/auth/presentation/screens/biometric_lock_screen.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockBiometricAuthService extends Mock implements BiometricAuthService {}

const _user = User(id: '1', name: 'Test User', email: 'test@example.com');
const _cached = Authenticated(user: _user, token: 'cached-token');

/// Same redirect shape as `app_router.dart`'s real (private, unexported)
/// `_redirect()`, narrowed to the two branches this scenario exercises —
/// this is what makes this an integration test of the *reachable outcome*
/// (Authenticated + locked -> /biometric-lock; unlocked -> /home) rather
/// than a full re-import of the production route table, which proved
/// unreliable to drive through Splash/StatefulShellRoute timing in a
/// widget test harness (the underlying unlock/redirect mechanism itself is
/// pre-existing, unmodified code — not part of this fix).
String? _redirect(ProviderContainer container, GoRouterState state) {
  final auth = container.read(authProvider);
  final loc = state.matchedLocation;

  final loggedIn = auth is Authenticated;
  if (!loggedIn) return loc == '/login' ? null : '/login';

  final locked = container.read(biometricLockProvider);
  if (locked) return loc == '/biometric-lock' ? null : '/biometric-lock';

  return loc == '/biometric-lock' || loc == '/login' ? '/home' : null;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group(
    'Mobile QA Fix — Biometric Login: restoreSession -> lock -> unlock -> Home',
    () {
      testWidgets(
        'a successful biometric unlock reaches Home even when the background '
        'validateAndRotate() refresh failed during restoreSession(), and the '
        'biometric preference is not disabled',
        (tester) async {
          await const BiometricPreferenceStorage().saveEnabled(true);

          final authRepository = _MockAuthRepository();
          when(
            () => authRepository.readCachedSession(),
          ).thenAnswer((_) async => _cached);
          // Simulates the exact race this fix addresses: the opportunistic
          // background token refresh fails (e.g. an idle-expired token)
          // while the user is on the biometric lock screen.
          when(() => authRepository.validateAndRotate()).thenThrow(
            const ApiException(message: 'Unauthenticated.', statusCode: 401),
          );

          final biometricAuthService = _MockBiometricAuthService();
          when(
            () => biometricAuthService.authenticate(any()),
          ).thenAnswer((_) async => true);

          final container = ProviderContainer(
            overrides: [
              authRepositoryProvider.overrideWithValue(authRepository),
              biometricAuthServiceProvider.overrideWithValue(
                biometricAuthService,
              ),
            ],
          );
          addTearDown(container.dispose);

          // Drive the real restoreSession() this fix touches: cached session
          // restored, biometric locked, background refresh fails and is
          // correctly swallowed rather than forcing a logout.
          await container.read(authProvider.notifier).restoreSession();

          expect(container.read(authProvider), isA<Authenticated>());
          expect(container.read(biometricLockProvider), isTrue);
          expect(
            await const BiometricPreferenceStorage().readEnabled(),
            isTrue,
          );

          final router = GoRouter(
            initialLocation: '/biometric-lock',
            redirect: (context, state) => _redirect(container, state),
            refreshListenable: _Listenable(container),
            routes: [
              GoRoute(
                path: '/biometric-lock',
                builder: (_, _) => const BiometricLockScreen(),
              ),
              GoRoute(
                path: '/login',
                builder: (_, _) => const Scaffold(body: Text('Login Screen')),
              ),
              GoRoute(
                path: '/home',
                builder: (_, _) => const Scaffold(body: Text('Home Screen')),
              ),
            ],
          );

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp.router(
                routerConfig: router,
                locale: const Locale('en'),
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                  SomaliMaterialLocalizationsDelegate(),
                  SomaliCupertinoLocalizationsDelegate(),
                ],
              ),
            ),
          );
          await tester.pump();

          expect(find.byType(BiometricLockScreen), findsOneWidget);
          expect(find.text('Login Screen'), findsNothing);
          expect(find.text('Home Screen'), findsNothing);

          // BiometricLockScreen auto-prompts on entry; the mocked service
          // resolves true — let that settle through to unlock(), which the
          // listenable propagates to the router's redirect. A duration-based
          // pump (not a bare pump()) is required here: GoRouter's default
          // page transition keeps the outgoing page mounted alongside the
          // incoming one for the transition's duration, and a zero-duration
          // pump never advances that animation clock.
          await tester.pump();
          await tester.pump();
          await tester.pump();
          expect(container.read(biometricLockProvider), isFalse);
          await tester.pump(const Duration(milliseconds: 500));

          expect(find.byType(BiometricLockScreen), findsNothing);
          expect(find.text('Login Screen'), findsNothing);
          // The redirect re-runs on the biometricLockProvider change and
          // must land on Home now that both auth and lock allow it — not
          // Login, which was the exact bug this fix addresses.
          expect(find.text('Home Screen'), findsOneWidget);
        },
      );
    },
  );
}

/// Bridges `authProvider`/`biometricLockProvider` to go_router's
/// `refreshListenable`, mirroring `RouterRefreshNotifier` in
/// `router_refresh_notifier.dart` without depending on it directly.
class _Listenable extends ChangeNotifier {
  _Listenable(ProviderContainer container) {
    container.listen(authProvider, (_, _) => notifyListeners());
    container.listen(biometricLockProvider, (_, _) => notifyListeners());
  }
}
