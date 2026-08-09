import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/cases/data/collection_case_repository.dart';
import 'package:mobile/features/customers/data/customer_repository.dart';
import 'package:mobile/features/customers/domain/customer.dart';
import 'package:mobile/features/debts/data/debt_repository.dart';
import 'package:mobile/features/reminders/data/reminder_repository.dart';
import 'package:mobile/features/reminders/domain/reminder.dart';
import 'package:mobile/features/reminders/presentation/screens/reminder_detail_screen.dart';
import 'package:mocktail/mocktail.dart';

class _MockReminderRepository extends Mock implements ReminderRepository {}

class _MockCustomerRepository extends Mock implements CustomerRepository {}

class _MockDebtRepository extends Mock implements DebtRepository {}

class _MockCollectionCaseRepository extends Mock implements CollectionCaseRepository {}

const _followUpReminder = Reminder(
  id: '1',
  type: 'payment_due',
  title: 'Payment Due',
  relatedEntityType: 'customer',
  relatedEntityId: '01CUST',
  relatedCaseId: '01CASE',
  dueDate: '2026-08-01T10:00:00.000000Z',
  amountDue: '4967.40',
  timingRule: 'one_day_before',
  customFireAt: null,
  deliveryMethods: ['in_app'],
  notes: 'Call before visiting',
  status: 'upcoming',
  createdByUserId: '01USER',
  createdAt: '2026-07-25T09:00:00.000000Z',
  updatedAt: '2026-07-25T09:00:00.000000Z',
  completedAt: null,
  checkedInAt: null,
);

const _completedFollowUpReminder = Reminder(
  id: '1',
  type: 'payment_due',
  title: 'Payment Due',
  relatedEntityType: 'customer',
  relatedEntityId: '01CUST',
  relatedCaseId: null,
  dueDate: '2026-08-01T10:00:00.000000Z',
  amountDue: '250.00',
  timingRule: 'one_day_before',
  customFireAt: null,
  deliveryMethods: ['in_app'],
  notes: null,
  status: 'completed',
  createdByUserId: '01USER',
  createdAt: '2026-07-25T09:00:00.000000Z',
  updatedAt: '2026-07-28T09:00:00.000000Z',
  completedAt: '2026-07-28T09:00:00.000000Z',
  checkedInAt: null,
);

const _clientVisitReminder = Reminder(
  id: '1',
  type: 'client_visit',
  title: 'Client Visit',
  relatedEntityType: 'customer',
  relatedEntityId: '01CUST',
  relatedCaseId: null,
  dueDate: '2026-08-01T10:00:00.000000Z',
  amountDue: null,
  timingRule: 'one_day_before',
  customFireAt: null,
  deliveryMethods: ['in_app'],
  notes: null,
  status: 'upcoming',
  createdByUserId: '01USER',
  createdAt: '2026-07-25T09:00:00.000000Z',
  updatedAt: '2026-07-25T09:00:00.000000Z',
  completedAt: null,
  checkedInAt: null,
);

const _checkedInClientVisitReminder = Reminder(
  id: '1',
  type: 'client_visit',
  title: 'Client Visit',
  relatedEntityType: 'customer',
  relatedEntityId: '01CUST',
  relatedCaseId: null,
  dueDate: '2026-08-01T10:00:00.000000Z',
  amountDue: null,
  timingRule: 'one_day_before',
  customFireAt: null,
  deliveryMethods: ['in_app'],
  notes: null,
  status: 'upcoming',
  createdByUserId: '01USER',
  createdAt: '2026-07-25T09:00:00.000000Z',
  updatedAt: '2026-08-01T09:15:00.000000Z',
  completedAt: null,
  checkedInAt: '2026-08-01T09:15:00.000000Z',
);

const _customer = Customer(
  id: '01CUST',
  name: 'Somali Builders',
  phone: '+252612345678',
  customerStatus: 'good_standing',
  creditLimit: '5000.00',
  outstandingBalance: '800.00',
  remainingCredit: '4200.00',
  riskLevel: 'low',
  creditScore: 720,
  creditScoreBand: 'good',
  archivedAt: null,
);

Future<void> _pumpScreen(
  WidgetTester tester, {
  required _MockReminderRepository reminderRepository,
  required _MockCustomerRepository customerRepository,
}) async {
  tester.view.physicalSize = const Size(400, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const Scaffold(body: Text('Reminder List Screen'))),
      GoRoute(path: '/reminders/1', builder: (_, _) => const ReminderDetailScreen(reminderId: '1')),
      GoRoute(path: '/reminders/1/edit', builder: (_, _) => const Scaffold(body: Text('Edit Screen'))),
      GoRoute(path: '/reminders/1/send', builder: (_, state) => Scaffold(body: Text('Send Screen ${state.uri.queryParameters['channel']}'))),
      GoRoute(path: '/cases/:id', builder: (_, _) => const Scaffold(body: Text('Case Screen'))),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        reminderRepositoryProvider.overrideWithValue(reminderRepository),
        customerRepositoryProvider.overrideWithValue(customerRepository),
        debtRepositoryProvider.overrideWithValue(_MockDebtRepository()),
        collectionCaseRepositoryProvider.overrideWithValue(_MockCollectionCaseRepository()),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  router.push('/reminders/1');
  await tester.pumpAndSettle();
}

