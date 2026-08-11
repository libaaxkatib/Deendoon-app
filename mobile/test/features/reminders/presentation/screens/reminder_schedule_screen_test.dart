import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/localization/somali_fallback_delegates.dart';
import 'package:mobile/features/reminders/data/reminder_repository.dart';
import 'package:mobile/features/reminders/domain/reminder.dart';
import 'package:mobile/features/reminders/domain/reminder_entity_preset.dart';
import 'package:mobile/features/reminders/presentation/screens/reminder_schedule_screen.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockReminderRepository extends Mock implements ReminderRepository {}

const _createdReminder = Reminder(
  id: '1',
  type: 'follow_up_call',
  title: 'Follow-up Call',
  relatedEntityType: 'debt',
  relatedEntityId: '01DEBT',
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

Future<void> _pumpScreen(
  WidgetTester tester, {
  required _MockReminderRepository reminderRepository,
  ReminderEntityPreset? entityPreset,
}) async {
  tester.view.physicalSize = const Size(400, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const Text('Reminder List Screen')),
      GoRoute(path: '/form', builder: (_, _) => ReminderScheduleScreen(entityPreset: entityPreset)),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [reminderRepositoryProvider.overrideWithValue(reminderRepository)],
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
  router.push('/form');
  await tester.pumpAndSettle();
}

void main() {
  late _MockReminderRepository mockReminderRepository;

  setUp(() {
    mockReminderRepository = _MockReminderRepository();
  });

  group('Entity-Aware Reminder Creation (P2.4)', () {
    testWidgets('with an entityPreset, Related To shows the locked label instead of a customer picker', (tester) async {
      await _pumpScreen(
        tester,
        reminderRepository: mockReminderRepository,
        entityPreset: const ReminderEntityPreset(type: 'debt', id: '01DEBT', label: 'Debt DBT-0001'),
      );

      expect(find.text('Debt DBT-0001'), findsOneWidget);
      expect(find.text('Select Customer'), findsNothing);
    });

    testWidgets('without a preset, the generic customer picker is shown', (tester) async {
      await _pumpScreen(tester, reminderRepository: mockReminderRepository);

      expect(find.text('Select Customer'), findsOneWidget);
    });

    testWidgets('saving with a preset creates the reminder against that entity without selecting a customer', (tester) async {
      when(() => mockReminderRepository.createReminder(
            type: 'follow_up_call',
            relatedEntityType: 'debt',
            relatedEntityId: '01DEBT',
            relatedCaseId: null,
            dueDate: any(named: 'dueDate'),
            amountDue: null,
            timingRule: 'one_day_before',
            customFireAt: null,
            deliveryMethods: ['in_app'],
            notes: null,
          )).thenAnswer((_) async => _createdReminder);

      await _pumpScreen(
        tester,
        reminderRepository: mockReminderRepository,
        entityPreset: const ReminderEntityPreset(type: 'debt', id: '01DEBT', label: 'Debt DBT-0001'),
      );

      await tester.tap(find.text('Follow-up Call'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Select Due Date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('In-App Notification'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.save_outlined));
      await tester.pumpAndSettle();

      verify(() => mockReminderRepository.createReminder(
            type: 'follow_up_call',
            relatedEntityType: 'debt',
            relatedEntityId: '01DEBT',
            relatedCaseId: null,
            dueDate: any(named: 'dueDate'),
            amountDue: null,
            timingRule: 'one_day_before',
            customFireAt: null,
            deliveryMethods: ['in_app'],
            notes: null,
          )).called(1);
    });
  });
}
