import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/models/payment.dart';
import 'package:mobile/features/analytics/data/analytics_repository.dart';
import 'package:mobile/features/analytics/domain/payment_page.dart';
import 'package:mobile/features/analytics/presentation/providers/report_payments_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockAnalyticsRepository extends Mock implements AnalyticsRepository {}

const _paymentOne = Payment(
  id: '1',
  debtId: '01DEBT1',
  amount: '250.00',
  paymentDate: '2026-08-01',
  paymentMethod: 'cash',
);

const _paymentTwo = Payment(
  id: '2',
  debtId: '01DEBT2',
  amount: '400.00',
  paymentDate: '2026-07-15',
  paymentMethod: 'bank_transfer',
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

  test('build() fetches page 1 with no date range filter', () async {
    when(
      () => mockRepository.fetchReportPayments(
        page: 1,
        dateFrom: null,
        dateTo: null,
      ),
    ).thenAnswer(
      (_) async => const PaymentPage(
        payments: [_paymentOne],
        currentPage: 1,
        lastPage: 2,
        total: 20,
      ),
    );

    final state = await container.read(reportPaymentsProvider.future);

    expect(state.payments, [_paymentOne]);
    expect(state.hasMore, isTrue);
  });

  test(
    'loadMore() appends the next page and stops once lastPage is reached',
    () async {
      when(
        () => mockRepository.fetchReportPayments(
          page: 1,
          dateFrom: null,
          dateTo: null,
        ),
      ).thenAnswer(
        (_) async => const PaymentPage(
          payments: [_paymentOne],
          currentPage: 1,
          lastPage: 2,
          total: 2,
        ),
      );
      await container.read(reportPaymentsProvider.future);

      when(
        () => mockRepository.fetchReportPayments(
          page: 2,
          dateFrom: null,
          dateTo: null,
        ),
      ).thenAnswer(
        (_) async => const PaymentPage(
          payments: [_paymentTwo],
          currentPage: 2,
          lastPage: 2,
          total: 2,
        ),
      );

      await container.read(reportPaymentsProvider.notifier).loadMore();

      final state = container.read(reportPaymentsProvider).value!;
      expect(state.payments, [_paymentOne, _paymentTwo]);
      expect(state.hasMore, isFalse);
    },
  );

  test(
    'loadMore() sets loadMoreError and preserves existing state when the request fails',
    () async {
      when(
        () => mockRepository.fetchReportPayments(
          page: 1,
          dateFrom: null,
          dateTo: null,
        ),
      ).thenAnswer(
        (_) async => const PaymentPage(
          payments: [_paymentOne],
          currentPage: 1,
          lastPage: 2,
          total: 2,
        ),
      );
      await container.read(reportPaymentsProvider.future);

      when(
        () => mockRepository.fetchReportPayments(
          page: 2,
          dateFrom: null,
          dateTo: null,
        ),
      ).thenThrow(Exception('network error'));

      await container.read(reportPaymentsProvider.notifier).loadMore();

      final state = container.read(reportPaymentsProvider).value!;
      expect(state.loadMoreError, isTrue);
      expect(state.isLoadingMore, isFalse);
      expect(state.payments, [_paymentOne]);
      expect(state.currentPage, 1);
      expect(state.hasMore, isTrue);
    },
  );

  test(
    'loadMore() retried after a failure clears loadMoreError, re-requests the same page, and appends on success',
    () async {
      when(
        () => mockRepository.fetchReportPayments(
          page: 1,
          dateFrom: null,
          dateTo: null,
        ),
      ).thenAnswer(
        (_) async => const PaymentPage(
          payments: [_paymentOne],
          currentPage: 1,
          lastPage: 2,
          total: 2,
        ),
      );
      await container.read(reportPaymentsProvider.future);

      when(
        () => mockRepository.fetchReportPayments(
          page: 2,
          dateFrom: null,
          dateTo: null,
        ),
      ).thenThrow(Exception('network error'));
      await container.read(reportPaymentsProvider.notifier).loadMore();
      expect(
        container.read(reportPaymentsProvider).value!.loadMoreError,
        isTrue,
      );

      when(
        () => mockRepository.fetchReportPayments(
          page: 2,
          dateFrom: null,
          dateTo: null,
        ),
      ).thenAnswer(
        (_) async => const PaymentPage(
          payments: [_paymentTwo],
          currentPage: 2,
          lastPage: 2,
          total: 2,
        ),
      );

      await container.read(reportPaymentsProvider.notifier).loadMore();

      final state = container.read(reportPaymentsProvider).value!;
      expect(state.loadMoreError, isFalse);
      expect(state.payments, [_paymentOne, _paymentTwo]);
      expect(state.hasMore, isFalse);
      verify(
        () => mockRepository.fetchReportPayments(
          page: 2,
          dateFrom: null,
          dateTo: null,
        ),
      ).called(2);
    },
  );
}
