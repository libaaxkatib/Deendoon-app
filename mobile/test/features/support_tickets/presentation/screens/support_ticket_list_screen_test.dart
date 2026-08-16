import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/localization/somali_fallback_delegates.dart';
import 'package:mobile/features/support_tickets/data/support_ticket_repository.dart';
import 'package:mobile/features/support_tickets/domain/support_ticket.dart';
import 'package:mobile/features/support_tickets/domain/support_ticket_page.dart';
import 'package:mobile/features/support_tickets/presentation/screens/support_ticket_list_screen.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockSupportTicketRepository extends Mock
    implements SupportTicketRepository {}

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

Future<void> _pumpScreen(
  WidgetTester tester, {
  required _MockSupportTicketRepository repository,
}) async {
  tester.view.physicalSize = const Size(400, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        supportTicketRepositoryProvider.overrideWithValue(repository),
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
        home: SupportTicketListScreen(),
      ),
    ),
  );
}

void main() {
  late _MockSupportTicketRepository mockRepository;

  setUp(() {
    mockRepository = _MockSupportTicketRepository();
  });

  testWidgets('shows the explicit empty state when there are no tickets', (
    tester,
  ) async {
    when(() => mockRepository.fetchTickets(page: 1, status: null)).thenAnswer(
      (_) async => const SupportTicketPage(
        tickets: [],
        currentPage: 1,
        lastPage: 1,
        total: 0,
      ),
    );

    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    expect(find.text('No tickets yet.'), findsOneWidget);
  });

  testWidgets('renders a ticket card with reference, subject, and status', (
    tester,
  ) async {
    when(() => mockRepository.fetchTickets(page: 1, status: null)).thenAnswer(
      (_) async => const SupportTicketPage(
        tickets: [_openTicket],
        currentPage: 1,
        lastPage: 1,
        total: 1,
      ),
    );

    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    expect(find.text('SUP-000001'), findsOneWidget);
    expect(find.text('Cannot generate demand letter'), findsOneWidget);
    // "Open" also appears as the first status filter chip — the card's own
    // status badge is the second occurrence.
    expect(find.text('Open'), findsNWidgets(2));
    expect(find.text('High'), findsOneWidget);
  });

  testWidgets(
    'shows the Contact Deendoon Support card with all three contact buttons',
    (tester) async {
      when(() => mockRepository.fetchTickets(page: 1, status: null)).thenAnswer(
        (_) async => const SupportTicketPage(
          tickets: [],
          currentPage: 1,
          lastPage: 1,
          total: 0,
        ),
      );

      await _pumpScreen(tester, repository: mockRepository);
      await tester.pumpAndSettle();

      expect(find.text('Contact Deendoon Support'), findsOneWidget);
      expect(find.text('Phone'), findsOneWidget);
      expect(find.text('WhatsApp'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
    },
  );

  testWidgets('selecting a status filter chip re-fetches with that status', (
    tester,
  ) async {
    when(() => mockRepository.fetchTickets(page: 1, status: null)).thenAnswer(
      (_) async => const SupportTicketPage(
        tickets: [_openTicket],
        currentPage: 1,
        lastPage: 1,
        total: 1,
      ),
    );
    when(
      () => mockRepository.fetchTickets(page: 1, status: 'in_progress'),
    ).thenAnswer(
      (_) async => const SupportTicketPage(
        tickets: [],
        currentPage: 1,
        lastPage: 1,
        total: 0,
      ),
    );

    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    // "In Progress" is the third filter chip, within the default cache
    // extent of the horizontally-scrolling ListView — unlike "Closed",
    // it doesn't need an explicit scroll-into-view first.
    await tester.tap(find.text('In Progress'));
    await tester.pumpAndSettle();

    verify(
      () => mockRepository.fetchTickets(page: 1, status: 'in_progress'),
    ).called(1);
    expect(find.text('No tickets match this status.'), findsOneWidget);
  });
}
