import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/support_ticket_actions.dart';
import '../widgets/ticket_priority_badge.dart';

const _priorities = <String>['low', 'medium', 'high', 'urgent'];
const _categories = <String>[
  'technical_issue',
  'payment_billing',
  'account',
  'subscription',
  'debt_recovery',
  'professional_collection',
  'feature_request',
  'other',
];

class SupportTicketCreateScreen extends ConsumerStatefulWidget {
  const SupportTicketCreateScreen({super.key});

  @override
  ConsumerState<SupportTicketCreateScreen> createState() =>
      _SupportTicketCreateScreenState();
}

class _SupportTicketCreateScreenState
    extends ConsumerState<SupportTicketCreateScreen> {
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _priority = 'medium';
  String _category = 'technical_issue';
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final subject = _subjectController.text.trim();
    final description = _descriptionController.text.trim();

    if (subject.isEmpty || description.isEmpty) {
      setState(() => _error = l10n.supportTicketCreateValidationError);
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final router = GoRouter.of(context);
    try {
      final ticket = await ref
          .read(supportTicketActionsProvider)
          .create(
            subject: subject,
            description: description,
            priority: _priority,
            category: _category,
          );
      if (mounted) router.pushReplacement('/support/tickets/${ticket.id}');
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.supportTicketCreateTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(l10n.supportTicketSubjectLabel, style: AppTypography.caption),
            const SizedBox(height: 6),
            TextField(
              controller: _subjectController,
              maxLength: 255,
              decoration: InputDecoration(
                hintText: l10n.supportTicketSubjectHint,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.supportTicketDescriptionLabel,
              style: AppTypography.caption,
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _descriptionController,
              maxLength: 5000,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: l10n.supportTicketDescriptionHint,
              ),
            ),
            const SizedBox(height: 12),
            Text(l10n.supportTicketPriorityLabel, style: AppTypography.caption),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                for (final priority in _priorities)
                  ChoiceChip(
                    label: TicketPriorityBadge(priority: priority),
                    selected: _priority == priority,
                    onSelected: (_) => setState(() => _priority = priority),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(l10n.supportTicketCategoryLabel, style: AppTypography.caption),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _category,
              isExpanded: true,
              items: [
                for (final category in _categories)
                  DropdownMenuItem(
                    value: category,
                    child: Text(ticketCategoryLabel(l10n, category)),
                  ),
              ],
              onChanged: (value) =>
                  setState(() => _category = value ?? _category),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            PrimaryButton(
              label: l10n.supportTicketSubmitButton,
              isLoading: _isSaving,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
