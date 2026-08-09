import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/retry_section.dart';
import '../../../../core/widgets/unavailable_section.dart';
import '../../data/customer_import_repository.dart';
import '../../domain/customer_import_state.dart';
import '../../domain/import_commit_result.dart';
import '../../domain/import_preview_row.dart';
import '../providers/customer_import_provider.dart';
import '../providers/import_file_picker_provider.dart';

String _formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kb = bytes / 1024;
  if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
  return '${(kb / 1024).toStringAsFixed(1)} MB';
}

/// Bulk Import (Customer Import) — Account → Bulk Import. Wraps the real
/// two-step `CustomerImportController` flow (`POST /customers/import`
/// Preview, then `POST /customers/import/{batch}/commit` with no
/// per-row resolutions) behind a single Import button, since no
/// duplicate-resolution UI was requested this sprint — every duplicate
/// match simply defaults to `skip` server-side, the backend's own
/// documented safe default.
class BulkImportScreen extends ConsumerWidget {
  const BulkImportScreen({super.key});

  Future<void> _pickFile(BuildContext context, WidgetRef ref) async {
    final picked = await ref.read(importFilePickerProvider)();
    if (picked == null) return;
    ref.read(customerImportProvider.notifier).selectFile(path: picked.path, name: picked.name, size: picked.size);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(customerImportProvider);
    final notifier = ref.read(customerImportProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Bulk Import')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Sample Template', style: AppTypography.subheading),
          const SizedBox(height: 8),
          const _SampleTemplateSection(),
          const SizedBox(height: 24),
          Text('Upload File', style: AppTypography.subheading),
          const SizedBox(height: 8),
          Text(
            'Accepted formats: .xlsx, .xls',
            style: AppTypography.caption,
          ),
          const SizedBox(height: 12),
          switch (state) {
            ImportFileSelected(fileName: final name, fileSize: final size) => _SelectedFileCard(
                fileName: name,
                fileSize: size,
                onRemove: notifier.clear,
              ),
            ImportRunning(fileName: final name) => _SelectedFileCard(fileName: name, fileSize: null, onRemove: null),
            ImportSucceeded() || ImportFailed() || ImportInitial() => _UploadFilePrompt(
                onTap: () => _pickFile(context, ref),
              ),
          },
          const SizedBox(height: 16),
          if (state is ImportFailed)
            RetrySection(
              message: state.message,
              onRetry: notifier.clear,
            ),
          if (state is ImportFailed) const SizedBox(height: 16),
          PrimaryButton(
            label: 'Import',
            isLoading: state is ImportRunning,
            onPressed: state is ImportFileSelected ? notifier.startImport : null,
          ),
          if (state is ImportSucceeded) ...[
            const SizedBox(height: 24),
            _ImportSummarySection(preview: state.preview.rows, result: state.result),
          ],
        ],
      ),
    );
  }
}

class _UploadFilePrompt extends StatelessWidget {
  final VoidCallback onTap;

  const _UploadFilePrompt({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: const Row(
        children: [
          Icon(Icons.upload_file_outlined, color: AppColors.primary, size: 22),
          SizedBox(width: 12),
          Expanded(child: Text('Select Excel file', style: AppTypography.body)),
          Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
        ],
      ),
    );
  }
}

class _SelectedFileCard extends StatelessWidget {
  final String fileName;
  final int? fileSize;
  final VoidCallback? onRemove;

  const _SelectedFileCard({required this.fileName, required this.fileSize, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          const Icon(Icons.description_outlined, color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fileName, style: AppTypography.body, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (fileSize != null) Text(_formatFileSize(fileSize!), style: AppTypography.caption),
              ],
            ),
          ),
          if (onRemove != null)
            IconButton(icon: const Icon(Icons.close, color: AppColors.textSecondary), onPressed: onRemove),
        ],
      ),
    );
  }
}

class _ImportSummarySection extends StatelessWidget {
  final List<ImportPreviewRow> preview;
  final ImportCommitResult result;

  const _ImportSummarySection({required this.preview, required this.result});

  @override
  Widget build(BuildContext context) {
    if (result.results.isEmpty) {
      return const UnavailableSection(reason: 'No rows found in the uploaded file.');
    }

    final createdCount = result.results.where((r) => r.outcome == 'created' || r.outcome == 'updated').length;
    final duplicateSkippedCount = result.results.where((r) => r.outcome == 'skipped').length;
    final failedRows = result.results.where((r) => r.outcome == 'skipped_invalid').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Import Summary', style: AppTypography.subheading),
        const SizedBox(height: 8),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SummaryRow(label: 'Imported Successfully', value: createdCount, color: AppColors.success),
              const SizedBox(height: 10),
              _SummaryRow(label: 'Skipped (Duplicate)', value: duplicateSkippedCount, color: AppColors.warning),
              const SizedBox(height: 10),
              _SummaryRow(label: 'Failed', value: failedRows.length, color: AppColors.danger),
              if (result.message.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(height: 1, color: Colors.white12),
                const SizedBox(height: 12),
                Text(result.message, style: AppTypography.caption),
              ],
            ],
          ),
        ),
        if (failedRows.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Failed Rows', style: AppTypography.subheading),
          const SizedBox(height: 8),
          for (final row in failedRows) ...[
            _FailedRowCard(
              rowNumber: row.rowNumber,
              errors: preview.where((r) => r.rowNumber == row.rowNumber).firstOrNull?.validationErrors,
            ),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _SummaryRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.body),
        Text('$value', style: AppTypography.body.copyWith(color: color, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _FailedRowCard extends StatelessWidget {
  final int rowNumber;
  final List<String>? errors;

  const _FailedRowCard({required this.rowNumber, required this.errors});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Row $rowNumber', style: AppTypography.body.copyWith(fontWeight: FontWeight.w700)),
          if (errors != null)
            for (final error in errors!) Text(error, style: AppTypography.caption.copyWith(color: AppColors.danger)),
        ],
      ),
    );
  }
}

/// `GET /customers/import/template` — downloads the real backend-generated
/// `.xlsx` template and saves it to the app's own documents directory,
/// same `path_provider` pattern as `DocumentActions.saveToDevice` (no
/// extra file-picker/permission package needed on either platform).
class _SampleTemplateSection extends ConsumerStatefulWidget {
  const _SampleTemplateSection();

  @override
  ConsumerState<_SampleTemplateSection> createState() => _SampleTemplateSectionState();
}

class _SampleTemplateSectionState extends ConsumerState<_SampleTemplateSection> {
  bool _isDownloading = false;
  String? _error;

  Future<void> _download() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _isDownloading = true;
      _error = null;
    });

    try {
      final bytes = await ref.read(customerImportRepositoryProvider).downloadTemplate();
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/customer-import-template.xlsx');
      await file.writeAsBytes(bytes, flush: true);
      if (mounted) messenger.showSnackBar(SnackBar(content: Text('Saved to ${file.path}')));
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null) ...[
          Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          const SizedBox(height: 8),
        ],
        PrimaryButton(label: 'Download Sample Template', isLoading: _isDownloading, onPressed: _download),
      ],
    );
  }
}