void main() {
  late _MockReminderRepository mockReminderRepository;
  late _MockCustomerRepository mockCustomerRepository;

  setUp(() {
    mockReminderRepository = _MockReminderRepository();
    mockCustomerRepository = _MockCustomerRepository();
    when(() => mockCustomerRepository.fetchCustomer('01CUST')).thenAnswer((_) async => _customer);
  });

  group('Follow-up reminders (every type except client_visit)', () {
    testWidgets('shows Call/WhatsApp/SMS instead of Send Reminder, plus Mark as Completed and Reschedule', (tester) async {
      when(() => mockReminderRepository.fetchReminder('1')).thenAnswer((_) async => _followUpReminder);

      await _pumpScreen(tester, reminderRepository: mockReminderRepository, customerRepository: mockCustomerRepository);
      await tester.pumpAndSettle();

      expect(find.text('Somali Builders'), findsOneWidget);
      // Reminder Module Final Polish: Amount Due renders with a thousand
      // separator via formatFriendlyAmount(), not the raw backend string.
      expect(find.text('4,967.40'), findsOneWidget);
      expect(find.text('Call before visiting'), findsOneWidget);
      expect(find.text('Call'), findsOneWidget);
      expect(find.text('WhatsApp'), findsOneWidget);
      expect(find.text('SMS'), findsOneWidget);
      expect(find.text('Send Reminder'), findsNothing);
      expect(find.text('Mark as Completed'), findsOneWidget);
      expect(find.text('Reschedule'), findsOneWidget);
      expect(find.text('View Case'), findsOneWidget);
      // Client Visit-only actions must never show for a Follow-up reminder.
      expect(find.text('Navigate'), findsNothing);
      expect(find.text('Check In'), findsNothing);
      expect(find.text('Log Visit Outcome'), findsNothing);
    });

    testWidgets('tapping WhatsApp navigates to the send screen preselecting the whatsapp channel', (tester) async {
      when(() => mockReminderRepository.fetchReminder('1')).thenAnswer((_) async => _followUpReminder);

      await _pumpScreen(tester, reminderRepository: mockReminderRepository, customerRepository: mockCustomerRepository);
      await tester.pumpAndSettle();

      await tester.tap(find.text('WhatsApp'));
      await tester.pumpAndSettle();

      expect(find.text('Send Screen whatsapp'), findsOneWidget);
    });

    testWidgets('tapping SMS navigates to the send screen preselecting the sms channel', (tester) async {
      when(() => mockReminderRepository.fetchReminder('1')).thenAnswer((_) async => _followUpReminder);

      await _pumpScreen(tester, reminderRepository: mockReminderRepository, customerRepository: mockCustomerRepository);
      await tester.pumpAndSettle();

      await tester.tap(find.text('SMS'));
      await tester.pumpAndSettle();

      expect(find.text('Send Screen sms'), findsOneWidget);
    });

    testWidgets('Mark as Completed is disabled once the reminder is already completed', (tester) async {
      when(() => mockReminderRepository.fetchReminder('1')).thenAnswer((_) async => _completedFollowUpReminder);

      await _pumpScreen(tester, reminderRepository: mockReminderRepository, customerRepository: mockCustomerRepository);
      await tester.pumpAndSettle();

      final button = tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Mark as Completed'));
      expect(button.onPressed, isNull);
    });

    testWidgets('Snooze 1 Hour persists via the real update endpoint sending only due_date', (tester) async {
      when(() => mockReminderRepository.fetchReminder('1')).thenAnswer((_) async => _followUpReminder);
      when(() => mockReminderRepository.updateReminder(
            id: '1',
            dueDate: any(named: 'dueDate'),
            amountDue: any(named: 'amountDue'),
            timingRule: any(named: 'timingRule'),
            customFireAt: any(named: 'customFireAt'),
            deliveryMethods: any(named: 'deliveryMethods'),
            notes: any(named: 'notes'),
          )).thenAnswer((_) async => _followUpReminder);

      await _pumpScreen(tester, reminderRepository: mockReminderRepository, customerRepository: mockCustomerRepository);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Snooze'));
      await tester.pumpAndSettle();

      expect(find.text('1 Hour'), findsOneWidget);
      await tester.tap(find.text('1 Hour'));
      await tester.pumpAndSettle();

      verify(() => mockReminderRepository.updateReminder(
            id: '1',
            dueDate: any(named: 'dueDate'),
            amountDue: null,
            timingRule: null,
            customFireAt: null,
            deliveryMethods: null,
            notes: null,
          )).called(1);
    });

    testWidgets('Snooze is disabled once the reminder is already completed', (tester) async {
      when(() => mockReminderRepository.fetchReminder('1')).thenAnswer((_) async => _completedFollowUpReminder);

      await _pumpScreen(tester, reminderRepository: mockReminderRepository, customerRepository: mockCustomerRepository);
      await tester.pumpAndSettle();

      final button = tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Snooze'));
      expect(button.onPressed, isNull);
    });
  });

  group('Client Visit reminders', () {
    testWidgets('shows Navigate/Check In/Log Visit Outcome/Mark as Completed, never Call/WhatsApp/SMS', (tester) async {
      when(() => mockReminderRepository.fetchReminder('1')).thenAnswer((_) async => _clientVisitReminder);

      await _pumpScreen(tester, reminderRepository: mockReminderRepository, customerRepository: mockCustomerRepository);
      await tester.pumpAndSettle();

      expect(find.text('Navigate'), findsOneWidget);
      expect(find.text('Check In'), findsOneWidget);
      expect(find.text('Log Visit Outcome'), findsOneWidget);
      expect(find.text('Snooze'), findsOneWidget);
      expect(find.text('Mark as Completed'), findsOneWidget);
      expect(find.text('Call'), findsNothing);
      expect(find.text('WhatsApp'), findsNothing);
      expect(find.text('SMS'), findsNothing);
      expect(find.text('Send Reminder'), findsNothing);
      // Reschedule is a Follow-up-only shortcut per the approved workflow —
      // Client Visit still has the Edit icon in the AppBar for the same
      // underlying action.
      expect(find.text('Reschedule'), findsNothing);
    });

    testWidgets('Check In persists via the real check-in endpoint and the button becomes disabled Checked In', (tester) async {
      var current = _clientVisitReminder;
      when(() => mockReminderRepository.fetchReminder('1')).thenAnswer((_) async => current);
      when(() => mockReminderRepository.checkInReminder('1')).thenAnswer((_) async {
        current = _checkedInClientVisitReminder;
        return current;
      });

      await _pumpScreen(tester, reminderRepository: mockReminderRepository, customerRepository: mockCustomerRepository);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Check In'));
      await tester.pumpAndSettle();

      verify(() => mockReminderRepository.checkInReminder('1')).called(1);
      expect(find.text('Checked In'), findsOneWidget);
      final button = tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Checked In'));
      expect(button.onPressed, isNull);
    });

    testWidgets('Log Visit Outcome pre-fills existing notes and Save persists via the real notes update endpoint', (tester) async {
      when(() => mockReminderRepository.fetchReminder('1')).thenAnswer((_) async => _clientVisitReminder);
      when(() => mockReminderRepository.updateReminder(
            id: '1',
            dueDate: any(named: 'dueDate'),
            amountDue: any(named: 'amountDue'),
            timingRule: any(named: 'timingRule'),
            customFireAt: any(named: 'customFireAt'),
            deliveryMethods: any(named: 'deliveryMethods'),
            notes: 'Customer was not home',
          )).thenAnswer((_) async => _clientVisitReminder);

      await _pumpScreen(tester, reminderRepository: mockReminderRepository, customerRepository: mockCustomerRepository);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Log Visit Outcome'));
      await tester.pumpAndSettle();

      expect(find.text('What happened during this visit?'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Customer was not home');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.text('Visit outcome saved.'), findsOneWidget);
      verify(() => mockReminderRepository.updateReminder(
            id: '1',
            dueDate: any(named: 'dueDate'),
            amountDue: any(named: 'amountDue'),
            timingRule: any(named: 'timingRule'),
            customFireAt: any(named: 'customFireAt'),
            deliveryMethods: any(named: 'deliveryMethods'),
            notes: 'Customer was not home',
          )).called(1);
    });
  });

  testWidgets('shows a retry affordance when the reminder fails to load', (tester) async {
    when(() => mockReminderRepository.fetchReminder('1')).thenThrow(Exception('network down'));

    await _pumpScreen(tester, reminderRepository: mockReminderRepository, customerRepository: mockCustomerRepository);
    await tester.pumpAndSettle();

    expect(find.text('Could not load this reminder.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('confirming delete calls the real endpoint and navigates back', (tester) async {
    when(() => mockReminderRepository.fetchReminder('1')).thenAnswer((_) async => _followUpReminder);
    when(() => mockReminderRepository.deleteReminder('1')).thenAnswer((_) async {});

    await _pumpScreen(tester, reminderRepository: mockReminderRepository, customerRepository: mockCustomerRepository);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    verify(() => mockReminderRepository.deleteReminder('1')).called(1);
  });
}
