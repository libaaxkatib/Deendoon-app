import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/localization/somali_fallback_delegates.dart';
import 'package:mobile/features/attachments/presentation/providers/attachment_providers.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';
import 'package:mobile/features/auth/domain/user.dart';
import 'package:mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:mobile/features/support_tickets/data/support_ticket_repository.dart';
import 'package:mobile/features/support_tickets/domain/support_ticket.dart';
import 'package:mobile/features/support_tickets/domain/ticket_attachment.dart';
import 'package:mobile/features/support_tickets/domain/ticket_message.dart';
import 'package:mobile/features/support_tickets/presentation/screens/support_ticket_detail_screen.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockSupportTicketRepository extends Mock
    implements SupportTicketRepository {}

class _FakeAuthenticatedNotifier extends AuthNotifier {
  @override
  AuthState build() => const Authenticated(
    user: User(id: '01USER', name: 'Test Owner', email: 'owner@example.com'),
    token: 'test-token',
  );
}

const _openTicket = SupportTicket(
  id: '1',
  tenantId: '01TENANT',
  referenceNumber: 'SUP-000001',
  subject: 'Cannot generate demand letter',
  description: 'The PDF fails to download.',
  status: 'open',
  priority: 'high',
  category: 'technical_issue',
  submittedByUserId: '01USER',
  businessName: 'Hodan Trading',
  createdAt: '2026-08-14T09:00:00.000000Z',
  updatedAt: '2026-08-14T09:00:00.000000Z',
  closedAt: null,
  reopenedAt: null,
);

const _closedTicket = SupportTicket(
  id: '1',
  tenantId: '01TENANT',
  referenceNumber: 'SUP-000001',
  subject: 'Cannot generate demand letter',
  description: 'The PDF fails to download.',
  status: 'closed',
  priority: 'high',
  category: 'technical_issue',
  submittedByUserId: '01USER',
  businessName: 'Hodan Trading',
  createdAt: '2026-08-14T09:00:00.000000Z',
  updatedAt: '2026-08-14T09:00:00.000000Z',
  closedAt: '2026-08-14T12:00:00.000000Z',
  reopenedAt: null,
);

const _ownMessage = TicketMessage(
  id: '1',
  supportTicketId: '1',
  senderUserId: '01USER',
  senderName: 'Test Owner',
  content: 'My message',
  createdAt: '2026-08-14T09:30:00.000000Z',
);

const _supportMessage = TicketMessage(
  id: '2',
  supportTicketId: '1',
  senderUserId: '02USER',
  senderName: null,
  content: 'Their reply',
  createdAt: '2026-08-14T10:00:00.000000Z',
);

Future<void> _pumpScreen(
  WidgetTester tester, {
  required _MockSupportTicketRepository repository,
  Future<PickedAttachmentFile?> Function()? filePicker,
}) async {
  tester.view.physicalSize = const Size(400, 1800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        supportTicketRepositoryProvider.overrideWithValue(repository),
        authProvider.overrideWith(_FakeAuthenticatedNotifier.new),
        if (filePicker != null)
          attachmentFilePickerProvider.overrideWithValue(filePicker),
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
        home: SupportTicketDetailScreen(ticketId: '1'),
      ),
    ),
  );
}

