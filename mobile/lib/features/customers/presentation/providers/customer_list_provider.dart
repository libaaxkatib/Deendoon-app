import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/customer_repository.dart';
import '../../domain/customer.dart';

/// Immutable snapshot of the searchable, infinitely-paginated Customer
/// List — real backend search/pagination only, no local filtering.
class CustomerListState {
  final List<Customer> customers;
  final int currentPage;
  final int lastPage;
  final int total;
  final String search;
  final bool isLoadingMore;

  const CustomerListState({
    required this.customers,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.search,
    this.isLoadingMore = false,
  });

  bool get hasMore => currentPage < lastPage;

  CustomerListState copyWith({
    List<Customer>? customers,
    int? currentPage,
    int? lastPage,
    int? total,
    String? search,
    bool? isLoadingMore,
  }) {
    return CustomerListState(
      customers: customers ?? this.customers,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      search: search ?? this.search,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

final customerListProvider =
    AsyncNotifierProvider<CustomerListNotifier, CustomerListState>(CustomerListNotifier.new);

class CustomerListNotifier extends AsyncNotifier<CustomerListState> {
  @override
  Future<CustomerListState> build() => _fetchFirstPage(search: '');

  CustomerRepository get _repository => ref.read(customerRepositoryProvider);

  /// Resets to page 1 under a new search term — always a real API call,
  /// never a client-side filter of already-loaded results.
  Future<void> search(String query) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchFirstPage(search: query));
  }

  Future<void> refresh() async {
    final search = state.valueOrNull?.search ?? '';
    state = await AsyncValue.guard(() => _fetchFirstPage(search: search));
  }

  /// Guards against duplicate/concurrent requests and against requesting
  /// past the last page.
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final next = await _repository.fetchCustomers(
        page: current.currentPage + 1,
        search: current.search,
      );
      state = AsyncData(current.copyWith(
        customers: [...current.customers, ...next.customers],
        currentPage: next.currentPage,
        lastPage: next.lastPage,
        total: next.total,
        isLoadingMore: false,
      ));
    } catch (_) {
      // Keep the already-loaded page; just stop the "loading more" spinner
      // so the user can retry by scrolling again.
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  Future<CustomerListState> _fetchFirstPage({required String search}) async {
    final page = await _repository.fetchCustomers(page: 1, search: search);
    return CustomerListState(
      customers: page.customers,
      currentPage: page.currentPage,
      lastPage: page.lastPage,
      total: page.total,
      search: search,
    );
  }
}
