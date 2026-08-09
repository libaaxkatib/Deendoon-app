import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/retry_section.dart';
import '../providers/reminder_actions.dart';
import '../providers/reminder_list_provider.dart';
import '../widgets/reminder_card.dart';
import '../widgets/reminder_summary_row.dart';

/// Reminder Center — combines §7.1 (Dashboard: summary row) and §7.3
/// (Reminder List: tab selector + cards) into the one screen reached via
/// the bottom navigation's "Reminders" tab, matching the frozen spec's
/// overall layout description ("A live summary Dashboard... [and] a
/// filterable Reminder List"). There is no `search` parameter on
/// `GET /reminders` — no search box is shown rather than displaying a
/// non-functional control (see the Sprint 14 summary's "Missing Backend
/// Support Required").
class ReminderListScreen extends ConsumerStatefulWidget {
  /// One of `_reminderFilterChips`' keys (e.g. `'today'`, `'payments'`) —
  /// pre-selects that chip on first load. Used for deep links from the
  /// Home Dashboard's Today's Overview rows (see `RoutePaths.reminders`'s
  /// registration in `app_router.dart`), same pattern as
  /// `CaseListScreen.initialTab`.
  final String? initialFilter;

  const ReminderListScreen({super.key, this.initialFilter});

  @override
  ConsumerState<ReminderListScreen> createState() => _ReminderListScreenState();
}

/// One chip in the filter row — either a real backend `tab` value
/// (including `tab: null` for "All") or a client-side `type` filter over
/// the five real `Reminder.type` values. `key` is the stable identifier
/// used for deep-link query params (`/reminders?filter=<key>`).
class _ReminderFilterChipDef {
  final String key;
  final String label;
  final String? tab;
  final String? type;
  final bool isTab;

  const _ReminderFilterChipDef.tab({required this.key, required this.label, required this.tab})
      : type = null,
        isTab = true;

  const _ReminderFilterChipDef.type({required this.key, required this.label, required this.type})
      : tab = null,
        isTab = false;
}

/// Matches the reminder categories shown in the Home Dashboard's Today's
/// Overview and the Reminder Center's own summary cards (Client Visits,
/// Follow-ups, Payments, Overdue), so the two screens no longer disagree
/// about what a "category" is. Chip `key`s are unchanged from their
/// original values ('visits'/'calls') even though their labels changed
/// (Client Visits/Follow-ups) — this keeps existing deep links
/// (`/reminders?filter=calls` from the Dashboard's Today's Overview)
/// working without any router/dashboard change.
const _reminderFilterChips = <_ReminderFilterChipDef>[
  _ReminderFilterChipDef.tab(key: 'all', label: 'All', tab: null),
  _ReminderFilterChipDef.tab(key: 'today', label: 'Today', tab: 'today'),
  _ReminderFilterChipDef.type(key: 'payments', label: 'Payments', type: 'payment_due'),
  _ReminderFilterChipDef.type(key: 'visits', label: 'Client Visits', type: 'client_visit'),
  _ReminderFilterChipDef.type(key: 'calls', label: 'Follow-ups', type: 'follow_up_call'),
  _ReminderFilterChipDef.tab(key: 'upcoming', label: 'Upcoming', tab: 'upcoming'),
  _ReminderFilterChipDef.tab(key: 'overdue', label: 'Overdue', tab: 'overdue'),
  _ReminderFilterChipDef.tab(key: 'completed', label: 'Completed', tab: 'completed'),
];

class _ReminderListScreenState extends ConsumerState<ReminderListScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    final initialFilter = widget.initialFilter;
    if (initialFilter != null) {
      Future.microtask(() => _applyFilterKey(initialFilter));
    }
  }

  /// The Reminders tab's Navigator is kept alive by the shell's
  /// `IndexedStack` (`StatefulShellRoute.indexedStack`), so re-navigating
  /// here from the Home Dashboard with a different `?filter=` doesn't
  /// necessarily recreate this State — it updates the existing widget
  /// instead. Re-apply the filter whenever it actually changes so a
  /// second deep link (e.g. Payments, then later Client Visits) still
  /// lands on the right chip.
  @override
  void didUpdateWidget(covariant ReminderListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final filter = widget.initialFilter;
    if (filter != null && filter != oldWidget.initialFilter) {
      Future.microtask(() => _applyFilterKey(filter));
    }
  }

  void _applyFilterKey(String key) {
    final def = _reminderFilterChips.firstWhere(
      (def) => def.key == key,
      orElse: () => _reminderFilterChips.first,
    );
    if (def.isTab) {
      ref.read(reminderListProvider.notifier).filterByTab(def.tab);
    } else {
      ref.read(reminderListProvider.notifier).filterByType(def.type!);
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
      ref.read(reminderListProvider.notifier).loadMore();
    }
  }

  Future<void> _complete(String id) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(reminderActionsProvider).complete(id);
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final remindersAsync = ref.watch(reminderListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'Calendar',
            onPressed: () => context.push('/calendar'),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Schedule Reminder',
            onPressed: () => context.push('/reminders/new'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ReminderSummaryRow(),
            const SizedBox(height: 16),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final def in _reminderFilterChips) ...[
                    _TabFilterChip(
                      label: def.label,
                      selected: def.isTab
                          ? (remindersAsync.valueOrNull?.typeFilter == null &&
                              remindersAsync.valueOrNull?.tab == def.tab)
                          : remindersAsync.valueOrNull?.typeFilter == def.type,
                      onTap: () => def.isTab
                          ? ref.read(reminderListProvider.notifier).filterByTab(def.tab)
                          : ref.read(reminderListProvider.notifier).filterByType(def.type!),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: remindersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: RetrySection(
                    message: 'Could not load reminders.',
                    onRetry: () => ref.invalidate(reminderListProvider),
                  ),
                ),
                data: (state) {
                  final typeFilter = state.typeFilter;
                  final displayed = typeFilter == null
                      ? state.reminders
                      : state.reminders.where((r) => r.type == typeFilter).toList();

                  final hasActiveFilter = state.tab != null || typeFilter != null;

                  if (displayed.isEmpty) {
                    // A type filter narrows an already-fetched "All" page — if
                    // this page happens to have no matches but more real pages
                    // exist, keep paging until a match is found (or the real
                    // `hasMore` signal says there's nothing left), rather than
                    // showing a false "nothing due" while matches sit unfetched
                    // on a later page.
                    if (typeFilter != null && state.hasMore && !state.isLoadingMore) {
                      WidgetsBinding.instance.addPostFrameCallback(
                        (_) => ref.read(reminderListProvider.notifier).loadMore(),
                      );
                      return const Center(child: CircularProgressIndicator());
                    }
                    return Center(
                      child: Text(
                        hasActiveFilter ? 'Nothing due in this filter' : 'Nothing due',
                        style: AppTypography.body,
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => ref.read(reminderListProvider.notifier).refresh(),
                    child: ListView.separated(
                      controller: _scrollController,
                      itemCount: displayed.length + (state.hasMore ? 1 : 0),
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index >= displayed.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final reminder = displayed[index];
                        return ReminderCard(
                          reminder: reminder,
                          onTap: () => context.push('/reminders/${reminder.id}'),
                          onComplete: () => _complete(reminder.id),
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
      labelStyle: TextStyle(color: selected ? AppColors.primary : AppColors.textSecondary),
      backgroundColor: AppColors.surface,
      side: BorderSide.none,
    );
  }
}
