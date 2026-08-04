import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/calendar/data/calendar_repository.dart';
import 'package:mobile/features/calendar/domain/calendar_data.dart';
import 'package:mobile/features/calendar/domain/calendar_entry.dart';
import 'package:mobile/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:mocktail/mocktail.dart';

class _MockCalendarRepository extends Mock implements CalendarRepository {}

const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

String _iso(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

Future<void> _pumpScreen(WidgetTester tester, _MockCalendarRepository repository) async {
  tester.view.physicalSize = const Size(400, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [calendarRepositoryProvider.overrideWithValue(repository)],
      child: const MaterialApp(home: CalendarScreen()),
    ),
  );
}

void main() {
  late _MockCalendarRepository mockRepository;
  late DateTime now;
  late DateTime monthStart;
  late DateTime monthEnd;

  setUp(() {
    mockRepository = _MockCalendarRepository();
    now = DateTime.now();
    monthStart = DateTime(now.year, now.month, 1);
    monthEnd = DateTime(now.year, now.month + 1, 0);
  });

  testWidgets('fetches the current month range and shows its label', (tester) async {
    when(() => mockRepository.fetchEntries(from: _iso(monthStart), to: _iso(monthEnd))).thenAnswer(
      (_) async => CalendarData(from: _iso(monthStart), to: _iso(monthEnd), entries: const []),
    );

    await _pumpScreen(tester, mockRepository);
    await tester.pumpAndSettle();

    verify(() => mockRepository.fetchEntries(from: _iso(monthStart), to: _iso(monthEnd))).called(1);
    expect(find.text('${_monthNames[now.month - 1]} ${now.year}'), findsOneWidget);
  });

  testWidgets('shows the empty state for today when there are no entries', (tester) async {
    when(() => mockRepository.fetchEntries(from: _iso(monthStart), to: _iso(monthEnd))).thenAnswer(
      (_) async => CalendarData(from: _iso(monthStart), to: _iso(monthEnd), entries: const []),
    );

    await _pumpScreen(tester, mockRepository);
    await tester.pumpAndSettle();

    expect(find.text('No events'), findsOneWidget);
  });

  testWidgets('renders an agenda tile for a real entry due today', (tester) async {
    final entry = CalendarEntry(
      type: 'due_date',
      date: _iso(now),
      relatedEntityType: 'debt',
      relatedEntityId: '01DEBT',
      label: 'INV-1001',
    );
    when(() => mockRepository.fetchEntries(from: _iso(monthStart), to: _iso(monthEnd))).thenAnswer(
      (_) async => CalendarData(from: _iso(monthStart), to: _iso(monthEnd), entries: [entry]),
    );

    await _pumpScreen(tester, mockRepository);
    await tester.pumpAndSettle();

    expect(find.text('Due: INV-1001'), findsOneWidget);
    expect(find.text('No events'), findsNothing);
  });

  testWidgets('tapping Next month re-fetches with next month\'s real date range', (tester) async {
    final nextMonthStart = DateTime(now.year, now.month + 1, 1);
    final nextMonthEnd = DateTime(now.year, now.month + 2, 0);

    when(() => mockRepository.fetchEntries(from: _iso(monthStart), to: _iso(monthEnd))).thenAnswer(
      (_) async => CalendarData(from: _iso(monthStart), to: _iso(monthEnd), entries: const []),
    );
    when(() => mockRepository.fetchEntries(from: _iso(nextMonthStart), to: _iso(nextMonthEnd))).thenAnswer(
      (_) async => CalendarData(from: _iso(nextMonthStart), to: _iso(nextMonthEnd), entries: const []),
    );

    await _pumpScreen(tester, mockRepository);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();

    verify(() => mockRepository.fetchEntries(from: _iso(nextMonthStart), to: _iso(nextMonthEnd))).called(1);
    expect(find.text('${_monthNames[nextMonthStart.month - 1]} ${nextMonthStart.year}'), findsOneWidget);
  });

  testWidgets('shows a retry affordance when the calendar fails to load', (tester) async {
    when(() => mockRepository.fetchEntries(from: any(named: 'from'), to: any(named: 'to')))
        .thenThrow(Exception('network down'));

    await _pumpScreen(tester, mockRepository);
    await tester.pumpAndSettle();

    expect(find.text('Could not load calendar data.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
