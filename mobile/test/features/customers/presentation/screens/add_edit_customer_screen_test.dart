import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/localization/somali_fallback_delegates.dart';
import 'package:mobile/features/customers/data/customer_repository.dart';
import 'package:mobile/features/customers/domain/customer.dart';
import 'package:mobile/features/customers/domain/customer_phone_number.dart';
import 'package:mobile/features/customers/domain/duplicate_warning.dart';
import 'package:mobile/features/customers/presentation/screens/add_edit_customer_screen.dart';
import 'package:mobile/features/quick_actions/domain/customer_draft.dart';
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

class _MockCustomerRepository extends Mock implements CustomerRepository {}

const _existingCustomer = Customer(
  id: '1',
  name: 'Somali Builders',
  phone: '+252612345678',
  phoneNumbers: [
    CustomerPhoneNumber(id: 'p1', phone: '+252612345678', isPrimary: true),
  ],
  customerStatus: 'good_standing',
  creditLimit: '5000.00',
  outstandingBalance: '800.00',
  remainingCredit: '4200.00',
  riskLevel: 'low',
  creditScore: 720,
  creditScoreBand: 'good',
  archivedAt: null,
);

const _existingCustomerWithTwoPhones = Customer(
  id: '2',
  name: 'Hodan Store',
  phone: '+252611111111',
  phoneNumbers: [
    CustomerPhoneNumber(id: 'p1', phone: '+252611111111', isPrimary: true),
    CustomerPhoneNumber(id: 'p2', phone: '+252622222222', isPrimary: false),
  ],
  customerStatus: 'active',
  creditLimit: '3000.00',
  outstandingBalance: '0.00',
  remainingCredit: '3000.00',
  riskLevel: null,
  creditScore: null,
  creditScoreBand: null,
  archivedAt: null,
);

Future<void> _pumpScreen(
  WidgetTester tester, {
  required _MockCustomerRepository repository,
  String? customerId,
}) async {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const Text('Customer List Screen')),
      GoRoute(
        path: '/form',
        builder: (_, _) => AddEditCustomerScreen(customerId: customerId),
      ),
      GoRoute(
        path: '/customers/:id',
        builder: (_, state) =>
            Text('Customer Detail ${state.pathParameters['id']}'),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [customerRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: _localizationsDelegates,
      ),
    ),
  );
  router.push('/form');
  await tester.pumpAndSettle();
}

