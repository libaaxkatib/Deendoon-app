import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mobile Fix #17: whether the app is currently locked pending a
/// successful biometric confirmation of an already-restored session.
///
/// Deliberately orthogonal to `AuthState` rather than a new state variant
/// on it — this can only ever gate *revealing* an already-valid session,
/// never grant or replace one. `AuthNotifier.restoreSession()` is the only
/// place that calls `lock()` (when a cached session was found and
/// Biometric Login is enabled); only a real biometric success
/// (`BiometricLockScreen`) or a real password login
/// (`AuthNotifier.login()`/`register()`) can call `unlock()`.
final biometricLockProvider = NotifierProvider<BiometricLockNotifier, bool>(
  BiometricLockNotifier.new,
);

class BiometricLockNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void lock() => state = true;

  void unlock() => state = false;
}
