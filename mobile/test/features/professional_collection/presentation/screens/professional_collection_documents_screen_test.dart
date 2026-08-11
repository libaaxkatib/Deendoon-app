import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/localization/somali_fallback_delegates.dart';
import 'package:mobile/core/models/document_summary.dart';
import 'package:mobile/features/professional_collection/data/professional_collection_repository.dart';
import 'package:mobile/features/professional_collection/presentation/screens/professional_collection_documents_screen.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockProfessionalCollectionRepository extends Mock implements ProfessionalCollectionRepository {}

void main() {
  late _MockProfessionalCollectionRepository mockRepository;

  setUp(() {
    mockRepository = _MockProfessionalCollectionRepository();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [professionalCollectionRepositoryProvider.overrideWithValue(mockRepository)],
        child: const MaterialApp(
          locale: Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            SomaliMaterialLocalizationsDelegate(),
            SomaliCupertinoLocalizationsDelegate(),
          ],
          home: ProfessionalCollectionDocumentsScreen(requestId: '1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders the linked documents with real fields', (tester) async {
    when(() => mockRepository.fetchDocuments('1')).thenAnswer((_) async => const [
          DocumentSummary(
            id: '1',
            documentType: 'receipt',
            referenceNumber: 'RCT-0001',
            generatedAt: '2026-08-01T00:00:00.000000Z',
            fileSize: 2000,
          ),
        ]);

    await pumpScreen(tester);

    expect(find.text('RCT-0001'), findsOneWidget);
    expect(find.text('Receipt'), findsOneWidget);
  });

  testWidgets('shows the explicit empty state when nothing is linked yet', (tester) async {
    when(() => mockRepository.fetchDocuments('1')).thenAnswer((_) async => []);

    await pumpScreen(tester);

    expect(find.text('No documents linked to this Request yet'), findsOneWidget);
  });

  testWidgets('shows a retry affordance when the fetch fails', (tester) async {
    when(() => mockRepository.fetchDocuments('1')).thenThrow(Exception('network down'));

    await pumpScreen(tester);

    expect(find.text('Could not load documents.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
