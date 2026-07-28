import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/retry_section.dart';
import '../providers/debt_detail_providers.dart';

const _stageLabels = {
  'debt_created': 'Debt Created',
  'whatsapp_reminder': 'WhatsApp Reminder',
  'sms_reminder': 'SMS Reminder',
  'phone_call': 'Phone Call',
  'promise_to_pay': 'Promise to Pay',
  'payment': 'Payment',
  'professional_collection': 'Professional Collection',
  'recovered': 'Recovered',
};

/// Follow-up Timeline — `GET /debts/{id}/timeline`, the real FR-024
/// progression: 8 fixed stages, each genuinely `pending` until a real
/// event backs it (never fabricated as "completed").
class DebtTimelineSection extends ConsumerWidget {
  final String debtId;

  const DebtTimelineSection({super.key, required this.debtId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineAsync = ref.watch(debtTimelineProvider(debtId));

    return timelineAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => RetrySection(
        message: 'Could not load the follow-up timeline.',
        onRetry: () => ref.invalidate(debtTimelineProvider(debtId)),
      ),
      data: (timeline) => AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final stage in timeline.stages) ...[
              _StageRow(
                label: _stageLabels[stage.event] ?? stage.event,
                completed: stage.status == 'completed',
                occurredAt: stage.occurredAt,
              ),
              if (stage != timeline.stages.last) const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _StageRow extends StatelessWidget {
  final String label;
  final bool completed;
  final String? occurredAt;

  const _StageRow({required this.label, required this.completed, required this.occurredAt});

  @override
  Widget build(BuildContext context) {
    final color = completed ? AppColors.success : AppColors.textSecondary;
    return Row(
      children: [
        Icon(
          completed ? Icons.check_circle : Icons.radio_button_unchecked,
          color: color,
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: AppTypography.body)),
        if (occurredAt != null) Text(occurredAt!, style: AppTypography.caption),
      ],
    );
  }
}
