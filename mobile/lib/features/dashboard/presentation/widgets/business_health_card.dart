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
import '../providers/dashboard_providers.dart';

const _statusLabels = <String, String>{
  'healthy': 'Healthy',
  'needs_attention': 'Needs Attention',
  'at_risk': 'At Risk',
  'neutral_baseline': 'Neutral Baseline',
};

const _statusSubtext = <String, String>{
  'healthy': 'You are doing great!',
  'needs_attention': 'Some areas need review.',
  'at_risk': 'Immediate attention recommended.',
  'neutral_baseline': 'Not enough data yet.',
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
    final healthAsync = ref.watch(businessHealthProvider);

    return AppCard(
      onTap: () => context.go(RoutePaths.analytics),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      child: healthAsync.when(
        loading: () => _BusinessHealthContent(
          label: 'Business Health',
          subtext: 'Loading...',
          score: null,
          color: context.colors.textSecondary,
          isLoading: true,
        ),
        error: (error, _) => Row(
          children: [
            Expanded(
              child: RetrySection(
                message: 'Could not load Business Health.',
                onRetry: () => ref.invalidate(businessHealthProvider),
              ),
            ),
          ],
        ),
        data: (health) => _BusinessHealthContent(
          label: _statusLabels[health.status] ?? health.status,
          subtext: _statusSubtext[health.status] ?? '',
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
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Business Health',
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
