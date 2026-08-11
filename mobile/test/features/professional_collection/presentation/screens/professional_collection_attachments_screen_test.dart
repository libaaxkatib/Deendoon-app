import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/localization/somali_fallback_delegates.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/features/attachments/presentation/providers/attachment_providers.dart';
import 'package:mobile/features/professional_collection/data/professional_collection_repository.dart';
import 'package:mobile/features/professional_collection/domain/professional_collection_attachment.dart';
import 'package:mobile/features/professional_collection/domain/professional_collection_request.dart';
import 'package:mobile/features/professional_collection/presentation/screens/professional_collection_attachments_screen.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockProfessionalCollectionRepository extends Mock implements ProfessionalCollectionRepository {}

ProfessionalCollectionRequest _request({required String status}) => ProfessionalCollectionRequest(
      id: '1',
      collectionCaseId: '01CASE',
      referenceNumber: 'PCR-0001',
      status: status,
      submittedByUserId: '01USER',
      actionedByUserId: null,
      reasons: const ['Repeated missed promises'],
      notes: null,
      requestedServices: const ['Field Visit'],
      declarationAcceptedAt: '2026-08-01T00:00:00.000000Z',
      declarationAcceptedBy: '01USER',
      createdAt: '2026-08-01T00:00:00.000000Z',
      closedAt: null,
    );

void main() {
  late _MockProfessionalCollectionRepository mockRepository;

  setUp(() {
    mockRepository = _MockProfessionalCollectionRepository();
    when(() => mockRepository.fetchAttachments('1')).thenAnswer((_) async => []);
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    ({String path, String name})? pickedFile,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          professionalCollectionRepositoryProvider.overrideWithValue(mockRepository),
          attachmentFilePickerProvider.overrideWithValue(() async => pickedFile),
        ],
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
          home: ProfessionalCollectionAttachmentsScreen(requestId: '1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders existing attachments with real fields', (tester) async {
    when(() => mockRepository.fetchRequest('1')).thenAnswer((_) async => _request(status: 'submitted'));
    when(() => mockRepository.fetchAttachments('1')).thenAnswer((_) async => const [
          ProfessionalCollectionAttachment(
            id: '1',
            professionalCollectionRequestId: '1',
            timelineEventId: null,
            uploadedByUserId: '01USER',
            originalFilename: 'evidence.pdf',
            mimeType: 'application/pdf',
            fileSize: 1500,
            createdAt: '2026-08-01T00:00:00.000000Z',
          ),
        ]);

    await pumpScreen(tester);

    expect(find.text('evidence.pdf'), findsOneWidget);
  });

  testWidgets('offers upload when the Request is pre-Assigned (submitted)', (tester) async {
    when(() => mockRepository.fetchRequest('1')).thenAnswer((_) async => _request(status: 'submitted'));

    await pumpScreen(tester);

    expect(find.widgetWithText(ElevatedButton, 'Upload Attachment'), findsOneWidget);
  });

  testWidgets('hides upload once the Request is assigned to the recovery team', (tester) async {
    when(() => mockRepository.fetchRequest('1')).thenAnswer((_) async => _request(status: 'assigned'));

    await pumpScreen(tester);

    expect(find.widgetWithText(ElevatedButton, 'Upload Attachment'), findsNothing);
    expect(find.text('Uploading is not available at this stage of the Request.'), findsOneWidget);
  });

  testWidgets('hides upload once the Request is closed', (tester) async {
    when(() => mockRepository.fetchRequest('1')).thenAnswer((_) async => _request(status: 'closed'));

    await pumpScreen(tester);

    expect(find.widgetWithText(ElevatedButton, 'Upload Attachment'), findsNothing);
  });

  testWidgets('picking a file uploads it and refreshes the list', (tester) async {
    when(() => mockRepository.fetchRequest('1')).thenAnswer((_) async => _request(status: 'submitted'));
    when(() => mockRepository.uploadAttachment(id: '1', filePath: '/tmp/evidence.pdf', fileName: 'evidence.pdf'))
        .thenAnswer((_) async => const ProfessionalCollectionAttachment(
              id: '1',
              professionalCollectionRequestId: '1',
              timelineEventId: null,
              uploadedByUserId: '01USER',
              originalFilename: 'evidence.pdf',
              mimeType: 'application/pdf',
              fileSize: 1500,
              createdAt: '2026-08-01T00:00:00.000000Z',
            ));

    await pumpScreen(tester, pickedFile: (path: '/tmp/evidence.pdf', name: 'evidence.pdf'));

    await tester.tap(find.widgetWithText(ElevatedButton, 'Upload Attachment'));
    await tester.pumpAndSettle();

    verify(() => mockRepository.uploadAttachment(id: '1', filePath: '/tmp/evidence.pdf', fileName: 'evidence.pdf'))
        .called(1);
  });

  testWidgets('shows the exact backend error when upload fails', (tester) async {
    when(() => mockRepository.fetchRequest('1')).thenAnswer((_) async => _request(status: 'submitted'));
    when(() => mockRepository.uploadAttachment(id: '1', filePath: '/tmp/evidence.pdf', fileName: 'evidence.pdf'))
        .thenThrow(const ApiException(message: 'The file must be a file of type: pdf, jpg, jpeg, png, doc, docx.'));

    await pumpScreen(tester, pickedFile: (path: '/tmp/evidence.pdf', name: 'evidence.pdf'));

    await tester.tap(find.widgetWithText(ElevatedButton, 'Upload Attachment'));
    await tester.pumpAndSettle();

    expect(find.text('The file must be a file of type: pdf, jpg, jpeg, png, doc, docx.'), findsOneWidget);
  });
}
