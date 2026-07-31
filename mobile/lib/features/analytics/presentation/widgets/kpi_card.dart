import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';

/// §5.4 — one of the three Collection Analytics cards. No "vs previous
/// period" delta is rendered: the backend does not compute one (confirmed
/// in the Sprint 16 backend audit), and this sprint's explicit product
/// decision is to display only the real value, never an estimated one.
class KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;

  const KpiCard({super.key, required this.label, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTypography.display.copyWith(color: AppColors.primary, fontSize: 22),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
