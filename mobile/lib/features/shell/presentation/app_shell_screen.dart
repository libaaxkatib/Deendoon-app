import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/generated/app_localizations.dart';

/// Wraps the 5 frozen tabs (`Mobile_UI_V1_Frozen.md` §3's fixed order) in a
/// `StatefulShellRoute.indexedStack` branch container so each tab preserves
/// its own state/scroll position when switching away and back.
///
/// Mobile QA Fix — Back Button: each branch's own pushed screens (Customer
/// Detail, Case Detail, forms, etc.) already pop correctly on Back — they
/// have their own nested Navigator stack, which receives the system Back
/// event before it ever reaches this widget's [PopScope]. This widget only
/// ever sees Back when a branch's stack is already empty (i.e. at one of
/// the 5 tab roots), which is exactly when Android's default behavior
/// would otherwise exit the app immediately.
class AppShellScreen extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  /// Overridable only for tests — production always uses the real
  /// [SystemNavigator.pop].
  final Future<void> Function() onExit;

  /// Overridable only for tests — `DateTime.now()` isn't affected by
  /// [WidgetTester.pump]'s fake clock, so the "press again within N
  /// seconds" window can't otherwise be exercised without a real delay.
  final DateTime Function() now;

  const AppShellScreen({
    super.key,
    required this.navigationShell,
    Future<void> Function()? onExit,
    DateTime Function()? now,
  }) : onExit = onExit ?? SystemNavigator.pop,
       now = now ?? DateTime.now;

  @override
  ConsumerState<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends ConsumerState<AppShellScreen> {
  static const _exitWindow = Duration(seconds: 2);

  DateTime? _lastBackPressAt;

  void _handleBackPress(BuildContext context) {
    if (widget.navigationShell.currentIndex != 0) {
      widget.navigationShell.goBranch(0);
      return;
    }

    final now = widget.now();
    final last = _lastBackPressAt;
    if (last != null && now.difference(last) < _exitWindow) {
      widget.onExit();
      return;
    }

    _lastBackPressAt = now;
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.shellExitConfirmationMessage),
          duration: _exitWindow,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackPress(context);
      },
      child: Scaffold(
        body: widget.navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: widget.navigationShell.currentIndex,
          onDestinationSelected: (index) => widget.navigationShell.goBranch(
            index,
            initialLocation: index == widget.navigationShell.currentIndex,
          ),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: l10n.navHome,
            ),
            NavigationDestination(
              icon: const Icon(Icons.bar_chart_outlined),
              selectedIcon: const Icon(Icons.bar_chart),
              label: l10n.navAnalytics,
            ),
            NavigationDestination(
              icon: const Icon(Icons.folder_outlined),
              selectedIcon: const Icon(Icons.folder),
              label: l10n.navCases,
            ),
            NavigationDestination(
              icon: const Icon(Icons.notifications_outlined),
              selectedIcon: const Icon(Icons.notifications),
              label: l10n.navReminders,
            ),
            NavigationDestination(
              icon: const Icon(Icons.description_outlined),
              selectedIcon: const Icon(Icons.description),
              label: l10n.navDocuments,
            ),
          ],
        ),
      ),
    );
  }
}
