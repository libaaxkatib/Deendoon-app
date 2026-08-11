import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/deendoon_colors.dart';

/// §2.5 "Every entity type and reminder/document type is represented by
/// a dedicated icon on a colored, rounded-square or circular background."
/// The four real `document_type` values, confirmed by reading every
/// Document Resource: `invoice`, `receipt`, `demand_letter`, `statement`.
class DocumentTypeIcon extends StatelessWidget {
  final String documentType;
  final double size;

  const DocumentTypeIcon({super.key, required this.documentType, this.size = 40});

  static (IconData, Color) _iconAndColor(BuildContext context, String documentType) => switch (documentType) {
        'invoice' => (Icons.receipt_long_outlined, AppColors.info),
        'receipt' => (Icons.receipt_outlined, AppColors.success),
        'demand_letter' => (Icons.mail_outline, AppColors.danger),
        'statement' => (Icons.description_outlined, AppColors.accent),
        _ => (Icons.insert_drive_file_outlined, context.colors.textSecondary),
      };

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _iconAndColor(context, documentType);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

const documentTypeLabels = <String, String>{
  'invoice': 'Invoice',
  'receipt': 'Receipt',
  'demand_letter': 'Demand Letter',
  'statement': 'Statement',
};

/// Bytes → a short human-readable label (`KB`/`MB`/`GB`). `fileSize` is
/// nullable on the real resource (confirmed in the Sprint 12 audit); a
/// null value renders as "—" rather than a fabricated size.
String formatFileSize(int? bytes) {
  if (bytes == null) return '—';
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}
