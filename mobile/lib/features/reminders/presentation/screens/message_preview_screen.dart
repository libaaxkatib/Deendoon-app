import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/retry_section.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../data/reminder_repository.dart';
import '../../domain/message_template.dart';
import '../providers/reminder_detail_providers.dart';

/// The approved V1 default template display order — the backend's
/// `GET message-templates` sorts alphabetically (`orderBy('name')`, a
/// reasonable general-purpose default for the endpoint itself), which
/// doesn't match the documented chip order, so this screen re-sorts the
/// fetched list rather than changing the backend's general-purpose
/// ordering. Templates not in this list (e.g. a future custom template)
/// sort after these seven, in whatever order the backend returned them.
const _templateDisplayOrder = <String>[
  'First Reminder',
  'Second Reminder',
  'Third Reminder',
  'Last Reminder',
  'Meeting Request',
  'Phone Call Follow-up',
  'Promise to Pay Confirmation',
];

List<MessageTemplate> _sortedForDisplay(List<MessageTemplate> templates) {
  final sorted = [...templates];
  sorted.sort((a, b) {
    final aIndex = _templateDisplayOrder.indexOf(a.name);
    final bIndex = _templateDisplayOrder.indexOf(b.name);
    if (aIndex == -1 && bIndex == -1) return 0;
    if (aIndex == -1) return 1;
    if (bIndex == -1) return -1;
    return aIndex.compareTo(bIndex);
  });
  return sorted;
}

/// WhatsApp Preview / SMS Preview (§7.7/§7.8) — identical structure for
/// both channels per §7.8 ("Identical in structure to WhatsApp Preview"),
/// implemented as one screen with a channel toggle rather than two
/// near-duplicate screens. Recipient name/phone come from the real
/// `POST /messages/render` response (`MessageRenderingService::
/// resolveCustomer()` resolves the customer server-side regardless of
/// the reminder's `related_entity_type`) — more reliable than the client
/// re-deriving it.
///
/// "Send via WhatsApp"/"Send via SMS" work exactly like the existing Call
/// action (`ReminderDetailScreen._placeCall`'s non-debt path): they launch
/// the device's own WhatsApp/SMS app via `url_launcher` with the recipient
/// and rendered text pre-filled, and the user presses that app's own Send
/// button. No backend call is made here and no message-sent record is
/// created — there is no confirmation that the user actually pressed Send
/// in the external app, so claiming one would be dishonest. WhatsApp tries
/// the native `whatsapp://send` app intent first (opens the installed app
/// directly to the chat, same as the wa.me "click to chat" API but without
/// ever touching a browser) and only falls back to the `wa.me` web link if
/// WhatsApp isn't installed; SMS uses the standard `sms:` URI. No WhatsApp
/// Business API, no paid service either way. The backend's
/// `POST /reminders/{id}/send` endpoint and `ReminderActions.send()` still
/// exist and are still tested, but nothing in the UI calls them anymore.
class MessagePreviewScreen extends ConsumerStatefulWidget {
  final String reminderId;

  /// Preselects the channel toggle when arriving from a Follow-up
  /// reminder's WhatsApp/SMS action (Reminder Detail). Falls back to
  /// 'whatsapp' for any other/unrecognized value, same as the toggle's
  /// original default.
  final String? initialChannel;

  /// Fix #23 Decision 8 — the phone number the user chose on Reminder
  /// Detail's picker, if the customer had more than one. Passed straight
  /// through to `POST /messages/render` on every template selection; when
  /// null, the backend defaults to the customer's primary phone
  /// (Decision 7).
  final String? phoneNumberId;

  const MessagePreviewScreen({
    super.key,
    required this.reminderId,
    this.initialChannel,
    this.phoneNumberId,
  });

  @override
  ConsumerState<MessagePreviewScreen> createState() =>
      _MessagePreviewScreenState();
}

class _MessagePreviewScreenState extends ConsumerState<MessagePreviewScreen> {
  late String _channel = widget.initialChannel == 'sms' ? 'sms' : 'whatsapp';
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
          .renderMessage(
            templateId: template.id,
            reminderId: widget.reminderId,
            phoneNumberId: widget.phoneNumberId,
          );
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

