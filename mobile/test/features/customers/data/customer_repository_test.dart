import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/models/document_summary.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/features/customers/data/customer_api.dart';
import 'package:mobile/features/customers/data/customer_repository.dart';
import 'package:mobile/features/customers/domain/customer.dart';
import 'package:mobile/features/customers/domain/customer_page.dart';
import 'package:mobile/features/customers/domain/duplicate_warning.dart';
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
  archivedAt: null,
);

void main() {
  late _MockCustomerApi mockApi;
  late CustomerRepository repository;

  setUp(() {
    mockApi = _MockCustomerApi();
    repository = CustomerRepository(mockApi);
  });

  test(
    'fetchCustomers passes search/page through and returns the page',
    () async {
      const page = CustomerPage(
        customers: [_customer],
        currentPage: 1,
        lastPage: 2,
        total: 21,
      );
      when(
        () => mockApi.list(
          page: 1,
          search: 'somali',
          status: null,
          riskLevel: null,
        ),
      ).thenAnswer((_) async => page);

      final result = await repository.fetchCustomers(page: 1, search: 'somali');

      expect(result.customers, [_customer]);
      verify(
        () => mockApi.list(
          page: 1,
          search: 'somali',
          status: null,
          riskLevel: null,
        ),
      ).called(1);
    },
  );

  test('fetchCustomers throws ApiException on failure', () async {
    when(
      () => mockApi.list(page: 1, search: '', status: null, riskLevel: null),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/customers'),
        response: Response(
          requestOptions: RequestOptions(path: '/customers'),
          statusCode: 401,
          data: {
            'success': false,
            'message': 'Unauthenticated.',
            'data': null,
            'errors': null,
          },
        ),
        type: DioExceptionType.badResponse,
      ),
    );

    expect(
      () => repository.fetchCustomers(page: 1),
      throwsA(
        isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
      ),
    );
  });

  test('fetchCustomer returns the customer straight through', () async {
    when(() => mockApi.show('1')).thenAnswer((_) async => _customer);

    final result = await repository.fetchCustomer('1');

    expect(result, _customer);
  });

  test('fetchPayments delegates to the api', () async {
    when(() => mockApi.payments('1')).thenAnswer((_) async => []);

    final result = await repository.fetchPayments('1');

    expect(result, isEmpty);
    verify(() => mockApi.payments('1')).called(1);
  });

  test('fetchCustomers passes includeArchived through', () async {
    const page = CustomerPage(
      customers: [_customer],
      currentPage: 1,
      lastPage: 1,
      total: 1,
    );
    when(
      () => mockApi.list(
        page: 1,
        search: '',
        status: null,
        riskLevel: null,
        includeArchived: true,
      ),
    ).thenAnswer((_) async => page);

    final result = await repository.fetchCustomers(
      page: 1,
      includeArchived: true,
    );

    expect(result.customers, [_customer]);
    verify(
      () => mockApi.list(
        page: 1,
        search: '',
        status: null,
        riskLevel: null,
        includeArchived: true,
      ),
    ).called(1);
  });

  test('fetchDocuments delegates to the api', () async {
    const document = DocumentSummary(
      id: '1',
      documentType: 'invoice',
      referenceNumber: 'INV-0001',
      generatedAt: '2026-07-01T00:00:00.000000Z',
      fileSize: 1024,
    );
    when(() => mockApi.documents('1')).thenAnswer((_) async => [document]);

    final result = await repository.fetchDocuments('1');

    expect(result, [document]);
  });

  test(
    'createCustomer delegates every field to the api and returns the save result',
    () async {
      const result = (customer: _customer, warning: null);
      when(
        () => mockApi.store(
          name: 'Somali Builders',
          phone: '+252612345678',
          address: null,
          creditLimit: '5000.00',
        ),
      ).thenAnswer((_) async => result);

      final saved = await repository.createCustomer(
        name: 'Somali Builders',
        phone: '+252612345678',
        creditLimit: '5000.00',
      );

      expect(saved.customer, _customer);
      expect(saved.warning, isNull);
    },
  );

  test(
    'createCustomer surfaces a possible-duplicate warning when present',
    () async {
      const warning = DuplicateWarning(
        type: 'POSSIBLE_DUPLICATE_CUSTOMER',
        message: 'This customer may already exist.',
        matchedCustomerId: '99',
      );
      const result = (customer: _customer, warning: warning);
      when(
        () => mockApi.store(
          name: 'Somali Builders',
          phone: '+252612345678',
          address: null,
          creditLimit: '5000.00',
        ),
      ).thenAnswer((_) async => result);

      final saved = await repository.createCustomer(
        name: 'Somali Builders',
        phone: '+252612345678',
        creditLimit: '5000.00',
      );

      expect(saved.warning, warning);
    },
  );

  test('updateCustomer delegates every field to the api', () async {
    const result = (customer: _customer, warning: null);
    when(
      () => mockApi.update(
        id: '1',
        name: 'Somali Builders',
        phone: '+252612345678',
        address: null,
        creditLimit: '6000.00',
      ),
    ).thenAnswer((_) async => result);

    final saved = await repository.updateCustomer(
      id: '1',
      name: 'Somali Builders',
      phone: '+252612345678',
      creditLimit: '6000.00',
    );

    expect(saved.customer, _customer);
  });

  test(
    'createCustomer passes a real address through when given one (Item 13)',
    () async {
      const result = (customer: _customer, warning: null);
      when(
        () => mockApi.store(
          name: 'Somali Builders',
          phone: '+252612345678',
          address: '123 Market Street',
          creditLimit: '5000.00',
        ),
      ).thenAnswer((_) async => result);

      await repository.createCustomer(
        name: 'Somali Builders',
        phone: '+252612345678',
        address: '123 Market Street',
        creditLimit: '5000.00',
      );

      verify(
        () => mockApi.store(
          name: 'Somali Builders',
          phone: '+252612345678',
          address: '123 Market Street',
          creditLimit: '5000.00',
        ),
      ).called(1);
    },
  );

  test('archiveCustomer delegates to the api', () async {
    when(() => mockApi.archive('1')).thenAnswer((_) async {});

    await repository.archiveCustomer('1');

    verify(() => mockApi.archive('1')).called(1);
  });

  test('restoreCustomer delegates to the api', () async {
    when(() => mockApi.restore('1')).thenAnswer((_) async => _customer);

    final result = await repository.restoreCustomer('1');

    expect(result, _customer);
  });

  test('updateCreditLimit delegates to the api', () async {
    when(
      () => mockApi.updateCreditLimit(id: '1', creditLimit: '7000.00'),
    ).thenAnswer((_) async => _customer);

    final result = await repository.updateCreditLimit(
      id: '1',
      creditLimit: '7000.00',
    );

    expect(result, _customer);
  });

  test('updateStatus delegates to the api', () async {
    when(
      () => mockApi.updateStatus(id: '1', customerStatus: 'high_risk'),
    ).thenAnswer((_) async => _customer);

    final result = await repository.updateStatus(
      id: '1',
      customerStatus: 'high_risk',
    );

    expect(result, _customer);
  });

  test(
    'updateStatus throws ApiException on a read-only customer (403)',
    () async {
      when(
        () => mockApi.updateStatus(id: '1', customerStatus: 'high_risk'),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/customers/1/status'),
          response: Response(
            requestOptions: RequestOptions(path: '/customers/1/status'),
            statusCode: 403,
            data: {
              'success': false,
              'message': 'This action is unauthorized.',
              'data': null,
              'errors': null,
            },
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      expect(
        () => repository.updateStatus(id: '1', customerStatus: 'high_risk'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 403),
        ),
      );
    },
  );

  test('checkDuplicateCustomer delegates to the api', () async {
    const warning = DuplicateWarning(
      type: 'POSSIBLE_DUPLICATE_CUSTOMER',
      message: 'This customer may already exist.',
      matchedCustomerId: '99',
    );
    when(
      () => mockApi.checkDuplicate(
        name: 'Somali Builders',
        phone: '+252612345678',
      ),
    ).thenAnswer((_) async => warning);

    final result = await repository.checkDuplicateCustomer(
      name: 'Somali Builders',
      phone: '+252612345678',
    );

    expect(result, warning);
  });

  test('generateStatement delegates to the api', () async {
    const statement = DocumentSummary(
      id: '1',
      documentType: 'statement',
      referenceNumber: 'STM-0001',
      generatedAt: '2026-08-01T00:00:00.000000Z',
      fileSize: 3000,
    );
    when(
      () => mockApi.generateStatement('1'),
    ).thenAnswer((_) async => statement);

    final result = await repository.generateStatement('1');

    expect(result, statement);
  });
}
