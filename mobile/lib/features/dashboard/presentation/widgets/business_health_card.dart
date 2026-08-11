import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/deendoon_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/retry_section.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/dashboard_providers.dart';

String _statusLabel(AppLocalizations l10n, String status) => switch (status) {
  'healthy' => l10n.statusHealthy,
  'needs_attention' => l10n.statusNeedsAttention,
  'at_risk' => l10n.statusAtRisk,
  'neutral_baseline' => l10n.statusNeutralBaseline,
  _ => status,
};

String _statusSubtext(AppLocalizations l10n, String status) => switch (status) {
  'healthy' => l10n.businessHealthSubtextHealthy,
  'needs_attention' => l10n.businessHealthSubtextNeedsAttention,
  'at_risk' => l10n.businessHealthSubtextAtRisk,
  'neutral_baseline' => l10n.businessHealthSubtextNeutralBaseline,
  _ => '',
};

const _statusColors = <String, Color>{
  'healthy': AppColors.success,
  'needs_attention': AppColors.warning,
  'at_risk': AppColors.danger,
};

/// §4.1 Business Health — "a status label, a short encouraging subtext,
/// and a circular percentage gauge." Tapping navigates to Analytics.
///
/// Known behaviour: the released backend currently always returns
/// `status: neutral_baseline, score: null` — intentional, not a bug —
/// because two of `BusinessHealthService`'s three formula inputs
/// (Collection Performance/DD-032, Outstanding Exposure normalization)
/// are unresolved and hardcoded to `null` pending those decisions.
/// Flutter must treat this as expected behaviour: rendered as an
/// empty/neutral gauge with "—" rather than a fabricated percentage,
/// per §4.1's own Empty State rule.
class BusinessHealthCard extends ConsumerWidget {
  const BusinessHealthCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final healthAsync = ref.watch(businessHealthProvider);

    return AppCard(
      onTap: () => context.go(RoutePaths.analytics),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      child: healthAsync.when(
        loading: () => _BusinessHealthContent(
          label: l10n.dashboardBusinessHealthTitle,
          subtext: l10n.commonLoading,
          score: null,
          color: context.colors.textSecondary,
          isLoading: true,
        ),
        error: (error, _) => Row(
          children: [
            Expanded(
              child: RetrySection(
                message: l10n.businessHealthLoadError,
                onRetry: () => ref.invalidate(businessHealthProvider),
              ),
            ),
          ],
        ),
        data: (health) => _BusinessHealthContent(
          label: _statusLabel(l10n, health.status),
          subtext: _statusSubtext(l10n, health.status),
          score: health.score,
          color: _statusColors[health.status] ?? context.colors.textSecondary,
          isLoading: false,
        ),
      ),
    );
  }
}

class _BusinessHealthContent extends StatelessWidget {
  final String label;
  final String subtext;
  final int? score;
  final Color color;
  final bool isLoading;

  const _BusinessHealthContent({
    required this.label,
    required this.subtext,
    required this.score,
    required this.color,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.dashboardBusinessHealthTitle,
                style: AppTypography.caption.copyWith(
                  letterSpacing: 0.3,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTypography.heading.copyWith(color: color, fontSize: 19, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 1),
              Text(subtext, style: AppTypography.caption.copyWith(color: context.colors.textSecondary)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        _HealthGauge(score: score, color: color, isLoading: isLoading),
      ],
    );
  }
}

/// Hand-rolled `CustomPainter` circular gauge — no charting package added,
/// same rationale as `donut_chart.dart` (a single simple static shape,
/// zero new dependencies).
class _HealthGauge extends StatelessWidget {
  final int? score;
  final Color color;
  final bool isLoading;

  const _HealthGauge({required this.score, required this.color, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    const size = 56.0;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(size, size),
            painter: _GaugePainter(
              percentage: isLoading ? null : score,
              color: color,
              trackColor: context.colors.textSecondary.withValues(alpha: 0.08),
            ),
          ),
          Text(
            score != null ? '$score%' : '—',
            style: AppTypography.subheading.copyWith(fontWeight: FontWeight.w800, color: context.colors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final int? percentage;
  final Color color;
  final Color trackColor;

  const _GaugePainter({required this.percentage, required this.color, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.12;
    final radius = (size.shortestSide - strokeWidth) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final arcRect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawArc(arcRect, 0, 2 * math.pi, false, trackPaint);

    if (percentage == null) return;

    final sweep = (percentage!.clamp(0, 100) / 100) * 2 * math.pi;
    // Subtle sweep gradient — a dimmer version of the status color easing
    // into the full color along the filled arc, rather than a flat stroke.
    final valuePaint = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + 2 * math.pi,
        colors: [color.withValues(alpha: 0.5), color],
      ).createShader(arcRect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;
    canvas.drawArc(arcRect, -math.pi / 2, sweep, false, valuePaint);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.percentage != percentage || oldDelegate.color != color;
}
