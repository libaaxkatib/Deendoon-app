import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Decision 10 — zero-cost static Deendoon contact links only (no WhatsApp
/// Business API/SMS gateway/paid service). Mirrors
/// `reminder_detail_screen.dart`'s `tel:` pattern and
/// `message_preview_screen.dart`'s native-intent-first WhatsApp pattern
/// exactly; `mailto:` follows the identical `Uri(scheme: ...)` shape.
class ContactDeendoonCard extends StatelessWidget {
  const ContactDeendoonCard({super.key});

  static const _phone = '615178666';
  static const _whatsappPhone = '252615514692';
  static const _email = 'deendoonapp@gmail.com';

  Future<void> _call(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final launched = await launchUrl(Uri(scheme: 'tel', path: _phone));
    if (!launched && context.mounted) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.supportTicketContactLaunchError)),
      );
    }
  }

  Future<void> _sendEmail(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final launched = await launchUrl(Uri(scheme: 'mailto', path: _email));
    if (!launched && context.mounted) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.supportTicketContactLaunchError)),
      );
    }
  }

  Future<void> _whatsapp(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final nativeUri = Uri(
      scheme: 'whatsapp',
      host: 'send',
      queryParameters: {'phone': _whatsappPhone},
    );
    try {
      if (await launchUrl(nativeUri, mode: LaunchMode.externalApplication))
        return;
    } on PlatformException {
      // WhatsApp not installed — fall through to the web fallback below.
    }
    final webUri = Uri.https('wa.me', '/$_whatsappPhone');
    final launched = await launchUrl(
      webUri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && context.mounted) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.supportTicketContactLaunchError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.supportTicketContactCardTitle, style: AppTypography.body),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _call(context),
                icon: const Icon(Icons.call_outlined, size: 18),
                label: Text(l10n.supportTicketContactPhoneButton),
              ),
              OutlinedButton.icon(
                onPressed: () => _whatsapp(context),
                icon: const Icon(
                  Icons.chat_outlined,
                  size: 18,
                  color: AppColors.success,
                ),
                label: Text(l10n.supportTicketContactWhatsAppButton),
              ),
              OutlinedButton.icon(
                onPressed: () => _sendEmail(context),
                icon: const Icon(Icons.email_outlined, size: 18),
                label: Text(l10n.supportTicketContactEmailButton),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
