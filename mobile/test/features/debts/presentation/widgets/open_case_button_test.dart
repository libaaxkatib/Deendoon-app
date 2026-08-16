import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/localization/somali_fallback_delegates.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/features/cases/domain/collection_case.dart';
import 'package:mobile/features/debts/data/debt_repository.dart';
import 'package:mobile/features/debts/presentation/widgets/open_case_button.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockDebtRepository extends Mock implements DebtRepository {}

final _collectionCase = CollectionCase(
  id: '01CASE',
  debtId: '01DEBT',
  customerId: '01CUST',
  customerName: 'Acme Traders',
  outstandingAmount: '500.00',
  riskLevel: 'high',
  referenceNumber: 'CASE-000001',
  assignedOfficerUserId: null,
  caseStatus: 'open',
  closureOutcome: null,
  notes: null,
  lastActivityAt: '2026-08-01T09:00:00.000000Z',
  createdAt: '2026-08-01T09:00:00.000000Z',
  closedAt: null,
);

void main() {
  late _MockDebtRepository mockRepository;

  setUp(() {
    mockRepository = _MockDebtRepository();
    // DebtActions.openCase() invalidates debtRelatedCaseProvider on
    // success (pre-existing behavior, unrelated to this fix) — null is
    // the real, expected "no case yet" value, matching
    // DebtRepository.fetchRelatedCase()'s own contract.
    when(
      () => mockRepository.fetchRelatedCase(any()),
    ).thenAnswer((_) async => null);
  });

  Future<void> pumpButton(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/debts/01DEBT',
      routes: [
        GoRoute(
          path: '/debts/01DEBT',
          builder: (_, _) => const Scaffold(
            body: OpenCaseButton(debtId: '01DEBT', customerId: '01CUST'),
          ),
        ),
        GoRoute(
          path: '/cases/:id',
          builder: (_, state) =>
              Scaffold(body: Text('Case ${state.pathParameters['id']}')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [debtRepositoryProvider.overrideWithValue(mockRepository)],
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
  }

  testWidgets(
    'a single tap opens the case and navigates to the case detail screen',
    (tester) async {
      when(
        () => mockRepository.openCase('01DEBT'),
      ).thenAnswer((_) async => _collectionCase);

      await pumpButton(tester);
      await tester.tap(find.byType(OutlinedButton));
      await tester.pumpAndSettle();

      verify(() => mockRepository.openCase('01DEBT')).called(1);
      expect(find.text('Case 01CASE'), findsOneWidget);
    },
  );

  testWidgets(
    'rapid repeated taps while the request is in flight only call openCase once',
    (tester) async {
      final completer = Completer<CollectionCase>();
      when(
        () => mockRepository.openCase('01DEBT'),
      ).thenAnswer((_) => completer.future);

      await pumpButton(tester);

      // First tap starts the request; the button becomes disabled while it's
      // pending, so a rapid second/third tap before it resolves must not
      // fire another request — this is the exact duplicate-case scenario.
      await tester.tap(find.byType(OutlinedButton));
      await tester.pump();
      await tester.tap(find.byType(OutlinedButton));
      await tester.tap(find.byType(OutlinedButton));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete(_collectionCase);
      await tester.pumpAndSettle();

      // Still exactly one call in total once the request resolves — the
      // blocked taps never queued up a second request.
      verify(() => mockRepository.openCase('01DEBT')).called(1);
      expect(find.text('Case 01CASE'), findsOneWidget);
    },
  );

  testWidgets(
    'shows the real error message and re-enables the button on failure',
    (tester) async {
      when(() => mockRepository.openCase('01DEBT')).thenThrow(
        const ApiException(
          message: 'This Debt already has an open Collection Case.',
        ),
      );

      await pumpButton(tester);
      await tester.tap(find.byType(OutlinedButton));
      await tester.pumpAndSettle();

      expect(
        find.text('This Debt already has an open Collection Case.'),
        findsOneWidget,
      );

      final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      expect(button.onPressed, isNotNull);

      // Re-enabled after failure: a second tap can retry.
      when(
        () => mockRepository.openCase('01DEBT'),
      ).thenAnswer((_) async => _collectionCase);
      await tester.tap(find.byType(OutlinedButton));
      await tester.pumpAndSettle();

      verify(() => mockRepository.openCase('01DEBT')).called(2);
      expect(find.text('Case 01CASE'), findsOneWidget);
    },
  );
}
