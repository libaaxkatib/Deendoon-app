import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../quick_actions/presentation/add_case_flow.dart';
import '../../../quick_actions/presentation/record_payment_flow.dart';

/// Quick Actions — a single row of 4 tiles: Add Case, Record Payment, Add
/// Reminder, Global Search. Add Case and Record Payment are multi-step
/// flows orchestrated by [startAddCaseFlow]/[startRecordPaymentFlow]; Add
/// Reminder is a direct redirect to the existing Reminder Scheduling
/// screen. Global Search (Sprint 3) navigates to the real `/search`
/// screen — `GET /search` covers Customers, Debts, Payments, Receipts/
/// Demand Letters/Statements, and Collection Cases; it does not index
/// Professional Collection Requests, Reminders, an "Invoice" entity (no
/// such model exists — Receipts/Demand Letters/Statements are the real
/// document types), or Analytics data, so those are not searchable yet
/// (see the Sprint 3 report).
class QuickActionsGrid extends ConsumerWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: _QuickActionTile(
            icon: Icons.add_box_outlined,
            iconColor: AppColors.primary,
            label: l10n.quickActionAddCase,
            emphasized: true,
            onTap: () => startAddCaseFlow(context),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickActionTile(
            icon: Icons.attach_money,
            iconColor: AppColors.warning,
            label: l10n.quickActionRecordPayment,
            onTap: () => startRecordPaymentFlow(context),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickActionTile(
            icon: Icons.notifications_active_outlined,
            iconColor: AppColors.accent,
            label: l10n.quickActionAddReminder,
            onTap: () => context.push('/reminders/new'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickActionTile(
            icon: Icons.search,
            iconColor: AppColors.info,
            label: l10n.quickActionGlobalSearch,
            onTap: () => context.push('/search'),
          ),
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;
  final bool emphasized;

  const _QuickActionTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: emphasized
          ? BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(AppCard.radius),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1.5),
            )
          : null,
      child: AppCard(
        onTap: onTap,
        elevation: emphasized ? 0 : 1,
        splashColor: iconColor.withValues(alpha: 0.14),
        highlightColor: iconColor.withValues(alpha: 0.06),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: AppTypography.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
