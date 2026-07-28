import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/coming_soon.dart';
import '../../../../core/widgets/app_card.dart';

/// §4.4 Quick Actions — a static 2x2 grid, no data/loading/error/empty
/// states apply at the grid level per the frozen spec. Each tile's real
/// destination workflow (case creation, payment recording, invoice
/// capture, message composition) is out of scope this sprint.
class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: [
        _QuickActionTile(icon: Icons.add_box_outlined, label: 'Add Case', destination: 'Case creation'),
        _QuickActionTile(icon: Icons.attach_money, label: 'Add Payment', destination: 'Payment recording'),
        _QuickActionTile(icon: Icons.document_scanner_outlined, label: 'Scan Invoice', destination: 'Invoice capture'),
        _QuickActionTile(icon: Icons.send_outlined, label: 'Send Message', destination: 'Message composition'),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String destination;

  const _QuickActionTile({required this.icon, required this.label, required this.destination});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => showComingSoon(context, destination),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              label,
              style: AppTypography.body,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
