import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/cases/data/collection_case_repository.dart';
import 'package:mobile/features/customers/data/customer_repository.dart';
import 'package:mobile/features/customers/domain/customer.dart';
import 'package:mobile/features/debts/data/debt_repository.dart';
import 'package:mobile/features/reminders/data/reminder_repository.dart';
import 'package:mobile/features/reminders/domain/reminder.dart';
import 'package:mobile/features/reminders/domain/reminder_page.dart';
import 'package:mobile/features/reminders/domain/reminder_summary.dart';
import 'package:mobile/features/reminders/presentation/screens/reminder_list_screen.dart';
import 'package:mocktail/mocktail.dart';

class _MockReminderRepository extends Mock implements ReminderRepository {}

class _MockCustomerRepository extends Mock implements CustomerRepository {}

class _MockDebtRepository extends Mock implements DebtRepository {}

class _MockCollectionCaseRepository extends Mock implements CollectionCaseRepository {}

const _summary = ReminderSummary(
  totalDueToday: 4,
  overdueCount: 1,
  clientVisits: 1,
  followUpCalls: 1,
  paymentsDue: 2,
  contractRenewals: 0,
  promisesToPay: 0,
);

const _reminder = Reminder(
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
  status: 'upcoming',
  createdByUserId: '01USER',
  createdAt: '2026-07-25T09:00:00.000000Z',
  updatedAt: '2026-07-25T09:00:00.000000Z',
  completedAt: null,
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

const _clientVisitReminder = Reminder(
  id: '2',
  type: 'client_visit',
  title: 'Client Visit',
  relatedEntityType: 'customer',
  relatedEntityId: '01CUST',
  relatedCaseId: null,
  dueDate: '2026-07-28T10:00:00.000000Z',
  amountDue: null,
  timingRule: 'same_day',
  customFireAt: null,
  deliveryMethods: ['push'],
  notes: null,
  status: 'today',
  createdByUserId: '01USER',
  createdAt: '2026-07-20T09:00:00.000000Z',
  updatedAt: '2026-07-20T09:00:00.000000Z',
  completedAt: null,
);

Future<void> _pumpScreen(
  WidgetTester tester, {
  required _MockReminderRepository reminderRepository,
  required _MockCustomerRepository customerRepository,
  String? initialFilter,
  double width = 400,
}) async {
  tester.view.physicalSize = Size(width, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        reminderRepositoryProvider.overrideWithValue(reminderRepository),
        customerRepositoryProvider.overrideWithValue(customerRepository),
        debtRepositoryProvider.overrideWithValue(_MockDebtRepository()),
        collectionCaseRepositoryProvider.overrideWithValue(_MockCollectionCaseRepository()),
      ],
      child: MaterialApp(home: ReminderListScreen(initialFilter: initialFilter)),
    ),
  );
}

