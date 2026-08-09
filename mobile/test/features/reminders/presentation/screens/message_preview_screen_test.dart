import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/reminders/data/reminder_repository.dart';
import 'package:mobile/features/reminders/domain/message_template.dart';
import 'package:mobile/features/reminders/presentation/screens/message_preview_screen.dart';
import 'package:mocktail/mocktail.dart';

class _MockReminderRepository extends Mock implements ReminderRepository {}

MessageTemplate _template(String name) => MessageTemplate(
      id: name,
      name: name,
      channel: 'whatsapp',
      body: 'Body for $name',
      createdAt: '2026-08-01T00:00:00.000000Z',
      updatedAt: '2026-08-01T00:00:00.000000Z',
    );

Future<void> _pumpScreen(WidgetTester tester, _MockReminderRepository repository) async {
  final router = GoRouter(
    initialLocation: '/send',
    routes: [
      GoRoute(path: '/send', builder: (_, _) => const MessagePreviewScreen(reminderId: '1')),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [reminderRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late _MockReminderRepository mockRepository;

  setUp(() {
    mockRepository = _MockReminderRepository();
  });

  testWidgets('renders the 7 default templates in the approved document order, not alphabetically', (tester) async {
    // Seeded intentionally out of order (and the backend itself returns
    // them alphabetically, per MessageTemplateService::forChannel) to
    // prove the screen re-sorts rather than trusting fetch order.
    when(() => mockRepository.fetchMessageTemplates(channel: 'whatsapp')).thenAnswer(
      (_) async => [
        _template('Promise to Pay Confirmation'),
        _template('Last Reminder'),
        _template('First Reminder'),
        _template('Third Reminder'),
        _template('Phone Call Follow-up'),
        _template('Meeting Request'),
        _template('Second Reminder'),
      ],
    );

    await _pumpScreen(tester, mockRepository);

    final order = [
      'First Reminder',
      'Second Reminder',
      'Third Reminder',
      'Last Reminder',
      'Meeting Request',
      'Phone Call Follow-up',
      'Promise to Pay Confirmation',
    ];
    final positions = order.map((name) => tester.getTopLeft(find.text(name)).dy).toList();
    for (var i = 1; i < positions.length; i++) {
      expect(positions[i], greaterThanOrEqualTo(positions[i - 1]), reason: '"${order[i]}" should not appear before "${order[i - 1]}"');
    }
  });

  testWidgets('Send via WhatsApp is disabled until a template has rendered, then enabled', (tester) async {
    // "Send" now launches the device's own WhatsApp app (like the existing
    // Call action) instead of calling a backend endpoint, so this only
    // asserts enablement — actually tapping through to launchUrl would hit
    // a real platform channel, which none of this app's other launch-based
    // actions (Call, Navigate) exercise in widget tests either.
    when(() => mockRepository.fetchMessageTemplates(channel: 'whatsapp'))
        .thenAnswer((_) async => [_template('First Reminder')]);
    when(() => mockRepository.renderMessage(templateId: 'First Reminder', reminderId: '1')).thenAnswer(
      (_) async => {
        'rendered_text': 'Mudane/Marwo Hodan Store, waxaad leedahay deyn dhan 200.00.',
        'recipient_name': 'Hodan Store',
        'recipient_phone': '254712345678',
      },
    );

    await _pumpScreen(tester, mockRepository);

    final buttonBefore = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Send via WhatsApp'));
    expect(buttonBefore.onPressed, isNull);

    await tester.tap(find.text('First Reminder'));
    await tester.pumpAndSettle();

    expect(find.text('Mudane/Marwo Hodan Store, waxaad leedahay deyn dhan 200.00.'), findsOneWidget);
    final buttonAfter = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Send via WhatsApp'));
    expect(buttonAfter.onPressed, isNotNull);
  });
}
