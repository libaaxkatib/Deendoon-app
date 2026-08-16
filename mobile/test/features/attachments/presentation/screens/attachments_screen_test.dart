import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/localization/somali_fallback_delegates.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/features/attachments/data/attachment_repository.dart';
import 'package:mobile/features/attachments/domain/attachment.dart';
import 'package:mobile/features/attachments/presentation/providers/attachment_providers.dart';
import 'package:mobile/features/attachments/presentation/screens/attachments_screen.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';
import 'package:mobile/features/auth/domain/user.dart';
import 'package:mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockAttachmentRepository extends Mock implements AttachmentRepository {}

class _FakeAuthenticatedNotifier extends AuthNotifier {
  @override
  AuthState build() => const Authenticated(
    user: User(id: '01USER', name: 'Test Owner', email: 'owner@example.com'),
    token: 'test-token',
  );
}

const _attachment = Attachment(
  id: '1',
  entityId: '01CUST',
  uploadedByUserId: '01USER',
  originalFilename: 'id-card.pdf',
  mimeType: 'application/pdf',
  fileSize: 2000,
  description: 'ID card',
  createdAt: '2026-08-01T00:00:00.000000Z',
);

const _otherUsersAttachment = Attachment(
  id: '2',
  entityId: '01CUST',
  uploadedByUserId: '02OTHER',
  originalFilename: 'contract.pdf',
  mimeType: 'application/pdf',
  fileSize: 3000,
  description: null,
  createdAt: '2026-08-02T00:00:00.000000Z',
);

