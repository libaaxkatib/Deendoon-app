import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/localization/somali_fallback_delegates.dart';
import 'package:mobile/core/storage/secure_token_storage.dart';
import 'package:mobile/features/account/presentation/screens/account_screen.dart';
import 'package:mobile/features/auth/data/auth_api.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';
import 'package:mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthApi extends Mock implements AuthApi {}

class _MockSecureTokenStorage extends Mock implements SecureTokenStorage {}

void main() {
  late _MockAuthApi mockApi;
  late _MockSecureTokenStorage mockStorage;

  setUp(() {
    mockApi = _MockAuthApi();
    mockStorage = _MockSecureTokenStorage();
  });

  Future<ProviderContainer> pumpScreen(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/account',
      routes: [
        GoRoute(path: '/account', builder: (_, _) => const AccountScreen()),
        GoRoute(path: '/account/profile', builder: (_, _) => const Scaffold(body: Text('Profile Screen'))),
        GoRoute(
          path: '/account/business-profile',
          builder: (_, _) => const Scaffold(body: Text('Business Profile Screen')),
        ),
        GoRoute(
          path: '/account/subscription',
          builder: (_, _) => const Scaffold(body: Text('Subscription Screen')),
        ),
        GoRoute(path: '/account/settings', builder: (_, _) => const Scaffold(body: Text('Settings Screen'))),
        GoRoute(path: '/account/about', builder: (_, _) => const Scaffold(body: Text('About Screen'))),
        GoRoute(path: '/account/bulk-import', builder: (_, _) => const Scaffold(body: Text('Bulk Import Screen'))),
        GoRoute(path: '/notifications', builder: (_, _) => const Scaffold(body: Text('Notifications Screen'))),
      ],
    );

    final container = ProviderContainer(
      overrides: [
        authApiProvider.overrideWithValue(mockApi),
        secureTokenStorageProvider.overrideWithValue(mockStorage),
      ],
    );
    addTearDown(container.dispose);

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

  testWidgets('renders all 6 menu items plus the destructive Logout action', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Profile'), findsNothing);
    expect(find.text('Business Profile'), findsOneWidget);
    expect(find.text('Subscription'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
    expect(find.text('Bulk Import'), findsOneWidget);
    expect(find.text('Logout'), findsOneWidget);
  });

  testWidgets('tapping Subscription navigates to the Subscription screen', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Subscription'));
    await tester.pumpAndSettle();

    expect(find.text('Subscription Screen'), findsOneWidget);
  });

  testWidgets('tapping Bulk Import navigates to the Bulk Import screen', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Bulk Import'));
    await tester.pumpAndSettle();

    expect(find.text('Bulk Import Screen'), findsOneWidget);
  });

  testWidgets('tapping Notifications navigates to the Notifications screen', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();

    expect(find.text('Notifications Screen'), findsOneWidget);
  });

  testWidgets('tapping About navigates to the About screen', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();

    expect(find.text('About Screen'), findsOneWidget);
  });

  testWidgets('tapping the profile header card navigates to the Profile screen', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byKey(const Key('accountProfileHeaderCard')));
    await tester.pumpAndSettle();

    expect(find.text('Profile Screen'), findsOneWidget);
  });

  testWidgets('tapping Logout calls the real endpoint and clears the session', (tester) async {
    when(() => mockApi.logout()).thenAnswer((_) async {});
    when(() => mockStorage.clear()).thenAnswer((_) async {});

    final container = await pumpScreen(tester);

    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();

    verify(() => mockApi.logout()).called(1);
    verify(() => mockStorage.clear()).called(1);
    expect(container.read(authProvider), isA<Unauthenticated>());
  });
}
