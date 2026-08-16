import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/providers/biometric_lock_provider.dart';

/// Bridges Riverpod's `authProvider` (and, since Mobile Fix #17,
/// `biometricLockProvider`) to go_router's `refreshListenable`, so a
/// mid-session forced logout (fired from anywhere, e.g. the Dio interceptor)
/// or a biometric lock/unlock re-runs the router's redirect without any
/// widget needing to call `context.go()` directly.
final routerRefreshProvider = ChangeNotifierProvider<RouterRefreshNotifier>((
  ref,
) {
  return RouterRefreshNotifier(ref);
});

class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(Ref ref) {
    ref.listen(authProvider, (_, _) => notifyListeners());
    ref.listen(biometricLockProvider, (_, _) => notifyListeners());
  }
}
