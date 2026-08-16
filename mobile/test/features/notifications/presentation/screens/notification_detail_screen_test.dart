import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/localization/somali_fallback_delegates.dart';
import 'package:mobile/features/notifications/domain/app_notification.dart';
import 'package:mobile/features/notifications/presentation/screens/notification_detail_screen.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';

final _subscriptionNotification = AppNotification(
  id: '1',
  type: 'subscription_request_update',
  relatedEntityType: 'subscription_change_request',
  relatedEntityId: 'req-1',
  readAt: null,
  createdAt: DateTime.parse('2026-08-01T09:00:00.000000Z'),
);

final _storageNotification = AppNotification(
  id: '2',
  type: 'storage_request_update',
  relatedEntityType: 'storage_addon',
  relatedEntityId: 'addon-1',
  readAt: null,
  createdAt: DateTime.parse('2026-08-01T09:00:00.000000Z'),
);

final _announcementNotification = AppNotification(
  id: '3',
  type: 'admin_announcement',
  title: 'Scheduled maintenance',
  message: 'The platform will be briefly unavailable tonight.',
  relatedEntityType: 'announcement',
  relatedEntityId: 'batch-1',
  readAt: null,
  createdAt: DateTime.parse('2026-08-01T09:00:00.000000Z'),
);

Future<void> _pumpScreen(
  WidgetTester tester,
  AppNotification notification,
) async {
  final router = GoRouter(
    initialLocation: '/notifications/${notification.id}',
    routes: [
      GoRoute(
        path: '/notifications/:id',
        builder: (_, _) => NotificationDetailScreen(notification: notification),
      ),
      GoRoute(
        path: '/account/subscription',
        builder: (_, _) => const Scaffold(body: Text('Subscription Screen')),
      ),
      GoRoute(
        path: '/account/storage',
        builder: (_, _) => const Scaffold(body: Text('Storage Screen')),
      ),
    ],
  );

  await tester.pumpWidget(
    MaterialApp.router(
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
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'a subscription_request_update notification renders its real label and opens the Subscription screen',
    (tester) async {
      await _pumpScreen(tester, _subscriptionNotification);

      expect(find.text('Subscription Update'), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Subscription Screen'), findsOneWidget);
    },
  );

  testWidgets(
    'a storage_request_update notification renders its real label and opens the Storage screen',
    (tester) async {
      await _pumpScreen(tester, _storageNotification);

      expect(find.text('Storage Add-on Update'), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Storage Screen'), findsOneWidget);
    },
  );

  testWidgets(
    'an admin_announcement notification renders its real title/message and has no Open button',
    (tester) async {
      await _pumpScreen(tester, _announcementNotification);

      expect(find.text('Scheduled maintenance'), findsOneWidget);
      expect(
        find.text('The platform will be briefly unavailable tonight.'),
        findsOneWidget,
      );
      expect(find.text('Open'), findsNothing);
    },
  );
}
