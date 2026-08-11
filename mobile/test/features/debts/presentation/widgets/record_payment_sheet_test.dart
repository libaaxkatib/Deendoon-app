import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/localization/somali_fallback_delegates.dart';
import 'package:mobile/core/models/payment.dart';
import 'package:mobile/features/debts/data/debt_repository.dart';
import 'package:mobile/features/debts/presentation/widgets/record_payment_sheet.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

const _localizationsDelegates = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
  SomaliMaterialLocalizationsDelegate(),
  SomaliCupertinoLocalizationsDelegate(),
];

class _MockDebtRepository extends Mock implements DebtRepository {}

const _payment = Payment(
  id: '01PAY',
  debtId: '1',
  amount: '250.00',
  paymentDate: '2026-08-01',
  paymentMethod: 'Cash',
);

void main() {
  late _MockDebtRepository mockRepository;

  setUp(() {
    mockRepository = _MockDebtRepository();
  });

  testWidgets('submits amount, method, and notes to the real endpoint', (
    tester,
  ) async {
    when(
      () => mockRepository.recordPayment(
        debtId: '1',
        amount: '250.00',
        paymentDate: any(named: 'paymentDate'),
        paymentMethod: 'Cash',
        referenceNotes: 'Partial settlement',
      ),
    ).thenAnswer((_) async => _payment);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [debtRepositoryProvider.overrideWithValue(mockRepository)],
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: _localizationsDelegates,
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showRecordPaymentSheet(context, '1'),
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Amount'),
      '250.00',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Payment Method (optional)'),
      'Cash',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Notes (optional)'),
      'Partial settlement',
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Save Payment'));
    await tester.pumpAndSettle();

    verify(
      () => mockRepository.recordPayment(
        debtId: '1',
        amount: '250.00',
        paymentDate: any(named: 'paymentDate'),
        paymentMethod: 'Cash',
        referenceNotes: 'Partial settlement',
      ),
    ).called(1);
  });

  testWidgets('method and notes are optional', (tester) async {
    when(
      () => mockRepository.recordPayment(
        debtId: '1',
        amount: '100.00',
        paymentDate: any(named: 'paymentDate'),
        paymentMethod: null,
        referenceNotes: null,
      ),
    ).thenAnswer((_) async => _payment);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [debtRepositoryProvider.overrideWithValue(mockRepository)],
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: _localizationsDelegates,
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showRecordPaymentSheet(context, '1'),
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Amount'),
      '100.00',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save Payment'));
    await tester.pumpAndSettle();

    verify(
      () => mockRepository.recordPayment(
        debtId: '1',
        amount: '100.00',
        paymentDate: any(named: 'paymentDate'),
        paymentMethod: null,
        referenceNotes: null,
      ),
    ).called(1);
  });
}
