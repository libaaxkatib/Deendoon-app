import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/deendoon_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/retry_section.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/document_detail_providers.dart';
import 'document_type_icon.dart';

/// §8.1 Storage Usage card: "a progress bar and a used/total label."
/// Loads and errors independently of the document list above it. Two
/// real backend caveats surfaced honestly rather than silently absorbed:
/// `used_bytes` excludes Invoice file sizes (a confirmed backend gap),
/// and `total_bytes` is a single hardcoded env-configurable default (10
/// GiB), not a real per-tenant quota.
class StorageUsageCard extends ConsumerWidget {
  const StorageUsageCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final usageAsync = ref.watch(storageUsageProvider);

    return usageAsync.when(
      loading: () => const SectionLoading(),
      error: (error, _) => RetrySection(
        message: l10n.documentStorageUsageLoadError,
        onRetry: () => ref.invalidate(storageUsageProvider),
      ),
      data: (usage) => AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.documentStorageUsageTitle,
              style: AppTypography.body.copyWith(
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (usage.usedPercentage / 100).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: context.colors.background,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.documentStorageUsageLabel(
                formatFileSize(context, usage.usedBytes),
                formatFileSize(context, usage.totalBytes),
              ),
              style: AppTypography.caption.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
