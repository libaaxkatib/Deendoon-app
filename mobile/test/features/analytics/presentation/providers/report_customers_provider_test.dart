import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/analytics/data/analytics_repository.dart';
import 'package:mobile/features/analytics/presentation/providers/report_customers_provider.dart';
import 'package:mobile/features/customers/domain/customer.dart';
import 'package:mobile/features/customers/domain/customer_page.dart';
import 'package:mocktail/mocktail.dart';

class _MockAnalyticsRepository extends Mock implements AnalyticsRepository {}

const _customerOne = Customer(
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

const _customerTwo = Customer(
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
  late _MockAnalyticsRepository mockRepository;
  late ProviderContainer container;

  setUp(() {
    mockRepository = _MockAnalyticsRepository();
    container = ProviderContainer(
      overrides: [
        analyticsRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
    addTearDown(container.dispose);
  });

  test('build() fetches page 1 with no status/risk filter', () async {
    when(
      () => mockRepository.fetchReportCustomers(
        page: 1,
        customerStatus: null,
        riskLevel: null,
      ),
    ).thenAnswer(
      (_) async => const CustomerPage(
        customers: [_customerOne],
        currentPage: 1,
        lastPage: 2,
        total: 20,
      ),
    );

    final state = await container.read(reportCustomersProvider.future);

    expect(state.customers, [_customerOne]);
    expect(state.hasMore, isTrue);
  });

  test(
    'loadMore() appends the next page and stops once lastPage is reached',
    () async {
      when(
        () => mockRepository.fetchReportCustomers(
          page: 1,
          customerStatus: null,
          riskLevel: null,
        ),
      ).thenAnswer(
        (_) async => const CustomerPage(
          customers: [_customerOne],
          currentPage: 1,
          lastPage: 2,
          total: 2,
        ),
      );
      await container.read(reportCustomersProvider.future);

      when(
        () => mockRepository.fetchReportCustomers(
          page: 2,
          customerStatus: null,
          riskLevel: null,
        ),
      ).thenAnswer(
        (_) async => const CustomerPage(
          customers: [_customerTwo],
          currentPage: 2,
          lastPage: 2,
          total: 2,
        ),
      );

      await container.read(reportCustomersProvider.notifier).loadMore();

      final state = container.read(reportCustomersProvider).value!;
      expect(state.customers, [_customerOne, _customerTwo]);
      expect(state.hasMore, isFalse);
    },
  );

  test(
    'loadMore() sets loadMoreError and preserves existing state when the request fails',
    () async {
      when(
        () => mockRepository.fetchReportCustomers(
          page: 1,
          customerStatus: null,
          riskLevel: null,
        ),
      ).thenAnswer(
        (_) async => const CustomerPage(
          customers: [_customerOne],
          currentPage: 1,
          lastPage: 2,
          total: 2,
        ),
      );
      await container.read(reportCustomersProvider.future);

      when(
        () => mockRepository.fetchReportCustomers(
          page: 2,
          customerStatus: null,
          riskLevel: null,
        ),
      ).thenThrow(Exception('network error'));

      await container.read(reportCustomersProvider.notifier).loadMore();

      final state = container.read(reportCustomersProvider).value!;
      expect(state.loadMoreError, isTrue);
      expect(state.isLoadingMore, isFalse);
      expect(state.customers, [_customerOne]);
      expect(state.currentPage, 1);
      expect(state.hasMore, isTrue);
    },
  );

  test(
    'loadMore() retried after a failure clears loadMoreError, re-requests the same page, and appends on success',
    () async {
      when(
        () => mockRepository.fetchReportCustomers(
          page: 1,
          customerStatus: null,
          riskLevel: null,
        ),
      ).thenAnswer(
        (_) async => const CustomerPage(
          customers: [_customerOne],
          currentPage: 1,
          lastPage: 2,
          total: 2,
        ),
      );
      await container.read(reportCustomersProvider.future);

      when(
        () => mockRepository.fetchReportCustomers(
          page: 2,
          customerStatus: null,
          riskLevel: null,
        ),
      ).thenThrow(Exception('network error'));
      await container.read(reportCustomersProvider.notifier).loadMore();
      expect(
        container.read(reportCustomersProvider).value!.loadMoreError,
        isTrue,
      );

      when(
        () => mockRepository.fetchReportCustomers(
          page: 2,
          customerStatus: null,
          riskLevel: null,
        ),
      ).thenAnswer(
        (_) async => const CustomerPage(
          customers: [_customerTwo],
          currentPage: 2,
          lastPage: 2,
          total: 2,
        ),
      );

      await container.read(reportCustomersProvider.notifier).loadMore();

      final state = container.read(reportCustomersProvider).value!;
      expect(state.loadMoreError, isFalse);
      expect(state.customers, [_customerOne, _customerTwo]);
      expect(state.hasMore, isFalse);
      verify(
        () => mockRepository.fetchReportCustomers(
          page: 2,
          customerStatus: null,
          riskLevel: null,
        ),
      ).called(2);
    },
  );
}
