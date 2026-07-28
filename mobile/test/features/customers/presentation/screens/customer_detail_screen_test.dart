import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/customers/data/customer_repository.dart';
import 'package:mobile/features/customers/domain/customer.dart';
import 'package:mobile/features/customers/domain/customer_payment.dart';
import 'package:mobile/features/customers/presentation/screens/customer_detail_screen.dart';
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

final _payment = CustomerPayment(
  id: '01PAY',
  debtId: '01DEBT',
  amount: '250.00',
  paymentDate: '2026-07-20',
  paymentMethod: 'cash',
);

Future<void> _pumpScreen(WidgetTester tester, {required _MockCustomerRepository mockRepository}) async {
  tester.view.physicalSize = const Size(400, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [customerRepositoryProvider.overrideWithValue(mockRepository)],
      child: const MaterialApp(home: CustomerDetailScreen(customerId: '1')),
    ),
  );
}

void main() {
  late _MockCustomerRepository mockRepository;

  setUp(() {
    mockRepository = _MockCustomerRepository();
  });

  testWidgets('renders customer info and recent payments from the real backend fields', (tester) async {
    when(() => mockRepository.fetchCustomer('1')).thenAnswer((_) async => _customer);
    when(() => mockRepository.fetchCustomerPayments('1')).thenAnswer((_) async => [_payment]);

    await _pumpScreen(tester, mockRepository: mockRepository);
    await tester.pumpAndSettle();

    expect(find.text('Somali Builders'), findsWidgets); // AppBar title + info card
    expect(find.text('+252612345678'), findsOneWidget);
    expect(find.text('800.00'), findsOneWidget);
    expect(find.text('5000.00'), findsOneWidget);
    expect(find.text('4200.00'), findsOneWidget);
    expect(find.text('720 (good)'), findsOneWidget);
    expect(find.text('250.00'), findsOneWidget);
    expect(find.text('cash'), findsOneWidget);

    // Active Cases / Recent Follow-ups are deliberately not rendered — no
    // backend endpoint scopes either to a single customer.
    expect(find.textContaining('Active Cases'), findsNothing);
    expect(find.textContaining('Follow-up'), findsNothing);
  });

  testWidgets('shows the explicit empty state when there are no payments', (tester) async {
    when(() => mockRepository.fetchCustomer('1')).thenAnswer((_) async => _customer);
    when(() => mockRepository.fetchCustomerPayments('1')).thenAnswer((_) async => []);

    await _pumpScreen(tester, mockRepository: mockRepository);
    await tester.pumpAndSettle();

    expect(find.text('No recent payments'), findsOneWidget);
  });

  testWidgets('shows a retry affordance when the customer fails to load', (tester) async {
    when(() => mockRepository.fetchCustomer('1')).thenThrow(Exception('network down'));
    when(() => mockRepository.fetchCustomerPayments('1')).thenAnswer((_) async => []);

    await _pumpScreen(tester, mockRepository: mockRepository);
    await tester.pumpAndSettle();

    expect(find.text('Could not load this customer.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