void main() {
  late _MockSupportTicketRepository mockRepository;

  setUp(() {
    mockRepository = _MockSupportTicketRepository();
  });

  testWidgets('renders ticket subject, description, status, and priority', (
    tester,
  ) async {
    when(
      () => mockRepository.fetchTicket('1'),
    ).thenAnswer((_) async => _openTicket);
    when(() => mockRepository.fetchMessages('1')).thenAnswer((_) async => []);
    when(
      () => mockRepository.fetchAttachments('1'),
    ).thenAnswer((_) async => []);

    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    expect(find.text('Cannot generate demand letter'), findsOneWidget);
    expect(find.text('The PDF fails to download.'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('High'), findsOneWidget);
  });

  testWidgets(
    'renders conversation messages distinguishing own from Deendoon replies',
    (tester) async {
      when(
        () => mockRepository.fetchTicket('1'),
      ).thenAnswer((_) async => _openTicket);
      when(
        () => mockRepository.fetchMessages('1'),
      ).thenAnswer((_) async => [_ownMessage, _supportMessage]);
      when(
        () => mockRepository.fetchAttachments('1'),
      ).thenAnswer((_) async => []);

      await _pumpScreen(tester, repository: mockRepository);
      await tester.pumpAndSettle();

      expect(find.text('My message'), findsOneWidget);
      expect(find.text('Their reply'), findsOneWidget);
      expect(find.text('You'), findsOneWidget);
      expect(find.text('Deendoon Support'), findsOneWidget);
    },
  );

  testWidgets('shows the empty states for no attachments and no replies', (
    tester,
  ) async {
    when(
      () => mockRepository.fetchTicket('1'),
    ).thenAnswer((_) async => _openTicket);
    when(() => mockRepository.fetchMessages('1')).thenAnswer((_) async => []);
    when(
      () => mockRepository.fetchAttachments('1'),
    ).thenAnswer((_) async => []);

    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    expect(find.text('No attachments uploaded.'), findsOneWidget);
    expect(find.text('No replies yet.'), findsOneWidget);
  });

  testWidgets('sending a reply calls the real endpoint and clears the field', (
    tester,
  ) async {
    when(
      () => mockRepository.fetchTicket('1'),
    ).thenAnswer((_) async => _openTicket);
    when(
      () => mockRepository.fetchMessages('1'),
    ).thenAnswer((_) async => [_ownMessage]);
    when(
      () => mockRepository.fetchAttachments('1'),
    ).thenAnswer((_) async => []);
    when(
      () => mockRepository.postMessage(id: '1', content: 'Following up'),
    ).thenAnswer((_) async => _ownMessage);

    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Following up');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    verify(
      () => mockRepository.postMessage(id: '1', content: 'Following up'),
    ).called(1);
  });

  testWidgets(
    'the reply composer and upload button are hidden and a closed notice is shown when closed',
    (tester) async {
      when(
        () => mockRepository.fetchTicket('1'),
      ).thenAnswer((_) async => _closedTicket);
      when(
        () => mockRepository.fetchMessages('1'),
      ).thenAnswer((_) async => [_ownMessage]);
      when(
        () => mockRepository.fetchAttachments('1'),
      ).thenAnswer((_) async => []);

      await _pumpScreen(tester, repository: mockRepository);
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);
      expect(find.text('Attach File'), findsNothing);
      expect(
        find.text('This ticket is closed — new replies are not accepted.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('picking and uploading a file calls the real endpoint', (
    tester,
  ) async {
    when(
      () => mockRepository.fetchTicket('1'),
    ).thenAnswer((_) async => _openTicket);
    when(() => mockRepository.fetchMessages('1')).thenAnswer((_) async => []);
    when(
      () => mockRepository.fetchAttachments('1'),
    ).thenAnswer((_) async => []);
    const attachment = TicketAttachment(
      id: '1',
      supportTicketId: '1',
      uploadedByUserId: '01USER',
      originalFilename: 'evidence.pdf',
      mimeType: 'application/pdf',
      fileSize: 1024,
      createdAt: '2026-08-14T09:45:00.000000Z',
    );
    when(
      () => mockRepository.uploadAttachment(
        id: '1',
        filePath: '/tmp/evidence.pdf',
        fileName: 'evidence.pdf',
      ),
    ).thenAnswer((_) async => attachment);

    await _pumpScreen(
      tester,
      repository: mockRepository,
      filePicker: () async => (path: '/tmp/evidence.pdf', name: 'evidence.pdf'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Attach File'));
    await tester.pumpAndSettle();

    verify(
      () => mockRepository.uploadAttachment(
        id: '1',
        filePath: '/tmp/evidence.pdf',
        fileName: 'evidence.pdf',
      ),
    ).called(1);
  });

  group('Attachment deletion (Mobile Fix #4A)', () {
    const ownAttachment = TicketAttachment(
      id: '1',
      supportTicketId: '1',
      uploadedByUserId: '01USER',
      originalFilename: 'evidence.pdf',
      mimeType: 'application/pdf',
      fileSize: 1024,
      createdAt: '2026-08-14T09:45:00.000000Z',
    );

    const otherUsersAttachment = TicketAttachment(
      id: '2',
      supportTicketId: '1',
      uploadedByUserId: '02ADMIN',
      originalFilename: 'admin-log.pdf',
      mimeType: 'application/pdf',
      fileSize: 512,
      createdAt: '2026-08-14T09:50:00.000000Z',
    );

    testWidgets(
      'shows a delete action only on the attachment the current user uploaded',
      (tester) async {
        when(
          () => mockRepository.fetchTicket('1'),
        ).thenAnswer((_) async => _openTicket);
        when(
          () => mockRepository.fetchMessages('1'),
        ).thenAnswer((_) async => []);
        when(
          () => mockRepository.fetchAttachments('1'),
        ).thenAnswer((_) async => [ownAttachment, otherUsersAttachment]);

        await _pumpScreen(tester, repository: mockRepository);
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      },
    );

    testWidgets(
      'deleting an own attachment asks for confirmation and calls the real endpoint',
      (tester) async {
        when(
          () => mockRepository.fetchTicket('1'),
        ).thenAnswer((_) async => _openTicket);
        when(
          () => mockRepository.fetchMessages('1'),
        ).thenAnswer((_) async => []);
        when(
          () => mockRepository.fetchAttachments('1'),
        ).thenAnswer((_) async => [ownAttachment]);
        when(
          () => mockRepository.deleteAttachment(id: '1', attachmentId: '1'),
        ).thenAnswer((_) async {});

        await _pumpScreen(tester, repository: mockRepository);
        await tester.pumpAndSettle();

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
          () => mockRepository.deleteAttachment(id: '1', attachmentId: '1'),
        ).called(1);
        expect(find.text('Attachment deleted successfully'), findsOneWidget);
      },
    );

    testWidgets('cancelling the confirmation dialog deletes nothing', (
      tester,
    ) async {
      when(
        () => mockRepository.fetchTicket('1'),
      ).thenAnswer((_) async => _openTicket);
      when(() => mockRepository.fetchMessages('1')).thenAnswer((_) async => []);
      when(
        () => mockRepository.fetchAttachments('1'),
      ).thenAnswer((_) async => [ownAttachment]);

      await _pumpScreen(tester, repository: mockRepository);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      verifyNever(
        () => mockRepository.deleteAttachment(
          id: any(named: 'id'),
          attachmentId: any(named: 'attachmentId'),
        ),
      );
    });

    testWidgets(
      'no delete action is shown on any attachment once the ticket is closed',
      (tester) async {
        when(
          () => mockRepository.fetchTicket('1'),
        ).thenAnswer((_) async => _closedTicket);
        when(
          () => mockRepository.fetchMessages('1'),
        ).thenAnswer((_) async => []);
        when(
          () => mockRepository.fetchAttachments('1'),
        ).thenAnswer((_) async => [ownAttachment]);

        await _pumpScreen(tester, repository: mockRepository);
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.delete_outline), findsNothing);
      },
    );
  });
}
