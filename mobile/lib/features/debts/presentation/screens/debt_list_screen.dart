import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/retry_section.dart';
import '../../../customers/presentation/providers/customer_detail_providers.dart';
import '../providers/debt_list_provider.dart';
import '../widgets/debt_card.dart';

/// Debt List — always scoped to one customer (`Dashboard → Customers →
/// Customer Details → Debt Details`; `GET /debts` only supports
/// `customer_id` as a scoping filter, not a global cross-customer list).
/// Status filter chips use the real `debt_status` values. There is no
/// `search` parameter on `GET /debts` (unlike `GET /customers`, which
/// does support one) — no search box is shown rather than displaying a
/// non-functional control; see the Sprint 12 summary's "Missing Backend
/// Support Required".
class DebtListScreen extends ConsumerStatefulWidget {
  final String customerId;

  /// When true, tapping a card pops the route with the selected [Debt]
  /// instead of pushing to its detail screen — reused as-is by any flow
  /// that needs to pick one of a customer's debts, e.g. Record Payment.
  final bool selectionMode;

  const DebtListScreen({super.key, required this.customerId, this.selectionMode = false});

  @override
  ConsumerState<DebtListScreen> createState() => _DebtListScreenState();
}

class _DebtListScreenState extends ConsumerState<DebtListScreen> {
  final _scrollController = ScrollController();

  static const _statusFilters = <String?, String>{
    null: 'All',
    'overdue': 'Overdue',
    'pending': 'Pending',
    'partial_paid': 'Partially Paid',
    'paid': 'Paid',
  };

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
      ref.read(debtListProvider(widget.customerId).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerAsync = ref.watch(customerDetailProvider(widget.customerId));
    final debtsAsync = ref.watch(debtListProvider(widget.customerId));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.selectionMode ? 'Select Debt' : (customerAsync.valueOrNull?.name ?? 'Debts')),
      ),
      floatingActionButton: widget.selectionMode
          ? null
          : FloatingActionButton(
              onPressed: () => context.push('/customers/${widget.customerId}/debts/new'),
              tooltip: 'Add Debt',
              child: const Icon(Icons.add),
            ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final entry in _statusFilters.entries) ...[
                    _StatusFilterChip(
                      label: entry.value,
                      selected: debtsAsync.valueOrNull?.status == entry.key,
                      onTap: () => ref.read(debtListProvider(widget.customerId).notifier).filterByStatus(entry.key),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: debtsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: RetrySection(
                    message: 'Could not load debts.',
                    onRetry: () => ref.invalidate(debtListProvider(widget.customerId)),
                  ),
                ),
                data: (state) {
                  if (state.debts.isEmpty) {
                    return Center(
                      child: Text(
                        state.status == null ? 'No debts yet' : 'No debts with this status',
                        style: AppTypography.body,
                      ),
                    );
                  }

                  final riskLevel = customerAsync.valueOrNull?.riskLevel;

                  return RefreshIndicator(
                    onRefresh: () => ref.read(debtListProvider(widget.customerId).notifier).refresh(),
                    child: ListView.separated(
                      controller: _scrollController,
                      itemCount: state.debts.length + (state.hasMore ? 1 : 0),
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index >= state.debts.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final debt = state.debts[index];
                        return DebtCard(
                          debt: debt,
                          riskLevel: riskLevel,
                          onTap: widget.selectionMode
                              ? () => context.pop(debt)
                              : () => context.push('/debts/${debt.id}'),
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

class _StatusFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StatusFilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      labelStyle: TextStyle(color: selected ? AppColors.primary : AppColors.textSecondary),
      backgroundColor: AppColors.surface,
      side: BorderSide.none,
    );
  }
}
