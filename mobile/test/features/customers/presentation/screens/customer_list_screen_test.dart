import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/customers/data/customer_repository.dart';
import 'package:mobile/features/customers/domain/customer.dart';
import 'package:mobile/features/customers/domain/customer_page.dart';
import 'package:mobile/features/customers/presentation/screens/customer_list_screen.dart';
import 'package:mocktail/mocktail.dart';

class _MockCustomerRepository extends Mock implements CustomerRepository {}

const _customer = Customer(
  id: '1',
  name: 'Somali Builders',
  phone: '+252612345678',
  customerStatus: 'good_standing',
  creditLimit: '5000.00',
  outstandingBalance: '800.00',
  remainingCredit: '4200.00',
  riskLevel: 'low',
  creditScore: 720,
  creditScoreBand: 'good',
);

Future<void> _pumpScreen(WidgetTester tester, {required _MockCustomerRepository mockRepository}) async {
  tester.view.physicalSize = const Size(400, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [customerRepositoryProvider.overrideWithValue(mockRepository)],
      child: const MaterialApp(home: CustomerListScreen()),
    ),
  );
}

void main() {
  late _MockCustomerRepository mockRepository;

  setUp(() {
    mockRepository = _MockCustomerRepository();
  });

  testWidgets('shows a loading indicator before data arrives', (tester) async {
    when(() => mockRepository.fetchCustomers(page: 1, search: '', status: null, riskLevel: null))
        .thenAnswer((_) => Future.delayed(const Duration(seconds: 1),
            () => const CustomerPage(customers: [], currentPage: 1, lastPage: 1, total: 0)));

    await _pumpScreen(tester, mockRepository: mockRepository);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('renders customer cards with the real backend fields', (tester) async {
    when(() => mockRepository.fetchCustomers(page: 1, search: '', status: null, riskLevel: null))
        .thenAnswer((_) async => const CustomerPage(customers: [_customer], currentPage: 1, lastPage: 1, total: 1));

    await _pumpScreen(tester, mockRepository: mockRepository);
    await tester.pumpAndSettle();

    expect(find.text('Somali Builders'), findsOneWidget);
    expect(find.text('+252612345678'), findsOneWidget);
    expect(find.text('800.00'), findsOneWidget);
    expect(find.text('Low'), findsOneWidget);
    expect(find.text('Good Standing'), findsOneWidget);
  });

  testWidgets('shows the explicit empty state when there are no customers', (tester) async {
    when(() => mockRepository.fetchCustomers(page: 1, search: '', status: null, riskLevel: null))
        .thenAnswer((_) async => const CustomerPage(customers: [], currentPage: 1, lastPage: 1, total: 0));

    await _pumpScreen(tester, mockRepository: mockRepository);
    await tester.pumpAndSettle();

    expect(find.text('No customers yet'), findsOneWidget);
  });

  testWidgets('shows a retry affordance when the list fails to load', (tester) async {
    when(() => mockRepository.fetchCustomers(page: 1, search: '', status: null, riskLevel: null))
        .thenThrow(Exception('network down'));

    await _pumpScreen(tester, mockRepository: mockRepository);
    await tester.pumpAndSettle();

    expect(find.text('Could not load customers.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('typing in the search field triggers a real API call with the query', (tester) async {
    when(() => mockRepository.fetchCustomers(page: 1, search: '', status: null, riskLevel: null))
        .thenAnswer((_) async => const CustomerPage(customers: [_customer], currentPage: 1, lastPage: 1, total: 1));
    when(() => mockRepository.fetchCustomers(page: 1, search: 'somali', status: null, riskLevel: null))
        .thenAnswer((_) async => const CustomerPage(customers: [_customer], currentPage: 1, lastPage: 1, total: 1));

    await _pumpScreen(tester, mockRepository: mockRepository);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'somali');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    verify(() => mockRepository.fetchCustomers(page: 1, search: 'somali', status: null, riskLevel: null)).called(1);
  });
}
