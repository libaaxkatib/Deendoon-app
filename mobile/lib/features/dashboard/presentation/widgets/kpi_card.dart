import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/deendoon_colors.dart';
import '../../../../core/widgets/app_card.dart';

/// A single KPI card (§4.2): label, primary value, and an optional trend
/// delta. `trendPercentage`/`trendUp` stay `null` today — the backend does
/// not return a month-over-month delta (see the Sprint 10 summary's
/// flagged gap) — so the trend row simply doesn't render rather than
/// inventing one. The layout already reserves the visual slot for it so
/// that, once the backend adds this field, no further redesign is needed.
class KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? trendPercentage;
  final bool? trendUp;
  final Color? valueColor;
  final VoidCallback? onTap;

  const KpiCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.trendPercentage,
    this.trendUp,
    this.valueColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      elevation: 2,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: (valueColor ?? context.colors.textSecondary).withValues(alpha: 0.85)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.caption.copyWith(fontSize: 11, color: context.colors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTypography.heading.copyWith(color: valueColor ?? context.colors.textPrimary, fontSize: 19),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (trendPercentage != null && trendUp != null) ...[
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  trendUp! ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 12,
                  color: trendUp! ? AppColors.success : AppColors.danger,
                ),
                const SizedBox(width: 2),
                Text(
                  '$trendPercentage vs last month',
                  style: AppTypography.caption.copyWith(
                    fontSize: 10,
                    color: trendUp! ? AppColors.success : AppColors.danger,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
