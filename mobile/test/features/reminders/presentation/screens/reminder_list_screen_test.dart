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
);

Future<void> _pumpScreen(
  WidgetTester tester, {
  required _MockReminderRepository reminderRepository,
  required _MockCustomerRepository customerRepository,
}) async {
  tester.view.physicalSize = const Size(400, 1600);
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
      child: const MaterialApp(home: ReminderListScreen()),
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