  /// Launches the device's own WhatsApp/SMS app with the recipient and
  /// rendered message pre-filled — the user presses that app's Send
  /// button themselves, same as `_placeCall`'s dialer launch. SMS uses the
  /// standard `sms:` URI, which accepts the phone number as-is.
  Future<void> _send() async {
    if (_selectedTemplate == null || _renderedText == null) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final phone = _recipientPhone;
    if (phone == null || phone.trim().isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.reminderNoPhoneNumberMessage)),
      );
      return;
    }

    setState(() {
      _isSending = true;
      _error = null;
    });
    final navigator = Navigator.of(context);
    final launched = _channel == 'whatsapp'
        ? await _launchWhatsApp(phone, _renderedText!)
        : await launchUrl(
            Uri(
              scheme: 'sms',
              path: phone,
              queryParameters: {'body': _renderedText!},
            ),
            mode: LaunchMode.externalApplication,
          );
    if (!mounted) return;
    setState(() => _isSending = false);
    if (launched) {
      navigator.pop();
    } else {
      setState(
        () => _error = _channel == 'whatsapp'
            ? l10n.messagePreviewWhatsAppOpenError
            : l10n.messagePreviewMessagingAppOpenError,
      );
    }
  }

  /// Tries the native `whatsapp://send` app intent first — this opens the
  /// installed WhatsApp app directly to the customer's chat, never a
  /// browser. Only if that fails (WhatsApp not installed) does it fall
  /// back to the `wa.me` web "click to chat" link. Both require the phone
  /// number in digits-only international format, hence the strip.
  ///
  /// Unlike `tel:`/`sms:`, `launchUrl` doesn't return `false` for the
  /// unregistered `whatsapp:` scheme when no app can handle it — it throws
  /// `PlatformException(ACTIVITY_NOT_FOUND)` instead, so that has to be
  /// caught here and treated the same as "not installed" to reach the
  /// fallback rather than surfacing as an unhandled error.
  Future<bool> _launchWhatsApp(String phone, String text) async {
    final digitsOnlyPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final nativeUri = Uri(
      scheme: 'whatsapp',
      host: 'send',
      queryParameters: {'phone': digitsOnlyPhone, 'text': text},
    );
    try {
      if (await launchUrl(nativeUri, mode: LaunchMode.externalApplication))
        return true;
    } on PlatformException {
      // WhatsApp not installed — fall through to the web fallback below.
    }

    final webUri = Uri.https('wa.me', '/$digitsOnlyPhone', {'text': text});
    return launchUrl(webUri, mode: LaunchMode.externalApplication);
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
    final l10n = AppLocalizations.of(context);
    final templatesAsync = ref.watch(messageTemplatesProvider(_channel));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.messagePreviewTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'whatsapp',
                  label: Text(l10n.reminderDetailWhatsAppButton),
                ),
                ButtonSegment(
                  value: 'sms',
                  label: Text(l10n.reminderDetailSmsButton),
                ),
              ],
              selected: {_channel},
              onSelectionChanged: (selection) =>
                  _switchChannel(selection.first),
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
                          Text(
                            _recipientName ??
                                l10n.messagePreviewUnknownRecipient,
                            style: AppTypography.body,
                          ),
                          if (_recipientPhone != null)
                            Text(
                              _recipientPhone!,
                              style: AppTypography.caption,
                            ),
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
                  message: l10n.messagePreviewTemplatesLoadError,
                  onRetry: () =>
                      ref.invalidate(messageTemplatesProvider(_channel)),
                ),
                data: (templates) {
                  if (templates.isEmpty) {
                    return Center(
                      child: Text(
                        l10n.messagePreviewEmptyTemplatesState,
                        style: AppTypography.body,
                      ),
                    );
                  }

                  return ListView(
                    children: [
                      Text(
                        l10n.messagePreviewUseTemplateHeading,
                        style: AppTypography.heading,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final template in _sortedForDisplay(templates))
                            ChoiceChip(
                              label: Text(template.name),
                              selected: _selectedTemplate?.id == template.id,
                              onSelected: (_) => _selectTemplate(template),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_isRendering)
                        const Center(child: CircularProgressIndicator()),
                      if (_renderedText != null)
                        AppCard(
                          child: Text(
                            _renderedText!,
                            style: AppTypography.body.copyWith(height: 1.6),
                          ),
                        ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed:
                  (_selectedTemplate == null ||
                      _renderedText == null ||
                      _isSending)
                  ? null
                  : _send,
              child: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _channel == 'whatsapp'
                          ? l10n.messagePreviewSendViaWhatsAppButton
                          : l10n.messagePreviewSendViaSmsButton,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
