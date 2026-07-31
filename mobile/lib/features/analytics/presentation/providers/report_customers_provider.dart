import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../customers/domain/customer.dart';
import '../../data/analytics_repository.dart';

/// §5.2 Reports — Customers category. Real, backend-supported filters
/// only: `customer_status` and `risk_level` (`ReportController::
/// customersQuery()`). No search box — `GET /reports/customers` has no
/// `search` param (unlike the Customers module's own `GET /customers`).
class ReportCustomersState {
  final List<Customer> customers;
  final int currentPage;
  final int lastPage;
  final int total;
  final String? customerStatus;
  final String? riskLevel;
  final bool isLoadingMore;

  const ReportCustomersState({
    required this.customers,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.customerStatus,
    required this.riskLevel,
    this.isLoadingMore = false,
  });

  bool get hasMore => currentPage < lastPage;

  ReportCustomersState copyWith({
    List<Customer>? customers,
    int? currentPage,
    int? lastPage,
    int? total,
    String? customerStatus,
    String? riskLevel,
    bool? isLoadingMore,
  }) {
    return ReportCustomersState(
      customers: customers ?? this.customers,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      customerStatus: customerStatus ?? this.customerStatus,
      riskLevel: riskLevel ?? this.riskLevel,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

final reportCustomersProvider =
    AsyncNotifierProvider<ReportCustomersNotifier, ReportCustomersState>(ReportCustomersNotifier.new);

class ReportCustomersNotifier extends AsyncNotifier<ReportCustomersState> {
  @override
  Future<ReportCustomersState> build() => _fetchFirstPage(customerStatus: null, riskLevel: null);

  AnalyticsRepository get _repository => ref.read(analyticsRepositoryProvider);

  Future<void> filterByStatus(String? status) async {
    final riskLevel = state.valueOrNull?.riskLevel;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchFirstPage(customerStatus: status, riskLevel: riskLevel));
  }

  Future<void> filterByRiskLevel(String? riskLevel) async {
    final status = state.valueOrNull?.customerStatus;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchFirstPage(customerStatus: status, riskLevel: riskLevel));
  }

  Future<void> refresh() async {
    final current = state.valueOrNull;
    state = await AsyncValue.guard(
      () => _fetchFirstPage(customerStatus: current?.customerStatus, riskLevel: current?.riskLevel),
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final next = await _repository.fetchReportCustomers(
        page: current.currentPage + 1,
        customerStatus: current.customerStatus,
        riskLevel: current.riskLevel,
      );
      state = AsyncData(current.copyWith(
        customers: [...current.customers, ...next.customers],
        currentPage: next.currentPage,
        lastPage: next.lastPage,
        total: next.total,
        isLoadingMore: false,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  Future<ReportCustomersState> _fetchFirstPage({required String? customerStatus, required String? riskLevel}) async {
    final page = await _repository.fetchReportCustomers(page: 1, customerStatus: customerStatus, riskLevel: riskLevel);
    return ReportCustomersState(
      customers: page.customers,
      currentPage: page.currentPage,
      lastPage: page.lastPage,
      total: page.total,
      customerStatus: customerStatus,
      riskLevel: riskLevel,
    );
  }
}
