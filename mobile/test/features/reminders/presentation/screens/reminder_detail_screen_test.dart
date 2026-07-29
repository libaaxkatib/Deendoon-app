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

const _openReminder = Reminder(
  id: '1',
  type: 'payment_due',
  title: 'Payment Due',
  relatedEntityType: 'customer',
  relatedEntityId: '01CUST',
  relatedCaseId: '01CASE',
  dueDate: '2026-08-01T10:00:00.000000Z',
  amountDue: '250.00',
  timingRule: 'one_day_before',
  customFireAt: null,
  deliveryMethods: ['in_app'],
  notes: 'Call before visiting',
  status: 'upcoming',
  createdByUserId: '01USER',
  createdAt: '2026-07-25T09:00:00.000000Z',
  updatedAt: '2026-07-25T09:00:00.000000Z',
  completedAt: null,
);

const _completedReminder = Reminder(
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
      GoRoute(path: '/reminders/1/send', builder: (_, _) => const Scaffold(body: Text('Send Screen'))),
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

  testWidgets('renders reminder details, notes, and all three actions', (tester) async {
    when(() => mockReminderRepository.fetchReminder('1')).thenAnswer((_) async => _openReminder);

    await _pumpScreen(tester, reminderRepository: mockReminderRepository, customerRepository: mockCustomerRepository);
    await tester.pumpAndSettle();

    expect(find.text('Somali Builders'), findsOneWidget);
    expect(find.text('250.00'), findsOneWidget);
    expect(find.text('Call before visiting'), findsOneWidget);
    expect(find.text('Send Reminder'), findsOneWidget);
    expect(find.text('Mark as Completed'), findsOneWidget);
    expect(find.text('Reschedule'), findsOneWidget);
    expect(find.text('View Case'), findsOneWidget);
  });

  testWidgets('Mark as Completed is disabled once the reminder is already completed', (tester) async {
    when(() => mockReminderRepository.fetchReminder('1')).thenAnswer((_) async => _completedReminder);

    await _pumpScreen(tester, reminderRepository: mockReminderRepository, customerRepository: mockCustomerRepository);
    await tester.pumpAndSettle();

    final button = tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Mark as Completed'));
    expect(button.onPressed, isNull);
  });

  testWidgets('shows a retry affordance when the reminder fails to load', (tester) async {
    when(() => mockReminderRepository.fetchReminder('1')).thenThrow(Exception('network down'));

    await _pumpScreen(tester, reminderRepository: mockReminderRepository, customerRepository: mockCustomerRepository);
    await tester.pumpAndSettle();

    expect(find.text('Could not load this reminder.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('confirming delete calls the real endpoint and navigates back', (tester) async {
    when(() => mockReminderRepository.fetchReminder('1')).thenAnswer((_) async => _openReminder);
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
