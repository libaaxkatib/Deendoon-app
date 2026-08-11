import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/deendoon_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/retry_section.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/domain/auth_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/request_message.dart';
import '../providers/professional_collection_actions.dart';
import '../providers/professional_collection_detail_providers.dart';

/// Messages (conversation) for one Professional Collection Request —
/// `GET/POST /professional-requests/{id}/messages`. Business Owner
/// messages render right-aligned, the other party ("Deendoon Team" — no
/// endpoint resolves an arbitrary user id to a name, so a generic,
/// Product-Owner-approved label is used instead of a raw id) renders
/// left-aligned. Same `AppCard` style as everywhere else in the app —
/// deliberately not a chat-bubble UI; alignment is the only visual
/// distinction, per the approved design decision.
class ProfessionalCollectionMessagesScreen extends ConsumerStatefulWidget {
  final String requestId;

  const ProfessionalCollectionMessagesScreen({super.key, required this.requestId});

  @override
  ConsumerState<ProfessionalCollectionMessagesScreen> createState() => _ProfessionalCollectionMessagesScreenState();
}

class _ProfessionalCollectionMessagesScreenState extends ConsumerState<ProfessionalCollectionMessagesScreen> {
  final _contentController = TextEditingController();
  bool _isSending = false;
  String? _error;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;

    setState(() {
      _isSending = true;
      _error = null;
    });

    try {
      await ref.read(professionalCollectionActionsProvider).postMessage(
            requestId: widget.requestId,
            content: content,
          );
      _contentController.clear();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final messagesAsync = ref.watch(professionalCollectionMessagesProvider(widget.requestId));
    final requestAsync = ref.watch(professionalCollectionDetailProvider(widget.requestId));
    final authState = ref.watch(authProvider);
    final currentUserId = authState is Authenticated ? authState.user.id : null;
    final isTerminal = requestAsync.valueOrNull?.isTerminal ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.professionalCollectionMessagesTitle)),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: RetrySection(
                  message: l10n.professionalCollectionMessagesLoadError,
                  onRetry: () => ref.invalidate(professionalCollectionMessagesProvider(widget.requestId)),
                ),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.professionalCollectionMessagesEmptyState,
                      style: AppTypography.body.copyWith(color: context.colors.textPrimary),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isOwnMessage = currentUserId != null && message.senderUserId == currentUserId;
                    return _MessageBubble(message: message, isOwnMessage: isOwnMessage);
                  },
                );
              },
            ),
          ),
          if (isTerminal)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.professionalCollectionMessagesClosedNotice,
                style: AppTypography.caption.copyWith(color: context.colors.textSecondary),
                textAlign: TextAlign.center,
              ),
            )
          else
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null) ...[
                      Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _contentController,
                            maxLines: 3,
                            minLines: 1,
                            decoration: InputDecoration(hintText: l10n.professionalCollectionMessageInputHint),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: _isSending
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.send, color: AppColors.primary),
                          onPressed: _isSending ? null : _send,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final RequestMessage message;
  final bool isOwnMessage;

  const _MessageBubble({required this.message, required this.isOwnMessage});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Flexible(
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOwnMessage
                      ? l10n.professionalCollectionMessageSenderYou
                      : l10n.professionalCollectionMessageSenderTeam,
                  style: AppTypography.caption.copyWith(color: context.colors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  message.content,
                  style: AppTypography.body.copyWith(color: context.colors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  message.createdAt.split('T').first,
                  style: AppTypography.caption.copyWith(color: context.colors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
