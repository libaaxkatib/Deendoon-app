import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/deendoon_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/retry_section.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/professional_collection_list_provider.dart';

Map<String?, String> _statusFilters(AppLocalizations l10n) => <String?, String>{
  null: l10n.debtListFilterAll,
  'submitted': l10n.statusSubmitted,
  'under_review': l10n.statusUnderReview,
  'need_more_information': l10n.statusNeedMoreInformation,
  'accepted': l10n.statusAccepted,
  'assigned': l10n.statusAssigned,
  'in_progress': l10n.statusInProgress,
  'recovered': l10n.statusRecovered,
  'closed': l10n.statusClosed,
};

/// Professional Collection Requests List — tenant-wide, reached from the
/// Cases tab (mirrors the existing "Browse Customers" icon pattern on
/// `CaseListScreen`, since this is not one of the 5 frozen bottom-nav
/// tabs). Status filter chips map 1:1 onto the real 8 status values.
/// No screen for this module exists in `Mobile_UI_V1_Frozen.md` — built
/// with the established Deendoon Design System, same precedent as
/// Customers/Debts in Sprint 19.
class ProfessionalCollectionListScreen extends ConsumerStatefulWidget {
  const ProfessionalCollectionListScreen({super.key});

  @override
  ConsumerState<ProfessionalCollectionListScreen> createState() =>
      _ProfessionalCollectionListScreenState();
}

class _ProfessionalCollectionListScreenState
    extends ConsumerState<ProfessionalCollectionListScreen> {
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
      ref.read(professionalCollectionListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final requestsAsync = ref.watch(professionalCollectionListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.caseListProfessionalRequestsTooltip)),
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
                  for (final entry in _statusFilters(l10n).entries) ...[
                    _StatusFilterChip(
                      label: entry.value,
                      selected: requestsAsync.valueOrNull?.status == entry.key,
                      onTap: () => ref
                          .read(professionalCollectionListProvider.notifier)
                          .filterByStatus(entry.key),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: requestsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: RetrySection(
                    message: l10n.professionalCollectionListLoadError,
                    onRetry: () =>
                        ref.invalidate(professionalCollectionListProvider),
                  ),
                ),
                data: (state) {
                  if (state.requests.isEmpty) {
                    return Center(
                      child: Text(
                        state.status == null
                            ? l10n.professionalCollectionListEmptyState
                            : l10n.professionalCollectionListEmptyFilteredState,
                        style: AppTypography.body.copyWith(
                          color: context.colors.textPrimary,
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => ref
                        .read(professionalCollectionListProvider.notifier)
                        .refresh(),
                    child: ListView.separated(
                      controller: _scrollController,
                      itemCount:
                          state.requests.length + (state.hasMore ? 1 : 0),
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index >= state.requests.length) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: state.loadMoreError
                                  ? RetrySection(
                                      message: l10n.paginationLoadMoreError,
                                      onRetry: () => ref
                                          .read(
                                            professionalCollectionListProvider
                                                .notifier,
                                          )
                                          .loadMore(),
                                    )
                                  : const CircularProgressIndicator(),
                            ),
                          );
                        }
                        final request = state.requests[index];
                        return AppCard(
                          onTap: () => context.push(
                            '/professional-requests/${request.id}',
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      request.referenceNumber,
                                      style: AppTypography.body.copyWith(
                                        color: context.colors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      request.createdAt.split('T').first,
                                      style: AppTypography.caption.copyWith(
                                        color: context.colors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              StatusBadge(status: request.status),
                            ],
                          ),
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

  const _StatusFilterChip({
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
