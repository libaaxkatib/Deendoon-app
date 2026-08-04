import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/models/document_summary.dart';
import 'package:mobile/features/customers/data/customer_repository.dart';
import 'package:mobile/features/customers/presentation/screens/customer_documents_screen.dart';
import 'package:mocktail/mocktail.dart';

class _MockCustomerRepository extends Mock implements CustomerRepository {}

const _document = DocumentSummary(
  id: '1',
  documentType: 'invoice',
  referenceNumber: 'INV-0001',
  generatedAt: '2026-07-01T00:00:00.000000Z',
  fileSize: 1024,
);

Future<void> _pumpScreen(WidgetTester tester, {required _MockCustomerRepository repository}) async {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const CustomerDocumentsScreen(customerId: '1')),
      GoRoute(path: '/documents/:id', builder: (_, state) => Text('Document Preview ${state.pathParameters['id']}')),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [customerRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
}

void main() {
  late _MockCustomerRepository mockRepository;

  setUp(() {
    mockRepository = _MockCustomerRepository();
  });

  testWidgets('renders the customer-scoped document list', (tester) async {
    when(() => mockRepository.fetchDocuments('1')).thenAnswer((_) async => [_document]);

    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    expect(find.text('INV-0001'), findsOneWidget);
    expect(find.text('Invoice'), findsOneWidget);
  });

  testWidgets('shows the explicit empty state when there are no documents', (tester) async {
    when(() => mockRepository.fetchDocuments('1')).thenAnswer((_) async => []);

    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    expect(find.text('No documents yet'), findsOneWidget);
  });

  testWidgets('shows a retry affordance when the list fails to load', (tester) async {
    when(() => mockRepository.fetchDocuments('1')).thenThrow(Exception('network down'));

    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    expect(find.text('Could not load documents.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('tapping a document opens the real Document Preview screen', (tester) async {
    when(() => mockRepository.fetchDocuments('1')).thenAnswer((_) async => [_document]);

    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    await tester.tap(find.text('INV-0001'));
    await tester.pumpAndSettle();

    expect(find.text('Document Preview 1'), findsOneWidget);
  });
}
