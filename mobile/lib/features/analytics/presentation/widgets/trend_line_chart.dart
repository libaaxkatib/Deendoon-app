import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/deendoon_colors.dart';
import '../../domain/collections_trend.dart';

String _formatAxisValue(double value) {
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}K';
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(1);
}

/// Hand-rolled `CustomPainter` line chart for the single supported metric
/// (`collected_amount`) — see `donut_chart.dart`'s docblock for why a
/// custom painter was chosen over adding a charting package. A flat,
/// zero-value line for an all-zero series is the correct rendering per
/// §5.3's own empty-state rule, not a special case handled here.
class TrendLineChart extends StatelessWidget {
  final List<TrendPoint> series;
  final double height;

  const TrendLineChart({super.key, required this.series, this.height = 140});

  @override
  Widget build(BuildContext context) {
    final values = series.map((p) => double.tryParse(p.value) ?? 0.0).toList();
    final maxValue = values.isEmpty ? 0.0 : values.reduce((a, b) => a > b ? a : b);
    final safeMax = maxValue <= 0 ? 1.0 : maxValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 34,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatAxisValue(safeMax),
                      style: AppTypography.caption.copyWith(color: context.colors.textSecondary),
                    ),
                    Text(
                      _formatAxisValue(safeMax / 2),
                      style: AppTypography.caption.copyWith(color: context.colors.textSecondary),
                    ),
                    Text('0', style: AppTypography.caption.copyWith(color: context.colors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CustomPaint(
                  painter: _TrendPainter(
                    values: values,
                    gridColor: context.colors.surface,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (series.isNotEmpty) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 42),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(series.first.date, style: AppTypography.caption.copyWith(color: context.colors.textSecondary)),
                Text(series.last.date, style: AppTypography.caption.copyWith(color: context.colors.textSecondary)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _TrendPainter extends CustomPainter {
  final List<double> values;
  final Color gridColor;

  const _TrendPainter({required this.values, required this.gridColor});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, 0), Offset(size.width, 0), gridPaint);
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), gridPaint);
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), gridPaint);

    if (values.isEmpty) return;

    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final safeMax = maxValue <= 0 ? 1.0 : maxValue;
    final stepX = values.length > 1 ? size.width / (values.length - 1) : 0.0;

    final path = Path();
    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = values.length > 1 ? i * stepX : size.width / 2;
      final y = size.height - (values[i] / safeMax) * size.height;
      points.add(Offset(x, y));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final linePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();
    final fillPaint = Paint()..color = AppColors.primary.withValues(alpha: 0.12);
    canvas.drawPath(fillPath, fillPaint);

    final endDotPaint = Paint()..color = AppColors.primary;
    canvas.drawCircle(points.last, 3.5, endDotPaint);
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.gridColor != gridColor;
}
