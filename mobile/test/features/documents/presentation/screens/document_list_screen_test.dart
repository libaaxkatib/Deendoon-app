import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/localization/somali_fallback_delegates.dart';
import 'package:mobile/core/models/document_summary.dart';
import 'package:mobile/features/documents/data/document_repository.dart';
import 'package:mobile/features/documents/domain/document_page.dart';
import 'package:mobile/features/documents/presentation/screens/document_list_screen.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockDocumentRepository extends Mock implements DocumentRepository {}

const _document = DocumentSummary(
  id: '1',
  documentType: 'receipt',
  referenceNumber: 'RCT-000045',
  generatedAt: '2026-07-19T10:00:00.000000Z',
  fileSize: 1024,
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
          home: const DocumentListScreen(),
        ),
      ),
    );
  }

  testWidgets('renders the full document list', (tester) async {
    when(() => mockRepository.fetchDocuments(page: 1, type: null, search: ''))
        .thenAnswer((_) async => const DocumentPage(documents: [_document], currentPage: 1, lastPage: 1, total: 1));

    await pumpScreen(tester);
    await tester.pumpAndSettle();

    expect(find.text('RCT-000045.pdf'), findsOneWidget);
    expect(find.text('All Documents'), findsOneWidget);
  });

  testWidgets('shows the explicit empty state when there are no documents', (tester) async {
    when(() => mockRepository.fetchDocuments(page: 1, type: null, search: ''))
        .thenAnswer((_) async => const DocumentPage(documents: [], currentPage: 1, lastPage: 1, total: 0));

    await pumpScreen(tester);
    await tester.pumpAndSettle();

    expect(find.text('No documents yet'), findsOneWidget);
  });

  testWidgets('shows a retry affordance when the list fails to load', (tester) async {
    when(() => mockRepository.fetchDocuments(page: 1, type: null, search: '')).thenThrow(Exception('network down'));

    await pumpScreen(tester);
    await tester.pumpAndSettle();

    expect(find.text('Could not load documents.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
