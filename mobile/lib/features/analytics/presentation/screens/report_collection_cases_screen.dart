import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/deendoon_colors.dart';
import '../../../../core/widgets/retry_section.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../cases/presentation/widgets/case_card.dart';
import '../providers/report_collection_cases_provider.dart';
import '../widgets/export_action.dart';

Map<String?, String> _statusFilters(AppLocalizations l10n) => {
  null: l10n.debtListFilterAll,
  'open': l10n.statusOpen,
  'closed': l10n.statusClosed,
};

/// §5.2 Reports — Collection Cases category, filtered by real `case_status`
/// (open/closed) — a different query param from the Cases module's own
/// `tab` filter (high_risk/follow_up/promise_due), so `activeTab` is
/// always passed `null` to `CaseCard` here (no follow-up/promise tag makes
/// sense outside that other, tab-scoped context).
class ReportCollectionCasesScreen extends ConsumerStatefulWidget {
  const ReportCollectionCasesScreen({super.key});

  @override
  ConsumerState<ReportCollectionCasesScreen> createState() =>
      _ReportCollectionCasesScreenState();
}

class _ReportCollectionCasesScreenState
    extends ConsumerState<ReportCollectionCasesScreen> {
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
      ref.read(reportCollectionCasesProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final casesAsync = ref.watch(reportCollectionCasesProvider);
    final statusFilters = _statusFilters(l10n);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reportCollectionCasesTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: l10n.reportExportTooltip,
            onPressed: () => showExportSheet(
              context,
              ref,
              reportType: 'collection-cases',
              filters: {
                if (casesAsync.valueOrNull?.status != null)
                  'status': casesAsync.valueOrNull!.status,
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
                      selected: casesAsync.valueOrNull?.status == entry.key,
                      onTap: () => ref
                          .read(reportCollectionCasesProvider.notifier)
                          .filterByStatus(entry.key),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: casesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: RetrySection(
                    message: l10n.reportCollectionCasesLoadError,
                    onRetry: () =>
                        ref.invalidate(reportCollectionCasesProvider),
                  ),
                ),
                data: (state) {
                  if (state.cases.isEmpty) {
                    return Center(
                      child: Text(
                        l10n.caseListEmptyFilteredState,
                        style: AppTypography.body.copyWith(
                          color: context.colors.textPrimary,
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => ref
                        .read(reportCollectionCasesProvider.notifier)
                        .refresh(),
                    child: ListView.separated(
                      controller: _scrollController,
                      itemCount: state.cases.length + (state.hasMore ? 1 : 0),
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index >= state.cases.length) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: state.loadMoreError
                                  ? RetrySection(
                                      message: l10n.paginationLoadMoreError,
                                      onRetry: () => ref
                                          .read(
                                            reportCollectionCasesProvider
                                                .notifier,
                                          )
                                          .loadMore(),
                                    )
                                  : const CircularProgressIndicator(),
                            ),
                          );
                        }
                        final item = state.cases[index];
                        return CaseCard(
                          collectionCase: item,
                          activeTab: null,
                          onTap: () => context.push('/cases/${item.id}'),
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
