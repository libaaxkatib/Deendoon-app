import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/retry_section.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/customer_actions.dart';
import '../providers/customer_list_provider.dart';
import '../widgets/customer_card.dart';
import '../widgets/customer_search_bar.dart';

/// Customer List — search (real API, debounced, no local filtering),
/// infinite-scroll pagination, pull-to-refresh, loading/empty/error
/// states. No screen for this module exists in `Mobile_UI_V1_Frozen.md`
/// (it only documents the 5 primary screens); the card/badge visual
/// language is reused from the already-approved Home Dashboard and the
/// frozen Case List's own card description (§6.1).
class CustomerListScreen extends ConsumerStatefulWidget {
  /// When true, tapping a card pops the route with the selected [Customer]
  /// instead of pushing to its detail screen — reused as-is (no duplicate
  /// picker screen) by any flow that needs to pick an existing customer,
  /// e.g. the Add Case and Record Payment Quick Actions.
  final bool selectionMode;

  const CustomerListScreen({super.key, this.selectionMode = false});

  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(customerListProvider.notifier).loadMore();
    }
  }

  Future<void> _restore(String customerId) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(customerActionsProvider).restore(customerId);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.customerRestoredSuccessfully)),
      );
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final customersAsync = ref.watch(customerListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.selectionMode
              ? l10n.customerListSelectTitle
              : l10n.customerListTitle,
        ),
      ),
      floatingActionButton: widget.selectionMode
          ? null
          : FloatingActionButton(
              onPressed: () => context.push('/customers/new'),
              tooltip: l10n.customerAddTitle,
              child: const Icon(Icons.add),
            ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomerSearchBar(
              onChanged: (query) =>
                  ref.read(customerListProvider.notifier).search(query),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilterChip(
                label: Text(l10n.customerListShowArchivedFilter),
                selected: customersAsync.valueOrNull?.includeArchived ?? false,
                onSelected: (_) => ref
                    .read(customerListProvider.notifier)
                    .toggleIncludeArchived(),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: customersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: RetrySection(
                    message: l10n.customerListLoadError,
                    onRetry: () => ref.invalidate(customerListProvider),
                  ),
                ),
                data: (state) {
                  if (state.customers.isEmpty) {
                    return Center(
                      child: Text(
                        state.search.isEmpty
                            ? l10n.customerListEmptyState
                            : l10n.customerListEmptySearchState(state.search),
                        style: AppTypography.body,
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () =>
                        ref.read(customerListProvider.notifier).refresh(),
                    child: ListView.separated(
                      controller: _scrollController,
                      itemCount:
                          state.customers.length + (state.hasMore ? 1 : 0),
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index >= state.customers.length) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: state.loadMoreError
                                  ? RetrySection(
                                      message: l10n.paginationLoadMoreError,
                                      onRetry: () => ref
                                          .read(customerListProvider.notifier)
                                          .loadMore(),
                                    )
                                  : const CircularProgressIndicator(),
                            ),
                          );
                        }
                        final customer = state.customers[index];
                        return CustomerCard(
                          customer: customer,
                          onTap: widget.selectionMode
                              ? () => context.pop(customer)
                              : () => context.push('/customers/${customer.id}'),
                          onRestore:
                              (!widget.selectionMode && customer.isArchived)
                              ? () => _restore(customer.id)
                              : null,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
