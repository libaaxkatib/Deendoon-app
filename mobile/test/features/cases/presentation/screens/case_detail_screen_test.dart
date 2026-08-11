import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/localization/somali_fallback_delegates.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/features/cases/data/collection_case_repository.dart';
import 'package:mobile/features/cases/domain/case_history.dart';
import 'package:mobile/features/cases/domain/collection_case.dart';
import 'package:mobile/features/cases/presentation/screens/case_detail_screen.dart';
import 'package:mobile/features/customers/data/customer_repository.dart';
import 'package:mobile/features/customers/domain/customer.dart';
import 'package:mobile/features/debts/data/debt_repository.dart';
import 'package:mobile/features/debts/domain/debt.dart';
import 'package:mobile/features/professional_collection/data/professional_collection_repository.dart';
import 'package:mobile/features/professional_collection/data/reference_data_repository.dart';
import 'package:mobile/features/professional_collection/domain/professional_collection_request.dart';
import 'package:mobile/features/professional_collection/domain/reference_data_item.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockCollectionCaseRepository extends Mock implements CollectionCaseRepository {}

class _MockCustomerRepository extends Mock implements CustomerRepository {}

class _MockDebtRepository extends Mock implements DebtRepository {}

class _MockProfessionalCollectionRepository extends Mock implements ProfessionalCollectionRepository {}

class _MockReferenceDataRepository extends Mock implements ReferenceDataRepository {}

const _transferReasons = [
  ReferenceDataItem(id: '1', category: 'transfer_reason', valueLabel: 'Repeated missed promises', sortOrder: 1, isActive: true),
];

const _requestedServices = [
  ReferenceDataItem(id: '1', category: 'requested_service', valueLabel: 'Field Visit', sortOrder: 1, isActive: true),
];

const _customer = Customer(
  id: '01CUST',
  name: 'Somali Builders',
  phone: '+252612345678',
  customerStatus: 'high_risk',
  creditLimit: '5000.00',
  outstandingBalance: '4467.40',
  remainingCredit: '532.60',
  riskLevel: 'high',
  creditScore: 480,
  creditScoreBand: 'poor',
  archivedAt: null,
);

const _debt = Debt(
  id: '01DEBT',
  customerId: '01CUST',
  referenceNumber: 'DBT-0001',
  amount: '4467.40',
  dueDate: '2026-08-26',
  debtStatus: 'pending',
  remainingBalance: '4467.40',
  recoveryStage: 5,
  notes: null,
);

const _openCase = CollectionCase(
  id: '01CASE',
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

const _openCaseWithNotes = CollectionCase(
  id: '01CASE',
  debtId: '01DEBT',
  customerId: '01CUST',
  customerName: 'Somali Builders',
  outstandingAmount: '4467.40',
  riskLevel: 'high',
  referenceNumber: 'COL-0001',
  assignedOfficerUserId: null,
  caseStatus: 'open',
  closureOutcome: null,
  notes: 'Called customer, promised payment next week.',
  lastActivityAt: '2026-07-28T10:00:00.000000Z',
  createdAt: '2026-07-01T10:00:00.000000Z',
  closedAt: null,
);

const _closedCase = CollectionCase(
  id: '01CASE',
  debtId: '01DEBT',
  customerId: '01CUST',
  customerName: 'Somali Builders',
  outstandingAmount: '4467.40',
  riskLevel: 'high',
  referenceNumber: 'COL-0001',
  assignedOfficerUserId: '01OFFICER',
  caseStatus: 'closed',
  closureOutcome: 'Paid in full',
  notes: null,
  lastActivityAt: '2026-07-28T12:00:00.000000Z',
  createdAt: '2026-07-01T10:00:00.000000Z',
  closedAt: '2026-07-28T12:00:00.000000Z',
);

Future<void> _pumpScreen(
  WidgetTester tester, {
  required _MockCollectionCaseRepository caseRepository,
  required _MockCustomerRepository customerRepository,
  required _MockDebtRepository debtRepository,
}) async {
  tester.view.physicalSize = const Size(400, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        collectionCaseRepositoryProvider.overrideWithValue(caseRepository),
        customerRepositoryProvider.overrideWithValue(customerRepository),
        debtRepositoryProvider.overrideWithValue(debtRepository),
      ],
      child: MaterialApp(
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
        home: const CaseDetailScreen(caseId: '01CASE'),
      ),
    ),
  );
}

