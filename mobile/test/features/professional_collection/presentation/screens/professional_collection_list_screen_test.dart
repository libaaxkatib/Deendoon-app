import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/localization/somali_fallback_delegates.dart';
import 'package:mobile/features/professional_collection/data/professional_collection_repository.dart';
import 'package:mobile/features/professional_collection/domain/professional_collection_request.dart';
import 'package:mobile/features/professional_collection/domain/professional_collection_request_page.dart';
import 'package:mobile/features/professional_collection/presentation/screens/professional_collection_list_screen.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockProfessionalCollectionRepository extends Mock implements ProfessionalCollectionRepository {}

const _request = ProfessionalCollectionRequest(
  id: '1',
  collectionCaseId: '01CASE',
  referenceNumber: 'PCR-0001',
  status: 'need_more_information',
  submittedByUserId: '01USER',
  actionedByUserId: null,
  reasons: [],
  notes: null,
  requestedServices: [],
  declarationAcceptedAt: null,
  declarationAcceptedBy: null,
  createdAt: '2026-08-01T00:00:00.000000Z',
  closedAt: null,
);

Future<void> _pumpScreen(WidgetTester tester, {required _MockProfessionalCollectionRepository repository}) async {
  tester.view.physicalSize = const Size(400, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const ProfessionalCollectionListScreen()),
      GoRoute(path: '/professional-requests/:id', builder: (_, state) => Text('Detail ${state.pathParameters['id']}')),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [professionalCollectionRepositoryProvider.overrideWithValue(repository)],
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
}

void main() {
  late _MockProfessionalCollectionRepository mockRepository;

  setUp(() {
    mockRepository = _MockProfessionalCollectionRepository();
  });

  testWidgets('renders request cards with real fields and status badge', (tester) async {
    when(() => mockRepository.fetchRequests(page: 1, status: null))
        .thenAnswer((_) async => const ProfessionalCollectionRequestPage(requests: [_request], currentPage: 1, lastPage: 1, total: 1));

    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    expect(find.text('PCR-0001'), findsOneWidget);
    expect(find.text('Need More Information'), findsOneWidget);
  });

  testWidgets('shows the explicit empty state when there are no requests', (tester) async {
    when(() => mockRepository.fetchRequests(page: 1, status: null))
        .thenAnswer((_) async => const ProfessionalCollectionRequestPage(requests: [], currentPage: 1, lastPage: 1, total: 0));

    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    expect(find.text('No Professional Collection Requests yet'), findsOneWidget);
  });

  testWidgets('shows a retry affordance when the list fails to load', (tester) async {
    when(() => mockRepository.fetchRequests(page: 1, status: null)).thenThrow(Exception('network down'));

    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    expect(find.text('Could not load Professional Collection Requests.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('tapping a status filter chip triggers a real API call with that status', (tester) async {
    when(() => mockRepository.fetchRequests(page: 1, status: null))
        .thenAnswer((_) async => const ProfessionalCollectionRequestPage(requests: [_request], currentPage: 1, lastPage: 1, total: 1));
    when(() => mockRepository.fetchRequests(page: 1, status: 'submitted'))
        .thenAnswer((_) async => const ProfessionalCollectionRequestPage(requests: [], currentPage: 1, lastPage: 1, total: 0));

    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Submitted'));
    await tester.pumpAndSettle();

    verify(() => mockRepository.fetchRequests(page: 1, status: 'submitted')).called(1);
    expect(find.text('No requests match this filter'), findsOneWidget);
  });

  testWidgets('tapping a request opens its Detail screen', (tester) async {
    when(() => mockRepository.fetchRequests(page: 1, status: null))
        .thenAnswer((_) async => const ProfessionalCollectionRequestPage(requests: [_request], currentPage: 1, lastPage: 1, total: 1));

    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    await tester.tap(find.text('PCR-0001'));
    await tester.pumpAndSettle();

    expect(find.text('Detail 1'), findsOneWidget);
  });
}
