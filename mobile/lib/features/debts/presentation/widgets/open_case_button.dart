import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/debt_actions.dart';

/// Open Case — `POST /debts/{id}/collection-cases`. Guards against
/// duplicate submissions from a rapid double-tap: the button disables
/// itself for the duration of the request, the same `_isSubmitting`
/// pattern already used by every submit action in this feature (see e.g.
/// `RecordPaymentSheet`). The backend's own partial unique index
/// (`collection_cases_one_open_per_debt`, Postgres) already prevents two
/// open cases for the same debt from ever persisting even without this
/// guard, so no backend change was needed — this closes the client-side
/// gap that let two redundant requests fire from a single rapid
/// double-tap in the first place, rather than relying solely on the
/// backend to reject the second one after the fact.
class OpenCaseButton extends ConsumerStatefulWidget {
  final String debtId;
  final String customerId;

  const OpenCaseButton({
    super.key,
    required this.debtId,
    required this.customerId,
  });

  @override
  ConsumerState<OpenCaseButton> createState() => _OpenCaseButtonState();
}

class _OpenCaseButtonState extends ConsumerState<OpenCaseButton> {
  bool _isSubmitting = false;

  Future<void> _openCase() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    try {
      final collectionCase = await ref
          .read(debtActionsProvider)
          .openCase(widget.debtId, widget.customerId);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.debtDetailCaseOpenedSuccess)),
      );
      router.push('/cases/${collectionCase.id}');
    } on ApiException catch (e) {
      if (mounted) messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return OutlinedButton(
      onPressed: _isSubmitting ? null : _openCase,
      child: _isSubmitting
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(l10n.debtDetailOpenCaseButton),
    );
  }
}
