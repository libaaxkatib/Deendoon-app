import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';
import 'package:mobile/features/auth/domain/user.dart';
import 'package:mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:mobile/features/professional_collection/data/professional_collection_repository.dart';
import 'package:mobile/features/professional_collection/domain/professional_collection_request.dart';
import 'package:mobile/features/professional_collection/domain/request_message.dart';
import 'package:mobile/features/professional_collection/presentation/screens/professional_collection_messages_screen.dart';
import 'package:mocktail/mocktail.dart';

class _MockProfessionalCollectionRepository extends Mock implements ProfessionalCollectionRepository {}

class _FakeAuthenticatedNotifier extends AuthNotifier {
  @override
  AuthState build() => const Authenticated(
        user: User(id: '01USER', name: 'Test Owner', email: 'owner@example.com'),
        token: 'test-token',
      );
}

const _activeRequest = ProfessionalCollectionRequest(
  id: '1',
  collectionCaseId: '01CASE',
  referenceNumber: 'PCR-0001',
  status: 'in_progress',
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

const _closedRequest = ProfessionalCollectionRequest(
  id: '1',
  collectionCaseId: '01CASE',
  referenceNumber: 'PCR-0001',
  status: 'closed',
  submittedByUserId: '01USER',
  actionedByUserId: '02USER',
  reasons: [],
  notes: null,
  requestedServices: [],
  declarationAcceptedAt: null,
  declarationAcceptedBy: null,
  createdAt: '2026-08-01T00:00:00.000000Z',
  closedAt: '2026-08-05T00:00:00.000000Z',
);

const _ownMessage = RequestMessage(
  id: '1',
  professionalCollectionRequestId: '1',
  senderUserId: '01USER',
  content: 'My message',
  createdAt: '2026-08-01T00:00:00.000000Z',
);

const _teamMessage = RequestMessage(
  id: '2',
  professionalCollectionRequestId: '1',
  senderUserId: '02USER',
  content: 'Their message',
  createdAt: '2026-08-01T01:00:00.000000Z',
);

Future<void> _pumpScreen(WidgetTester tester, {required _MockProfessionalCollectionRepository repository}) async {
  tester.view.physicalSize = const Size(400, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        professionalCollectionRepositoryProvider.overrideWithValue(repository),
        authProvider.overrideWith(_FakeAuthenticatedNotifier.new),
      ],
      child: const MaterialApp(home: ProfessionalCollectionMessagesScreen(requestId: '1')),
    ),
  );
}

void main() {
  late _MockProfessionalCollectionRepository mockRepository;

  setUp(() {
    mockRepository = _MockProfessionalCollectionRepository();
  });

  testWidgets('renders messages with the sender label distinguishing Business Owner from Deendoon Team', (tester) async {
    when(() => mockRepository.fetchRequest('1')).thenAnswer((_) async => _activeRequest);
    when(() => mockRepository.fetchMessages('1')).thenAnswer((_) async => [_ownMessage, _teamMessage]);

    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    expect(find.text('My message'), findsOneWidget);
    expect(find.text('Their message'), findsOneWidget);
    expect(find.text('You'), findsOneWidget);
    expect(find.text('Deendoon Team'), findsOneWidget);
  });

  testWidgets('own messages are right-aligned and team messages are left-aligned', (tester) async {
    when(() => mockRepository.fetchRequest('1')).thenAnswer((_) async => _activeRequest);
    when(() => mockRepository.fetchMessages('1')).thenAnswer((_) async => [_ownMessage, _teamMessage]);

    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    final rows = tester.widgetList<Row>(find.byType(Row)).where(
          (row) => row.mainAxisAlignment == MainAxisAlignment.end || row.mainAxisAlignment == MainAxisAlignment.start,
        );
    expect(rows.any((row) => row.mainAxisAlignment == MainAxisAlignment.end), isTrue);
    expect(rows.any((row) => row.mainAxisAlignment == MainAxisAlignment.start), isTrue);
  });

  testWidgets('shows the explicit empty state when there are no messages', (tester) async {
    when(() => mockRepository.fetchRequest('1')).thenAnswer((_) async => _activeRequest);
    when(() => mockRepository.fetchMessages('1')).thenAnswer((_) async => []);

    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    expect(find.text('No messages yet'), findsOneWidget);
  });

  testWidgets('sending a message calls the real endpoint and clears the field', (tester) async {
    when(() => mockRepository.fetchRequest('1')).thenAnswer((_) async => _activeRequest);
    when(() => mockRepository.fetchMessages('1')).thenAnswer((_) async => [_ownMessage]);
    when(() => mockRepository.postMessage(id: '1', content: 'New message')).thenAnswer((_) async => _ownMessage);

    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'New message');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    verify(() => mockRepository.postMessage(id: '1', content: 'New message')).called(1);
  });

  testWidgets('the composer is hidden and a closed notice is shown when the request is terminal', (tester) async {
    when(() => mockRepository.fetchRequest('1')).thenAnswer((_) async => _closedRequest);
    when(() => mockRepository.fetchMessages('1')).thenAnswer((_) async => [_ownMessage]);

    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing);
    expect(
      find.text('This Professional Collection Request is closed — new messages are not accepted.'),
      findsOneWidget,
    );
  });
}
