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
  const ReminderListScreen({super.key});

  @override
  ConsumerState<ReminderListScreen> createState() => _ReminderListScreenState();
}

class _ReminderListScreenState extends ConsumerState<ReminderListScreen> {
  final _scrollController = ScrollController();

  static const _tabFilters = <String?, String>{
    null: 'All',
    'today': 'Today',
    'upcoming': 'Upcoming',
    'overdue': 'Overdue',
    'completed': 'Completed',
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
                  for (final entry in _tabFilters.entries) ...[
                    _TabFilterChip(
                      label: entry.value,
                      selected: remindersAsync.valueOrNull?.tab == entry.key,
                      onTap: () => ref.read(reminderListProvider.notifier).filterByTab(entry.key),
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
                  if (state.reminders.isEmpty) {
                    return Center(
                      child: Text(
                        state.tab == null ? 'Nothing due' : 'Nothing due in this filter',
                        style: AppTypography.body,
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => ref.read(reminderListProvider.notifier).refresh(),
                    child: ListView.separated(
                      controller: _scrollController,
                      itemCount: state.reminders.length + (state.hasMore ? 1 : 0),
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index >= state.reminders.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final reminder = state.reminders[index];
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
