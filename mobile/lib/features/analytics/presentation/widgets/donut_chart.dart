import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class DonutSegment {
  final String label;
  final double value;
  final Color color;

  const DonutSegment({required this.label, required this.value, required this.color});
}

/// Hand-rolled `CustomPainter` donut — no charting package added (§5.5/§5.6
/// only need one simple, static chart shape; a `CustomPainter` matches the
/// approved design exactly without pulling in a library's own defaults,
/// and keeps this sprint's new-dependency count at zero, the smallest
/// possible footprint). A zero-total dataset renders as a single neutral
/// ring rather than nothing, per the Overview's "zero values ... rather
/// than an error" empty-state rule.
class DonutChart extends StatelessWidget {
  final List<DonutSegment> segments;
  final String centerValue;
  final String centerLabel;
  final double size;

  const DonutChart({
    super.key,
    required this.segments,
    required this.centerValue,
    required this.centerLabel,
    this.size = 128,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _DonutPainter(segments: segments),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  centerValue,
                  style: AppTypography.subheading.copyWith(fontSize: 15),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  centerLabel,
                  style: AppTypography.caption.copyWith(fontSize: 10),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<DonutSegment> segments;

  const _DonutPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final strokeWidth = size.width * 0.18;
    final radius = (size.shortestSide - strokeWidth) / 2;
    final center = rect.center;
    final arcRect = Rect.fromCircle(center: center, radius: radius);

    final total = segments.fold<double>(0, (sum, s) => sum + s.value);

    if (total <= 0) {
      // Distinct from `AppCard`'s own background (both this chart and its
      // legend always sit inside one) — using the same surface color here
      // would render an invisible ring on top of an identical background.
      final paint = Paint()
        ..color = AppColors.textSecondary.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawArc(arcRect, 0, 2 * pi, false, paint);
      return;
    }

    var startAngle = -pi / 2;
    for (final segment in segments) {
      if (segment.value <= 0) continue;
      final sweep = (segment.value / total) * 2 * pi;
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(arcRect, startAngle, sweep, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => oldDelegate.segments != segments;
}

/// One tappable legend row — color dot, label + de-emphasized value on one
/// line, percentage share prominent on the trailing edge. Compact 2-column
/// layout (not 3) to sit comfortably beside the donut in a side-by-side
/// row, matching the approved design reference's legend style.
class DonutLegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  final double percentage;
  final VoidCallback? onTap;

  const DonutLegendRow({
    super.key,
    required this.color,
    required this.label,
    required this.value,
    required this.percentage,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    value,
                    style: AppTypography.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${percentage.toStringAsFixed(0)}%',
              style: AppTypography.body.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
