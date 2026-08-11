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
    final messenger = ScaffoldMessenger.of(context);
    final isIOS = !kIsWeb && (Platform.isIOS || defaultTargetPlatform == TargetPlatform.iOS);
    if (isIOS) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Deendoon is not yet published on the App Store.')));
      return;
    }

    final info = await PackageInfo.fromPlatform();
    final uri = Uri.parse('https://play.google.com/store/apps/details?id=${info.packageName}');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Could not open the Play Store.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'ABOUT',
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
                'Kaaliyaha Casriga ah ee\nSoo Celinta Deymaha',
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
              const _SectionHeader(icon: Icons.info_outline, title: 'Hordhac DEENDOON'),
              const SizedBox(height: 12),
              Text(
                'DEENDOON waa app kaa caawinaya inaad si fudud u maamusho '
                'deymaha macaamiishaada oo aad u soo ceshato lacagta aad ku '
                'leedahay.',
                style: AppTypography.body.copyWith(color: context.colors.textSecondary),
              ),
              const SizedBox(height: 12),
              Text(
                'Waxaad ku diiwaangelin kartaa deymaha kaa maqan, la socon '
                'kartaa lacagaha la bixiyay iyo kuwa harsan, jadwal u samayn '
                'kartaa wicitaannada, fariimaha WhatsApp, SMS-ka iyo '
                'xasuusinnada muhiimka ah. App-ku wuxuu kuu sheegayaa cidda '
                'la xiriirkeedu gaaray iyo tallaabada xigta ee aad qaadi '
                'lahayd si aan deyn loo illoobin.',
                style: AppTypography.body.copyWith(color: context.colors.textSecondary),
              ),
              const SizedBox(height: 12),
              Text(
                'Haddii dadaalladaadu aysan ku filnaan soo celinta deynta, '
                'waxaad si toos ah uga codsan kartaa gudaha app-ka kooxda '
                'xirfadlayaasha Deendoon inay si sharci ah oo xirfad leh kuu '
                'metelaan, ula xiriiraan deyn-bixiyaha, ugana shaqeeyaan soo '
                'celinta lacagtaada.',
                style: AppTypography.body.copyWith(color: context.colors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _SectionHeader(icon: Icons.star, title: 'DEENDOON wuxuu kaa caawinayaa inaad:'),
              SizedBox(height: 4),
              _BulletItem('Diiwaangeliso oo aad maamusho dhammaan deymaha hal meel.'),
              _BulletItem('Xasuusinno u dirto macaamiisha waqtigooda.'),
              _BulletItem('La socoto wicitaannada, WhatsApp-ka, SMS-ka iyo ballamaha.'),
              _BulletItem('Diiwaangeliso lacagaha la bixiyay iyo kuwa harsan.'),
              _BulletItem('Hesho warbixinno cad oo ku saabsan deymahaaga.'),
              _BulletItem(
                'Kordhiso soo celinta lacagaha lagugu leeyahay iyo socodka lacagta (Cash Flow) ee ganacsigaaga.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionHeader(icon: Icons.check_circle, title: 'Gunaanad'),
              const SizedBox(height: 12),
              Text(
                'DEENDOON waa kaaliye casri ah oo kuu fududeynaya maamulka '
                'deymaha, xoojiyana la socodka macaamiisha, si ganacsigaagu u '
                'helo lacagtiisa waqtigeeda.',
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
              const _SectionHeader(icon: Icons.info_outline, title: 'Macluumaad'),
              const SizedBox(height: 12),
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  final info = snapshot.data;
                  return Column(
                    children: [
                      _InfoRow(label: 'Version', value: info?.version ?? '—'),
                      const SizedBox(height: 8),
                      _InfoRow(label: 'Build Number', value: info?.buildNumber ?? '—'),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              _InfoRow(label: 'Copyright', value: '© ${DateTime.now().year} Deendoon. All rights reserved.'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'KUWA KALE',
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
              label: 'Privacy Policy',
              onTap: () => context.push('/account/privacy-policy'),
            ),
            _AboutRow(
              icon: Icons.description_outlined,
              label: 'Terms & Conditions',
              onTap: () => context.push('/account/terms-conditions'),
            ),
            _AboutRow(
              icon: Icons.support_agent_outlined,
              label: 'Contact Support',
              onTap: () => showComingSoon(context, 'Contact Support'),
            ),
            _AboutRow(
              icon: Icons.star_outline,
              label: 'Rate the App',
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
