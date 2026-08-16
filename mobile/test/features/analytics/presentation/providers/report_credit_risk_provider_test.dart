import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/analytics/data/analytics_repository.dart';
import 'package:mobile/features/analytics/presentation/providers/report_credit_risk_provider.dart';
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
  riskLevel: 'high',
  creditScore: 40,
  creditScoreBand: 'poor',
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
  riskLevel: 'low',
  creditScore: 80,
  creditScoreBand: 'good',
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

  test('build() fetches page 1 with no risk filter', () async {
    when(
      () => mockRepository.fetchReportCreditRisk(page: 1, riskLevel: null),
    ).thenAnswer(
      (_) async => const CustomerPage(
        customers: [_customerOne],
        currentPage: 1,
        lastPage: 2,
        total: 20,
      ),
    );

    final state = await container.read(reportCreditRiskProvider.future);

    expect(state.customers, [_customerOne]);
    expect(state.hasMore, isTrue);
  });

  test(
    'loadMore() appends the next page and stops once lastPage is reached',
    () async {
      when(
        () => mockRepository.fetchReportCreditRisk(page: 1, riskLevel: null),
      ).thenAnswer(
        (_) async => const CustomerPage(
          customers: [_customerOne],
          currentPage: 1,
          lastPage: 2,
          total: 2,
        ),
      );
      await container.read(reportCreditRiskProvider.future);

      when(
        () => mockRepository.fetchReportCreditRisk(page: 2, riskLevel: null),
      ).thenAnswer(
        (_) async => const CustomerPage(
          customers: [_customerTwo],
          currentPage: 2,
          lastPage: 2,
          total: 2,
        ),
      );

      await container.read(reportCreditRiskProvider.notifier).loadMore();

      final state = container.read(reportCreditRiskProvider).value!;
      expect(state.customers, [_customerOne, _customerTwo]);
      expect(state.hasMore, isFalse);
    },
  );

  test(
    'loadMore() sets loadMoreError and preserves existing state when the request fails',
    () async {
      when(
        () => mockRepository.fetchReportCreditRisk(page: 1, riskLevel: null),
      ).thenAnswer(
        (_) async => const CustomerPage(
          customers: [_customerOne],
          currentPage: 1,
          lastPage: 2,
          total: 2,
        ),
      );
      await container.read(reportCreditRiskProvider.future);

      when(
        () => mockRepository.fetchReportCreditRisk(page: 2, riskLevel: null),
      ).thenThrow(Exception('network error'));

      await container.read(reportCreditRiskProvider.notifier).loadMore();

      final state = container.read(reportCreditRiskProvider).value!;
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
        () => mockRepository.fetchReportCreditRisk(page: 1, riskLevel: null),
      ).thenAnswer(
        (_) async => const CustomerPage(
          customers: [_customerOne],
          currentPage: 1,
          lastPage: 2,
          total: 2,
        ),
      );
      await container.read(reportCreditRiskProvider.future);

      when(
        () => mockRepository.fetchReportCreditRisk(page: 2, riskLevel: null),
      ).thenThrow(Exception('network error'));
      await container.read(reportCreditRiskProvider.notifier).loadMore();
      expect(
        container.read(reportCreditRiskProvider).value!.loadMoreError,
        isTrue,
      );

      when(
        () => mockRepository.fetchReportCreditRisk(page: 2, riskLevel: null),
      ).thenAnswer(
        (_) async => const CustomerPage(
          customers: [_customerTwo],
          currentPage: 2,
          lastPage: 2,
          total: 2,
        ),
      );

      await container.read(reportCreditRiskProvider.notifier).loadMore();

      final state = container.read(reportCreditRiskProvider).value!;
      expect(state.loadMoreError, isFalse);
      expect(state.customers, [_customerOne, _customerTwo]);
      expect(state.hasMore, isFalse);
      verify(
        () => mockRepository.fetchReportCreditRisk(page: 2, riskLevel: null),
      ).called(2);
    },
  );
}
