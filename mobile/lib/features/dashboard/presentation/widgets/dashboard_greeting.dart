import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../auth/domain/auth_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Replaces the plain "Home" AppBar title with a time-of-day greeting and
/// the signed-in user's name — reads the already-fetched `Authenticated`
/// user from `authProvider` (Sprint 8/9), no new API call.
class DashboardGreeting extends ConsumerWidget {
  const DashboardGreeting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final name = auth is Authenticated ? auth.user.name : 'there';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${_greeting(DateTime.now().hour)},', style: AppTypography.caption),
        const SizedBox(height: 2),
        Text('$name 👋', style: AppTypography.subheading),
      ],
    );
  }

  String _greeting(int hour) {
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}
