import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/auth_repository.dart';
import '../../domain/auth_state.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository(ref));

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthInitial();

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  /// Called once by the splash screen. Optimistically restores a stored
  /// session for a zero-latency return to `/home`, then validates it in the
  /// background via `POST /refresh` (there is no `GET /me` endpoint).
  Future<void> restoreSession() async {
    state = const AuthRestoring();

    final cached = await _repository.readCachedSession();
    if (cached == null) {
      state = const Unauthenticated();
      return;
    }

    state = cached;

    try {
      state = await _repository.validateAndRotate();
    } catch (_) {
      // The Dio auth interceptor already reacted to the underlying 401 by
      // calling forceLogout() (state is already Unauthenticated) — nothing
      // further to do here.
    }
  }

  Future<void> login(String email, String password) async {
    state = const Authenticating();
    try {
      state = await _repository.login(email, password);
    } on ApiException catch (e) {
      state = AuthError(e.message);
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
    } on ApiException catch (e) {
      state = AuthError(e.message);
    }
  }

  /// Invoked both by an explicit "log out" action and by the Dio
  /// interceptor when an already-authenticated request comes back 401.
  Future<void> forceLogout() async {
    await _repository.logout();
    state = const Unauthenticated();
  }
}
