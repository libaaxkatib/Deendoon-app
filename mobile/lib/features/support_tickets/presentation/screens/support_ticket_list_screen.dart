import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/deendoon_colors.dart';
import '../../../../core/widgets/retry_section.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/support_ticket_list_provider.dart';
import '../widgets/contact_deendoon_card.dart';
import '../widgets/support_ticket_card.dart';

/// Support & Tickets (Module 7) — "My Tickets" list plus the app's
/// Contact Support entry point (replaces the About screen's former
/// coming-soon row). Mirrors ReminderListScreen's structure: a status
/// filter chip row over real backend pagination/filtering, infinite
/// scroll, pull-to-refresh.
class SupportTicketListScreen extends ConsumerStatefulWidget {
  const SupportTicketListScreen({super.key});

  @override
  ConsumerState<SupportTicketListScreen> createState() =>
      _SupportTicketListScreenState();
}

const _statusFilters = <String?>[
  null,
  'open',
  'in_progress',
  'resolved',
  'closed',
];

String _statusFilterLabel(AppLocalizations l10n, String? status) =>
    switch (status) {
      null => l10n.debtListFilterAll,
      'open' => l10n.statusOpen,
      'in_progress' => l10n.statusInProgress,
      'resolved' => l10n.statusResolved,
      'closed' => l10n.statusClosed,
      _ => status,
    };

class _SupportTicketListScreenState
    extends ConsumerState<SupportTicketListScreen> {
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
      ref.read(supportTicketListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ticketsAsync = ref.watch(supportTicketListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.supportTicketListTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l10n.supportTicketCreateTitle,
            onPressed: () => context.push('/support/tickets/new'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ContactDeendoonCard(),
            const SizedBox(height: 16),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final status in _statusFilters) ...[
                    _StatusFilterChip(
                      label: _statusFilterLabel(l10n, status),
                      selected: ticketsAsync.valueOrNull?.status == status,
                      onTap: () => ref
                          .read(supportTicketListProvider.notifier)
                          .filterByStatus(status),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ticketsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: RetrySection(
                    message: l10n.supportTicketListLoadError,
                    onRetry: () => ref.invalidate(supportTicketListProvider),
                  ),
                ),
                data: (state) {
                  if (state.tickets.isEmpty) {
                    return Center(
                      child: Text(
                        state.status == null
                            ? l10n.supportTicketListEmptyState
                            : l10n.supportTicketListEmptyFilteredState,
                        style: AppTypography.body.copyWith(
                          color: context.colors.textPrimary,
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () =>
                        ref.read(supportTicketListProvider.notifier).refresh(),
                    child: ListView.separated(
                      controller: _scrollController,
                      itemCount: state.tickets.length + (state.hasMore ? 1 : 0),
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index >= state.tickets.length) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: state.loadMoreError
                                  ? RetrySection(
                                      message: l10n.paginationLoadMoreError,
                                      onRetry: () => ref
                                          .read(
                                            supportTicketListProvider.notifier,
                                          )
                                          .loadMore(),
                                    )
                                  : const CircularProgressIndicator(),
                            ),
                          );
                        }
                        final ticket = state.tickets[index];
                        return SupportTicketCard(
                          ticket: ticket,
                          onTap: () =>
                              context.push('/support/tickets/${ticket.id}'),
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
