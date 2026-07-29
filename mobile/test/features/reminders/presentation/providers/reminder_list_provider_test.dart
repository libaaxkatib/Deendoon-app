import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/reminders/data/reminder_repository.dart';
import 'package:mobile/features/reminders/domain/reminder.dart';
import 'package:mobile/features/reminders/domain/reminder_page.dart';
import 'package:mobile/features/reminders/presentation/providers/reminder_list_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockReminderRepository extends Mock implements ReminderRepository {}

const _reminderOne = Reminder(
  id: '1',
  type: 'payment_due',
  title: 'Payment Due',
  relatedEntityType: 'debt',
  relatedEntityId: '01DEBT',
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

const _reminderTwo = Reminder(
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

void main() {
  late _MockReminderRepository mockRepository;
  late ProviderContainer container;

  setUp(() {
    mockRepository = _MockReminderRepository();
    container = ProviderContainer(
      overrides: [reminderRepositoryProvider.overrideWithValue(mockRepository)],
    );
    addTearDown(container.dispose);
  });

  test('build() fetches page 1 with no tab filter', () async {
    when(() => mockRepository.fetchReminders(page: 1, tab: null))
        .thenAnswer((_) async => const ReminderPage(reminders: [_reminderOne], currentPage: 1, lastPage: 2, total: 30));

    final state = await container.read(reminderListProvider.future);

    expect(state.reminders, [_reminderOne]);
    expect(state.hasMore, isTrue);
  });

  test('filterByTab() re-fetches page 1 under the real tab value', () async {
    when(() => mockRepository.fetchReminders(page: 1, tab: null))
        .thenAnswer((_) async => const ReminderPage(reminders: [_reminderOne], currentPage: 1, lastPage: 1, total: 1));
    await container.read(reminderListProvider.future);

    when(() => mockRepository.fetchReminders(page: 1, tab: 'today'))
        .thenAnswer((_) async => const ReminderPage(reminders: [_reminderTwo], currentPage: 1, lastPage: 1, total: 1));

    await container.read(reminderListProvider.notifier).filterByTab('today');

    final state = container.read(reminderListProvider).value!;
    expect(state.reminders, [_reminderTwo]);
    expect(state.tab, 'today');
  });

  test('loadMore() appends the next page and stops once lastPage is reached', () async {
    when(() => mockRepository.fetchReminders(page: 1, tab: null))
        .thenAnswer((_) async => const ReminderPage(reminders: [_reminderOne], currentPage: 1, lastPage: 2, total: 2));
    await container.read(reminderListProvider.future);

    when(() => mockRepository.fetchReminders(page: 2, tab: null))
        .thenAnswer((_) async => const ReminderPage(reminders: [_reminderTwo], currentPage: 2, lastPage: 2, total: 2));

    await container.read(reminderListProvider.notifier).loadMore();

    final state = container.read(reminderListProvider).value!;
    expect(state.reminders, [_reminderOne, _reminderTwo]);
    expect(state.hasMore, isFalse);
  });

  test('replaceReminder() swaps in the updated reminder without refetching', () async {
    when(() => mockRepository.fetchReminders(page: 1, tab: null))
        .thenAnswer((_) async => const ReminderPage(reminders: [_reminderOne], currentPage: 1, lastPage: 1, total: 1));
    await container.read(reminderListProvider.future);

    const completed = Reminder(
      id: '1',
      type: 'payment_due',
      title: 'Payment Due',
      relatedEntityType: 'debt',
      relatedEntityId: '01DEBT',
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

    container.read(reminderListProvider.notifier).replaceReminder(completed);

    final state = container.read(reminderListProvider).value!;
    expect(state.reminders.single.status, 'completed');
  });

  test('removeReminder() drops the reminder and decrements total', () async {
    when(() => mockRepository.fetchReminders(page: 1, tab: null)).thenAnswer(
      (_) async => const ReminderPage(reminders: [_reminderOne, _reminderTwo], currentPage: 1, lastPage: 1, total: 2),
    );
    await container.read(reminderListProvider.future);

    container.read(reminderListProvider.notifier).removeReminder('1');

    final state = container.read(reminderListProvider).value!;
    expect(state.reminders, [_reminderTwo]);
    expect(state.total, 1);
  });
}
