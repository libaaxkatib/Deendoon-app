import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/debts/data/debt_repository.dart';
import 'package:mobile/features/debts/domain/credit_limit_warning.dart';
import 'package:mobile/features/debts/domain/debt.dart';
import 'package:mobile/features/debts/presentation/screens/add_edit_debt_screen.dart';
import 'package:mobile/features/quick_actions/domain/debt_draft.dart';
import 'package:mocktail/mocktail.dart';

class _MockDebtRepository extends Mock implements DebtRepository {}

const _existingDebt = Debt(
  id: '1',
  customerId: '01CUST',
  referenceNumber: 'DBT-0001',
  amount: '1000.00',
  dueDate: '2026-07-01',
  debtStatus: 'pending',
  remainingBalance: '1000.00',
  recoveryStage: 1,
  notes: 'Call before 5pm',
);

Future<void> _pumpScreen(
  WidgetTester tester, {
  required _MockDebtRepository repository,
  String? customerId,
  String? debtId,
}) async {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const Text('Debt List Screen')),
      GoRoute(
        path: '/form',
        builder: (_, _) => AddEditDebtScreen(customerId: customerId, debtId: debtId),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [debtRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  router.push('/form');
  await tester.pumpAndSettle();
}

void main() {
  late _MockDebtRepository mockRepository;

  setUp(() {
    mockRepository = _MockDebtRepository();
  });

  group('Add Debt', () {
    testWidgets('shows a validation error instead of submitting an empty amount', (tester) async {
      await _pumpScreen(tester, repository: mockRepository, customerId: '01CUST');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Debt'));
      await tester.pumpAndSettle();

      expect(find.text('Enter an amount'), findsOneWidget);
      verifyNever(() => mockRepository.createDebt(
            customerId: any(named: 'customerId'),
            amount: any(named: 'amount'),
            dueDate: any(named: 'dueDate'),
            notes: any(named: 'notes'),
          ));
    });

    testWidgets('shows a validation error when the amount is valid but no due date was picked', (tester) async {
      await _pumpScreen(tester, repository: mockRepository, customerId: '01CUST');

      await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '500.00');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Debt'));
      await tester.pumpAndSettle();

      expect(find.text('Select a due date.'), findsOneWidget);
      verifyNever(() => mockRepository.createDebt(
            customerId: any(named: 'customerId'),
            amount: any(named: 'amount'),
            dueDate: any(named: 'dueDate'),
            notes: any(named: 'notes'),
          ));
    });

    testWidgets('submits the entered fields and pops on success', (tester) async {
      when(() => mockRepository.createDebt(
            customerId: '01CUST',
            amount: '500.00',
            dueDate: '2026-08-15',
            notes: null,
          )).thenAnswer((_) async => (debt: _existingDebt, warning: null));

      await _pumpScreen(tester, repository: mockRepository, customerId: '01CUST');

      await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '500.00');
      // Date picking is exercised via the picker; here we set it directly
      // through the OutlinedButton's onPressed by opening and confirming
      // the date picker dialog.
      await tester.tap(find.text('Select Due Date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('15')); // any visible day in the default month
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Debt'));
      await tester.pumpAndSettle();

      verify(() => mockRepository.createDebt(
            customerId: '01CUST',
            amount: '500.00',
            dueDate: any(named: 'dueDate'),
            notes: null,
          )).called(1);
      expect(find.byType(AddEditDebtScreen), findsNothing);
    });

    testWidgets('shows a Credit Limit Exceeded dialog when the save returns a warning', (tester) async {
      const warning = CreditLimitWarning(
        type: 'CREDIT_LIMIT_EXCEEDED',
        message: 'This customer has exceeded the approved credit limit.',
        creditLimit: '5000.00',
        projectedOutstanding: '5500.00',
      );
      when(() => mockRepository.createDebt(
            customerId: '01CUST',
            amount: any(named: 'amount'),
            dueDate: any(named: 'dueDate'),
            notes: any(named: 'notes'),
          )).thenAnswer((_) async => (debt: _existingDebt, warning: warning));

      await _pumpScreen(tester, repository: mockRepository, customerId: '01CUST');

      await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '5500.00');
      await tester.tap(find.text('Select Due Date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Debt'));
      await tester.pumpAndSettle();

      expect(find.text('Credit Limit Exceeded'), findsOneWidget);
      expect(find.text('This customer has exceeded the approved credit limit.'), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.byType(AddEditDebtScreen), findsNothing);
    });
  });

  group('Edit Debt', () {
    testWidgets('prefills fields and shows the amount read-only', (tester) async {
      when(() => mockRepository.fetchDebt('1')).thenAnswer((_) async => _existingDebt);

      await _pumpScreen(tester, repository: mockRepository, debtId: '1');

      expect(find.text('1000.00'), findsOneWidget);
      expect(find.text('Call before 5pm'), findsOneWidget);
      // Amount is not an editable field in Edit mode.
      expect(find.widgetWithText(TextFormField, 'Amount'), findsNothing);
    });

    testWidgets('submits due date and notes without touching amount', (tester) async {
      when(() => mockRepository.fetchDebt('1')).thenAnswer((_) async => _existingDebt);
      when(() => mockRepository.updateDebt(debtId: '1', dueDate: any(named: 'dueDate'), notes: 'Updated notes'))
          .thenAnswer((_) async => _existingDebt);

      await _pumpScreen(tester, repository: mockRepository, debtId: '1');

      // Notes is the only TextFormField in Edit mode — Amount renders as
      // read-only Text and Due Date as an OutlinedButton, not form fields.
      await tester.enterText(find.byType(TextFormField), 'Updated notes');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save Changes'));
      await tester.pumpAndSettle();

      verify(() => mockRepository.updateDebt(debtId: '1', dueDate: any(named: 'dueDate'), notes: 'Updated notes'))
          .called(1);
    });
  });

  group('Draft mode (deferSubmit — Add Case wizard\'s Debt Details step)', () {
    Future<void> pumpDraftScreen(WidgetTester tester, {required _MockDebtRepository repository}) async {
      DebtDraft? popped;
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  popped = await context.push<DebtDraft>('/draft');
                },
                child: Text(popped == null ? 'Open Draft Form' : 'Draft: ${popped!.amount}'),
              ),
            ),
          ),
          GoRoute(path: '/draft', builder: (_, _) => const AddEditDebtScreen(deferSubmit: true)),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [debtRepositoryProvider.overrideWithValue(repository)],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.tap(find.text('Open Draft Form'));
      await tester.pumpAndSettle();
    }

    testWidgets('shows "Debt Details" title and a "Continue" button, not "Add Debt"', (tester) async {
      await pumpDraftScreen(tester, repository: mockRepository);

      expect(find.text('Debt Details'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Continue'), findsOneWidget);
    });

    testWidgets('submitting pops with a DebtDraft instead of calling the create API', (tester) async {
      await pumpDraftScreen(tester, repository: mockRepository);

      await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '500.00');
      await tester.tap(find.text('Select Due Date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pumpAndSettle();

      verifyNever(() => mockRepository.createDebt(
            customerId: any(named: 'customerId'),
            amount: any(named: 'amount'),
            dueDate: any(named: 'dueDate'),
            notes: any(named: 'notes'),
          ));
      expect(find.text('Draft: 500.00'), findsOneWidget);
    });
  });
}
