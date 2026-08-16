import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/localization/somali_fallback_delegates.dart';
import 'package:mobile/features/support_tickets/data/support_ticket_repository.dart';
import 'package:mobile/features/support_tickets/domain/support_ticket.dart';
import 'package:mobile/features/support_tickets/presentation/screens/support_ticket_create_screen.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockSupportTicketRepository extends Mock
    implements SupportTicketRepository {}

const _createdTicket = SupportTicket(
  id: '1',
  tenantId: '01TENANT',
  referenceNumber: 'SUP-000001',
  subject: 'Cannot generate demand letter',
  description: 'The PDF fails to download.',
  status: 'open',
  priority: 'medium',
  category: 'technical_issue',
  submittedByUserId: '01USER',
  businessName: 'Hodan Trading',
  createdAt: '2026-08-14T09:00:00.000000Z',
  updatedAt: '2026-08-14T09:00:00.000000Z',
  closedAt: null,
  reopenedAt: null,
);

Future<GoRouter> _pumpScreen(
  WidgetTester tester, {
  required _MockSupportTicketRepository repository,
}) async {
  tester.view.physicalSize = const Size(400, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    initialLocation: '/support/tickets/new',
    routes: [
      GoRoute(
        path: '/support/tickets/new',
        builder: (_, _) => const SupportTicketCreateScreen(),
      ),
      GoRoute(
        path: '/support/tickets/:id',
        builder: (_, state) =>
            Scaffold(body: Text('Ticket ${state.pathParameters['id']}')),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        supportTicketRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp.router(
        routerConfig: router,
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
      ),
    ),
  );
  return router;
}

void main() {
  late _MockSupportTicketRepository mockRepository;

  setUp(() {
    mockRepository = _MockSupportTicketRepository();
  });

  testWidgets(
    'submitting without subject/description shows a validation error',
    (tester) async {
      await _pumpScreen(tester, repository: mockRepository);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Submit Ticket'));
      await tester.pumpAndSettle();

      expect(
        find.text('Please fill in the subject and description.'),
        findsOneWidget,
      );
      verifyNever(
        () => mockRepository.createTicket(
          subject: any(named: 'subject'),
          description: any(named: 'description'),
          priority: any(named: 'priority'),
          category: any(named: 'category'),
        ),
      );
    },
  );

  testWidgets(
    'submitting a valid form calls the real endpoint and navigates to the new ticket',
    (tester) async {
      when(
        () => mockRepository.createTicket(
          subject: 'Cannot generate demand letter',
          description: 'The PDF fails to download.',
          priority: 'medium',
          category: 'technical_issue',
        ),
      ).thenAnswer((_) async => _createdTicket);

      await _pumpScreen(tester, repository: mockRepository);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField).first,
        'Cannot generate demand letter',
      );
      await tester.enterText(
        find.byType(TextField).last,
        'The PDF fails to download.',
      );
      await tester.tap(find.text('Submit Ticket'));
      await tester.pumpAndSettle();

      verify(
        () => mockRepository.createTicket(
          subject: 'Cannot generate demand letter',
          description: 'The PDF fails to download.',
          priority: 'medium',
          category: 'technical_issue',
        ),
      ).called(1);
      expect(find.text('Ticket 1'), findsOneWidget);
    },
  );
}
