import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/deendoon_colors.dart';
import '../../../../core/widgets/avatar_initial.dart';
import '../../../../l10n/generated/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(authProvider);
    final name = auth is Authenticated
        ? auth.user.name
        : l10n.dashboardGreetingFallbackName;

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
              _greeting(l10n, DateTime.now().hour),
              style: AppTypography.caption.copyWith(
                fontSize: 11,
                height: 1,
                color: context.colors.textSecondary,
              ),
            ),
            Text(
              '$name 👋',
              style: AppTypography.subheading.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                height: 1.15,
                color: context.colors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(width: 2),
        Icon(
          Icons.chevron_right,
          size: 18,
          color: context.colors.textSecondary,
        ),
      ],
    );
  }

  String _greeting(AppLocalizations l10n, int hour) {
    if (hour < 12) return l10n.dashboardGreetingMorning;
    if (hour < 17) return l10n.dashboardGreetingAfternoon;
    return l10n.dashboardGreetingEvening;
  }
}
