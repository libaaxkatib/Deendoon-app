import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/notifications/data/notification_repository.dart';
import 'package:mobile/features/notifications/domain/app_notification.dart';
import 'package:mobile/features/notifications/domain/notification_page.dart';
import 'package:mobile/features/notifications/presentation/screens/notification_list_screen.dart';
import 'package:mocktail/mocktail.dart';

class _MockNotificationRepository extends Mock implements NotificationRepository {}

final _unread = AppNotification(
  id: '1',
  type: 'payment_received',
  relatedEntityType: 'payment',
  relatedEntityId: '01PAYMENT',
  readAt: null,
  createdAt: DateTime.parse('2026-08-01T09:00:00.000000Z'),
);

void main() {
  late _MockNotificationRepository mockRepository;

  setUp(() {
    mockRepository = _MockNotificationRepository();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    // The filter chip row is a horizontally-scrolling list of 10 chips —
    // wider than the default 800px test viewport, so chips past that
    // width are never materialized in the element tree (not just
    // off-screen for tap purposes). Widened here so every chip's
    // existence and selected state can be asserted directly.
    tester.view.physicalSize = const Size(3200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/notifications',
      routes: [
        GoRoute(path: '/notifications', builder: (_, _) => const NotificationListScreen()),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [notificationRepositoryProvider.overrideWithValue(mockRepository)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
  }

  testWidgets('shows the explicit empty state when there are no notifications', (tester) async {
    when(() => mockRepository.fetchNotifications(page: 1, type: null)).thenAnswer(
      (_) async => const NotificationPage(notifications: [], currentPage: 1, lastPage: 1, total: 0),
    );

    await pumpScreen(tester);
    await tester.pumpAndSettle();

    expect(find.text('No notifications yet'), findsOneWidget);
  });

  testWidgets('renders a notification with its type label', (tester) async {
    when(() => mockRepository.fetchNotifications(page: 1, type: null)).thenAnswer(
      (_) async => NotificationPage(notifications: [_unread], currentPage: 1, lastPage: 1, total: 1),
    );

    await pumpScreen(tester);
    await tester.pumpAndSettle();

    // Two matches by design: the "Payment Received" filter chip plus the
    // notification card's own type label.
    expect(find.text('Payment Received'), findsNWidgets(2));
    expect(find.text('Mark all read'), findsOneWidget);
  });

  testWidgets('renders the All chip plus one chip per real notification type', (tester) async {
    when(() => mockRepository.fetchNotifications(page: 1, type: null)).thenAnswer(
      (_) async => const NotificationPage(notifications: [], currentPage: 1, lastPage: 1, total: 0),
    );

    await pumpScreen(tester);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ChoiceChip, 'All'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Credit Limit Reached'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Payment Received'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Document Available'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Collection Assignment'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Reminder Sent'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Promise to Pay Due'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Collection Request Update'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Subscription Update'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Storage Add-on Update'), findsOneWidget);
  });

  testWidgets('the All chip is selected by default', (tester) async {
    when(() => mockRepository.fetchNotifications(page: 1, type: null)).thenAnswer(
      (_) async => const NotificationPage(notifications: [], currentPage: 1, lastPage: 1, total: 0),
    );

    await pumpScreen(tester);
    await tester.pumpAndSettle();

    final allChip = tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'All'));
    expect(allChip.selected, isTrue);
  });

  testWidgets('tapping a type chip calls the real endpoint with that type and selects the chip', (tester) async {
    when(() => mockRepository.fetchNotifications(page: 1, type: null)).thenAnswer(
      (_) async => const NotificationPage(notifications: [], currentPage: 1, lastPage: 1, total: 0),
    );
    when(() => mockRepository.fetchNotifications(page: 1, type: 'payment_received')).thenAnswer(
      (_) async => NotificationPage(notifications: [_unread], currentPage: 1, lastPage: 1, total: 1),
    );

    await pumpScreen(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Payment Received'));
    await tester.pumpAndSettle();

    verify(() => mockRepository.fetchNotifications(page: 1, type: 'payment_received')).called(1);
    final paymentChip = tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Payment Received'));
    expect(paymentChip.selected, isTrue);
    final allChip = tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'All'));
    expect(allChip.selected, isFalse);
  });

  testWidgets('shows a filter-specific empty state when a type filter has no results', (tester) async {
    when(() => mockRepository.fetchNotifications(page: 1, type: null)).thenAnswer(
      (_) async => const NotificationPage(notifications: [], currentPage: 1, lastPage: 1, total: 0),
    );
    when(() => mockRepository.fetchNotifications(page: 1, type: 'document_available')).thenAnswer(
      (_) async => const NotificationPage(notifications: [], currentPage: 1, lastPage: 1, total: 0),
    );

    await pumpScreen(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Document Available'));
    await tester.pumpAndSettle();

    expect(find.text('No Document Available notifications'), findsOneWidget);
  });

  testWidgets('tapping "Mark all read" calls the real endpoint', (tester) async {
    when(() => mockRepository.fetchNotifications(page: 1, type: null)).thenAnswer(
      (_) async => NotificationPage(notifications: [_unread], currentPage: 1, lastPage: 1, total: 1),
    );
    when(() => mockRepository.markAllRead()).thenAnswer((_) async {});

    await pumpScreen(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mark all read'));
    await tester.pumpAndSettle();

    verify(() => mockRepository.markAllRead()).called(1);
    expect(find.text('Mark all read'), findsNothing);
  });
}