void main() {
  late _MockCollectionCaseRepository mockCaseRepository;
  late _MockCustomerRepository mockCustomerRepository;
  late _MockDebtRepository mockDebtRepository;
  late _MockProfessionalCollectionRepository mockProfessionalCollectionRepository;

  setUp(() {
    mockCaseRepository = _MockCollectionCaseRepository();
    mockCustomerRepository = _MockCustomerRepository();
    mockDebtRepository = _MockDebtRepository();
    mockProfessionalCollectionRepository = _MockProfessionalCollectionRepository();

    when(() => mockCustomerRepository.fetchCustomer('01CUST')).thenAnswer((_) async => _customer);
    when(() => mockDebtRepository.fetchDebt('01DEBT')).thenAnswer((_) async => _debt);
    when(() => mockDebtRepository.fetchPayments('01DEBT')).thenAnswer((_) async => []);
    when(() => mockDebtRepository.fetchDocuments('01DEBT')).thenAnswer((_) async => []);
    when(() => mockCaseRepository.fetchHistory('01CASE'))
        .thenAnswer((_) async => const CaseHistory(collectionCaseId: '01CASE', entries: []));
  });

  testWidgets('renders case summary, customer, debt, and collection stage from real data', (tester) async {
    when(() => mockCaseRepository.fetchCase('01CASE')).thenAnswer((_) async => _openCase);

    await _pumpScreen(
      tester,
      caseRepository: mockCaseRepository,
      customerRepository: mockCustomerRepository,
      debtRepository: mockDebtRepository,
    );
    await tester.pumpAndSettle();

    expect(find.text('COL-0001'), findsWidgets); // AppBar title + Case Summary card
    expect(find.text('Somali Builders'), findsOneWidget);
    expect(find.text('Stage 5 of 6'), findsOneWidget);
    expect(find.text('Unassigned'), findsOneWidget);

    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('No notes yet.'), findsOneWidget);
    expect(find.widgetWithIcon(IconButton, Icons.edit_outlined), findsOneWidget);

    expect(find.text('Add Follow-up'), findsOneWidget);
    expect(find.text('Mark Contacted'), findsOneWidget);
    expect(find.text('Record Visit'), findsOneWidget);
    expect(find.text('Promise to Pay'), findsOneWidget);
    expect(find.text('Close Case'), findsOneWidget);
  });

  testWidgets('a closed case hides action buttons and shows an explanatory note instead', (tester) async {
    when(() => mockCaseRepository.fetchCase('01CASE')).thenAnswer((_) async => _closedCase);

    await _pumpScreen(
      tester,
      caseRepository: mockCaseRepository,
      customerRepository: mockCustomerRepository,
      debtRepository: mockDebtRepository,
    );
    await tester.pumpAndSettle();

    expect(find.text('Add Follow-up'), findsNothing);
    expect(find.text('Close Case'), findsNothing);
    expect(find.textContaining('This case is closed'), findsOneWidget);
    expect(find.text('Officer 01OFFICER'), findsOneWidget);
    expect(find.text('Paid in full'), findsOneWidget);

    // Notes editing has no case-status restriction on the backend
    // (`CollectionCasePolicy::manage` only checks role + read-only) — the
    // edit affordance must remain available on a closed case too.
    expect(find.widgetWithIcon(IconButton, Icons.edit_outlined), findsOneWidget);
  });

  testWidgets('shows a retry affordance when the case fails to load', (tester) async {
    when(() => mockCaseRepository.fetchCase('01CASE')).thenThrow(Exception('network down'));

    await _pumpScreen(
      tester,
      caseRepository: mockCaseRepository,
      customerRepository: mockCustomerRepository,
      debtRepository: mockDebtRepository,
    );
    await tester.pumpAndSettle();

    expect(find.text('Could not load this case.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('Attachments opens the case-scoped Attachments screen', (tester) async {
    when(() => mockCaseRepository.fetchCase('01CASE')).thenAnswer((_) async => _openCase);

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const CaseDetailScreen(caseId: '01CASE')),
        GoRoute(path: '/cases/01CASE/attachments', builder: (_, _) => const Text('Attachments Screen')),
      ],
    );

    tester.view.physicalSize = const Size(400, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          collectionCaseRepositoryProvider.overrideWithValue(mockCaseRepository),
          customerRepositoryProvider.overrideWithValue(mockCustomerRepository),
          debtRepositoryProvider.overrideWithValue(mockDebtRepository),
        ],
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
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Attachments'));
    await tester.pumpAndSettle();

    expect(find.text('Attachments Screen'), findsOneWidget);
  });

  testWidgets('submitting Close Case calls the real endpoint with the entered outcome', (tester) async {
    when(() => mockCaseRepository.fetchCase('01CASE')).thenAnswer((_) async => _openCase);
    when(() => mockCaseRepository.close(caseId: '01CASE', closureOutcome: 'Paid in full'))
        .thenAnswer((_) async => _closedCase);

    await _pumpScreen(
      tester,
      caseRepository: mockCaseRepository,
      customerRepository: mockCustomerRepository,
      debtRepository: mockDebtRepository,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Close Case'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'Paid in full');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Close Case'));
    await tester.pumpAndSettle();

    verify(() => mockCaseRepository.close(caseId: '01CASE', closureOutcome: 'Paid in full')).called(1);
  });

  group('Notes', () {
    testWidgets('displays existing notes when present', (tester) async {
      when(() => mockCaseRepository.fetchCase('01CASE')).thenAnswer((_) async => _openCaseWithNotes);

      await _pumpScreen(
        tester,
        caseRepository: mockCaseRepository,
        customerRepository: mockCustomerRepository,
        debtRepository: mockDebtRepository,
      );
      await tester.pumpAndSettle();

      expect(find.text('Called customer, promised payment next week.'), findsOneWidget);
      expect(find.text('No notes yet.'), findsNothing);
    });

    testWidgets('editing pre-fills the current notes and submits the trimmed value', (tester) async {
      when(() => mockCaseRepository.fetchCase('01CASE')).thenAnswer((_) async => _openCaseWithNotes);
      when(() => mockCaseRepository.updateNotes(caseId: '01CASE', notes: 'Updated note text'))
          .thenAnswer((_) async => _openCaseWithNotes);

      await _pumpScreen(
        tester,
        caseRepository: mockCaseRepository,
        customerRepository: mockCustomerRepository,
        debtRepository: mockDebtRepository,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithIcon(IconButton, Icons.edit_outlined));
      await tester.pumpAndSettle();

      final field = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(field.controller?.text, 'Called customer, promised payment next week.');

      await tester.enterText(find.byType(TextFormField), 'Updated note text');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save Notes'));
      await tester.pumpAndSettle();

      verify(() => mockCaseRepository.updateNotes(caseId: '01CASE', notes: 'Updated note text')).called(1);
    });

    testWidgets('clearing notes to empty submits null', (tester) async {
      when(() => mockCaseRepository.fetchCase('01CASE')).thenAnswer((_) async => _openCaseWithNotes);
      when(() => mockCaseRepository.updateNotes(caseId: '01CASE', notes: null)).thenAnswer((_) async => _openCase);

      await _pumpScreen(
        tester,
        caseRepository: mockCaseRepository,
        customerRepository: mockCustomerRepository,
        debtRepository: mockDebtRepository,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithIcon(IconButton, Icons.edit_outlined));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), '');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save Notes'));
      await tester.pumpAndSettle();

      verify(() => mockCaseRepository.updateNotes(caseId: '01CASE', notes: null)).called(1);
    });

    testWidgets('on an API error, shows the exact backend message and keeps the sheet open', (tester) async {
      when(() => mockCaseRepository.fetchCase('01CASE')).thenAnswer((_) async => _openCase);
      when(() => mockCaseRepository.updateNotes(caseId: '01CASE', notes: 'New note')).thenThrow(
        const ApiException(message: 'This action is unauthorized.', statusCode: 403),
      );

      await _pumpScreen(
        tester,
        caseRepository: mockCaseRepository,
        customerRepository: mockCustomerRepository,
        debtRepository: mockDebtRepository,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithIcon(IconButton, Icons.edit_outlined));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'New note');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save Notes'));
      await tester.pumpAndSettle();

      expect(find.text('This action is unauthorized.'), findsOneWidget);
      expect(find.text('Save Notes'), findsOneWidget);
    });
  });

  group('Submit to Professional Collection', () {
    late _MockReferenceDataRepository mockReferenceDataRepository;

    setUp(() {
      mockReferenceDataRepository = _MockReferenceDataRepository();
      when(() => mockReferenceDataRepository.fetchCategory('transfer_reason'))
          .thenAnswer((_) async => _transferReasons);
      when(() => mockReferenceDataRepository.fetchCategory('requested_service'))
          .thenAnswer((_) async => _requestedServices);
    });

    Future<void> pumpWithRouter(WidgetTester tester, GoRouter router) async {
      tester.view.physicalSize = const Size(400, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      when(() => mockCaseRepository.fetchCase('01CASE')).thenAnswer((_) async => _openCase);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            collectionCaseRepositoryProvider.overrideWithValue(mockCaseRepository),
            customerRepositoryProvider.overrideWithValue(mockCustomerRepository),
            debtRepositoryProvider.overrideWithValue(mockDebtRepository),
            professionalCollectionRepositoryProvider.overrideWithValue(mockProfessionalCollectionRepository),
            referenceDataRepositoryProvider.overrideWithValue(mockReferenceDataRepository),
          ],
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
      await tester.pumpAndSettle();
    }

    /// Opens the sheet, selects the one available Reason and Service, and
    /// accepts the Client Declaration — the minimum valid submission.
    Future<void> fillValidForm(WidgetTester tester) async {
      await tester.tap(find.text('Submit to Professional Collection'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Repeated missed promises'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Field Visit'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('I confirm the Client Declaration for this hand-off.'));
      await tester.pumpAndSettle();
    }

    testWidgets('on success, submits the exact payload and navigates to the new Request Detail screen', (
      tester,
    ) async {
      const createdRequest = ProfessionalCollectionRequest(
        id: '01PCR',
        collectionCaseId: '01CASE',
        referenceNumber: 'PCR-0001',
        status: 'submitted',
        submittedByUserId: '01USER',
        actionedByUserId: null,
        reasons: ['Repeated missed promises'],
        notes: null,
        requestedServices: ['Field Visit'],
        declarationAcceptedAt: '2026-08-01T00:00:00.000000Z',
        declarationAcceptedBy: '01USER',
        createdAt: '2026-08-01T00:00:00.000000Z',
        closedAt: null,
      );
      when(() => mockProfessionalCollectionRepository.submit(
            caseId: '01CASE',
            reasons: ['Repeated missed promises'],
            services: ['Field Visit'],
            notes: null,
            declarationAccepted: true,
          )).thenAnswer((_) async => createdRequest);

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const CaseDetailScreen(caseId: '01CASE')),
          GoRoute(
            path: '/professional-requests/:id',
            builder: (_, state) => Text('Request Detail ${state.pathParameters['id']}'),
          ),
        ],
      );
      await pumpWithRouter(tester, router);

      await fillValidForm(tester);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Submit Request'));
      await tester.pumpAndSettle();

      verify(() => mockProfessionalCollectionRepository.submit(
            caseId: '01CASE',
            reasons: ['Repeated missed promises'],
            services: ['Field Visit'],
            notes: null,
            declarationAccepted: true,
          )).called(1);
      expect(find.text('Request Detail 01PCR'), findsOneWidget);
    });

    testWidgets('leaving no reason selected shows a client-side validation error and never calls the repository', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const CaseDetailScreen(caseId: '01CASE')),
          GoRoute(path: '/professional-requests/:id', builder: (_, _) => const Text('Request Detail')),
        ],
      );
      await pumpWithRouter(tester, router);

      await tester.tap(find.text('Submit to Professional Collection'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Field Visit'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('I confirm the Client Declaration for this hand-off.'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Submit Request'));
      await tester.pumpAndSettle();

      expect(find.text('Select at least one Reason for Transfer.'), findsOneWidget);
      verifyNever(() => mockProfessionalCollectionRepository.submit(
            caseId: any(named: 'caseId'),
            reasons: any(named: 'reasons'),
            services: any(named: 'services'),
            notes: any(named: 'notes'),
            declarationAccepted: any(named: 'declarationAccepted'),
          ));
    });

    testWidgets('leaving the declaration unchecked shows a client-side validation error', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const CaseDetailScreen(caseId: '01CASE')),
          GoRoute(path: '/professional-requests/:id', builder: (_, _) => const Text('Request Detail')),
        ],
      );
      await pumpWithRouter(tester, router);

      await tester.tap(find.text('Submit to Professional Collection'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Repeated missed promises'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Field Visit'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Submit Request'));
      await tester.pumpAndSettle();

      expect(find.text('You must accept the Client Declaration to submit.'), findsOneWidget);
      verifyNever(() => mockProfessionalCollectionRepository.submit(
            caseId: any(named: 'caseId'),
            reasons: any(named: 'reasons'),
            services: any(named: 'services'),
            notes: any(named: 'notes'),
            declarationAccepted: any(named: 'declarationAccepted'),
          ));
    });

    testWidgets('on a 409 conflict, shows the exact backend message and does not navigate', (tester) async {
      when(() => mockProfessionalCollectionRepository.submit(
            caseId: '01CASE',
            reasons: ['Repeated missed promises'],
            services: ['Field Visit'],
            notes: null,
            declarationAccepted: true,
          )).thenThrow(
        const ApiException(
          message: 'This Collection Case already has an active Professional Collection Request.',
          statusCode: 409,
        ),
      );

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const CaseDetailScreen(caseId: '01CASE')),
          GoRoute(path: '/professional-requests/:id', builder: (_, _) => const Text('Request Detail')),
        ],
      );
      await pumpWithRouter(tester, router);

      await fillValidForm(tester);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Submit Request'));
      await tester.pumpAndSettle();

      expect(
        find.text('This Collection Case already has an active Professional Collection Request.'),
        findsOneWidget,
      );
      expect(find.text('Request Detail'), findsNothing);
    });
  });
}
