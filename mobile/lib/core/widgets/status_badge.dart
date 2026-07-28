import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Generic status pill — used by Customer List/Details for
/// `customer_status`, whose 7 real values are enumerated exactly as
/// `UpdateCustomerStatusRequest` validates them: active, good_standing,
/// late_payer, high_risk, in_collection, recovered, blocked.
class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      'active' => (AppColors.success, 'Active'),
      'good_standing' => (AppColors.success, 'Good Standing'),
      'late_payer' => (AppColors.warning, 'Late Payer'),
      'high_risk' => (AppColors.danger, 'High Risk'),
      'in_collection' => (AppColors.danger, 'In Collection'),
      'recovered' => (AppColors.success, 'Recovered'),
      'blocked' => (AppColors.textSecondary, 'Blocked'),
      _ => (AppColors.textSecondary, status),
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
