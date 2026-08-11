import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/deendoon_colors.dart';
import '../../../../core/widgets/retry_section.dart';
import '../providers/case_list_provider.dart';
import '../widgets/case_card.dart';

/// Case List — tenant-wide (`GET /collection-cases` has no
/// `customer_id`/`debt_id` filter, only `tab`), the four approved filter
/// chips (All/High Risk/Follow Up/Promise Due) mapped 1:1 onto the real
/// `tab` query param, infinite-scroll pagination, pull-to-refresh,
/// loading/empty/error states. There is no `search` parameter on
/// `GET /collection-cases` at all — no search box is shown rather than
/// displaying a non-functional control (see the Sprint 13 summary's
/// "Missing Backend Support Required"). Also hosts the entry points into
/// the Customers module and Professional Collection Requests (neither is
/// one of the 5 frozen tabs).
class CaseListScreen extends ConsumerStatefulWidget {
  final String? initialTab;

  const CaseListScreen({super.key, this.initialTab});

  @override
  ConsumerState<CaseListScreen> createState() => _CaseListScreenState();
}

class _CaseListScreenState extends ConsumerState<CaseListScreen> {
  final _scrollController = ScrollController();

  static const _tabFilters = <String?, String>{
    null: 'All',
    'high_risk': 'High Risk',
    'follow_up': 'Follow Up',
    'promise_due': 'Promise Due',
  };

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (widget.initialTab != null) {
      Future.microtask(() => ref.read(caseListProvider.notifier).filterByTab(widget.initialTab));
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(caseListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final casesAsync = ref.watch(caseListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cases'),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_outline),
            tooltip: 'Browse Customers',
            onPressed: () => context.push('/customers'),
          ),
          IconButton(
            icon: const Icon(Icons.assignment_outlined),
            tooltip: 'Professional Collection Requests',
            onPressed: () => context.push('/professional-requests'),
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
                  for (final entry in _tabFilters.entries) ...[
                    _TabFilterChip(
                      label: entry.value,
                      selected: casesAsync.valueOrNull?.tab == entry.key,
                      onTap: () => ref.read(caseListProvider.notifier).filterByTab(entry.key),
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
                    message: 'Could not load cases.',
                    onRetry: () => ref.invalidate(caseListProvider),
                  ),
                ),
                data: (state) {
                  if (state.cases.isEmpty) {
                    return Center(
                      child: Text(
                        state.tab == null ? 'No collection cases yet' : 'No cases match this filter',
                        style: AppTypography.body.copyWith(color: context.colors.textPrimary),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => ref.read(caseListProvider.notifier).refresh(),
                    child: ListView.separated(
                      controller: _scrollController,
                      itemCount: state.cases.length + (state.hasMore ? 1 : 0),
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index >= state.cases.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final item = state.cases[index];
                        return CaseCard(
                          collectionCase: item,
                          activeTab: state.tab,
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

class _TabFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabFilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      labelStyle: TextStyle(color: selected ? AppColors.primary : context.colors.textSecondary),
      backgroundColor: context.colors.surface,
      side: BorderSide.none,
    );
  }
}
