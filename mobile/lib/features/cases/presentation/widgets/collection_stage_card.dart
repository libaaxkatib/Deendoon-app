import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Collection Stage — `Debt.recovery_stage`, a real integer 1–6 advanced
/// server-side (escalating a debt to a Collection Case sets it to 5).
/// Shown as a bare "Stage N of 6" rather than a named label — the backend
/// defines no stage-name mapping anywhere read during this sprint's
/// audit, so no name is invented for it.
class CollectionStageCard extends StatelessWidget {
  final int recoveryStage;

  const CollectionStageCard({super.key, required this.recoveryStage});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l10n.collectionStageLabel, style: AppTypography.caption),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.collectionStageValueLabel(recoveryStage),
              textAlign: TextAlign.end,
              style: AppTypography.body.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
