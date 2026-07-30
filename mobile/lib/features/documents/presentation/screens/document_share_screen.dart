import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/retry_section.dart';
// Reused directly from Reminders (Sprint 14) — `GET /message-templates`
// is a generic, tenant-wide endpoint with nothing reminder-specific
// about it; the same cross-feature provider-reuse pattern the Cases
// module already uses for Debt/Customer repositories (Sprint 13).
import '../../../reminders/domain/message_template.dart';
import '../../../reminders/presentation/providers/reminder_detail_providers.dart' show messageTemplatesProvider;
import '../providers/document_actions.dart';

/// Share (§8.8) — channel + template picker, sending via the real
/// `POST /documents/{id}/share`. Unlike the Reminder Send flow (Sprint
/// 14), there is no render-preview step: `DocumentShareRequest`/
/// `DocumentController::share()` sends immediately once a template is
/// chosen — no `POST /messages/render` equivalent exists for documents
/// (confirmed by a full read of `DocumentController`/
/// `MessageRenderingService`). The recipient's phone is resolved
/// server-side from the document's linked customer; it is never
/// client-supplied.
class DocumentShareScreen extends ConsumerStatefulWidget {
  final String documentId;

  const DocumentShareScreen({super.key, required this.documentId});

  @override
  ConsumerState<DocumentShareScreen> createState() => _DocumentShareScreenState();
}

class _DocumentShareScreenState extends ConsumerState<DocumentShareScreen> {
  String _channel = 'whatsapp';
  MessageTemplate? _selectedTemplate;
  bool _isSending = false;
  String? _error;

  Future<void> _send() async {
    if (_selectedTemplate == null) return;
    setState(() {
      _isSending = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      await ref.read(documentActionsProvider).share(
            documentId: widget.documentId,
            channel: _channel,
            templateId: _selectedTemplate!.id,
          );
      messenger.showSnackBar(const SnackBar(content: Text('Document shared successfully')));
      router.pop();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _switchChannel(String channel) {
    setState(() {
      _channel = channel;
      _selectedTemplate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(messageTemplatesProvider(_channel));

    return Scaffold(
      appBar: AppBar(title: const Text('Share Document')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'whatsapp', label: Text('WhatsApp')),
                ButtonSegment(value: 'sms', label: Text('SMS')),
              ],
              selected: {_channel},
              onSelectionChanged: (selection) => _switchChannel(selection.first),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: templatesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => RetrySection(
                  message: 'Could not load message templates.',
                  onRetry: () => ref.invalidate(messageTemplatesProvider(_channel)),
                ),
                data: (templates) {
                  if (templates.isEmpty) {
                    return const Center(
                      child: Text('No templates available for this channel', style: AppTypography.body),
                    );
                  }

                  return ListView(
                    children: [
                      const Text('Use Template', style: AppTypography.heading),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final template in templates)
                            ChoiceChip(
                              label: Text(template.name),
                              selected: _selectedTemplate?.id == template.id,
                              onSelected: (_) => setState(() => _selectedTemplate = template),
                            ),
                        ],
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      ],
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: (_selectedTemplate == null || _isSending) ? null : _send,
              child: _isSending
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_channel == 'whatsapp' ? 'Send via WhatsApp' : 'Send via SMS'),
            ),
          ],
        ),
      ),
    );
  }
}
