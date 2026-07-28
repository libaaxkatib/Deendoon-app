import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/placeholder_scaffold.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/shell/presentation/app_shell_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import 'route_paths.dart';
import 'router_refresh_notifier.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RoutePaths.splash,
    refreshListenable: ref.watch(routerRefreshProvider),
    redirect: (context, state) => _redirect(ref, state),
    routes: [
      GoRoute(path: RoutePaths.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: RoutePaths.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: RoutePaths.forgotPassword, builder: (_, _) => const ForgotPasswordScreen()),
      GoRoute(path: RoutePaths.resetPassword, builder: (_, _) => const ResetPasswordScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShellScreen(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: RoutePaths.home,
              builder: (_, _) => const PlaceholderScaffold(
                title: 'Home',
                actions: [LogoutAction()],
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: RoutePaths.analytics, builder: (_, _) => const PlaceholderScaffold(title: 'Analytics')),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: RoutePaths.cases, builder: (_, _) => const PlaceholderScaffold(title: 'Cases')),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: RoutePaths.reminders, builder: (_, _) => const PlaceholderScaffold(title: 'Reminders')),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: RoutePaths.documents, builder: (_, _) => const PlaceholderScaffold(title: 'Documents')),
          ]),
        ],
      ),
    ],
  );
});

/// Routes reachable without a session — login and both password-recovery
/// screens (there is no reason an authenticated user should be doing
/// password recovery mid-session, so these also bounce to /home if
/// reached while already logged in, same as /login already did).
const _publicRoutes = {
  RoutePaths.login,
  RoutePaths.forgotPassword,
  RoutePaths.resetPassword,
};

String? _redirect(Ref ref, GoRouterState state) {
  final auth = ref.read(authProvider);
  final loc = state.matchedLocation;

  if (auth is AuthInitial || auth is AuthRestoring) {
    return loc == RoutePaths.splash ? null : RoutePaths.splash;
  }

  final loggedIn = auth is Authenticated;
  if (!loggedIn) {
    return _publicRoutes.contains(loc) ? null : RoutePaths.login;
  }

  if (_publicRoutes.contains(loc) || loc == RoutePaths.splash) {
    return RoutePaths.home;
  }

  return null;
}