void main() {
  late _MockAttachmentRepository mockRepository;

  setUp(() {
    mockRepository = _MockAttachmentRepository();
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    bool canUpload = true,
    ({String path, String name})? pickedFile,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          attachmentRepositoryProvider.overrideWithValue(mockRepository),
          attachmentFilePickerProvider.overrideWithValue(
            () async => pickedFile,
          ),
          authProvider.overrideWith(_FakeAuthenticatedNotifier.new),
        ],
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
          home: AttachmentsScreen(
            entityPathPrefix: 'customers/01CUST',
            canUpload: canUpload,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders existing attachments with real fields', (tester) async {
    when(
      () => mockRepository.fetchAttachments('customers/01CUST'),
    ).thenAnswer((_) async => [_attachment]);

    await pumpScreen(tester);

    expect(find.text('id-card.pdf'), findsOneWidget);
    expect(find.text('ID card'), findsOneWidget);
  });

  testWidgets('shows the explicit empty state when there are none yet', (
    tester,
  ) async {
    when(
      () => mockRepository.fetchAttachments('customers/01CUST'),
    ).thenAnswer((_) async => []);

    await pumpScreen(tester);

    expect(find.text('No attachments yet'), findsOneWidget);
  });

  testWidgets('shows a retry affordance when the fetch fails', (tester) async {
    when(
      () => mockRepository.fetchAttachments('customers/01CUST'),
    ).thenThrow(Exception('network down'));

    await pumpScreen(tester);

    expect(find.text('Could not load attachments.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('offers upload when canUpload is true', (tester) async {
    when(
      () => mockRepository.fetchAttachments('customers/01CUST'),
    ).thenAnswer((_) async => []);

    await pumpScreen(tester);

    expect(
      find.widgetWithText(ElevatedButton, 'Upload Attachment'),
      findsOneWidget,
    );
  });

  testWidgets(
    'hides upload when canUpload is false (caller already knows it is blocked)',
    (tester) async {
      when(
        () => mockRepository.fetchAttachments('customers/01CUST'),
      ).thenAnswer((_) async => []);

      await pumpScreen(tester, canUpload: false);

      expect(
        find.widgetWithText(ElevatedButton, 'Upload Attachment'),
        findsNothing,
      );
    },
  );

  testWidgets('picking a file uploads it and refreshes the list', (
    tester,
  ) async {
    when(
      () => mockRepository.fetchAttachments('customers/01CUST'),
    ).thenAnswer((_) async => []);
    when(
      () => mockRepository.uploadAttachment(
        entityPathPrefix: 'customers/01CUST',
        filePath: '/tmp/id-card.pdf',
        fileName: 'id-card.pdf',
      ),
    ).thenAnswer((_) async => _attachment);

    await pumpScreen(
      tester,
      pickedFile: (path: '/tmp/id-card.pdf', name: 'id-card.pdf'),
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Upload Attachment'));
    await tester.pumpAndSettle();

    verify(
      () => mockRepository.uploadAttachment(
        entityPathPrefix: 'customers/01CUST',
        filePath: '/tmp/id-card.pdf',
        fileName: 'id-card.pdf',
      ),
    ).called(1);
  });

  testWidgets(
    'shows the exact backend error when upload fails (e.g. read-only)',
    (tester) async {
      when(
        () => mockRepository.fetchAttachments('customers/01CUST'),
      ).thenAnswer((_) async => []);
      when(
        () => mockRepository.uploadAttachment(
          entityPathPrefix: 'customers/01CUST',
          filePath: '/tmp/id-card.pdf',
          fileName: 'id-card.pdf',
        ),
      ).thenThrow(
        const ApiException(
          message: 'This action is unauthorized.',
          statusCode: 403,
        ),
      );

      await pumpScreen(
        tester,
        pickedFile: (path: '/tmp/id-card.pdf', name: 'id-card.pdf'),
      );

      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Upload Attachment'),
      );
      await tester.pumpAndSettle();

      expect(find.text('This action is unauthorized.'), findsOneWidget);
    },
  );

  testWidgets(
    'dismissing the file picker without a selection uploads nothing',
    (tester) async {
      when(
        () => mockRepository.fetchAttachments('customers/01CUST'),
      ).thenAnswer((_) async => []);

      await pumpScreen(tester, pickedFile: null);

      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Upload Attachment'),
      );
      await tester.pumpAndSettle();

      verifyNever(
        () => mockRepository.uploadAttachment(
          entityPathPrefix: any(named: 'entityPathPrefix'),
          filePath: any(named: 'filePath'),
          fileName: any(named: 'fileName'),
        ),
      );
    },
  );

  group('Attachment deletion (Mobile Fix #4A)', () {
    testWidgets(
      'shows a delete action only on the attachment the current user uploaded',
      (tester) async {
        when(
          () => mockRepository.fetchAttachments('customers/01CUST'),
        ).thenAnswer((_) async => [_attachment, _otherUsersAttachment]);

        await pumpScreen(tester);

        expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      },
    );

    testWidgets(
      'deleting an own attachment asks for confirmation and calls the real endpoint',
      (tester) async {
        when(
          () => mockRepository.fetchAttachments('customers/01CUST'),
        ).thenAnswer((_) async => [_attachment]);
        when(
          () => mockRepository.deleteAttachment('customers/01CUST', '1'),
        ).thenAnswer((_) async {});

        await pumpScreen(tester);

        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();

        expect(
          find.text(
            'This attachment will be permanently deleted. This cannot be undone.',
          ),
          findsOneWidget,
        );
        await tester.tap(find.widgetWithText(TextButton, 'Delete'));
        await tester.pumpAndSettle();

        verify(
          () => mockRepository.deleteAttachment('customers/01CUST', '1'),
        ).called(1);
        expect(find.text('Attachment deleted successfully'), findsOneWidget);
      },
    );

    testWidgets('cancelling the confirmation dialog deletes nothing', (
      tester,
    ) async {
      when(
        () => mockRepository.fetchAttachments('customers/01CUST'),
      ).thenAnswer((_) async => [_attachment]);

      await pumpScreen(tester);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      verifyNever(() => mockRepository.deleteAttachment(any(), any()));
    });

    testWidgets(
      'shows the exact backend error when delete is blocked (e.g. read-only/terminal)',
      (tester) async {
        when(
          () => mockRepository.fetchAttachments('customers/01CUST'),
        ).thenAnswer((_) async => [_attachment]);
        when(
          () => mockRepository.deleteAttachment('customers/01CUST', '1'),
        ).thenThrow(
          const ApiException(
            message: 'This action is unauthorized.',
            statusCode: 403,
          ),
        );

        await pumpScreen(tester);

        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(TextButton, 'Delete'));
        await tester.pumpAndSettle();

        expect(find.text('This action is unauthorized.'), findsOneWidget);
      },
    );
  });
}
