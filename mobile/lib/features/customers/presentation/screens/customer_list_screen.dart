import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/retry_section.dart';
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
  const CustomerListScreen({super.key});

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
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(customerListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customerListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Customers')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomerSearchBar(
              onChanged: (query) => ref.read(customerListProvider.notifier).search(query),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: customersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: RetrySection(
                    message: 'Could not load customers.',
                    onRetry: () => ref.invalidate(customerListProvider),
                  ),
                ),
                data: (state) {
                  if (state.customers.isEmpty) {
                    return Center(
                      child: Text(
                        state.search.isEmpty ? 'No customers yet' : 'No customers match "${state.search}"',
                        style: AppTypography.body,
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => ref.read(customerListProvider.notifier).refresh(),
                    child: ListView.separated(
                      controller: _scrollController,
                      itemCount: state.customers.length + (state.hasMore ? 1 : 0),
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index >= state.customers.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final customer = state.customers[index];
                        return CustomerCard(
                          customer: customer,
                          onTap: () => context.push('/customers/${customer.id}'),
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
