import 'package:flutter/material.dart';

import '../theme/app_typography.dart';
import '../theme/deendoon_colors.dart';

/// Shared "not yet connected" illustration — a soft tinted circular badge
/// around the icon instead of a bare icon, reused by Business Profile and
/// Settings (both real screens waiting on a backend endpoint that doesn't
/// exist yet). No fabricated data is ever shown here — this is purely a
/// premium presentation of the same honest empty state.
class PremiumEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const PremiumEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    context.colors.primary.withValues(alpha: 0.16),
                    context.colors.primary.withValues(alpha: 0.03),
                  ],
                ),
              ),
              child: Icon(
                icon,
                size: 36,
                color: context.colors.primary.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: AppTypography.subheading.copyWith(
                color: context.colors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTypography.caption.copyWith(
                color: context.colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
