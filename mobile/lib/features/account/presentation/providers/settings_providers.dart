import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/biometrics/biometric_auth_service.dart';
import '../../../../core/storage/biometric_preference_storage.dart';
import '../../data/settings_repository.dart';
import '../../domain/system_settings.dart';

final settingsProvider = FutureProvider<SystemSettings>(
  (ref) => ref.watch(settingsRepositoryProvider).fetchSettings(),
);

/// Real device capability check (Settings §Security — Biometric Login).
final biometricSupportedProvider = FutureProvider<bool>(
  (ref) => ref.watch(biometricAuthServiceProvider).isSupported(),
);

/// The user's local choice to require biometric login, persisted on-device.
/// `setEnabled(true)` is only ever called after a real, successful
/// biometric prompt — see `BiometricLoginTile` in the Settings screen.
class BiometricEnabledNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => ref.read(biometricPreferenceStorageProvider).readEnabled();

  Future<void> setEnabled(bool enabled) async {
    state = AsyncData(enabled);
    await ref.read(biometricPreferenceStorageProvider).saveEnabled(enabled);
  }
}

final biometricEnabledProvider = AsyncNotifierProvider<BiometricEnabledNotifier, bool>(BiometricEnabledNotifier.new);
