import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/deendoon_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/subscription_providers.dart';

/// Manual Mobile-Money Subscription Payment Flow (Product Owner decision,
/// final UX direction): the combined "Payment Instructions / Send Money"
/// step. Confirms the just-created (always Pending) Subscription Change
/// Request was saved, shows the platform's destination mobile-money
/// number (`subscriptionPaymentInfoProvider` — server-supplied, never
/// hardcoded), and offers exactly three named-operator buttons that open
/// the device dialer pre-filled with a fixed USSD code.
///
/// [_saalamBankUssd]/[_evcPlusUssd]/[_eDahabUssd] are fixed, Product-Owner-
/// approved strings, not derived from [subscriptionPaymentInfoProvider] and
/// not admin-configurable — deliberately distinct from the displayed
/// destination number above them, which remains backend-driven exactly as
/// before. `#` is percent-encoded to `%23` by `Uri(scheme:, path:)`
/// automatically (verified: `Uri(scheme: 'tel', path: '*799*32666663*5#')`
/// -> `tel:*799*32666663*5%23`) — without this, `#` would be read as a URI
/// fragment delimiter and the digits after it silently dropped.
///
/// Critically: neither button, nor returning from the external dialer/
/// mobile-money app, ever marks anything as paid or successful here —
/// there is no way to know whether the user actually completed the
/// transaction. The request stays exactly Pending, verified only by the
/// existing backend Platform Administrator approval workflow. "Done"
/// simply moves the user forward to the Thank You screen; it is a neutral
/// navigation action, not a success claim.
class PaymentSavedScreen extends ConsumerWidget {
  static const _saalamBankUssd = '*799*32666663*5#';
  static const _evcPlusUssd = '*712*615514692*5#';
  static const _eDahabUssd = '*712*625514692*5#';

  const PaymentSavedScreen({super.key});

  Future<void> _launchUssd(
    BuildContext context,
    ScaffoldMessengerState messenger,
    AppLocalizations l10n,
    String ussdCode,
  ) async {
    final launched = await launchUrl(Uri(scheme: 'tel', path: ussdCode));
    if (!launched) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.paymentSavedCouldNotOpenDialerMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final paymentInfoAsync = ref.watch(subscriptionPaymentInfoProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.paymentSavedTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.paymentSavedSuccessMessage,
                style: AppTypography.subheading.copyWith(
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.paymentSavedInstructionMessage,
                style: AppTypography.body.copyWith(
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.paymentSavedDestinationNumberLabel,
                style: AppTypography.caption.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              paymentInfoAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => Text(
                  l10n.paymentSavedDestinationNumberUnavailable,
                  style: AppTypography.body.copyWith(
                    color: context.colors.textPrimary,
                  ),
                ),
                data: (destinationNumber) => Text(
                  destinationNumber ?? l10n.paymentSavedDestinationNumberUnavailable,
                  style: AppTypography.subheading.copyWith(
                    color: context.colors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: l10n.paymentSavedSaalamBankButton,
                onPressed: () => _launchUssd(
                  context,
                  messenger,
                  l10n,
                  _saalamBankUssd,
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: l10n.paymentSavedEvcPlusButton,
                onPressed: () => _launchUssd(
                  context,
                  messenger,
                  l10n,
                  _evcPlusUssd,
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: l10n.paymentSavedEDahabButton,
                onPressed: () => _launchUssd(
                  context,
                  messenger,
                  l10n,
                  _eDahabUssd,
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () => context.pushReplacement(
                  '/account/subscription/thank-you',
                ),
                child: Text(l10n.paymentSavedDoneButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
