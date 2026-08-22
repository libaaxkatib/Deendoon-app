import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/deendoon_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../support_tickets/presentation/widgets/contact_deendoon_card.dart';

/// Manual Mobile-Money Subscription Payment Flow (Product Owner decision,
/// final UX direction): the terminal screen of the flow, reached from
/// `PaymentSavedScreen`'s "Done" action. Deliberately shows no payment
/// status, no "Verified"/"Successful"/"Pending"/"Active" state, and no
/// further navigation forward — the backend Platform Administrator
/// approval workflow (unchanged, `SubscriptionService::approve()`/
/// `reject()`) remains the only source of truth for the request's
/// eventual outcome; the app's role in this flow ends here.
///
/// Reuses [ContactDeendoonCard] as-is — the same approved phone/WhatsApp/
/// email support contact already used on the Support Tickets list screen
/// — rather than duplicating or re-hardcoding those values.
class ThankYouScreen extends StatelessWidget {
  const ThankYouScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.thankYouTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.thankYouHeading,
                textAlign: TextAlign.center,
                style: AppTypography.heading.copyWith(
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.thankYouMessage,
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              const ContactDeendoonCard(),
            ],
          ),
        ),
      ),
    );
  }
}
