import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/coming_soon.dart';

/// Profile screen's "About Deendoon" section. Version and build number are
/// real, read from the installed app bundle via `package_info_plus` — never
/// hardcoded, so they can't drift from what's actually installed. Privacy
/// Policy, Terms & Conditions, Contact Support, and Rate the App have no
/// real destination yet (no CMS/store listing exists), so each uses the
/// app's existing `showComingSoon` convention rather than a fake screen or
/// a dead link — the same honest pattern already used for Global Search
/// and the Business Profile/Settings gaps.
///
/// The brand mark is the real logo asset (`assets/deendoon_logo.png`,
/// declared in `pubspec.yaml`) rather than a text wordmark or placeholder.
/// Content (Somali) below it is the Product Owner's approved copy —
/// intro, benefits, and closing — laid out per the approved reference;
/// only the four Privacy/Terms/Contact/Rate rows below are untouched,
/// pre-existing structure.
class AboutDeendoonSection extends StatelessWidget {
  const AboutDeendoonSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'ABOUT',
          style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.8),
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
              const Text(
                'Kaaliyaha Casriga ah ee\nSoo Celinta Deymaha',
                style: AppTypography.caption,
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
                style: AppTypography.body.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              Text(
                'Waxaad ku diiwaangelin kartaa deymaha kaa maqan, la socon '
                'kartaa lacagaha la bixiyay iyo kuwa harsan, jadwal u samayn '
                'kartaa wicitaannada, fariimaha WhatsApp, SMS-ka iyo '
                'xasuusinnada muhiimka ah. App-ku wuxuu kuu sheegayaa cidda '
                'la xiriirkeedu gaaray iyo tallaabada xigta ee aad qaadi '
                'lahayd si aan deyn loo illoobin.',
                style: AppTypography.body.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              Text(
                'Haddii dadaalladaadu aysan ku filnaan soo celinta deynta, '
                'waxaad si toos ah uga codsan kartaa gudaha app-ka kooxda '
                'xirfadlayaasha Deendoon inay si sharci ah oo xirfad leh kuu '
                'metelaan, ula xiriiraan deyn-bixiyaha, ugana shaqeeyaan soo '
                'celinta lacagtaada.',
                style: AppTypography.body.copyWith(color: AppColors.textSecondary),
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
                style: AppTypography.body.copyWith(color: AppColors.textSecondary),
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
          style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.8),
        ),
        const SizedBox(height: 8),
        _MenuGroup(
          children: [
            _AboutRow(
              icon: Icons.privacy_tip_outlined,
              label: 'Privacy Policy',
              onTap: () => showComingSoon(context, 'Privacy Policy'),
            ),
            _AboutRow(
              icon: Icons.description_outlined,
              label: 'Terms & Conditions',
              onTap: () => showComingSoon(context, 'Terms & Conditions'),
            ),
            _AboutRow(
              icon: Icons.support_agent_outlined,
              label: 'Contact Support',
              onTap: () => showComingSoon(context, 'Contact Support'),
            ),
            _AboutRow(
              icon: Icons.star_outline,
              label: 'Rate the App',
              onTap: () => showComingSoon(context, 'Rate the App'),
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
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppCard.radius),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.4),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final row in children) ...[
            row,
            if (!row.isLast) const Divider(height: 1, indent: 56, color: Colors.white12),
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
            Icon(icon, color: AppColors.textSecondary, size: 20),
            const SizedBox(width: 16),
            Expanded(child: Text(label, style: AppTypography.body)),
            const Icon(Icons.chevron_right, size: 20, color: AppColors.textSecondary),
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
          child: Text(title, style: AppTypography.subheading.copyWith(fontWeight: FontWeight.w700)),
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
          Expanded(child: Text(text, style: AppTypography.body.copyWith(color: AppColors.textSecondary))),
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
        Text(label, style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
        Flexible(
          child: Text(value, style: AppTypography.body, textAlign: TextAlign.right),
        ),
      ],
    );
  }
}
