import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/payment.dart';
import '../../data/analytics_repository.dart';

String _isoDate(DateTime date) => date.toIso8601String().split('T').first;

/// §5.2 Reports — Payments category. Real filter: `dateFrom`/`dateTo` on
/// `payment_date` (`ReportController::paymentsQuery()`). No `debt_id`
/// filter here — there's no practical way to pick one while browsing a
/// tenant-wide report (unlike the Debt Detail screen's own scoped payment
/// history, which already has a debt in context).
class ReportPaymentsState {
  final List<Payment> payments;
  final int currentPage;
  final int lastPage;
  final int total;
  final DateTimeRange? dateRange;
  final bool isLoadingMore;
  final bool loadMoreError;

  const ReportPaymentsState({
    required this.payments,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.dateRange,
    this.isLoadingMore = false,
    this.loadMoreError = false,
  });

  bool get hasMore => currentPage < lastPage;

  ReportPaymentsState copyWith({
    List<Payment>? payments,
    int? currentPage,
    int? lastPage,
    int? total,
    DateTimeRange? dateRange,
    bool clearDateRange = false,
    bool? isLoadingMore,
    bool? loadMoreError,
  }) {
    return ReportPaymentsState(
      payments: payments ?? this.payments,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreError: loadMoreError ?? this.loadMoreError,
    );
  }
}

final reportPaymentsProvider =
    AsyncNotifierProvider<ReportPaymentsNotifier, ReportPaymentsState>(
      ReportPaymentsNotifier.new,
    );

class ReportPaymentsNotifier extends AsyncNotifier<ReportPaymentsState> {
  @override
  Future<ReportPaymentsState> build() => _fetchFirstPage(dateRange: null);

  AnalyticsRepository get _repository => ref.read(analyticsRepositoryProvider);

  Future<void> filterByDateRange(DateTimeRange? range) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchFirstPage(dateRange: range));
  }

  Future<void> refresh() async {
    final current = state.valueOrNull;
    state = await AsyncValue.guard(
      () => _fetchFirstPage(dateRange: current?.dateRange),
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(
      current.copyWith(isLoadingMore: true, loadMoreError: false),
    );
    try {
      final next = await _repository.fetchReportPayments(
        page: current.currentPage + 1,
        dateFrom: current.dateRange != null
            ? _isoDate(current.dateRange!.start)
            : null,
        dateTo: current.dateRange != null
            ? _isoDate(current.dateRange!.end)
            : null,
      );
      state = AsyncData(
        current.copyWith(
          payments: [...current.payments, ...next.payments],
          currentPage: next.currentPage,
          lastPage: next.lastPage,
          total: next.total,
          isLoadingMore: false,
          loadMoreError: false,
        ),
      );
    } catch (_) {
      state = AsyncData(
        current.copyWith(isLoadingMore: false, loadMoreError: true),
      );
    }
  }

  Future<ReportPaymentsState> _fetchFirstPage({
    required DateTimeRange? dateRange,
  }) async {
    final page = await _repository.fetchReportPayments(
      page: 1,
      dateFrom: dateRange != null ? _isoDate(dateRange.start) : null,
      dateTo: dateRange != null ? _isoDate(dateRange.end) : null,
    );
    return ReportPaymentsState(
      payments: page.payments,
      currentPage: page.currentPage,
      lastPage: page.lastPage,
      total: page.total,
      dateRange: dateRange,
    );
  }
}
