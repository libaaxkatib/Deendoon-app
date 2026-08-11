import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/localization/somali_fallback_delegates.dart';
import 'package:mobile/features/professional_collection/data/professional_collection_repository.dart';
import 'package:mobile/features/professional_collection/domain/professional_collection_request.dart';
import 'package:mobile/features/professional_collection/presentation/screens/professional_collection_detail_screen.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockProfessionalCollectionRepository extends Mock implements ProfessionalCollectionRepository {}

const _request = ProfessionalCollectionRequest(
  id: '1',
  collectionCaseId: '01CASE',
  referenceNumber: 'PCR-0001',
  status: 'accepted',
  submittedByUserId: '01USER',
  actionedByUserId: '02USER',
  reasons: ['Repeated missed promises', 'Customer unreachable'],
  notes: 'Customer stopped responding after the third follow-up.',
  requestedServices: ['Field Visit', 'Legal Notice'],
  declarationAcceptedAt: '2026-08-01T00:00:00.000000Z',
  declarationAcceptedBy: '01USER',
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
      GoRoute(path: '/professional-requests/:id/documents', builder: (_, _) => const Text('Documents Screen')),
      GoRoute(path: '/professional-requests/:id/attachments', builder: (_, _) => const Text('Attachments Screen')),
      GoRoute(path: '/professional-requests/:id/timeline', builder: (_, _) => const Text('Timeline Screen')),
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

  testWidgets('renders request summary with real fields', (tester) async {
    when(() => mockRepository.fetchRequest('1')).thenAnswer((_) async => _request);

    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    expect(find.text('PCR-0001'), findsWidgets); // AppBar title + summary card
    expect(find.text('Accepted'), findsOneWidget);
    expect(find.text('01USER'), findsWidgets); // Submitted By + Declaration Accepted By
    expect(find.text('02USER'), findsOneWidget);
  });

  testWidgets('renders reasons, requested services, notes, and declaration record from real data', (tester) async {
    when(() => mockRepository.fetchRequest('1')).thenAnswer((_) async => _request);

    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    expect(find.text('Repeated missed promises'), findsOneWidget);
    expect(find.text('Customer unreachable'), findsOneWidget);
    expect(find.text('Field Visit'), findsOneWidget);
    expect(find.text('Legal Notice'), findsOneWidget);
    expect(find.text('Customer stopped responding after the third follow-up.'), findsOneWidget);
    expect(find.text('Declaration Accepted'), findsOneWidget);
    expect(find.text('Declaration Accepted By'), findsOneWidget);
  });

  testWidgets('shows honest empty states when reasons/services/notes are absent', (tester) async {
    const bareRequest = ProfessionalCollectionRequest(
      id: '1',
      collectionCaseId: '01CASE',
      referenceNumber: 'PCR-0002',
      status: 'submitted',
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
    when(() => mockRepository.fetchRequest('1')).thenAnswer((_) async => bareRequest);

    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    expect(find.text('No reasons recorded for this Request.'), findsOneWidget);
    expect(find.text('No requested services recorded for this Request.'), findsOneWidget);
    expect(find.text('No notes were added to this Request.'), findsOneWidget);
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

  testWidgets('Documents opens the real Documents screen', (tester) async {
    when(() => mockRepository.fetchRequest('1')).thenAnswer((_) async => _request);

    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Documents'));
    await tester.pumpAndSettle();

    expect(find.text('Documents Screen'), findsOneWidget);
  });

  testWidgets('Attachments opens the real Attachments screen', (tester) async {
    when(() => mockRepository.fetchRequest('1')).thenAnswer((_) async => _request);

    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Attachments'));
    await tester.pumpAndSettle();

    expect(find.text('Attachments Screen'), findsOneWidget);
  });

  testWidgets('View Timeline opens the real Timeline screen', (tester) async {
    when(() => mockRepository.fetchRequest('1')).thenAnswer((_) async => _request);

    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    await tester.tap(find.text('View Timeline'));
    await tester.pumpAndSettle();

    expect(find.text('Timeline Screen'), findsOneWidget);
  });
}
