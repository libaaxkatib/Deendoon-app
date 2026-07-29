import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/retry_section.dart';
import '../../data/reminder_repository.dart';
import '../../domain/message_template.dart';
import '../providers/reminder_actions.dart';
import '../providers/reminder_detail_providers.dart';

/// WhatsApp Preview / SMS Preview (§7.7/§7.8) — identical structure for
/// both channels per §7.8 ("Identical in structure to WhatsApp Preview"),
/// implemented as one screen with a channel toggle rather than two
/// near-duplicate screens. Recipient name/phone come from the real
/// `POST /messages/render` response (`MessageRenderingService::
/// resolveCustomer()` resolves the customer server-side regardless of
/// the reminder's `related_entity_type`) — more reliable than the client
/// re-deriving it. The actual send commits through the single real
/// `POST /reminders/{id}/send` endpoint, which produces the identical
/// `SentMessage` row as the two-step `messages/render` →
/// `messages/send/whatsapp|sms` path.
class MessagePreviewScreen extends ConsumerStatefulWidget {
  final String reminderId;

  const MessagePreviewScreen({super.key, required this.reminderId});

  @override
  ConsumerState<MessagePreviewScreen> createState() => _MessagePreviewScreenState();
}

class _MessagePreviewScreenState extends ConsumerState<MessagePreviewScreen> {
  String _channel = 'whatsapp';
  MessageTemplate? _selectedTemplate;
  String? _renderedText;
  String? _recipientName;
  String? _recipientPhone;
  bool _isRendering = false;
  bool _isSending = false;
  String? _error;

  Future<void> _selectTemplate(MessageTemplate template) async {
    setState(() {
      _selectedTemplate = template;
      _isRendering = true;
      _error = null;
    });
    try {
      final rendered = await ref
          .read(reminderRepositoryProvider)
          .renderMessage(templateId: template.id, reminderId: widget.reminderId);
      if (!mounted) return;
      setState(() {
        _renderedText = rendered['rendered_text'] as String?;
        _recipientName = rendered['recipient_name'] as String?;
        _recipientPhone = rendered['recipient_phone'] as String?;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isRendering = false);
    }
  }

  Future<void> _send() async {
    if (_selectedTemplate == null) return;
    setState(() {
      _isSending = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      await ref.read(reminderActionsProvider).send(
            id: widget.reminderId,
            channel: _channel,
            templateId: _selectedTemplate!.id,
          );
      messenger.showSnackBar(const SnackBar(content: Text('Reminder sent successfully')));
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
      _renderedText = null;
      _recipientName = null;
      _recipientPhone = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(messageTemplatesProvider(_channel));

    return Scaffold(
      appBar: AppBar(title: const Text('Send Reminder')),
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
            if (_recipientName != null || _recipientPhone != null)
              AppCard(
                child: Row(
                  children: [
                    const Icon(Icons.person_outline, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_recipientName ?? 'Unknown recipient', style: AppTypography.body),
                          if (_recipientPhone != null) Text(_recipientPhone!, style: AppTypography.caption),
                        ],
                      ),
                    ),
                  ],
                ),
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
                    return const Center(child: Text('No templates available for this channel', style: AppTypography.body));
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
                              onSelected: (_) => _selectTemplate(template),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_isRendering) const Center(child: CircularProgressIndicator()),
                      if (_renderedText != null)
                        AppCard(child: Text(_renderedText!, style: AppTypography.body)),
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
