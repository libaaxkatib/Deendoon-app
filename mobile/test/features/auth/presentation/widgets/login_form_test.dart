import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/app/router/router_refresh_notifier.dart';
import 'package:mobile/core/storage/remember_me_preference_storage.dart';
import 'package:mobile/core/storage/remembered_credentials_storage.dart';
import 'package:mobile/core/localization/somali_fallback_delegates.dart';
import 'package:mobile/features/auth/data/auth_repository.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';
import 'package:mobile/features/auth/domain/user.dart';
import 'package:mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:mobile/features/auth/presentation/widgets/login_form.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

/// Real, in-memory `FlutterSecureStorage` stand-in — LoginForm's own
/// credential-restore/save/clear behavior needs actual stateful read/write
/// semantics across multiple calls within a test, not per-call stubbing.
class _InMemorySecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _values = {};

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _values.remove(key);
    } else {
      _values[key] = value;
    }
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => _values[key];

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _values.remove(key);
  }
}

/// Root-cause audit fix regression (C.1/C.3): a configurable fake
/// reproducing two specific real `flutter_secure_storage` 9.2.2 Android
/// behaviors confirmed directly against its actual source, which
/// `_InMemorySecureStorage` above never attempts to simulate — a write that
/// throws (C.1: a real Keystore write failure), and a read that resolves to
/// the literal `resetOnError` sentinel string instead of `null` or a thrown
/// `PlatformException` (C.3).
class _ConfigurableSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _values = {};
  final Set<String> resetSentinelKeys;
  final Set<String> throwOnWriteKeys;

  _ConfigurableSecureStorage({
    this.resetSentinelKeys = const {},
    this.throwOnWriteKeys = const {},
  });

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (throwOnWriteKeys.contains(key)) {
      throw Exception('Simulated Android Keystore write failure for "$key"');
    }
    if (value == null) {
      _values.remove(key);
    } else {
      _values[key] = value;
    }
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (resetSentinelKeys.contains(key)) return 'Data has been reset';
    return _values[key];
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _values.remove(key);
  }
}

const _user = User(id: '1', name: 'Test User', email: 'owner@example.com');

