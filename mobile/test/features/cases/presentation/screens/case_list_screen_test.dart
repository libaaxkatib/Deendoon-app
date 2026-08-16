import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/localization/somali_fallback_delegates.dart';
import 'package:mobile/features/cases/data/collection_case_repository.dart';
import 'package:mobile/features/cases/domain/collection_case.dart';
import 'package:mobile/features/cases/domain/collection_case_page.dart';
import 'package:mobile/features/cases/presentation/screens/case_list_screen.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockCollectionCaseRepository extends Mock
    implements CollectionCaseRepository {}

const _case = CollectionCase(
  id: '1',
  debtId: '01DEBT',
  customerId: '01CUST',
  customerName: 'Somali Builders',
  outstandingAmount: '4467.40',
  riskLevel: 'high',
  referenceNumber: 'COL-0001',
  assignedOfficerUserId: null,
  caseStatus: 'open',
  closureOutcome: null,
  notes: null,
  lastActivityAt: '2026-07-28T10:00:00.000000Z',
  createdAt: '2026-07-01T10:00:00.000000Z',
  closedAt: null,
);

Future<void> _pumpScreen(
  WidgetTester tester, {
  required _MockCollectionCaseRepository repository,
  String? initialTab,
}) async {
  tester.view.physicalSize = const Size(400, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        collectionCaseRepositoryProvider.overrideWithValue(repository),
      ],
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
        home: CaseListScreen(initialTab: initialTab),
      ),
    ),
  );
}

void main() {
  late _MockCollectionCaseRepository mockRepository;

  setUp(() {
    mockRepository = _MockCollectionCaseRepository();
  });

  testWidgets('renders case cards with real fields', (tester) async {
    when(() => mockRepository.fetchCases(page: 1, tab: null)).thenAnswer(
      (_) async => const CollectionCasePage(
        cases: [_case],
        currentPage: 1,
        lastPage: 1,
        total: 1,
      ),
    );

    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    expect(find.text('Somali Builders'), findsOneWidget);
    expect(find.text('COL-0001'), findsOneWidget);
    expect(find.text('4467.40'), findsOneWidget);
    expect(find.text('Unassigned'), findsOneWidget);
  });

  testWidgets('shows the explicit empty state when there are no cases', (
    tester,
  ) async {
    when(() => mockRepository.fetchCases(page: 1, tab: null)).thenAnswer(
      (_) async => const CollectionCasePage(
        cases: [],
        currentPage: 1,
        lastPage: 1,
        total: 0,
      ),
    );

    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    expect(find.text('No collection cases yet'), findsOneWidget);
  });

  testWidgets('shows a retry affordance when the list fails to load', (
    tester,
  ) async {
    when(
      () => mockRepository.fetchCases(page: 1, tab: null),
    ).thenThrow(Exception('network down'));

    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    expect(find.text('Could not load cases.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets(
    'tapping a tab filter chip triggers a real API call with that tab',
    (tester) async {
      when(() => mockRepository.fetchCases(page: 1, tab: null)).thenAnswer(
        (_) async => const CollectionCasePage(
          cases: [_case],
          currentPage: 1,
          lastPage: 1,
          total: 1,
        ),
      );
      when(
        () => mockRepository.fetchCases(page: 1, tab: 'high_risk'),
      ).thenAnswer(
        (_) async => const CollectionCasePage(
          cases: [],
          currentPage: 1,
          lastPage: 1,
          total: 0,
        ),
      );

      await _pumpScreen(tester, repository: mockRepository);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ChoiceChip, 'High Risk'));
      await tester.pumpAndSettle();

      verify(
        () => mockRepository.fetchCases(page: 1, tab: 'high_risk'),
      ).called(1);
      expect(find.text('No cases match this filter'), findsOneWidget);
    },
  );

  testWidgets(
    'an initialTab constructor argument applies the filter on first load',
    (tester) async {
      when(() => mockRepository.fetchCases(page: 1, tab: null)).thenAnswer(
        (_) async => const CollectionCasePage(
          cases: [_case],
          currentPage: 1,
          lastPage: 1,
          total: 1,
        ),
      );
      when(
        () => mockRepository.fetchCases(page: 1, tab: 'high_risk'),
      ).thenAnswer(
        (_) async => const CollectionCasePage(
          cases: [],
          currentPage: 1,
          lastPage: 1,
          total: 0,
        ),
      );

      await _pumpScreen(
        tester,
        repository: mockRepository,
        initialTab: 'high_risk',
      );
      await tester.pumpAndSettle();

      verify(
        () => mockRepository.fetchCases(page: 1, tab: 'high_risk'),
      ).called(1);
      expect(find.text('No cases match this filter'), findsOneWidget);
    },
  );

  testWidgets(
    'the Professional Collection Requests icon opens the real list screen',
    (tester) async {
      tester.view.physicalSize = const Size(400, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      when(() => mockRepository.fetchCases(page: 1, tab: null)).thenAnswer(
        (_) async => const CollectionCasePage(
          cases: [_case],
          currentPage: 1,
          lastPage: 1,
          total: 1,
        ),
      );

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const CaseListScreen()),
          GoRoute(
            path: '/professional-requests',
            builder: (_, _) =>
                const Text('Professional Collection Requests Screen'),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            collectionCaseRepositoryProvider.overrideWithValue(mockRepository),
          ],
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

      await tester.tap(find.byTooltip('Professional Collection Requests'));
      await tester.pumpAndSettle();

      expect(
        find.text('Professional Collection Requests Screen'),
        findsOneWidget,
      );
    },
  );
}
