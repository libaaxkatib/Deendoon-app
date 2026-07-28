import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';

/// A single KPI card (§4.2): label + primary value only — the backend
/// does not return a month-over-month delta (see the Sprint 10 summary's
/// flagged gap), so no trend indicator is rendered rather than inventing
/// one. Per the visual-refinement pass: trend indicators are added only
/// "where data is available" — today that's nowhere, for any KPI card.
class KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;

  const KpiCard({super.key, required this.label, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: AppTypography.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTypography.subheading.copyWith(color: AppColors.primary, fontSize: 20),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
