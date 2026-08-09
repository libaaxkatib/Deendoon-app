import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/dashboard/presentation/widgets/professional_collection_summary_card.dart';
import 'package:mobile/features/professional_collection/data/professional_collection_repository.dart';
import 'package:mobile/features/professional_collection/domain/professional_collection_request.dart';
import 'package:mobile/features/professional_collection/domain/professional_collection_summary.dart';
import 'package:mocktail/mocktail.dart';

class _MockProfessionalCollectionRepository extends Mock implements ProfessionalCollectionRepository {}

const _emptySummary = ProfessionalCollectionSummary(
  countsByStatus: {
    'submitted': 0,
    'under_review': 0,
    'need_more_information': 0,
    'accepted': 0,
    'assigned': 0,
    'in_progress': 0,
    'recovered': 0,
    'closed': 0,
  },
  totalActive: 0,
  totalRecovered: 0,
  latestRequest: null,
  latestTimelineEvent: null,
);

const _summaryWithLatest = ProfessionalCollectionSummary(
  countsByStatus: {
    'submitted': 1,
    'under_review': 0,
    'need_more_information': 0,
    'accepted': 0,
    'assigned': 1,
    'in_progress': 0,
    'recovered': 2,
    'closed': 0,
  },
  totalActive: 2,
  totalRecovered: 2,
  latestRequest: ProfessionalCollectionRequest(
    id: '01PCR',
    collectionCaseId: '01CASE',
    referenceNumber: 'PCR-0003',
    status: 'assigned',
    submittedByUserId: '01USER',
    actionedByUserId: '02USER',
    reasons: ['Repeated missed promises'],
    notes: null,
    requestedServices: ['Field Visit'],
    declarationAcceptedAt: '2026-08-01T00:00:00.000000Z',
    declarationAcceptedBy: '01USER',
    createdAt: '2026-08-03T00:00:00.000000Z',
    closedAt: null,
  ),
  latestTimelineEvent: null,
);

void main() {
  late _MockProfessionalCollectionRepository mockRepository;

  setUp(() {
    mockRepository = _MockProfessionalCollectionRepository();
  });

  testWidgets('shows the honest empty state when nothing has ever been submitted', (tester) async {
    when(() => mockRepository.fetchSummary()).thenAnswer((_) async => _emptySummary);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [professionalCollectionRepositoryProvider.overrideWithValue(mockRepository)],
        child: const MaterialApp(home: Scaffold(body: ProfessionalCollectionSummaryCard())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No cases submitted to Deendoon yet'), findsOneWidget);
  });

  testWidgets('renders real Active/Recovered counts and the latest Request', (tester) async {
    when(() => mockRepository.fetchSummary()).thenAnswer((_) async => _summaryWithLatest);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [professionalCollectionRepositoryProvider.overrideWithValue(mockRepository)],
        child: const MaterialApp(home: Scaffold(body: ProfessionalCollectionSummaryCard())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2'), findsNWidgets(2)); // Active + Recovered
    expect(find.text('PCR-0003'), findsOneWidget);
    expect(find.text('Assigned'), findsOneWidget);
  });

  testWidgets('tapping the latest Request navigates to its detail screen', (tester) async {
    when(() => mockRepository.fetchSummary()).thenAnswer((_) async => _summaryWithLatest);

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Scaffold(body: ProfessionalCollectionSummaryCard())),
        GoRoute(
          path: '/professional-requests/:id',
          builder: (_, state) => Text('Request Detail ${state.pathParameters['id']}'),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [professionalCollectionRepositoryProvider.overrideWithValue(mockRepository)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('PCR-0003'));
    await tester.pumpAndSettle();

    expect(find.text('Request Detail 01PCR'), findsOneWidget);
  });

  testWidgets('View All opens the real Professional Collection list', (tester) async {
    when(() => mockRepository.fetchSummary()).thenAnswer((_) async => _emptySummary);

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Scaffold(body: ProfessionalCollectionSummaryCard())),
        GoRoute(path: '/professional-requests', builder: (_, _) => const Text('Professional Collection List')),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [professionalCollectionRepositoryProvider.overrideWithValue(mockRepository)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('View All'));
    await tester.pumpAndSettle();

    expect(find.text('Professional Collection List'), findsOneWidget);
  });

  testWidgets('shows a retry affordance when the summary fails to load', (tester) async {
    when(() => mockRepository.fetchSummary()).thenThrow(Exception('network down'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [professionalCollectionRepositoryProvider.overrideWithValue(mockRepository)],
        child: const MaterialApp(home: Scaffold(body: ProfessionalCollectionSummaryCard())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Could not load Professional Collection summary.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