void main() {
  late _MockCustomerRepository mockRepository;

  setUp(() {
    mockRepository = _MockCustomerRepository();
  });

  group('Add Customer', () {
    testWidgets('shows validation errors instead of submitting an empty form', (
      tester,
    ) async {
      await _pumpScreen(tester, repository: mockRepository);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Customer'));
      await tester.pumpAndSettle();

      expect(find.text('Enter the customer\'s name'), findsOneWidget);
      expect(find.text('Enter a phone number'), findsOneWidget);
      expect(find.text('Enter a credit limit'), findsOneWidget);
      verifyNever(
        () => mockRepository.createCustomer(
          name: any(named: 'name'),
          phone: any(named: 'phone'),
          address: any(named: 'address'),
          creditLimit: any(named: 'creditLimit'),
          phoneNumbers: any(named: 'phoneNumbers'),
        ),
      );
    });

    testWidgets('submits the entered fields and pops on success', (
      tester,
    ) async {
      when(
        () => mockRepository.checkDuplicateCustomer(
          name: any(named: 'name'),
          phone: any(named: 'phone'),
        ),
      ).thenAnswer((_) async => null);
      when(
        () => mockRepository.createCustomer(
          name: 'New Customer',
          phone: '+252611111111',
          address: null,
          creditLimit: '1000.00',
          phoneNumbers: any(named: 'phoneNumbers'),
        ),
      ).thenAnswer((_) async => (customer: _existingCustomer, warning: null));

      await _pumpScreen(tester, repository: mockRepository);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Name'),
        'New Customer',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Phone'),
        '+252611111111',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Credit Limit'),
        '1000.00',
      );

      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Customer'));
      await tester.pumpAndSettle();

      verify(
        () => mockRepository.createCustomer(
          name: 'New Customer',
          phone: '+252611111111',
          address: null,
          creditLimit: '1000.00',
          phoneNumbers: any(named: 'phoneNumbers'),
        ),
      ).called(1);
      // Popped back to the router's home route (no Add Customer screen left).
      expect(find.byType(AddEditCustomerScreen), findsNothing);
    });

    testWidgets('shows a live duplicate warning after typing name and phone', (
      tester,
    ) async {
      const warning = DuplicateWarning(
        type: 'POSSIBLE_DUPLICATE_CUSTOMER',
        message: 'This customer may already exist.',
        matchedCustomerId: '99',
      );
      when(
        () => mockRepository.checkDuplicateCustomer(
          name: 'Somali Builders',
          phone: '+252612345678',
        ),
      ).thenAnswer((_) async => warning);

      await _pumpScreen(tester, repository: mockRepository);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Name'),
        'Somali Builders',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Phone'),
        '+252612345678',
      );
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      expect(find.text('This customer may already exist.'), findsOneWidget);
    });

    testWidgets(
      'shows a dialog with a link to the existing customer when the save itself returns a warning',
      (tester) async {
        const warning = DuplicateWarning(
          type: 'POSSIBLE_DUPLICATE_CUSTOMER',
          message: 'This customer may already exist.',
          matchedCustomerId: '99',
        );
        when(
          () => mockRepository.checkDuplicateCustomer(
            name: any(named: 'name'),
            phone: any(named: 'phone'),
          ),
        ).thenAnswer((_) async => null);
        when(
          () => mockRepository.createCustomer(
            name: 'New Customer',
            phone: '+252611111111',
            address: null,
            creditLimit: '1000.00',
            phoneNumbers: any(named: 'phoneNumbers'),
          ),
        ).thenAnswer(
          (_) async => (customer: _existingCustomer, warning: warning),
        );

        await _pumpScreen(tester, repository: mockRepository);
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Name'),
          'New Customer',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Phone'),
          '+252611111111',
        );
        // Flush the live-duplicate-check debounce before submitting so it
        // can't fire mid-way through the submit button's own pumpAndSettle.
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Credit Limit'),
          '1000.00',
        );

        await tester.tap(find.widgetWithText(ElevatedButton, 'Add Customer'));
        await tester.pumpAndSettle();

        expect(find.text('Possible Duplicate'), findsOneWidget);

        await tester.tap(find.text('View Existing Customer'));
        await tester.pumpAndSettle();

        expect(find.text('Customer Detail 99'), findsOneWidget);
      },
    );
  });

  group('Edit Customer', () {
    testWidgets('prefills fields from the existing customer', (tester) async {
      when(
        () => mockRepository.fetchCustomer('1'),
      ).thenAnswer((_) async => _existingCustomer);

      await _pumpScreen(tester, repository: mockRepository, customerId: '1');
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextFormField, 'Name'), findsOneWidget);
      expect(find.text('Somali Builders'), findsOneWidget);
      expect(find.text('+252612345678'), findsOneWidget);
      expect(find.text('5000.00'), findsOneWidget);
    });

    testWidgets('submits the updated fields without a live duplicate check', (
      tester,
    ) async {
      when(
        () => mockRepository.fetchCustomer('1'),
      ).thenAnswer((_) async => _existingCustomer);
      when(
        () => mockRepository.updateCustomer(
          id: '1',
          name: 'Somali Builders',
          phone: '+252612345678',
          address: null,
          creditLimit: '9000.00',
          phoneNumbers: any(named: 'phoneNumbers'),
        ),
      ).thenAnswer((_) async => (customer: _existingCustomer, warning: null));

      await _pumpScreen(tester, repository: mockRepository, customerId: '1');
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Credit Limit'),
        '9000.00',
      );
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      verify(
        () => mockRepository.updateCustomer(
          id: '1',
          name: 'Somali Builders',
          phone: '+252612345678',
          address: null,
          creditLimit: '9000.00',
          phoneNumbers: any(named: 'phoneNumbers'),
        ),
      ).called(1);
      verifyNever(
        () => mockRepository.checkDuplicateCustomer(
          name: any(named: 'name'),
          phone: any(named: 'phone'),
        ),
      );
    });
  });

  group('Draft mode (deferSubmit — Add Case wizard\'s New Customer step)', () {
    Future<void> pumpDraftScreen(
      WidgetTester tester, {
      required _MockCustomerRepository repository,
    }) async {
      CustomerDraft? popped;
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  popped = await context.push<CustomerDraft>('/draft');
                },
                child: Text(
                  popped == null ? 'Open Draft Form' : 'Draft: ${popped!.name}',
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/draft',
            builder: (_, _) => const AddEditCustomerScreen(deferSubmit: true),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [customerRepositoryProvider.overrideWithValue(repository)],
          child: MaterialApp.router(
            routerConfig: router,
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: _localizationsDelegates,
          ),
        ),
      );
      await tester.tap(find.text('Open Draft Form'));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'shows "Customer Details" title and a "Continue" button, not "Add Customer"',
      (tester) async {
        await pumpDraftScreen(tester, repository: mockRepository);

        expect(find.text('Customer Details'), findsOneWidget);
        expect(find.widgetWithText(ElevatedButton, 'Continue'), findsOneWidget);
      },
    );

    testWidgets(
      'submitting pops with a CustomerDraft instead of calling the create API',
      (tester) async {
        await pumpDraftScreen(tester, repository: mockRepository);

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Name'),
          'New Customer',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Phone'),
          '+252611111111',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Credit Limit'),
          '1000.00',
        );

        await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
        await tester.pumpAndSettle();

        verifyNever(
          () => mockRepository.createCustomer(
            name: any(named: 'name'),
            phone: any(named: 'phone'),
            address: any(named: 'address'),
            creditLimit: any(named: 'creditLimit'),
            phoneNumbers: any(named: 'phoneNumbers'),
          ),
        );
        expect(find.text('Draft: New Customer'), findsOneWidget);
      },
    );
  });

  testWidgets(
    'Mobile Fix #5: Add Customer stays reachable and tappable on a short viewport with a system nav bar inset',
    (tester) async {
      tester.view.physicalSize = const Size(400, 500);
      tester.view.devicePixelRatio = 1.0;
      tester.view.padding = const FakeViewPadding(bottom: 48);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);

      when(
        () => mockRepository.checkDuplicateCustomer(
          name: any(named: 'name'),
          phone: any(named: 'phone'),
        ),
      ).thenAnswer((_) async => null);
      when(
        () => mockRepository.createCustomer(
          name: 'New Customer',
          phone: '+252611111111',
          address: null,
          creditLimit: '1000.00',
          phoneNumbers: any(named: 'phoneNumbers'),
        ),
      ).thenAnswer((_) async => (customer: _existingCustomer, warning: null));

      await _pumpScreen(tester, repository: mockRepository);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Name'),
        'New Customer',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Phone'),
        '+252611111111',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Credit Limit'),
        '1000.00',
      );
      await tester.pump();

      // Fix #23 made this form taller (the multi-phone editor), so the
      // submit button now starts out beyond the ListView's cache extent
      // and isn't built into the tree at all yet — plain `ensureVisible`
      // can't scroll to a widget that doesn't exist. `scrollUntilVisible`
      // scrolls incrementally and re-checks after each step, which
      // handles that correctly.
      await tester.scrollUntilVisible(
        find.widgetWithText(ElevatedButton, 'Add Customer'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Customer'));
      await tester.pumpAndSettle();

      verify(
        () => mockRepository.createCustomer(
          name: 'New Customer',
          phone: '+252611111111',
          address: null,
          creditLimit: '1000.00',
          phoneNumbers: any(named: 'phoneNumbers'),
        ),
      ).called(1);
      expect(tester.takeException(), isNull);
    },
  );

  group('Multiple phone numbers (Fix #23)', () {
    testWidgets(
      'Add Customer starts with exactly one phone field and no Remove button',
      (tester) async {
        await _pumpScreen(tester, repository: mockRepository);
        await tester.pumpAndSettle();

        expect(find.widgetWithText(TextFormField, 'Phone'), findsOneWidget);
        expect(find.byIcon(Icons.close), findsNothing);
        expect(find.text('Add Phone'), findsOneWidget);
      },
    );

    testWidgets('Add Phone adds a second, non-primary phone field', (
      tester,
    ) async {
      await _pumpScreen(tester, repository: mockRepository);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Phone'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextFormField, 'Phone'), findsNWidgets(2));
      expect(find.text('Primary'), findsOneWidget);
      expect(find.text('Set Primary'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsNWidgets(2));
    });

    testWidgets(
      'a third phone can be added but a fourth cannot — Add Phone is replaced by the max-reached message',
      (tester) async {
        await _pumpScreen(tester, repository: mockRepository);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Add Phone'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Add Phone'));
        await tester.pumpAndSettle();

        expect(find.widgetWithText(TextFormField, 'Phone'), findsNWidgets(3));
        expect(find.text('Add Phone'), findsNothing);
        expect(
          find.text('You can add up to 3 phone numbers.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('Set Primary moves the Primary badge to the chosen entry', (
      tester,
    ) async {
      await _pumpScreen(tester, repository: mockRepository);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Phone'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Set Primary'));
      await tester.pumpAndSettle();

      expect(find.text('Set Primary'), findsOneWidget); // now on the other row
      expect(find.text('Primary'), findsOneWidget);
    });

    testWidgets(
      'saving submits phoneNumbers with the chosen primary and the entered secondary number',
      (tester) async {
        when(
          () => mockRepository.checkDuplicateCustomer(
            name: any(named: 'name'),
            phone: any(named: 'phone'),
          ),
        ).thenAnswer((_) async => null);
        when(
          () => mockRepository.createCustomer(
            name: any(named: 'name'),
            phone: any(named: 'phone'),
            address: any(named: 'address'),
            creditLimit: any(named: 'creditLimit'),
            phoneNumbers: any(named: 'phoneNumbers'),
          ),
        ).thenAnswer((_) async => (customer: _existingCustomer, warning: null));

        await _pumpScreen(tester, repository: mockRepository);
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Name'),
          'New Customer',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Phone').at(0),
          '+252611111111',
        );
        await tester.tap(find.text('Add Phone'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Phone').at(1),
          '+252622222222',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Credit Limit'),
          '1000.00',
        );

        await tester.scrollUntilVisible(
          find.widgetWithText(ElevatedButton, 'Add Customer'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.widgetWithText(ElevatedButton, 'Add Customer'));
        await tester.pumpAndSettle();

        final captured = verify(
          () => mockRepository.createCustomer(
            name: 'New Customer',
            phone: '+252611111111',
            address: null,
            creditLimit: '1000.00',
            phoneNumbers: captureAny(named: 'phoneNumbers'),
          ),
        ).captured;
        final phoneNumbers = captured.single as List<CustomerPhoneNumber>;
        expect(phoneNumbers, hasLength(2));
        expect(phoneNumbers[0].phone, '+252611111111');
        expect(phoneNumbers[0].isPrimary, isTrue);
        expect(phoneNumbers[1].phone, '+252622222222');
        expect(phoneNumbers[1].isPrimary, isFalse);
      },
    );

    testWidgets(
      'removing the primary entry promotes the remaining one to primary',
      (tester) async {
        await _pumpScreen(tester, repository: mockRepository);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Add Phone'));
        await tester.pumpAndSettle();

        // Row 0 is primary; remove it via its Remove (close) icon.
        await tester.tap(find.byIcon(Icons.close).first);
        await tester.pumpAndSettle();

        expect(find.widgetWithText(TextFormField, 'Phone'), findsOneWidget);
        expect(find.text('Primary'), findsOneWidget);
        // Only one phone left — Remove is hidden again.
        expect(find.byIcon(Icons.close), findsNothing);
      },
    );

    testWidgets('Edit Customer prefills every existing phone number', (
      tester,
    ) async {
      when(
        () => mockRepository.fetchCustomer('2'),
      ).thenAnswer((_) async => _existingCustomerWithTwoPhones);

      await _pumpScreen(tester, repository: mockRepository, customerId: '2');
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextFormField, 'Phone'), findsNWidgets(2));
      expect(find.text('+252611111111'), findsOneWidget);
      expect(find.text('+252622222222'), findsOneWidget);
      expect(find.text('Primary'), findsOneWidget);
    });

    testWidgets(
      'saving an edit with an existing phone id updates rather than duplicating it',
      (tester) async {
        when(
          () => mockRepository.fetchCustomer('2'),
        ).thenAnswer((_) async => _existingCustomerWithTwoPhones);
        when(
          () => mockRepository.updateCustomer(
            id: '2',
            name: 'Hodan Store',
            phone: '+252611111111',
            address: null,
            creditLimit: '3000.00',
            phoneNumbers: any(named: 'phoneNumbers'),
          ),
        ).thenAnswer(
          (_) async => (customer: _existingCustomerWithTwoPhones, warning: null),
        );

        await _pumpScreen(tester, repository: mockRepository, customerId: '2');
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save Changes'));
        await tester.pumpAndSettle();

        final captured = verify(
          () => mockRepository.updateCustomer(
            id: '2',
            name: 'Hodan Store',
            phone: '+252611111111',
            address: null,
            creditLimit: '3000.00',
            phoneNumbers: captureAny(named: 'phoneNumbers'),
          ),
        ).captured;
        final phoneNumbers = captured.single as List<CustomerPhoneNumber>;
        expect(phoneNumbers.map((p) => p.id), containsAll(['p1', 'p2']));
      },
    );
  });
}
