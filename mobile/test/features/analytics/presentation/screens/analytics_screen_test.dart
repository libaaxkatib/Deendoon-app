import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/localization/somali_fallback_delegates.dart';
import 'package:mobile/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:mobile/features/subscription/data/subscription_repository.dart';
import 'package:mobile/features/subscription/domain/subscription.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

const _localizationsDelegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
  SomaliMaterialLocalizationsDelegate(),
  SomaliCupertinoLocalizationsDelegate(),
];

class _MockSubscriptionRepository extends Mock implements SubscriptionRepository {}

Subscription _subscription({required bool analyticsEnabled}) => Subscription(
      plan: null,
      planName: 'Small Business',
      planPrice: '20.00',
      onTrial: false,
      trialEndsAt: null,
      startedAt: null,
      expiresAt: null,
      subscriptionStatus: 'active',
      customerUsage: 10,
      customerLimit: 100,
      storageUsageBytes: 0,
      storageLimit: 10,
      analyticsEnabled: analyticsEnabled,
      readOnly: false,
    );

void main() {
  late _MockSubscriptionRepository mockRepository;

  setUp(() {
    mockRepository = _MockSubscriptionRepository();
  });

  testWidgets(
    'a plan without analytics shows the locked/upgrade state instead of the tabs',
    (tester) async {
      when(() => mockRepository.fetchSubscription()).thenAnswer((_) async => _subscription(analyticsEnabled: false));

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const AnalyticsScreen()),
          GoRoute(path: '/account/subscription', builder: (_, _) => const Text('Subscription Screen')),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [subscriptionRepositoryProvider.overrideWithValue(mockRepository)],
          child: MaterialApp.router(
            routerConfig: router,
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: _localizationsDelegates,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Analytics Not Included'), findsOneWidget);
      expect(find.text('Overview'), findsNothing);
      expect(find.text('Reports'), findsNothing);
      expect(find.text('Trends'), findsNothing);

      await tester.tap(find.text('Upgrade Plan'));
      await tester.pumpAndSettle();

      expect(find.text('Subscription Screen'), findsOneWidget);
    },
  );

  testWidgets('a plan with analytics shows the real Overview/Reports/Trends tabs', (tester) async {
    when(() => mockRepository.fetchSubscription()).thenAnswer((_) async => _subscription(analyticsEnabled: true));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [subscriptionRepositoryProvider.overrideWithValue(mockRepository)],
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: _localizationsDelegates,
          home: const AnalyticsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Analytics Not Included'), findsNothing);
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Reports'), findsOneWidget);
    expect(find.text('Trends'), findsOneWidget);
  });

  testWidgets('a subscription fetch failure fails open and still shows the tabs', (tester) async {
    when(() => mockRepository.fetchSubscription()).thenThrow(Exception('network down'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [subscriptionRepositoryProvider.overrideWithValue(mockRepository)],
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: _localizationsDelegates,
          home: const AnalyticsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Analytics Not Included'), findsNothing);
    expect(find.text('Overview'), findsOneWidget);
  });
}
