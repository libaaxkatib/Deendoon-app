import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/analytics/data/analytics_repository.dart';
import 'package:mobile/features/analytics/presentation/screens/report_debts_screen.dart';
import 'package:mobile/features/debts/domain/debt.dart';
import 'package:mobile/features/debts/domain/debt_page.dart';
import 'package:mocktail/mocktail.dart';

class _MockAnalyticsRepository extends Mock implements AnalyticsRepository {}

const _debt = Debt(
  id: '1',
  customerId: '1',
  referenceNumber: 'DBT-000001',
  amount: '500.00',
  dueDate: '2026-08-01',
  debtStatus: 'overdue',
  remainingBalance: '500.00',
  recoveryStage: 1,
  notes: null,
);

Future<void> _pumpScreen(
  WidgetTester tester, {
  required _MockAnalyticsRepository repository,
  String? initialStatus,
}) async {
  tester.view.physicalSize = const Size(400, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [analyticsRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(home: ReportDebtsScreen(initialStatus: initialStatus)),
    ),
  );
}

void main() {
  late _MockAnalyticsRepository mockRepository;

  setUp(() {
    mockRepository = _MockAnalyticsRepository();
  });

  testWidgets('renders the full debts report', (tester) async {
    when(() => mockRepository.fetchReportDebts(page: 1, status: null))
        .thenAnswer((_) async => const DebtPage(debts: [_debt], currentPage: 1, lastPage: 1, total: 1));

    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    expect(find.text('DBT-000001'), findsOneWidget);
  });

  testWidgets('shows the explicit empty state when there are no debts', (tester) async {
    when(() => mockRepository.fetchReportDebts(page: 1, status: null))
        .thenAnswer((_) async => const DebtPage(debts: [], currentPage: 1, lastPage: 1, total: 0));

    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    expect(find.text('No debts match this filter'), findsOneWidget);
  });

  testWidgets('shows a retry affordance when the report fails to load', (tester) async {
    when(() => mockRepository.fetchReportDebts(page: 1, status: null)).thenThrow(Exception('network down'));

    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    expect(find.text('Could not load debts.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('tapping a status filter chip triggers a real API call with that status', (tester) async {
    when(() => mockRepository.fetchReportDebts(page: 1, status: null))
        .thenAnswer((_) async => const DebtPage(debts: [_debt], currentPage: 1, lastPage: 1, total: 1));
    when(() => mockRepository.fetchReportDebts(page: 1, status: 'overdue'))
        .thenAnswer((_) async => const DebtPage(debts: [_debt], currentPage: 1, lastPage: 1, total: 1));

    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Overdue'));
    await tester.pumpAndSettle();

    verify(() => mockRepository.fetchReportDebts(page: 1, status: 'overdue')).called(1);
  });

  testWidgets('an initialStatus constructor argument applies the filter on first load', (tester) async {
    when(() => mockRepository.fetchReportDebts(page: 1, status: null))
        .thenAnswer((_) async => const DebtPage(debts: [_debt], currentPage: 1, lastPage: 1, total: 1));
    when(() => mockRepository.fetchReportDebts(page: 1, status: 'overdue'))
        .thenAnswer((_) async => const DebtPage(debts: [_debt], currentPage: 1, lastPage: 1, total: 1));

    await _pumpScreen(tester, repository: mockRepository, initialStatus: 'overdue');
    await tester.pumpAndSettle();

    verify(() => mockRepository.fetchReportDebts(page: 1, status: 'overdue')).called(1);
  });
}
