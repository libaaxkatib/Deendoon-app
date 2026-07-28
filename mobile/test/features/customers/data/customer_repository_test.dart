import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/features/customers/data/customer_api.dart';
import 'package:mobile/features/customers/data/customer_repository.dart';
import 'package:mobile/features/customers/domain/customer.dart';
import 'package:mobile/features/customers/domain/customer_page.dart';
import 'package:mocktail/mocktail.dart';

class _MockCustomerApi extends Mock implements CustomerApi {}

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

void main() {
  late _MockCustomerApi mockApi;
  late CustomerRepository repository;

  setUp(() {
    mockApi = _MockCustomerApi();
    repository = CustomerRepository(mockApi);
  });

  test('fetchCustomers passes search/page through and returns the page', () async {
    const page = CustomerPage(customers: [_customer], currentPage: 1, lastPage: 2, total: 21);
    when(() => mockApi.list(page: 1, search: 'somali', status: null, riskLevel: null))
        .thenAnswer((_) async => page);

    final result = await repository.fetchCustomers(page: 1, search: 'somali');

    expect(result.customers, [_customer]);
    verify(() => mockApi.list(page: 1, search: 'somali', status: null, riskLevel: null)).called(1);
  });

  test('fetchCustomers throws ApiException on failure', () async {
    when(() => mockApi.list(page: 1, search: '', status: null, riskLevel: null)).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/customers'),
        response: Response(
          requestOptions: RequestOptions(path: '/customers'),
          statusCode: 401,
          data: {'success': false, 'message': 'Unauthenticated.', 'data': null, 'errors': null},
        ),
        type: DioExceptionType.badResponse,
      ),
    );

    expect(
      () => repository.fetchCustomers(page: 1),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401)),
    );
  });

  test('fetchCustomer returns the customer straight through', () async {
    when(() => mockApi.show('1')).thenAnswer((_) async => _customer);

    final result = await repository.fetchCustomer('1');

    expect(result, _customer);
  });

  test('fetchCustomerPayments delegates to the api', () async {
    when(() => mockApi.payments('1')).thenAnswer((_) async => []);

    final result = await repository.fetchCustomerPayments('1');

    expect(result, isEmpty);
    verify(() => mockApi.payments('1')).called(1);
  });
}
