import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/localization/somali_fallback_delegates.dart';
import 'package:mobile/core/models/document_summary.dart';
import 'package:mobile/features/documents/data/document_repository.dart';
import 'package:mobile/features/documents/domain/document_page.dart';
import 'package:mobile/features/documents/domain/storage_usage.dart';
import 'package:mobile/features/documents/presentation/screens/documents_home_screen.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockDocumentRepository extends Mock implements DocumentRepository {}

const _usage = StorageUsage(
  usedBytes: 5242880,
  totalBytes: 10737418240,
  usedPercentage: 0.05,
);

const _document = DocumentSummary(
  id: '1',
  documentType: 'invoice',
  referenceNumber: 'INV-000123',
  generatedAt: '2026-07-20T10:00:00.000000Z',
  fileSize: 2048,
);

Future<void> _pumpScreen(
  WidgetTester tester, {
  required _MockDocumentRepository repository,
}) async {
  tester.view.physicalSize = const Size(400, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [documentRepositoryProvider.overrideWithValue(repository)],
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
        home: const DocumentsHomeScreen(),
      ),
    ),
  );
}

void main() {
  late _MockDocumentRepository mockRepository;

  setUp(() {
    mockRepository = _MockDocumentRepository();
    when(
      () => mockRepository.fetchStorageUsage(),
    ).thenAnswer((_) async => _usage);
  });

  testWidgets('renders recent documents and the storage usage card', (
    tester,
  ) async {
    when(
      () => mockRepository.fetchDocuments(page: 1, type: null, search: ''),
    ).thenAnswer(
      (_) async => const DocumentPage(
        documents: [_document],
        currentPage: 1,
        lastPage: 1,
        total: 1,
      ),
    );

    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    expect(find.text('INV-000123.pdf'), findsOneWidget);
    expect(find.textContaining('of'), findsOneWidget);
    expect(find.textContaining('used'), findsOneWidget);
  });

  testWidgets('shows the explicit empty state when there are no documents', (
    tester,
  ) async {
    when(
      () => mockRepository.fetchDocuments(page: 1, type: null, search: ''),
    ).thenAnswer(
      (_) async => const DocumentPage(
        documents: [],
        currentPage: 1,
        lastPage: 1,
        total: 0,
      ),
    );

    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    expect(find.text('No documents yet'), findsOneWidget);
  });

  testWidgets('shows a retry affordance when the list fails to load', (
    tester,
  ) async {
    when(
      () => mockRepository.fetchDocuments(page: 1, type: null, search: ''),
    ).thenThrow(Exception('network down'));

    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    expect(find.text('Could not load documents.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets(
    'tapping a tab filter chip triggers a real API call with that type',
    (tester) async {
      when(
        () => mockRepository.fetchDocuments(page: 1, type: null, search: ''),
      ).thenAnswer(
        (_) async => const DocumentPage(
          documents: [_document],
          currentPage: 1,
          lastPage: 1,
          total: 1,
        ),
      );
      when(
        () => mockRepository.fetchDocuments(
          page: 1,
          type: 'invoices',
          search: '',
        ),
      ).thenAnswer(
        (_) async => const DocumentPage(
          documents: [_document],
          currentPage: 1,
          lastPage: 1,
          total: 1,
        ),
      );

      await _pumpScreen(tester, repository: mockRepository);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ChoiceChip, 'Invoices'));
      await tester.pumpAndSettle();

      verify(
        () => mockRepository.fetchDocuments(
          page: 1,
          type: 'invoices',
          search: '',
        ),
      ).called(1);
    },
  );

  testWidgets(
    'typing in the search field triggers a real API call with the query',
    (tester) async {
      when(
        () => mockRepository.fetchDocuments(page: 1, type: null, search: ''),
      ).thenAnswer(
        (_) async => const DocumentPage(
          documents: [_document],
          currentPage: 1,
          lastPage: 1,
          total: 1,
        ),
      );
      when(
        () => mockRepository.fetchDocuments(
          page: 1,
          type: null,
          search: 'INV-000123',
        ),
      ).thenAnswer(
        (_) async => const DocumentPage(
          documents: [_document],
          currentPage: 1,
          lastPage: 1,
          total: 1,
        ),
      );

      await _pumpScreen(tester, repository: mockRepository);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'INV-000123');
      await tester.pumpAndSettle();

      verify(
        () => mockRepository.fetchDocuments(
          page: 1,
          type: null,
          search: 'INV-000123',
        ),
      ).called(1);
    },
  );
}
