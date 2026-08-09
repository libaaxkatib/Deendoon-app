import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/documents/data/document_repository.dart';
import 'package:mobile/features/documents/domain/document_event.dart';
import 'package:mobile/features/documents/presentation/screens/document_history_screen.dart';
import 'package:mocktail/mocktail.dart';

class _MockDocumentRepository extends Mock implements DocumentRepository {}

const _generatedEvent = DocumentEvent(
  id: '1',
  documentType: 'receipt',
  documentId: '01DOC',
  eventType: 'generated',
  userId: '01USER',
  occurredAt: '2026-07-19T10:00:00.000000Z',
);

const _downloadedEvent = DocumentEvent(
  id: '2',
  documentType: 'receipt',
  documentId: '01DOC',
  eventType: 'downloaded',
  userId: '01USER',
  occurredAt: '2026-07-20T14:30:00.000000Z',
);

void main() {
  late _MockDocumentRepository mockRepository;

  setUp(() {
    mockRepository = _MockDocumentRepository();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [documentRepositoryProvider.overrideWithValue(mockRepository)],
        child: const MaterialApp(home: DocumentHistoryScreen(documentId: '01DOC')),
      ),
    );
  }

  testWidgets('renders each real event with its actor, labeled action, and timestamp', (tester) async {
    when(() => mockRepository.fetchHistory('01DOC')).thenAnswer((_) async => [_generatedEvent, _downloadedEvent]);

    await pumpScreen(tester);
    await tester.pumpAndSettle();

    expect(find.text('Generated'), findsOneWidget);
    expect(find.text('Downloaded'), findsOneWidget);
    expect(find.text('User 01USER'), findsNWidgets(2));
  });

  testWidgets('shows the explicit empty state when there is no history yet', (tester) async {
    when(() => mockRepository.fetchHistory('01DOC')).thenAnswer((_) async => []);

    await pumpScreen(tester);
    await tester.pumpAndSettle();

    expect(find.text('No history yet'), findsOneWidget);
  });

  testWidgets('shows a retry affordance when history fails to load', (tester) async {
    when(() => mockRepository.fetchHistory('01DOC')).thenThrow(Exception('network down'));

    await pumpScreen(tester);
    await tester.pumpAndSettle();

    expect(find.text('Could not load this document\'s history.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
