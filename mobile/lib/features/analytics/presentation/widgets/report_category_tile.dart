import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/deendoon_colors.dart';
import '../../../../core/widgets/app_card.dart';

/// §5.2 — one row in the Reports tab's category list.
class ReportCategoryTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const ReportCategoryTile({super.key, required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label, style: AppTypography.body.copyWith(color: context.colors.textPrimary)),
          ),
          Icon(Icons.chevron_right, size: 20, color: context.colors.textSecondary),
        ],
      ),
    );
  }
}
