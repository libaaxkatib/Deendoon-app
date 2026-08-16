import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/customers/data/customer_repository.dart';
import 'package:mobile/features/customers/domain/customer.dart';
import 'package:mobile/features/customers/domain/customer_page.dart';
import 'package:mobile/features/customers/presentation/providers/customer_list_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockCustomerRepository extends Mock implements CustomerRepository {}

const _pageOneCustomer = Customer(
  id: '1',
  name: 'Somali Builders',
  phone: '111',
  customerStatus: 'active',
  creditLimit: '0.00',
  outstandingBalance: '0.00',
  remainingCredit: '0.00',
  riskLevel: null,
  creditScore: null,
  creditScoreBand: null,
  archivedAt: null,
);

const _pageTwoCustomer = Customer(
  id: '2',
  name: 'Hargeisa Traders',
  phone: '222',
  customerStatus: 'active',
  creditLimit: '0.00',
  outstandingBalance: '0.00',
  remainingCredit: '0.00',
  riskLevel: null,
  creditScore: null,
  creditScoreBand: null,
  archivedAt: null,
);

void main() {
  late _MockCustomerRepository mockRepository;
  late ProviderContainer container;

  setUp(() {
    mockRepository = _MockCustomerRepository();
    container = ProviderContainer(
      overrides: [customerRepositoryProvider.overrideWithValue(mockRepository)],
    );
    addTearDown(container.dispose);
  });

  test('build() fetches page 1 with an empty search term', () async {
    when(
      () => mockRepository.fetchCustomers(
        page: 1,
        search: '',
        status: null,
        riskLevel: null,
      ),
    ).thenAnswer(
      (_) async => const CustomerPage(
        customers: [_pageOneCustomer],
        currentPage: 1,
        lastPage: 2,
        total: 30,
      ),
    );

    final state = await container.read(customerListProvider.future);

    expect(state.customers, [_pageOneCustomer]);
    expect(state.hasMore, isTrue);
  });

  test(
    'search() resets to page 1 under the new term via a real API call',
    () async {
      when(
        () => mockRepository.fetchCustomers(
          page: 1,
          search: '',
          status: null,
          riskLevel: null,
        ),
      ).thenAnswer(
        (_) async => const CustomerPage(
          customers: [_pageOneCustomer],
          currentPage: 1,
          lastPage: 1,
          total: 1,
        ),
      );
      await container.read(customerListProvider.future);

      when(
        () => mockRepository.fetchCustomers(
          page: 1,
          search: 'hargeisa',
          status: null,
          riskLevel: null,
        ),
      ).thenAnswer(
        (_) async => const CustomerPage(
          customers: [_pageTwoCustomer],
          currentPage: 1,
          lastPage: 1,
          total: 1,
        ),
      );

      await container.read(customerListProvider.notifier).search('hargeisa');

      final state = container.read(customerListProvider).value!;
      expect(state.customers, [_pageTwoCustomer]);
      expect(state.search, 'hargeisa');
      verify(
        () => mockRepository.fetchCustomers(
          page: 1,
          search: 'hargeisa',
          status: null,
          riskLevel: null,
        ),
      ).called(1);
    },
  );

  test(
    'loadMore() appends the next page and stops once lastPage is reached',
    () async {
      when(
        () => mockRepository.fetchCustomers(
          page: 1,
          search: '',
          status: null,
          riskLevel: null,
        ),
      ).thenAnswer(
        (_) async => const CustomerPage(
          customers: [_pageOneCustomer],
          currentPage: 1,
          lastPage: 2,
          total: 2,
        ),
      );
      await container.read(customerListProvider.future);

      when(
        () => mockRepository.fetchCustomers(
          page: 2,
          search: '',
          status: null,
          riskLevel: null,
        ),
      ).thenAnswer(
        (_) async => const CustomerPage(
          customers: [_pageTwoCustomer],
          currentPage: 2,
          lastPage: 2,
          total: 2,
        ),
      );

      await container.read(customerListProvider.notifier).loadMore();

      final state = container.read(customerListProvider).value!;
      expect(state.customers, [_pageOneCustomer, _pageTwoCustomer]);
      expect(state.hasMore, isFalse);

      // Calling loadMore() again must not fire a duplicate request — there is
      // no further page.
      await container.read(customerListProvider.notifier).loadMore();
      verifyNever(
        () => mockRepository.fetchCustomers(
          page: 3,
          search: any(named: 'search'),
          status: any(named: 'status'),
          riskLevel: any(named: 'riskLevel'),
        ),
      );
    },
  );

  test(
    'loadMore() sets loadMoreError and preserves existing state when the request fails',
    () async {
      when(
        () => mockRepository.fetchCustomers(
          page: 1,
          search: '',
          status: null,
          riskLevel: null,
        ),
      ).thenAnswer(
        (_) async => const CustomerPage(
          customers: [_pageOneCustomer],
          currentPage: 1,
          lastPage: 2,
          total: 2,
        ),
      );
      await container.read(customerListProvider.future);

      when(
        () => mockRepository.fetchCustomers(
          page: 2,
          search: '',
          status: null,
          riskLevel: null,
        ),
      ).thenThrow(Exception('network error'));

      await container.read(customerListProvider.notifier).loadMore();

      final state = container.read(customerListProvider).value!;
      expect(state.loadMoreError, isTrue);
      expect(state.isLoadingMore, isFalse);
      expect(state.customers, [_pageOneCustomer]);
      expect(state.currentPage, 1);
      expect(state.lastPage, 2);
      expect(state.hasMore, isTrue);
    },
  );

  test(
    'loadMore() retried after a failure clears loadMoreError, re-requests the same page, and appends on success',
    () async {
      when(
        () => mockRepository.fetchCustomers(
          page: 1,
          search: '',
          status: null,
          riskLevel: null,
        ),
      ).thenAnswer(
        (_) async => const CustomerPage(
          customers: [_pageOneCustomer],
          currentPage: 1,
          lastPage: 2,
          total: 2,
        ),
      );
      await container.read(customerListProvider.future);

      when(
        () => mockRepository.fetchCustomers(
          page: 2,
          search: '',
          status: null,
          riskLevel: null,
        ),
      ).thenThrow(Exception('network error'));
      await container.read(customerListProvider.notifier).loadMore();
      expect(container.read(customerListProvider).value!.loadMoreError, isTrue);

      when(
        () => mockRepository.fetchCustomers(
          page: 2,
          search: '',
          status: null,
          riskLevel: null,
        ),
      ).thenAnswer(
        (_) async => const CustomerPage(
          customers: [_pageTwoCustomer],
          currentPage: 2,
          lastPage: 2,
          total: 2,
        ),
      );

      await container.read(customerListProvider.notifier).loadMore();

      final state = container.read(customerListProvider).value!;
      expect(state.loadMoreError, isFalse);
      expect(state.isLoadingMore, isFalse);
      expect(state.customers, [_pageOneCustomer, _pageTwoCustomer]);
      expect(state.hasMore, isFalse);
      verify(
        () => mockRepository.fetchCustomers(
          page: 2,
          search: '',
          status: null,
          riskLevel: null,
        ),
      ).called(2);
    },
  );

  test(
    'refresh() re-fetches page 1 preserving the current search term',
    () async {
      when(
        () => mockRepository.fetchCustomers(
          page: 1,
          search: '',
          status: null,
          riskLevel: null,
        ),
      ).thenAnswer(
        (_) async => const CustomerPage(
          customers: [_pageOneCustomer],
          currentPage: 1,
          lastPage: 1,
          total: 1,
        ),
      );
      await container.read(customerListProvider.future);

      when(
        () => mockRepository.fetchCustomers(
          page: 1,
          search: '',
          status: null,
          riskLevel: null,
        ),
      ).thenAnswer(
        (_) async => const CustomerPage(
          customers: [_pageOneCustomer, _pageTwoCustomer],
          currentPage: 1,
          lastPage: 1,
          total: 2,
        ),
      );

      await container.read(customerListProvider.notifier).refresh();

      final state = container.read(customerListProvider).value!;
      expect(state.customers, [_pageOneCustomer, _pageTwoCustomer]);
    },
  );

  test(
    'toggleIncludeArchived() re-fetches page 1 with a real includeArchived query param',
    () async {
      when(
        () => mockRepository.fetchCustomers(
          page: 1,
          search: '',
          status: null,
          riskLevel: null,
        ),
      ).thenAnswer(
        (_) async => const CustomerPage(
          customers: [_pageOneCustomer],
          currentPage: 1,
          lastPage: 1,
          total: 1,
        ),
      );
      await container.read(customerListProvider.future);

      when(
        () => mockRepository.fetchCustomers(
          page: 1,
          search: '',
          status: null,
          riskLevel: null,
          includeArchived: true,
        ),
      ).thenAnswer(
        (_) async => const CustomerPage(
          customers: [_pageOneCustomer, _pageTwoCustomer],
          currentPage: 1,
          lastPage: 1,
          total: 2,
        ),
      );

      await container
          .read(customerListProvider.notifier)
          .toggleIncludeArchived();

      final state = container.read(customerListProvider).value!;
      expect(state.includeArchived, isTrue);
      expect(state.customers, [_pageOneCustomer, _pageTwoCustomer]);

      // Toggling again goes back to the default (excluded) filter.
      when(
        () => mockRepository.fetchCustomers(
          page: 1,
          search: '',
          status: null,
          riskLevel: null,
        ),
      ).thenAnswer(
        (_) async => const CustomerPage(
          customers: [_pageOneCustomer],
          currentPage: 1,
          lastPage: 1,
          total: 1,
        ),
      );

      await container
          .read(customerListProvider.notifier)
          .toggleIncludeArchived();

      expect(
        container.read(customerListProvider).value!.includeArchived,
        isFalse,
      );
    },
  );
}
