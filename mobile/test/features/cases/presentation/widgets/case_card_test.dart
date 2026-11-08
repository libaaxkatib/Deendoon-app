import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/localization/somali_fallback_delegates.dart';
import 'package:mobile/features/cases/domain/collection_case.dart';
import 'package:mobile/features/cases/presentation/widgets/case_card.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';

const _baseCase = CollectionCase(
  id: '1',
  debtId: '01DEBT',
  customerId: '01CUST',
  customerName: 'Somali Builders',
  outstandingAmount: '4467.40',
  riskLevel: 'high',
  referenceNumber: 'COL-0001',
  assignedOfficerUserId: null,
  caseStatus: 'open',
  closureOutcome: null,
  notes: null,
  lastActivityAt: '2026-07-28T10:00:00.000000Z',
  createdAt: '2026-07-01T10:00:00.000000Z',
  closedAt: null,
);

const _archivedCustomerCase = CollectionCase(
  id: '1',
  debtId: '01DEBT',
  customerId: '01CUST',
  customerName: 'Somali Builders',
  customerArchived: true,
  outstandingAmount: '4467.40',
  riskLevel: 'high',
  referenceNumber: 'COL-0001',
  assignedOfficerUserId: null,
  caseStatus: 'open',
  closureOutcome: null,
  notes: null,
  lastActivityAt: '2026-07-28T10:00:00.000000Z',
  createdAt: '2026-07-01T10:00:00.000000Z',
  closedAt: null,
);

Future<void> _pumpCard(WidgetTester tester, CollectionCase collectionCase) {
  return tester.pumpWidget(
    MaterialApp(
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
      home: Scaffold(
        body: CaseCard(
          collectionCase: collectionCase,
          activeTab: 'all',
          onTap: () {},
        ),
      ),
    ),
  );
}

void main() {
  group('Mobile QA Fix — Archived Customer', () {
    testWidgets(
      'shows an Archived tag next to the customer name when customerArchived is true',
      (tester) async {
        await _pumpCard(tester, _archivedCustomerCase);

        expect(find.text('Somali Builders'), findsOneWidget);
        expect(find.text('Archived'), findsOneWidget);
      },
    );

    testWidgets(
      'shows no Archived tag for an active (non-archived) customer',
      (tester) async {
        await _pumpCard(tester, _baseCase);

        expect(find.text('Somali Builders'), findsOneWidget);
        expect(find.text('Archived'), findsNothing);
      },
    );
  });
}
