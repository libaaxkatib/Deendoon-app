import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/providers/auth_provider.dart';

/// Wraps the 5 frozen tabs (`Mobile_UI_V1_Frozen.md` §3's fixed order) in a
/// `StatefulShellRoute.indexedStack` branch container so each tab preserves
/// its own state/scroll position when switching away and back.
class AppShellScreen extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AppShellScreen({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Analytics'),
          NavigationDestination(icon: Icon(Icons.folder_outlined), selectedIcon: Icon(Icons.folder), label: 'Cases'),
          NavigationDestination(icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications), label: 'Reminders'),
          NavigationDestination(icon: Icon(Icons.description_outlined), selectedIcon: Icon(Icons.description), label: 'Documents'),
        ],
      ),
    );
  }
}

/// Temporary manual-QA affordance (per plan): the only in-app way to
/// exercise the logout/re-login loop without hand-corrupting storage or
/// waiting out the 60-minute idle timeout. Remove once a real settings/
/// profile screen exists in a future sprint.
class LogoutAction extends ConsumerWidget {
  const LogoutAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.logout),
      tooltip: 'Log out',
      onPressed: () => ref.read(authProvider.notifier).forceLogout(),
    );
  }
}
