import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/storage/biometric_preference_storage.dart';
import '../../data/auth_repository.dart';
import '../../domain/auth_state.dart';
import '../../domain/google_login_result.dart';
import 'biometric_lock_provider.dart';
import 'tenant_scoped_providers.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref),
);

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthInitial();

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  BiometricPreferenceStorage get _biometricPreferenceStorage =>
      ref.read(biometricPreferenceStorageProvider);

  /// Called once by the splash screen. Optimistically restores a stored
  /// session for a zero-latency return to `/home`, then validates it in the
  /// background via `POST /refresh` (there is no `GET /me` endpoint).
  ///
  /// Mobile Fix #17: a restored (not freshly logged-in) session locks
  /// behind the biometric prompt when the device-local preference is
  /// enabled — enabling the toggle only takes effect from the *next*
  /// restore, never retroactively locks the session already in progress.
  Future<void> restoreSession() async {
    state = const AuthRestoring();

    final cached = await _repository.readCachedSession();
    if (cached == null) {
      state = const Unauthenticated();
      return;
    }

    state = cached;

    if (await _biometricPreferenceStorage.readEnabled()) {
      ref.read(biometricLockProvider.notifier).lock();
    }

    try {
      state = await _repository.validateAndRotate();
    } catch (_) {
      // The Dio auth interceptor already reacted to the underlying 401 by
      // calling forceLogout() (state is already Unauthenticated) — nothing
      // further to do here.
    }
  }

  /// Mobile Fix #17: a successful password login always unlocks any
  /// pending biometric lock — this is also how the lock screen's "Use
  /// Password Instead" fallback resolves, since it just navigates to this
  /// same real login flow rather than a separate credential path.
  Future<void> login(String email, String password) async {
    state = const Authenticating();
    try {
      state = await _repository.login(email, password);
      resetTenantScopedProviders(ref);
      ref.read(biometricLockProvider.notifier).unlock();
    } on ApiException catch (e) {
      state = AuthError(e.detailedMessage, fieldErrors: e.fieldErrors);
    }
  }

  Future<void> register({
    required String businessName,
    required String name,
    required String phone,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    state = const Authenticating();
    try {
      state = await _repository.register(
        businessName: businessName,
        name: name,
        phone: phone,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      resetTenantScopedProviders(ref);
      ref.read(biometricLockProvider.notifier).unlock();
    } on ApiException catch (e) {
      state = AuthError(e.detailedMessage, fieldErrors: e.fieldErrors);
    }
  }

  /// Mobile Fix #22 — Google Login. Deliberately returns the outcome
  /// instead of encoding it into `AuthState` — no new `AuthState` variant
  /// is added. An existing-account result behaves exactly like [login];
  /// a registration-required result leaves `state` at `Unauthenticated`
  /// so the caller can navigate to the business-name-collection screen
  /// without a stray `AuthError` flash. A genuine failure (invalid token,
  /// email already tied to a password account) is a real `ApiException`
  /// and is rethrown for the caller to handle — it is not folded into
  /// this method's own result type.
  Future<GoogleLoginResult> googleLogin(String idToken) async {
    state = const Authenticating();
    try {
      final result = await _repository.googleLogin(idToken);
      if (result is GoogleLoginAuthenticated) {
        state = Authenticated(user: result.user, token: result.token);
        resetTenantScopedProviders(ref);
        ref.read(biometricLockProvider.notifier).unlock();
      } else {
        state = const Unauthenticated();
      }
      return result;
    } catch (_) {
      state = const Unauthenticated();
      rethrow;
    }
  }

  /// Mobile Fix #22 — Google Login. Completes registration for a Google
  /// identity [googleLogin] reported as new — same shape as [register],
  /// including how an [ApiException] (e.g. the identity was registered by
  /// a concurrent request) becomes an [AuthError] rather than propagating.
  Future<void> completeGoogleRegistration({
    required String idToken,
    required String businessName,
    String? phone,
  }) async {
    state = const Authenticating();
    try {
      state = await _repository.googleRegister(
        idToken: idToken,
        businessName: businessName,
        phone: phone,
      );
      resetTenantScopedProviders(ref);
      ref.read(biometricLockProvider.notifier).unlock();
    } on ApiException catch (e) {
      state = AuthError(e.detailedMessage, fieldErrors: e.fieldErrors);
    }
  }

  /// Clears a stale [AuthError] before re-validating and resubmitting the
  /// Login/Register form, so a per-field backend error from a previous
  /// attempt can't keep blocking the form's own client-side re-validation
  /// after the user has actually fixed the value (Mobile Fix #10).
  void clearError() {
    if (state is AuthError) state = const Unauthenticated();
  }

  /// Invoked both by an explicit "log out" action and by the Dio
  /// interceptor when an already-authenticated request comes back 401.
  ///
  /// Mobile Fix #17: also clears the device-local biometric preference —
  /// it's an unscoped `SharedPreferences` boolean, not tied to any
  /// user/tenant id, so leaving it set would silently require biometric
  /// login from whichever account signs in next on this device, even
  /// though that account never opted in.
  Future<void> forceLogout() async {
    await _repository.logout();
    state = const Unauthenticated();
    resetTenantScopedProviders(ref);
    await _biometricPreferenceStorage.saveEnabled(false);
  }

  /// Self-service Close Account. Rethrows `ApiException` on failure (e.g.
  /// a wrong password) so the confirmation screen can show the real error
  /// and let the user retry — unlike `forceLogout()`, this must not
  /// silently succeed from the caller's point of view. Only transitions
  /// to `Unauthenticated` once the server call has actually succeeded.
  Future<void> closeAccount(String password) async {
    await _repository.closeAccount(password: password);
    state = const Unauthenticated();
    resetTenantScopedProviders(ref);
    await _biometricPreferenceStorage.saveEnabled(false);
  }
}