void main() {
  late _MockReminderRepository mockReminderRepository;
  late _MockCustomerRepository mockCustomerRepository;

  setUp(() {
    mockReminderRepository = _MockReminderRepository();
    mockCustomerRepository = _MockCustomerRepository();
    when(() => mockReminderRepository.fetchSummary()).thenAnswer((_) async => _summary);
    when(() => mockCustomerRepository.fetchCustomer('01CUST')).thenAnswer((_) async => _customer);
  });

  testWidgets('renders a Calendar entry point icon in the app bar', (tester) async {
    when(() => mockReminderRepository.fetchReminders(page: 1, tab: null))
        .thenAnswer((_) async => const ReminderPage(reminders: [], currentPage: 1, lastPage: 1, total: 0));

    await _pumpScreen(tester, reminderRepository: mockReminderRepository, customerRepository: mockCustomerRepository);
    await tester.pumpAndSettle();

    expect(find.byTooltip('Calendar'), findsOneWidget);
  });

  testWidgets('renders the summary row and reminder cards with real fields', (tester) async {
    when(() => mockReminderRepository.fetchReminders(page: 1, tab: null))
        .thenAnswer((_) async => const ReminderPage(reminders: [_reminder], currentPage: 1, lastPage: 1, total: 1));

    await _pumpScreen(tester, reminderRepository: mockReminderRepository, customerRepository: mockCustomerRepository);
    await tester.pumpAndSettle();

    expect(find.text('Payment Due'), findsWidgets);
    expect(find.text('Somali Builders'), findsOneWidget);
    expect(find.text('4', skipOffstage: false), findsOneWidget);
  });

  testWidgets('shows the explicit empty state when there are no reminders', (tester) async {
    when(() => mockReminderRepository.fetchReminders(page: 1, tab: null))
        .thenAnswer((_) async => const ReminderPage(reminders: [], currentPage: 1, lastPage: 1, total: 0));

    await _pumpScreen(tester, reminderRepository: mockReminderRepository, customerRepository: mockCustomerRepository);
    await tester.pumpAndSettle();

    expect(find.text('Nothing due'), findsOneWidget);
  });

  testWidgets('shows a retry affordance when the list fails to load', (tester) async {
    when(() => mockReminderRepository.fetchReminders(page: 1, tab: null)).thenThrow(Exception('network down'));

    await _pumpScreen(tester, reminderRepository: mockReminderRepository, customerRepository: mockCustomerRepository);
    await tester.pumpAndSettle();

    expect(find.text('Could not load reminders.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('tapping a tab filter chip triggers a real API call with that tab', (tester) async {
    when(() => mockReminderRepository.fetchReminders(page: 1, tab: null))
        .thenAnswer((_) async => const ReminderPage(reminders: [_reminder], currentPage: 1, lastPage: 1, total: 1));
    when(() => mockReminderRepository.fetchReminders(page: 1, tab: 'today'))
        .thenAnswer((_) async => const ReminderPage(reminders: [], currentPage: 1, lastPage: 1, total: 0));

    await _pumpScreen(tester, reminderRepository: mockReminderRepository, customerRepository: mockCustomerRepository);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Today'));
    await tester.pumpAndSettle();

    verify(() => mockReminderRepository.fetchReminders(page: 1, tab: 'today')).called(1);
    expect(find.text('Nothing due in this filter'), findsOneWidget);
  });

  testWidgets('renders the 8 filter chips matching the dashboard reminder categories', (tester) async {
    when(() => mockReminderRepository.fetchReminders(page: 1, tab: null))
        .thenAnswer((_) async => const ReminderPage(reminders: [_reminder], currentPage: 1, lastPage: 1, total: 1));

    // Wide enough that the horizontal chip row lays out all 8 chips
    // without needing a scroll — the default 400-wide phone viewport used
    // elsewhere in this file only realizes chips within its cache extent.
    await _pumpScreen(
      tester,
      reminderRepository: mockReminderRepository,
      customerRepository: mockCustomerRepository,
      width: 1200,
    );
    await tester.pumpAndSettle();

    for (final label in ['All', 'Today', 'Payments', 'Visits', 'Calls', 'Upcoming', 'Overdue', 'Completed']) {
      expect(find.widgetWithText(ChoiceChip, label), findsOneWidget, reason: '$label chip should render');
    }
  });

  testWidgets('tapping the Visits chip shows only client_visit reminders from the same All fetch', (tester) async {
    when(() => mockReminderRepository.fetchReminders(page: 1, tab: null)).thenAnswer(
      (_) async =>
          const ReminderPage(reminders: [_reminder, _clientVisitReminder], currentPage: 1, lastPage: 1, total: 2),
    );

    await _pumpScreen(
      tester,
      reminderRepository: mockReminderRepository,
      customerRepository: mockCustomerRepository,
      width: 1200,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Visits'));
    await tester.pumpAndSettle();

    // Both calls are the same real "All" fetch (initial load, then re-fetched
    // by filterByType) — Visits is a client-side filter, never a distinct
    // `tab`/`reminder_type` API call.
    verify(() => mockReminderRepository.fetchReminders(page: 1, tab: null)).called(2);
    expect(find.text('Client Visit'), findsWidgets);
    expect(find.text('Payment Due'), findsNothing);
  });

  testWidgets('tapping the Visits mini-stat card applies the same Visits filter', (tester) async {
    when(() => mockReminderRepository.fetchReminders(page: 1, tab: null)).thenAnswer(
      (_) async =>
          const ReminderPage(reminders: [_reminder, _clientVisitReminder], currentPage: 1, lastPage: 1, total: 2),
    );

    await _pumpScreen(tester, reminderRepository: mockReminderRepository, customerRepository: mockCustomerRepository);
    await tester.pumpAndSettle();

    // 'Visits' also labels the filter chip below — the mini-stat is the
    // first match in tree order since the summary row renders above it.
    await tester.tap(find.text('Visits').first);
    await tester.pumpAndSettle();

    expect(find.text('Client Visit'), findsWidgets);
    expect(find.text('Payment Due'), findsNothing);
    expect(find.widgetWithText(ChoiceChip, 'Visits'), findsOneWidget);
  });

  testWidgets('an initialFilter of payments pre-selects the Payments chip and filters the list', (tester) async {
    when(() => mockReminderRepository.fetchReminders(page: 1, tab: null)).thenAnswer(
      (_) async =>
          const ReminderPage(reminders: [_reminder, _clientVisitReminder], currentPage: 1, lastPage: 1, total: 2),
    );

    await _pumpScreen(
      tester,
      reminderRepository: mockReminderRepository,
      customerRepository: mockCustomerRepository,
      initialFilter: 'payments',
    );
    await tester.pumpAndSettle();

    expect(find.text('Payment Due'), findsWidgets);
    expect(find.text('Client Visit'), findsNothing);
  });

  testWidgets('tapping Complete on a card calls the real endpoint', (tester) async {
    when(() => mockReminderRepository.fetchReminders(page: 1, tab: null))
        .thenAnswer((_) async => const ReminderPage(reminders: [_reminder], currentPage: 1, lastPage: 1, total: 1));
    const completed = Reminder(
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
      updatedAt: '2026-07-25T09:00:00.000000Z',
      completedAt: '2026-07-28T10:00:00.000000Z',
    );
    when(() => mockReminderRepository.completeReminder('1')).thenAnswer((_) async => completed);

    await _pumpScreen(tester, reminderRepository: mockReminderRepository, customerRepository: mockCustomerRepository);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Complete'));
    await tester.pumpAndSettle();

    verify(() => mockReminderRepository.completeReminder('1')).called(1);
  });
}
