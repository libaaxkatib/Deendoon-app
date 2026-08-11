import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/localization/somali_fallback_delegates.dart';
import 'package:mobile/features/dashboard/data/dashboard_repository.dart';
import 'package:mobile/features/dashboard/domain/business_health.dart';
import 'package:mobile/features/dashboard/presentation/widgets/business_health_card.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

const _localizationsDelegates = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
  SomaliMaterialLocalizationsDelegate(),
  SomaliCupertinoLocalizationsDelegate(),
];

class _MockDashboardRepository extends Mock implements DashboardRepository {}

void main() {
  late _MockDashboardRepository mockRepository;

  setUp(() {
    mockRepository = _MockDashboardRepository();
  });

  Future<void> pumpCard(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dashboardRepositoryProvider.overrideWithValue(mockRepository)],
        child: const MaterialApp(
          locale: Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: _localizationsDelegates,
          home: Scaffold(body: BusinessHealthCard()),
        ),
      ),
    );
  }

  testWidgets('shows a loading placeholder before data arrives', (tester) async {
    when(() => mockRepository.fetchBusinessHealth()).thenAnswer(
      (_) => Future.delayed(const Duration(seconds: 1), () => const BusinessHealth(status: 'healthy', score: 90)),
    );

    await pumpCard(tester);
    await tester.pump();

    expect(find.text('Loading...'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('shows a retry affordance when the fetch fails', (tester) async {
    when(() => mockRepository.fetchBusinessHealth()).thenThrow(Exception('network down'));

    await pumpCard(tester);
    await tester.pumpAndSettle();

    expect(find.text('Could not load Business Health.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    when(() => mockRepository.fetchBusinessHealth())
        .thenAnswer((_) async => const BusinessHealth(status: 'healthy', score: 90));
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Healthy'), findsOneWidget);
  });

  testWidgets('renders the healthy status with its score', (tester) async {
    when(() => mockRepository.fetchBusinessHealth())
        .thenAnswer((_) async => const BusinessHealth(status: 'healthy', score: 90));

    await pumpCard(tester);
    await tester.pumpAndSettle();

    expect(find.text('Healthy'), findsOneWidget);
    expect(find.text('You are doing great!'), findsOneWidget);
    expect(find.text('90%'), findsOneWidget);
  });

  testWidgets('renders the needs_attention status with its score', (tester) async {
    when(() => mockRepository.fetchBusinessHealth())
        .thenAnswer((_) async => const BusinessHealth(status: 'needs_attention', score: 60));

    await pumpCard(tester);
    await tester.pumpAndSettle();

    expect(find.text('Needs Attention'), findsOneWidget);
    expect(find.text('Some areas need review.'), findsOneWidget);
    expect(find.text('60%'), findsOneWidget);
  });

  testWidgets('renders the at_risk status with its score', (tester) async {
    when(() => mockRepository.fetchBusinessHealth())
        .thenAnswer((_) async => const BusinessHealth(status: 'at_risk', score: 25));

    await pumpCard(tester);
    await tester.pumpAndSettle();

    expect(find.text('At Risk'), findsOneWidget);
    expect(find.text('Immediate attention recommended.'), findsOneWidget);
    expect(find.text('25%'), findsOneWidget);
  });

  testWidgets('renders the neutral_baseline status with a dash instead of a fabricated score', (tester) async {
    when(() => mockRepository.fetchBusinessHealth())
        .thenAnswer((_) async => const BusinessHealth(status: 'neutral_baseline', score: null));

    await pumpCard(tester);
    await tester.pumpAndSettle();

    expect(find.text('Neutral Baseline'), findsOneWidget);
    expect(find.text('Not enough data yet.'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
  });

  testWidgets('tapping the card navigates to Analytics', (tester) async {
    when(() => mockRepository.fetchBusinessHealth())
        .thenAnswer((_) async => const BusinessHealth(status: 'healthy', score: 90));

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Scaffold(body: BusinessHealthCard())),
        GoRoute(path: '/analytics', builder: (_, _) => const Scaffold(body: Text('Analytics Screen'))),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [dashboardRepositoryProvider.overrideWithValue(mockRepository)],
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: _localizationsDelegates,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Healthy'));
    await tester.pumpAndSettle();

    expect(find.text('Analytics Screen'), findsOneWidget);
  });
}
