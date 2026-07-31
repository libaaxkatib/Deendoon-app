import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/retry_section.dart';
import '../../../debts/presentation/widgets/debt_card.dart';
import '../providers/report_debts_provider.dart';
import '../widgets/export_action.dart';

const _statusFilters = <String?, String>{
  null: 'All',
  'pending': 'Pending',
  'overdue': 'Overdue',
  'partial_paid': 'Partially Paid',
  'paid': 'Paid',
  'cancelled': 'Cancelled',
  'written_off': 'Written Off',
};

/// §5.2 Reports — Debts category, tenant-wide (unlike the Debts module's
/// own per-customer `DebtListScreen`). `riskLevel` is always passed `null`
/// to `DebtCard` — this report has no customer context per row (no
/// `risk_level` on `DebtResource`, and resolving one per row would mean an
/// N+1 lookup) — `RiskBadge` already renders that honestly as "Unknown".
class ReportDebtsScreen extends ConsumerStatefulWidget {
  const ReportDebtsScreen({super.key});

  @override
  ConsumerState<ReportDebtsScreen> createState() => _ReportDebtsScreenState();
}

class _ReportDebtsScreenState extends ConsumerState<ReportDebtsScreen> {
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
      ref.read(reportDebtsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final debtsAsync = ref.watch(reportDebtsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debts Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: 'Export',
            onPressed: () => showExportSheet(
              context,
              ref,
              reportType: 'debts',
              filters: {if (debtsAsync.valueOrNull?.status != null) 'status': debtsAsync.valueOrNull!.status},
            ),
          ),
        ],
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
                    _FilterChip(
                      label: entry.value,
                      selected: debtsAsync.valueOrNull?.status == entry.key,
                      onTap: () => ref.read(reportDebtsProvider.notifier).filterByStatus(entry.key),
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
                    onRetry: () => ref.invalidate(reportDebtsProvider),
                  ),
                ),
                data: (state) {
                  if (state.debts.isEmpty) {
                    return const Center(child: Text('No debts match this filter', style: AppTypography.body));
                  }

                  return RefreshIndicator(
                    onRefresh: () => ref.read(reportDebtsProvider.notifier).refresh(),
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
                        return DebtCard(debt: debt, riskLevel: null, onTap: () => context.push('/debts/${debt.id}'));
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

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
