import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/bottom_sheet_content.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/retry_section.dart';
import '../../../../core/widgets/unavailable_section.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/professional_collection_request.dart';
import '../providers/professional_collection_actions.dart';
import '../providers/reference_data_providers.dart';

/// Submit to Professional Collection — `POST /collection-cases/{id}/
/// professional-requests` (`SubmitProfessionalCollectionRequestRequest`:
/// `reasons` required array min 1, `services` required array min 1, both
/// values from the tenant's own active Reference Data; `notes` optional,
/// max 2000; `declaration_accepted` required true). BRL-078/FR-072.
/// Returns the created Request on success (so the caller can navigate to
/// its detail screen), or `null` if the sheet was dismissed without
/// submitting.
Future<ProfessionalCollectionRequest?> showSubmitProfessionalCollectionSheet(
  BuildContext context,
  String caseId,
) {
  return showModalBottomSheet<ProfessionalCollectionRequest>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _SubmitProfessionalCollectionSheet(caseId: caseId),
  );
}

class _SubmitProfessionalCollectionSheet extends ConsumerStatefulWidget {
  final String caseId;

  const _SubmitProfessionalCollectionSheet({required this.caseId});

  @override
  ConsumerState<_SubmitProfessionalCollectionSheet> createState() =>
      _SubmitProfessionalCollectionSheetState();
}

class _SubmitProfessionalCollectionSheetState
    extends ConsumerState<_SubmitProfessionalCollectionSheet> {
  final Set<String> _selectedReasons = {};
  final Set<String> _selectedServices = {};
  final _notesController = TextEditingController();
  bool _declarationAccepted = false;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (_selectedReasons.isEmpty) {
      setState(
        () =>
            _error = l10n.professionalCollectionSubmitReasonsRequiredValidator,
      );
      return;
    }
    if (_selectedServices.isEmpty) {
      setState(
        () =>
            _error = l10n.professionalCollectionSubmitServicesRequiredValidator,
      );
      return;
    }
    if (!_declarationAccepted) {
      setState(
        () => _error =
            l10n.professionalCollectionSubmitDeclarationRequiredValidator,
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final request = await ref
          .read(professionalCollectionActionsProvider)
          .submit(
            caseId: widget.caseId,
            reasons: _selectedReasons.toList(),
            services: _selectedServices.toList(),
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
            declarationAccepted: _declarationAccepted,
          );
      if (mounted) Navigator.of(context).pop(request);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _multiSelect({
    required String category,
    required Set<String> selected,
    required String emptyReason,
    required String errorMessage,
  }) {
    return Consumer(
      builder: (context, ref, _) {
        final itemsAsync = ref.watch(referenceDataProvider(category));
        return itemsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => RetrySection(
            message: errorMessage,
            onRetry: () => ref.invalidate(referenceDataProvider(category)),
          ),
          data: (items) {
            final active = items.where((i) => i.isActive).toList()
              ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
            if (active.isEmpty) {
              return UnavailableSection(reason: emptyReason);
            }
            return Column(
              children: [
                for (final item in active)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.valueLabel),
                    value: selected.contains(item.valueLabel),
                    onChanged: (checked) => setState(() {
                      if (checked ?? false) {
                        selected.add(item.valueLabel);
                      } else {
                        selected.remove(item.valueLabel);
                      }
                    }),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BottomSheetContent(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.professionalCollectionSubmitSheetTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.professionalCollectionSubmitSheetDescription,
            style: AppTypography.caption,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.professionalCollectionReasonForTransferHeading,
            style: AppTypography.heading,
          ),
          const SizedBox(height: 8),
          _multiSelect(
            category: ReferenceDataCategory.transferReason,
            selected: _selectedReasons,
            emptyReason: l10n.professionalCollectionNoActiveReasonsConfigured,
            errorMessage: l10n.professionalCollectionReasonsLoadError,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.professionalCollectionRequestedServicesHeading,
            style: AppTypography.heading,
          ),
          const SizedBox(height: 8),
          _multiSelect(
            category: ReferenceDataCategory.requestedService,
            selected: _selectedServices,
            emptyReason: l10n.professionalCollectionNoActiveServicesConfigured,
            errorMessage: l10n.professionalCollectionServicesLoadError,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            decoration: InputDecoration(
              labelText: l10n.recordPaymentNotesLabel,
            ),
            maxLength: 2000,
            maxLines: 3,
            minLines: 2,
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(l10n.professionalCollectionDeclarationConfirmLabel),
            value: _declarationAccepted,
            onChanged: (checked) =>
                setState(() => _declarationAccepted = checked ?? false),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 12),
          PrimaryButton(
            label: l10n.professionalCollectionSubmitButton,
            isLoading: _isLoading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
