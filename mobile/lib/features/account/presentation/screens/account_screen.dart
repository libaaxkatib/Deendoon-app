import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/avatar_initial.dart';
import '../../../auth/domain/auth_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Account — reached by tapping the greeting/avatar on the Home Dashboard
/// header. The profile summary card itself (avatar, name, email — all
/// real, cached from login) is the entry point to the Profile screen, so
/// no separate "Profile" menu entry is shown below it; the grouped menu
/// card holds Business Profile, Subscription, Settings, Notifications, and
/// About, with Logout separated below as a clearly destructive action.
/// Subscription's own screen is the entry point to Storage (Phase 5) —
/// no separate "Storage" menu entry here, matching the approved
/// Account → Subscription → Storage flow.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final name = auth is Authenticated ? auth.user.name : '';
    final email = auth is Authenticated ? auth.user.email : '';

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            key: const Key('accountProfileHeaderCard'),
            onTap: () => context.push('/account/profile'),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Row(
              children: [
                AvatarInitial(name: name.isEmpty ? '?' : name, radius: 26),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty ? '—' : name,
                        style: AppTypography.subheading.copyWith(fontWeight: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        email.isEmpty ? '—' : email,
                        style: AppTypography.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, size: 22, color: AppColors.textSecondary),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'ACCOUNT',
            style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),
          _MenuGroup(
            children: [
              _AccountMenuTile(
                icon: Icons.business_outlined,
                label: 'Business Profile',
                onTap: () => context.push('/account/business-profile'),
              ),
              _AccountMenuTile(
                icon: Icons.card_membership_outlined,
                label: 'Subscription',
                onTap: () => context.push('/account/subscription'),
              ),
              _AccountMenuTile(
                icon: Icons.settings_outlined,
                label: 'Settings',
                onTap: () => context.push('/account/settings'),
              ),
              _AccountMenuTile(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                onTap: () => context.push('/notifications'),
              ),
              _AccountMenuTile(
                icon: Icons.info_outline,
                label: 'About',
                onTap: () => context.push('/account/about'),
              ),
              _AccountMenuTile(
                icon: Icons.upload_file_outlined,
                label: 'Bulk Import',
                onTap: () => context.push('/account/bulk-import'),
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 24),
          AppCard(
            onTap: () => ref.read(authProvider.notifier).forceLogout(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            splashColor: AppColors.danger.withValues(alpha: 0.12),
            highlightColor: AppColors.danger.withValues(alpha: 0.06),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout, color: AppColors.danger, size: 20),
                SizedBox(width: 10),
                Text(
                  'Logout',
                  style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Groups related menu rows into one continuous card with hairline
/// dividers between rows — same visual grouping pattern iOS/Material
/// settings screens use, instead of four separate floating cards.
class _MenuGroup extends StatelessWidget {
  final List<_AccountMenuTile> children;

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
          for (final tile in children) ...[
            tile,
            if (!tile.isLast) const Divider(height: 1, indent: 56, color: Colors.white12),
          ],
        ],
      ),
    );
  }
}

class _AccountMenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLast;

  const _AccountMenuTile({required this.icon, required this.label, required this.onTap, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textPrimary, size: 21),
            const SizedBox(width: 16),
            Expanded(child: Text(label, style: AppTypography.body)),
            const Icon(Icons.chevron_right, size: 20, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
