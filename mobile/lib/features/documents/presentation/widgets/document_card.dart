import 'package:flutter/material.dart';

import '../../../../core/models/document_summary.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import 'document_type_icon.dart';

/// §8.1 document card: "a type icon, filename, a one-line descriptor,
/// date, and file size." No `filename` field exists on any Document
/// Resource (confirmed in the backend audit) — the backend itself names
/// the downloaded file `"{reference_number}.pdf"` (`DocumentController::
/// download()`), so `reference_number` is used as the filename here,
/// which is exactly what the file is actually called once downloaded.
class DocumentCard extends StatelessWidget {
  final DocumentSummary document;
  final VoidCallback onTap;

  const DocumentCard({super.key, required this.document, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          DocumentTypeIcon(documentType: document.documentType),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${document.referenceNumber}.pdf',
                  style: AppTypography.body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  documentTypeLabel(context, document.documentType),
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                document.generatedAt.split('T').first,
                style: AppTypography.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(formatFileSize(context, document.fileSize), style: AppTypography.caption),
            ],
          ),
        ],
      ),
    );
  }
}
