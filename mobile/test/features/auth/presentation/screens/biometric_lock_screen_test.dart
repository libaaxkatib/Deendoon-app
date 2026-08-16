import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/biometrics/biometric_auth_service.dart';
import 'package:mobile/core/localization/somali_fallback_delegates.dart';
import 'package:mobile/features/auth/presentation/providers/biometric_lock_provider.dart';
import 'package:mobile/features/auth/presentation/screens/biometric_lock_screen.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockBiometricAuthService extends Mock implements BiometricAuthService {}

void main() {
  late _MockBiometricAuthService mockBiometricAuthService;

  setUp(() {
    mockBiometricAuthService = _MockBiometricAuthService();
  });

  Future<ProviderContainer> pumpScreen(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        biometricAuthServiceProvider.overrideWithValue(
          mockBiometricAuthService,
        ),
      ],
    );
    addTearDown(container.dispose);
    // Mirrors the real app: restoreSession() locks before the router ever
    // sends the user to this screen.
    container.read(biometricLockProvider.notifier).lock();

    final router = GoRouter(
      initialLocation: '/biometric-lock',
      routes: [
        GoRoute(
          path: '/biometric-lock',
          builder: (_, _) => const BiometricLockScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (_, _) => const Scaffold(body: Text('Login Screen')),
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
    return container;
  }

  testWidgets(
    'prompts automatically on entry and unlocks on a successful biometric',
    (tester) async {
      when(
        () => mockBiometricAuthService.authenticate(any()),
      ).thenAnswer((_) async => true);

      final container = await pumpScreen(tester);
      // Deliberately bounded pumps, not pumpAndSettle(): on a successful
      // unlock this screen keeps its CircularProgressIndicator spinning
      // (matching splash_screen.dart's own pattern) until the real app's
      // router redirect replaces it with /home — there is nothing here to
      // "settle" in this isolated screen test, which has no redirect.
      await tester.pump();
      await tester.pump();
      await tester.pump();

      verify(() => mockBiometricAuthService.authenticate(any())).called(1);
      expect(container.read(biometricLockProvider), isFalse);
    },
  );

  testWidgets(
    'a cancelled/failed biometric remains locked and offers Retry and Use Password Instead',
    (tester) async {
      when(
        () => mockBiometricAuthService.authenticate(any()),
      ).thenAnswer((_) async => false);

      final container = await pumpScreen(tester);
      await tester.pumpAndSettle();

      expect(container.read(biometricLockProvider), isTrue);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Use Password Instead'), findsOneWidget);
      expect(
        find.text('Authentication failed. Try again or use your password.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('Retry prompts again and can succeed the second time', (
    tester,
  ) async {
    when(
      () => mockBiometricAuthService.authenticate(any()),
    ).thenAnswer((_) async => false);

    final container = await pumpScreen(tester);
    await tester.pumpAndSettle();
    verify(() => mockBiometricAuthService.authenticate(any())).called(1);

    when(
      () => mockBiometricAuthService.authenticate(any()),
    ).thenAnswer((_) async => true);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Retry'));
    // Bounded pumps here too — see the success-path test above for why
    // pumpAndSettle() can't be used once authenticate() resolves true.
    await tester.pump();
    await tester.pump();
    await tester.pump();

    verify(() => mockBiometricAuthService.authenticate(any())).called(1);
    expect(container.read(biometricLockProvider), isFalse);
  });

  testWidgets(
    'Use Password Instead reaches the real login route without unlocking on its own',
    (tester) async {
      when(
        () => mockBiometricAuthService.authenticate(any()),
      ).thenAnswer((_) async => false);

      final container = await pumpScreen(tester);
      await tester.pumpAndSettle();

      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Use Password Instead'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Login Screen'), findsOneWidget);
      // Navigating away is not itself an unlock — only a real login()
      // success unlocks (covered in auth_provider_test.dart); this proves
      // the fallback never silently bypasses biometric protection.
      expect(container.read(biometricLockProvider), isTrue);
    },
  );
}