Future<ProviderContainer> _pumpLoginForm(
  WidgetTester tester, {
  RememberedCredentialsStorage? credentialsStorage,
  AuthRepository? authRepository,
}) async {
  final container = ProviderContainer(
    overrides: [
      rememberedCredentialsStorageProvider.overrideWithValue(
        credentialsStorage ??
            RememberedCredentialsStorage(_InMemorySecureStorage()),
      ),
      if (authRepository != null)
        authRepositoryProvider.overrideWithValue(authRepository),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
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
        home: const Scaffold(body: LoginForm()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

/// Root-cause audit fix regression (C.2): unlike [_pumpLoginForm] above,
/// this uses a real `GoRouter` wired to the app's own `routerRefreshProvider`
/// (the exact mechanism that reactively navigates `/login` → `/home` the
/// instant login succeeds, per `RouterRefreshNotifier`) and a redirect that
/// mirrors that same behavior. `_pumpLoginForm`'s bare `MaterialApp` never
/// disposes `LoginForm` on a successful login, so it could never reproduce
/// (or catch a regression of) the disposal race this fix addresses — this
/// helper closes that gap.
Future<ProviderContainer> _pumpLoginFormWithRealRouter(
  WidgetTester tester, {
  RememberedCredentialsStorage? credentialsStorage,
  AuthRepository? authRepository,
}) async {
  final container = ProviderContainer(
    overrides: [
      rememberedCredentialsStorageProvider.overrideWithValue(
        credentialsStorage ??
            RememberedCredentialsStorage(_InMemorySecureStorage()),
      ),
      if (authRepository != null)
        authRepositoryProvider.overrideWithValue(authRepository),
    ],
  );
  addTearDown(container.dispose);

  final router = GoRouter(
    initialLocation: '/login',
    refreshListenable: container.read(routerRefreshProvider),
    redirect: (context, state) {
      final loggedIn = container.read(authProvider) is Authenticated;
      if (loggedIn && state.matchedLocation == '/login') return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, _) => const Scaffold(body: LoginForm()),
      ),
      GoRoute(
        path: '/home',
        builder: (_, _) => const Scaffold(body: Text('Home Screen')),
      ),
    ],
  );
  addTearDown(router.dispose);

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
  await tester.pumpAndSettle();
  return container;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Mobile QA Fix — Remember Me', () {
    testWidgets('the checkbox is visible with the "Remember Me" label', (
      tester,
    ) async {
      await _pumpLoginForm(tester);

      expect(find.byType(CheckboxListTile), findsOneWidget);
      expect(find.text('Remember Me'), findsOneWidget);
    });

    testWidgets('defaults to unchecked when nothing was previously saved', (
      tester,
    ) async {
      await _pumpLoginForm(tester);

      final checkbox = tester.widget<CheckboxListTile>(
        find.byType(CheckboxListTile),
      );
      expect(checkbox.value, isFalse);
    });

    testWidgets('can be toggled on and persists the preference to storage', (
      tester,
    ) async {
      await _pumpLoginForm(tester);

      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();

      final checkbox = tester.widget<CheckboxListTile>(
        find.byType(CheckboxListTile),
      );
      expect(checkbox.value, isTrue);
      expect(await const RememberMePreferenceStorage().readEnabled(), isTrue);
    });

    testWidgets('toggling off after on persists false', (tester) async {
      await _pumpLoginForm(tester);

      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();

      final checkbox = tester.widget<CheckboxListTile>(
        find.byType(CheckboxListTile),
      );
      expect(checkbox.value, isFalse);
      expect(await const RememberMePreferenceStorage().readEnabled(), isFalse);
    });

    testWidgets(
      'restores a previously-saved ON preference the next time the form mounts',
      (tester) async {
        await const RememberMePreferenceStorage().saveEnabled(true);

        await _pumpLoginForm(tester);

        final checkbox = tester.widget<CheckboxListTile>(
          find.byType(CheckboxListTile),
        );
        expect(checkbox.value, isTrue);
      },
    );

    testWidgets('autofillHints are attached to the email and password fields', (
      tester,
    ) async {
      await _pumpLoginForm(tester);

      final fields = tester.widgetList<TextField>(find.byType(TextField));
      final hintSets = fields
          .map((f) => f.autofillHints)
          .whereType<Iterable<String>>()
          .toList();

      expect(
        hintSets.any((hints) => hints.contains(AutofillHints.email)),
        isTrue,
      );
      expect(
        hintSets.any((hints) => hints.contains(AutofillHints.password)),
        isTrue,
      );
    });

    testWidgets(
      'AutofillGroup uses CANCEL when Remember Me is OFF (the default)',
      (tester) async {
        await _pumpLoginForm(tester);

        final group = tester.widget<AutofillGroup>(find.byType(AutofillGroup));
        expect(group.onDisposeAction, AutofillContextAction.cancel);
      },
    );

    testWidgets('AutofillGroup uses COMMIT when Remember Me is ON', (
      tester,
    ) async {
      await _pumpLoginForm(tester);

      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();

      final group = tester.widget<AutofillGroup>(find.byType(AutofillGroup));
      expect(group.onDisposeAction, AutofillContextAction.commit);
    });

    testWidgets(
      'no password is ever written to any app-local preference storage',
      (tester) async {
        const typedPassword = 'CorrectHorseBatteryStaple123!';
        await _pumpLoginForm(tester);

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'owner@example.com',
        );
        await tester.enterText(find.byType(TextField).last, typedPassword);
        await tester.tap(find.byType(CheckboxListTile));
        await tester.pumpAndSettle();

        final prefs = await SharedPreferences.getInstance();
        for (final key in prefs.getKeys()) {
          final value = prefs.get(key);
          expect(
            value.toString(),
            isNot(contains(typedPassword)),
            reason:
                'SharedPreferences key "$key" must never contain the '
                'password',
          );
        }
      },
    );

    group('credential restore/save/clear', () {
      testWidgets(
        'Remember Me ON restores both the remembered email and password '
        'on mount',
        (tester) async {
          await const RememberMePreferenceStorage().saveEnabled(true);
          final credentialsStorage = RememberedCredentialsStorage(
            _InMemorySecureStorage(),
          );
          await credentialsStorage.saveCredentials(
            email: 'owner@example.com',
            password: 'CorrectHorseBatteryStaple123!',
          );

          await _pumpLoginForm(tester, credentialsStorage: credentialsStorage);

          expect(
            tester
                .widget<TextFormField>(
                  find.widgetWithText(TextFormField, 'Email'),
                )
                .controller
                ?.text,
            'owner@example.com',
          );
          final passwordField = tester.widget<TextField>(
            find.byType(TextField).last,
          );
          expect(
            passwordField.controller?.text,
            'CorrectHorseBatteryStaple123!',
          );
        },
      );

      testWidgets(
        'Remember Me OFF does not restore any previously-saved credentials',
        (tester) async {
          // Preference is OFF (default), but credentials happen to still be
          // present in storage — must not be restored while OFF.
          final credentialsStorage = RememberedCredentialsStorage(
            _InMemorySecureStorage(),
          );
          await credentialsStorage.saveCredentials(
            email: 'owner@example.com',
            password: 'CorrectHorseBatteryStaple123!',
          );

          await _pumpLoginForm(tester, credentialsStorage: credentialsStorage);

          final emailField = tester.widget<TextFormField>(
            find.widgetWithText(TextFormField, 'Email'),
          );
          expect(emailField.controller?.text, isEmpty);
          final passwordField = tester.widget<TextField>(
            find.byType(TextField).last,
          );
          expect(passwordField.controller?.text, isEmpty);
        },
      );

      testWidgets(
        'turning Remember Me OFF immediately clears any remembered credentials',
        (tester) async {
          await const RememberMePreferenceStorage().saveEnabled(true);
          final credentialsStorage = RememberedCredentialsStorage(
            _InMemorySecureStorage(),
          );
          await credentialsStorage.saveCredentials(
            email: 'owner@example.com',
            password: 'CorrectHorseBatteryStaple123!',
          );

          await _pumpLoginForm(tester, credentialsStorage: credentialsStorage);
          await tester.tap(find.byType(CheckboxListTile));
          await tester.pumpAndSettle();

          expect(await credentialsStorage.readEmail(), isNull);
          expect(await credentialsStorage.readPassword(), isNull);
        },
      );

      testWidgets(
        'a successful login with Remember Me ON saves the credentials',
        (tester) async {
          final authRepository = _MockAuthRepository();
          when(
            () => authRepository.login('owner@example.com', 'S3cret!Pass'),
          ).thenAnswer(
            (_) async => const Authenticated(user: _user, token: 'live-token'),
          );
          final credentialsStorage = RememberedCredentialsStorage(
            _InMemorySecureStorage(),
          );

          await _pumpLoginForm(
            tester,
            credentialsStorage: credentialsStorage,
            authRepository: authRepository,
          );
          await tester.tap(find.byType(CheckboxListTile));
          await tester.pumpAndSettle();
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Email'),
            'owner@example.com',
          );
          await tester.enterText(find.byType(TextField).last, 'S3cret!Pass');
          await tester.tap(find.widgetWithText(ElevatedButton, 'Log In'));
          await tester.pumpAndSettle();

          expect(await credentialsStorage.readEmail(), 'owner@example.com');
          expect(await credentialsStorage.readPassword(), 'S3cret!Pass');
        },
      );

      testWidgets(
        'a successful login with Remember Me OFF does not save any credentials',
        (tester) async {
          final authRepository = _MockAuthRepository();
          when(
            () => authRepository.login('owner@example.com', 'S3cret!Pass'),
          ).thenAnswer(
            (_) async => const Authenticated(user: _user, token: 'live-token'),
          );
          final credentialsStorage = RememberedCredentialsStorage(
            _InMemorySecureStorage(),
          );

          await _pumpLoginForm(
            tester,
            credentialsStorage: credentialsStorage,
            authRepository: authRepository,
          );
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Email'),
            'owner@example.com',
          );
          await tester.enterText(find.byType(TextField).last, 'S3cret!Pass');
          await tester.tap(find.widgetWithText(ElevatedButton, 'Log In'));
          await tester.pumpAndSettle();

          expect(await credentialsStorage.readEmail(), isNull);
          expect(await credentialsStorage.readPassword(), isNull);
        },
      );
    });

    group(
      'Root-cause audit fix — C.1/C.2/C.3 (real GoRouter, not a bare MaterialApp)',
      () {
        testWidgets(
          'a successful login with Remember Me ON saves the credentials and '
          'survives the reactive navigation to Home (C.2: this is the '
          'condition the bare-MaterialApp harness above can never reproduce, '
          'since LoginForm is never disposed there)',
          (tester) async {
            final authRepository = _MockAuthRepository();
            when(
              () => authRepository.login('owner@example.com', 'S3cret!Pass'),
            ).thenAnswer(
              (_) async =>
                  const Authenticated(user: _user, token: 'live-token'),
            );
            final credentialsStorage = RememberedCredentialsStorage(
              _InMemorySecureStorage(),
            );

            await _pumpLoginFormWithRealRouter(
              tester,
              credentialsStorage: credentialsStorage,
              authRepository: authRepository,
            );
            await tester.tap(find.byType(CheckboxListTile));
            await tester.pumpAndSettle();
            await tester.enterText(
              find.widgetWithText(TextFormField, 'Email'),
              'owner@example.com',
            );
            await tester.enterText(find.byType(TextField).last, 'S3cret!Pass');
            await tester.tap(find.widgetWithText(ElevatedButton, 'Log In'));
            await tester.pumpAndSettle();

            // Confirms the router really did navigate away — i.e. this test
            // is actually exercising the disposal race, not a no-op.
            expect(find.byType(LoginForm), findsNothing);
            expect(find.text('Home Screen'), findsOneWidget);

            expect(await credentialsStorage.readEmail(), 'owner@example.com');
            expect(await credentialsStorage.readPassword(), 'S3cret!Pass');
          },
        );

        testWidgets(
          'Remember Me OFF still does not save credentials, even through '
          'the real router',
          (tester) async {
            final authRepository = _MockAuthRepository();
            when(
              () => authRepository.login('owner@example.com', 'S3cret!Pass'),
            ).thenAnswer(
              (_) async =>
                  const Authenticated(user: _user, token: 'live-token'),
            );
            final credentialsStorage = RememberedCredentialsStorage(
              _InMemorySecureStorage(),
            );

            await _pumpLoginFormWithRealRouter(
              tester,
              credentialsStorage: credentialsStorage,
              authRepository: authRepository,
            );
            await tester.enterText(
              find.widgetWithText(TextFormField, 'Email'),
              'owner@example.com',
            );
            await tester.enterText(find.byType(TextField).last, 'S3cret!Pass');
            await tester.tap(find.widgetWithText(ElevatedButton, 'Log In'));
            await tester.pumpAndSettle();

            expect(find.text('Home Screen'), findsOneWidget);
            expect(await credentialsStorage.readEmail(), isNull);
            expect(await credentialsStorage.readPassword(), isNull);
          },
        );

        testWidgets(
          'C.1: a secure-storage write failure during save does not make a '
          'successful login look like it failed — the app still navigates '
          'to Home normally',
          (tester) async {
            final authRepository = _MockAuthRepository();
            when(
              () => authRepository.login('owner@example.com', 'S3cret!Pass'),
            ).thenAnswer(
              (_) async =>
                  const Authenticated(user: _user, token: 'live-token'),
            );
            final credentialsStorage = RememberedCredentialsStorage(
              _ConfigurableSecureStorage(
                throwOnWriteKeys: {'remembered_email', 'remembered_password'},
              ),
            );

            await _pumpLoginFormWithRealRouter(
              tester,
              credentialsStorage: credentialsStorage,
              authRepository: authRepository,
            );
            await tester.tap(find.byType(CheckboxListTile));
            await tester.pumpAndSettle();
            await tester.enterText(
              find.widgetWithText(TextFormField, 'Email'),
              'owner@example.com',
            );
            await tester.enterText(find.byType(TextField).last, 'S3cret!Pass');
            await tester.tap(find.widgetWithText(ElevatedButton, 'Log In'));
            await tester.pumpAndSettle();

            // The write failure must be fully invisible to the user — login
            // still succeeds and still navigates normally.
            expect(find.text('Home Screen'), findsOneWidget);
            expect(find.text('Data has been reset'), findsNothing);
          },
        );

        testWidgets(
          'C.3: a previously-reset ("Data has been reset" sentinel) secure '
          'storage entry restores as no saved credentials, never as the '
          'literal sentinel text in the email/password fields',
          (tester) async {
            await const RememberMePreferenceStorage().saveEnabled(true);
            final credentialsStorage = RememberedCredentialsStorage(
              _ConfigurableSecureStorage(
                resetSentinelKeys: {'remembered_email', 'remembered_password'},
              ),
            );

            await _pumpLoginFormWithRealRouter(
              tester,
              credentialsStorage: credentialsStorage,
            );

            expect(find.text('Data has been reset'), findsNothing);
            final emailField = tester.widget<TextFormField>(
              find.widgetWithText(TextFormField, 'Email'),
            );
            expect(emailField.controller?.text, isEmpty);
            final passwordField = tester.widget<TextField>(
              find.byType(TextField).last,
            );
            expect(passwordField.controller?.text, isEmpty);

            // The checkbox itself still correctly reflects the preference —
            // only the (unrecoverable) credential values are suppressed.
            final checkbox = tester.widget<CheckboxListTile>(
              find.byType(CheckboxListTile),
            );
            expect(checkbox.value, isTrue);
          },
        );
      },
    );
  });
}
