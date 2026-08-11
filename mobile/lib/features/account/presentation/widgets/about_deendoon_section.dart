import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/deendoon_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/coming_soon.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Profile screen's "About Deendoon" section. Version and build number are
/// real, read from the installed app bundle via `package_info_plus` — never
/// hardcoded, so they can't drift from what's actually installed.
///
/// Of the four "KUWA KALE" rows: Privacy Policy and Terms & Conditions push
/// a real in-app `LegalContentScreen` (local static copy — no CMS exists,
/// so there is nothing to fetch); Rate the App opens the real Play Store
/// listing for this app's actual package id on Android (constructed from
/// `package_info_plus`, not invented) — iOS shows an honest "not yet
/// published" message until an App Store ID is assigned post-submission.
/// Contact Support stays on the app's `showComingSoon` convention: no real
/// support email/phone/WhatsApp number exists anywhere in this project yet,
/// and wiring one up would mean inventing a destination nobody actually
/// monitors — this is a pending Product Owner decision, not a build gap.
///
/// The brand mark is the real logo asset (`assets/deendoon_logo.png`,
/// declared in `pubspec.yaml`) rather than a text wordmark or placeholder.
/// Content (Somali) below it is the Product Owner's approved copy —
/// intro, benefits, and closing — laid out per the approved reference.
class AboutDeendoonSection extends StatelessWidget {
  const AboutDeendoonSection({super.key});

  /// Opens the real Play Store listing for this app's actual installed
  /// package id. iOS has no assigned App Store ID yet (only issued after
  /// first submission to App Store Connect), so it shows an honest status
  /// message instead of a fabricated store link.
  Future<void> _rateApp(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final isIOS = !kIsWeb && (Platform.isIOS || defaultTargetPlatform == TargetPlatform.iOS);
    if (isIOS) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.aboutDeendoonNotPublishedMessage)));
      return;
    }

    final info = await PackageInfo.fromPlatform();
    final uri = Uri.parse('https://play.google.com/store/apps/details?id=${info.packageName}');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.aboutDeendoonPlayStoreOpenError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.aboutDeendoonAboutSectionLabel,
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: context.colors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            children: [
              Image.asset(
                'assets/deendoon_logo.png',
                width: 104,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.aboutDeendoonTagline,
                style: AppTypography.caption.copyWith(color: context.colors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(icon: Icons.info_outline, title: l10n.aboutDeendoonIntroHeading),
              const SizedBox(height: 12),
              Text(
                l10n.aboutDeendoonIntroParagraph1,
                style: AppTypography.body.copyWith(color: context.colors.textSecondary),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.aboutDeendoonIntroParagraph2,
                style: AppTypography.body.copyWith(color: context.colors.textSecondary),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.aboutDeendoonIntroParagraph3,
                style: AppTypography.body.copyWith(color: context.colors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(icon: Icons.star, title: l10n.aboutDeendoonBenefitsHeading),
              const SizedBox(height: 4),
              _BulletItem(l10n.aboutDeendoonBenefit1),
              _BulletItem(l10n.aboutDeendoonBenefit2),
              _BulletItem(l10n.aboutDeendoonBenefit3),
              _BulletItem(l10n.aboutDeendoonBenefit4),
              _BulletItem(l10n.aboutDeendoonBenefit5),
              _BulletItem(l10n.aboutDeendoonBenefit6),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(icon: Icons.check_circle, title: l10n.aboutDeendoonConclusionHeading),
              const SizedBox(height: 12),
              Text(
                l10n.aboutDeendoonConclusionParagraph,
                style: AppTypography.body.copyWith(color: context.colors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(icon: Icons.info_outline, title: l10n.aboutDeendoonInfoHeading),
              const SizedBox(height: 12),
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  final info = snapshot.data;
                  return Column(
                    children: [
                      _InfoRow(label: l10n.aboutDeendoonVersionLabel, value: info?.version ?? '—'),
                      const SizedBox(height: 8),
                      _InfoRow(label: l10n.aboutDeendoonBuildNumberLabel, value: info?.buildNumber ?? '—'),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              _InfoRow(
                label: l10n.aboutDeendoonCopyrightLabel,
                value: l10n.aboutDeendoonCopyrightValue(DateTime.now().year),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          l10n.aboutDeendoonOthersSectionLabel,
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: context.colors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        _MenuGroup(
          children: [
            _AboutRow(
              icon: Icons.privacy_tip_outlined,
              label: l10n.aboutDeendoonPrivacyPolicyLabel,
              onTap: () => context.push('/account/privacy-policy'),
            ),
            _AboutRow(
              icon: Icons.description_outlined,
              label: l10n.aboutDeendoonTermsConditionsLabel,
              onTap: () => context.push('/account/terms-conditions'),
            ),
            _AboutRow(
              icon: Icons.support_agent_outlined,
              label: l10n.aboutDeendoonContactSupportLabel,
              onTap: () => showComingSoon(context, l10n.aboutDeendoonContactSupportLabel),
            ),
            _AboutRow(
              icon: Icons.star_outline,
              label: l10n.aboutDeendoonRateAppLabel,
              onTap: () => _rateApp(context),
              isLast: true,
            ),
          ],
        ),
      ],
    );
  }
}

class _MenuGroup extends StatelessWidget {
  final List<_AboutRow> children;

  const _MenuGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(AppCard.radius),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.4),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final row in children) ...[
            row,
            if (!row.isLast)
              Divider(height: 1, indent: 56, color: context.colors.textSecondary.withValues(alpha: 0.12)),
          ],
        ],
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLast;

  const _AboutRow({required this.icon, required this.label, required this.onTap, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Icon(icon, color: context.colors.textSecondary, size: 20),
            const SizedBox(width: 16),
            Expanded(child: Text(label, style: AppTypography.body.copyWith(color: context.colors.textPrimary))),
            Icon(Icons.chevron_right, size: 20, color: context.colors.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// A small green icon badge + bold title — the header row repeated above
/// each of the four content cards (Hordhac/Caawinayaa/Gunaanad/
/// Macluumaad), matching the approved reference layout.
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 15),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: AppTypography.subheading.copyWith(
              fontWeight: FontWeight.w700,
              color: context.colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

/// One "DEENDOON wuxuu kaa caawinayaa inaad" bullet — a small green
/// checkmark badge instead of a plain bullet dot.
class _BulletItem extends StatelessWidget {
  final String text;

  const _BulletItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(top: 1),
            decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
            child: const Icon(Icons.check, color: Colors.white, size: 13),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppTypography.body.copyWith(color: context.colors.textSecondary))),
        ],
      ),
    );
  }
}

/// One label/value row inside the "Macluumaad" card (Version, Build
/// Number, Copyright) — label left, real value right.
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.body.copyWith(color: context.colors.textSecondary)),
        Flexible(
          child: Text(
            value,
            style: AppTypography.body.copyWith(color: context.colors.textPrimary),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
