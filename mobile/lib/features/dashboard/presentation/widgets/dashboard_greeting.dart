import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/avatar_initial.dart';
import '../../../auth/domain/auth_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Replaces the plain "Home" AppBar title with a time-of-day greeting, the
/// signed-in user's avatar/name, and a trailing chevron — reads the
/// already-fetched `Authenticated` user from `authProvider` (Sprint 8/9),
/// no new API call. The avatar and chevron are a premium affordance
/// signaling the whole row is tappable (opens Account / Profile); the
/// underlying tap target and destination are unchanged.
class DashboardGreeting extends ConsumerWidget {
  const DashboardGreeting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final name = auth is Authenticated ? auth.user.name : 'there';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AvatarInitial(name: name, radius: 17),
        const SizedBox(width: 10),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _greeting(DateTime.now().hour),
              style: AppTypography.caption.copyWith(fontSize: 11, height: 1),
            ),
            Text(
              '$name 👋',
              style: AppTypography.subheading.copyWith(fontWeight: FontWeight.w800, fontSize: 17, height: 1.15),
            ),
          ],
        ),
        const SizedBox(width: 2),
        const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
      ],
    );
  }

  String _greeting(int hour) {
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}
