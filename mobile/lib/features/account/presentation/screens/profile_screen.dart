import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/avatar_initial.dart';
import '../../../auth/domain/auth_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Real, cached data only — `{id, name, email}` from `UserResource`,
/// already held in `AuthState.Authenticated` since login/refresh. There is
/// no `GET/PUT /me` endpoint (`AuthApi`'s own doc comment), so this screen
/// is read-only: no edit action is offered rather than inventing one.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth is Authenticated ? auth.user : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            child: Column(
              children: [
                AvatarInitial(name: user?.name.isNotEmpty == true ? user!.name : '?', radius: 30),
                const SizedBox(height: 12),
                Text(
                  user?.name ?? '—',
                  style: AppTypography.subheading.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(user?.email ?? '—', style: AppTypography.caption),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            onTap: () => context.push('/account/change-password'),
            child: const Row(
              children: [
                Icon(Icons.lock_outline, color: AppColors.textPrimary),
                SizedBox(width: 14),
                Expanded(child: Text('Change Password', style: AppTypography.body)),
                Icon(Icons.chevron_right, size: 20, color: AppColors.textSecondary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
