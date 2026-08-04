import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/professional_collection/data/professional_collection_repository.dart';
import 'package:mobile/features/professional_collection/domain/professional_collection_request.dart';
import 'package:mobile/features/professional_collection/presentation/screens/professional_collection_detail_screen.dart';
import 'package:mocktail/mocktail.dart';

class _MockProfessionalCollectionRepository extends Mock implements ProfessionalCollectionRepository {}

const _request = ProfessionalCollectionRequest(
  id: '1',
  collectionCaseId: '01CASE',
  referenceNumber: 'PCR-0001',
  status: 'accepted',
  submittedByUserId: '01USER',
  actionedByUserId: '02USER',
  createdAt: '2026-08-01T00:00:00.000000Z',
  closedAt: null,
);

Future<void> _pumpScreen(WidgetTester tester, {required _MockProfessionalCollectionRepository repository}) async {
  tester.view.physicalSize = const Size(400, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const ProfessionalCollectionDetailScreen(requestId: '1')),
      GoRoute(path: '/cases/:id', builder: (_, state) => Text('Case Detail ${state.pathParameters['id']}')),
      GoRoute(path: '/professional-requests/:id/messages', builder: (_, _) => const Text('Messages Screen')),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [professionalCollectionRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
}

void main() {
  late _MockProfessionalCollectionRepository mockRepository;

  setUp(() {
    mockRepository = _MockProfessionalCollectionRepository();
  });

  testWidgets('renders request summary with real fields', (tester) async {
    when(() => mockRepository.fetchRequest('1')).thenAnswer((_) async => _request);

    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    expect(find.text('PCR-0001'), findsWidgets); // AppBar title + summary card
    expect(find.text('Accepted'), findsOneWidget);
    expect(find.text('01USER'), findsOneWidget);
    expect(find.text('02USER'), findsOneWidget);
  });

  testWidgets('shows a retry affordance when the request fails to load', (tester) async {
    when(() => mockRepository.fetchRequest('1')).thenThrow(Exception('network down'));

    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    expect(find.text('Could not load this Professional Collection Request.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('View Collection Case opens the real Case Detail screen', (tester) async {
    when(() => mockRepository.fetchRequest('1')).thenAnswer((_) async => _request);

    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    await tester.tap(find.text('View Collection Case'));
    await tester.pumpAndSettle();

    expect(find.text('Case Detail 01CASE'), findsOneWidget);
  });

  testWidgets('View Messages opens the real Messages screen', (tester) async {
    when(() => mockRepository.fetchRequest('1')).thenAnswer((_) async => _request);

    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    await tester.tap(find.text('View Messages'));
    await tester.pumpAndSettle();

    expect(find.text('Messages Screen'), findsOneWidget);
  });
}
