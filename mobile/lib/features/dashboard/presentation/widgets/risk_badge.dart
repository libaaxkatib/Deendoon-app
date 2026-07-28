import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// §2.9 status color vocabulary: High Risk = danger/red, Medium = warning/
/// amber, Low = success/green. A null/unrecognized level renders neutrally
/// rather than guessing a color.
class RiskBadge extends StatelessWidget {
  final String? riskLevel;

  const RiskBadge({super.key, required this.riskLevel});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (riskLevel) {
      'high' => (AppColors.danger, 'High'),
      'medium' => (AppColors.warning, 'Medium'),
      'low' => (AppColors.success, 'Low'),
      _ => (AppColors.textSecondary, 'Unknown'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
