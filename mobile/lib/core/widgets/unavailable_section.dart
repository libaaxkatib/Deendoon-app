import 'package:flutter/material.dart';

import '../theme/app_typography.dart';
import '../theme/deendoon_colors.dart';
import 'app_card.dart';

/// Keeps a section's structural slot in the approved layout even when no
/// backend endpoint exists to fill it with real data — an honest "not
/// available" note, never a fabricated value. Per Sprint 12's explicit
/// instruction (a deliberate reversal of the earlier Business Health
/// precedent, which hid the section entirely): "Keep the screen structure
/// matching the approved design... report the missing backend capability
/// instead of removing the UI concept."
class UnavailableSection extends StatelessWidget {
  final String reason;

  const UnavailableSection({super.key, required this.reason});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: context.colors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              reason,
              style: AppTypography.caption.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
