import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/notifications/data/notification_repository.dart';
import 'package:mobile/features/notifications/domain/app_notification.dart';
import 'package:mobile/features/notifications/domain/notification_page.dart';
import 'package:mobile/features/notifications/presentation/providers/notification_list_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockNotificationRepository extends Mock implements NotificationRepository {}

final _unreadOne = AppNotification(
  id: '1',
  type: 'payment_received',
  relatedEntityType: 'payment',
  relatedEntityId: '01PAYMENT',
  readAt: null,
  createdAt: DateTime.parse('2026-08-01T09:00:00.000000Z'),
);

final _unreadTwo = AppNotification(
  id: '2',
  type: 'credit_limit_reached',
  relatedEntityType: 'customer',
  relatedEntityId: '01CUST',
  readAt: null,
  createdAt: DateTime.parse('2026-07-30T09:00:00.000000Z'),
);

void main() {
  late _MockNotificationRepository mockRepository;
  late ProviderContainer container;

  setUp(() {
    mockRepository = _MockNotificationRepository();
    container = ProviderContainer(
      overrides: [notificationRepositoryProvider.overrideWithValue(mockRepository)],
    );
    addTearDown(container.dispose);
  });

  test('build() fetches page 1 with no type filter', () async {
    when(() => mockRepository.fetchNotifications(page: 1, type: null)).thenAnswer(
      (_) async => NotificationPage(notifications: [_unreadOne], currentPage: 1, lastPage: 2, total: 30),
    );

    final state = await container.read(notificationListProvider.future);

    expect(state.notifications, [_unreadOne]);
    expect(state.hasMore, isTrue);
    expect(state.hasUnread, isTrue);
  });

  test('loadMore() appends the next page and stops once lastPage is reached', () async {
    when(() => mockRepository.fetchNotifications(page: 1, type: null)).thenAnswer(
      (_) async => NotificationPage(notifications: [_unreadOne], currentPage: 1, lastPage: 2, total: 2),
    );
    await container.read(notificationListProvider.future);

    when(() => mockRepository.fetchNotifications(page: 2, type: null)).thenAnswer(
      (_) async => NotificationPage(notifications: [_unreadTwo], currentPage: 2, lastPage: 2, total: 2),
    );

    await container.read(notificationListProvider.notifier).loadMore();

    final state = container.read(notificationListProvider).value!;
    expect(state.notifications, [_unreadOne, _unreadTwo]);
    expect(state.hasMore, isFalse);
  });

  test('markRead() calls the real endpoint and updates the notification in place', () async {
    when(() => mockRepository.fetchNotifications(page: 1, type: null)).thenAnswer(
      (_) async => NotificationPage(notifications: [_unreadOne], currentPage: 1, lastPage: 1, total: 1),
    );
    await container.read(notificationListProvider.future);
    when(() => mockRepository.markRead('1')).thenAnswer((_) async {});

    await container.read(notificationListProvider.notifier).markRead('1');

    final state = container.read(notificationListProvider).value!;
    expect(state.notifications.single.isRead, isTrue);
    expect(state.hasUnread, isFalse);
    verify(() => mockRepository.markRead('1')).called(1);
  });

  test('markAllRead() calls the real endpoint and marks every notification read', () async {
    when(() => mockRepository.fetchNotifications(page: 1, type: null)).thenAnswer(
      (_) async => NotificationPage(notifications: [_unreadOne, _unreadTwo], currentPage: 1, lastPage: 1, total: 2),
    );
    await container.read(notificationListProvider.future);
    when(() => mockRepository.markAllRead()).thenAnswer((_) async {});

    await container.read(notificationListProvider.notifier).markAllRead();

    final state = container.read(notificationListProvider).value!;
    expect(state.hasUnread, isFalse);
    verify(() => mockRepository.markAllRead()).called(1);
  });
}
