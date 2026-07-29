import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/retry_section.dart';
import '../../domain/case_history.dart';
import '../providers/case_detail_providers.dart';

/// Timeline / Follow-up History — `GET /collection-cases/{id}/history`.
/// This single real endpoint merges `follow_up_history` and `audit_log`
/// rows into one chronological stream; there is no separate backend
/// concept for "Timeline" versus "Follow-up History", so this one section
/// (rendered once) satisfies both — see the Sprint 13 summary's
/// "Timeline Support" for why a second, duplicate section was not built.
class CaseTimelineSection extends ConsumerWidget {
  final String caseId;

  const CaseTimelineSection({super.key, required this.caseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(caseHistoryProvider(caseId));

    return historyAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => RetrySection(
        message: 'Could not load the case timeline.',
        onRetry: () => ref.invalidate(caseHistoryProvider(caseId)),
      ),
      data: (history) {
        if (history.entries.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('No activity recorded yet', style: AppTypography.body),
          );
        }

        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final entry in history.entries.reversed) ...[
                _HistoryRow(entry: entry),
                if (entry != history.entries.first) const SizedBox(height: 14),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final CaseHistoryEntry entry;

  const _HistoryRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.circle, size: 8, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_actionLabel(entry.action), style: AppTypography.body),
              if (entry.details?.isNotEmpty == true) ...[
                const SizedBox(height: 2),
                Text(entry.details!, style: AppTypography.caption),
              ],
              const SizedBox(height: 2),
              Text(entry.occurredAt, style: AppTypography.caption),
            ],
          ),
        ),
      ],
    );
  }

  String _actionLabel(String action) => action
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
