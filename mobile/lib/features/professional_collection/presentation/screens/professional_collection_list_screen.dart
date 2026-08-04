import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/retry_section.dart';
import '../../../../core/widgets/status_badge.dart';
import '../providers/professional_collection_list_provider.dart';

const _statusFilters = <String?, String>{
  null: 'All',
  'submitted': 'Submitted',
  'under_review': 'Under Review',
  'need_more_information': 'Need More Information',
  'accepted': 'Accepted',
  'assigned': 'Assigned',
  'in_progress': 'In Progress',
  'recovered': 'Recovered',
  'closed': 'Closed',
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
  ConsumerState<ProfessionalCollectionListScreen> createState() => _ProfessionalCollectionListScreenState();
}

class _ProfessionalCollectionListScreenState extends ConsumerState<ProfessionalCollectionListScreen> {
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
      ref.read(professionalCollectionListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(professionalCollectionListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Professional Collection Requests')),
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
                      selected: requestsAsync.valueOrNull?.status == entry.key,
                      onTap: () => ref.read(professionalCollectionListProvider.notifier).filterByStatus(entry.key),
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
                    message: 'Could not load Professional Collection Requests.',
                    onRetry: () => ref.invalidate(professionalCollectionListProvider),
                  ),
                ),
                data: (state) {
                  if (state.requests.isEmpty) {
                    return Center(
                      child: Text(
                        state.status == null
                            ? 'No Professional Collection Requests yet'
                            : 'No requests match this filter',
                        style: AppTypography.body,
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => ref.read(professionalCollectionListProvider.notifier).refresh(),
                    child: ListView.separated(
                      controller: _scrollController,
                      itemCount: state.requests.length + (state.hasMore ? 1 : 0),
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index >= state.requests.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final request = state.requests[index];
                        return AppCard(
                          onTap: () => context.push('/professional-requests/${request.id}'),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(request.referenceNumber, style: AppTypography.body),
                                    const SizedBox(height: 4),
                                    Text(
                                      request.createdAt.split('T').first,
                                      style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
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
