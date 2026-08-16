import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../theme/deendoon_colors.dart';

/// §2.9 status color vocabulary: High Risk = danger/red, Medium = warning/
/// amber, Low = success/green. A null/unrecognized level renders neutrally
/// rather than guessing a color. Shared across Dashboard (Recent Cases)
/// and Customers (List/Details) — both render the same `risk_level` field.
class RiskBadge extends StatelessWidget {
  final String? riskLevel;

  const RiskBadge({super.key, required this.riskLevel});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (color, label) = switch (riskLevel) {
      'high' => (context.colors.danger, l10n.riskHigh),
      'medium' => (context.colors.warning, l10n.riskMedium),
      'low' => (context.colors.success, l10n.riskLow),
      _ => (context.colors.textSecondary, l10n.riskUnknown),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
