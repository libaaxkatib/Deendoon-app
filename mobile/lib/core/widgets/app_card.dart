import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Shared card container — consistent corner radius/background/padding/
/// elevation across every card-style section in the app (Home Dashboard's
/// Business Health/KPI/Quick Actions/Recent Cases, Customers' list and
/// detail cards, and any future module's cards).
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  static const radius = 16.0;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(radius),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
