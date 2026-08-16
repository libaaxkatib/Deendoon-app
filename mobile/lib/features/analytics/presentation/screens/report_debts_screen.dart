import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/deendoon_colors.dart';
import '../../../../core/widgets/retry_section.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../debts/presentation/widgets/debt_card.dart';
import '../providers/report_debts_provider.dart';
import '../widgets/export_action.dart';

Map<String?, String> _statusFilters(AppLocalizations l10n) => {
  null: l10n.debtListFilterAll,
  'pending': l10n.statusPending,
  'overdue': l10n.statusOverdue,
  'partial_paid': l10n.statusPartiallyPaid,
  'paid': l10n.statusPaid,
  'cancelled': l10n.statusCancelled,
  'written_off': l10n.statusWrittenOff,
};

/// §5.2 Reports — Debts category, tenant-wide (unlike the Debts module's
/// own per-customer `DebtListScreen`). `riskLevel` is always passed `null`
/// to `DebtCard` — this report has no customer context per row (no
/// `risk_level` on `DebtResource`, and resolving one per row would mean an
/// N+1 lookup) — `RiskBadge` already renders that honestly as "Unknown".
class ReportDebtsScreen extends ConsumerStatefulWidget {
  final String? initialStatus;

  const ReportDebtsScreen({super.key, this.initialStatus});

  @override
  ConsumerState<ReportDebtsScreen> createState() => _ReportDebtsScreenState();
}

class _ReportDebtsScreenState extends ConsumerState<ReportDebtsScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (widget.initialStatus != null) {
      Future.microtask(
        () => ref
            .read(reportDebtsProvider.notifier)
            .filterByStatus(widget.initialStatus),
      );
    }
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
      ref.read(reportDebtsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final debtsAsync = ref.watch(reportDebtsProvider);
    final statusFilters = _statusFilters(l10n);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reportDebtsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: l10n.reportExportTooltip,
            onPressed: () => showExportSheet(
              context,
              ref,
              reportType: 'debts',
              filters: {
                if (debtsAsync.valueOrNull?.status != null)
                  'status': debtsAsync.valueOrNull!.status,
              },
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
                  for (final entry in statusFilters.entries) ...[
                    _FilterChip(
                      label: entry.value,
                      selected: debtsAsync.valueOrNull?.status == entry.key,
                      onTap: () => ref
                          .read(reportDebtsProvider.notifier)
                          .filterByStatus(entry.key),
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
                    message: l10n.debtListLoadError,
                    onRetry: () => ref.invalidate(reportDebtsProvider),
                  ),
                ),
                data: (state) {
                  if (state.debts.isEmpty) {
                    return Center(
                      child: Text(
                        l10n.reportDebtsEmptyState,
                        style: AppTypography.body.copyWith(
                          color: context.colors.textPrimary,
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () =>
                        ref.read(reportDebtsProvider.notifier).refresh(),
                    child: ListView.separated(
                      controller: _scrollController,
                      itemCount: state.debts.length + (state.hasMore ? 1 : 0),
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index >= state.debts.length) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: state.loadMoreError
                                  ? RetrySection(
                                      message: l10n.paginationLoadMoreError,
                                      onRetry: () => ref
                                          .read(reportDebtsProvider.notifier)
                                          .loadMore(),
                                    )
                                  : const CircularProgressIndicator(),
                            ),
                          );
                        }
                        final debt = state.debts[index];
                        return DebtCard(
                          debt: debt,
                          riskLevel: null,
                          onTap: () => context.push('/debts/${debt.id}'),
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : context.colors.textSecondary,
      ),
      backgroundColor: context.colors.surface,
      side: BorderSide.none,
    );
  }
}
