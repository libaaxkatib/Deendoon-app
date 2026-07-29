import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// §2.5 "Every entity type and reminder/document type is represented by a
/// dedicated icon on a colored, rounded-square or circular background...
/// consistent everywhere that entity or type appears." §7.2 defines
/// exactly five types — this is the one place their icon/color is
/// defined, reused by the List, Details, and (in a future Smart Calendar
/// sprint) the Calendar grid.
class ReminderTypeIcon extends StatelessWidget {
  final String type;
  final double size;

  const ReminderTypeIcon({super.key, required this.type, this.size = 40});

  static (IconData, Color) _iconAndColor(String type) => switch (type) {
        'client_visit' => (Icons.person_outline, AppColors.accent),
        'follow_up_call' => (Icons.call_outlined, AppColors.warning),
        'payment_due' => (Icons.payments_outlined, AppColors.success),
        'contract_renewal' => (Icons.description_outlined, AppColors.info),
        'promise_to_pay' => (Icons.handshake_outlined, AppColors.primary),
        _ => (Icons.notifications_outlined, AppColors.textSecondary),
      };

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _iconAndColor(type);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}
