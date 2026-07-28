import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// A single KPI card (§4.2): label + primary value only — the backend
/// does not return a month-over-month delta (see the Sprint 10 summary's
/// flagged gap), so no delta line is rendered rather than inventing one.
class KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;

  const KpiCard({super.key, required this.label, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: AppTypography.caption),
              const SizedBox(height: 8),
              Text(
                value,
                style: AppTypography.subheading.copyWith(color: AppColors.primary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
