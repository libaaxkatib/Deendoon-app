import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

final biometricAuthServiceProvider = Provider<BiometricAuthService>((ref) => BiometricAuthService());

/// Settings §Security — Biometric Login. Device-local only, no backend
/// involved. `isSupported()` is a real hardware/enrollment capability
/// check; enabling the toggle requires a real, successful biometric
/// prompt before the preference is persisted — never assumed to work.
///
/// Scope note: this sprint wires the capability check, the real
/// authenticate() prompt, and local persistence of the preference. It
/// does not wire enforcement at app launch (that touches the Auth/Router
/// startup flow, outside Settings' scope this sprint) — disclosed in the
/// Sprint 2 report rather than silently implied.
class BiometricAuthService {
  final LocalAuthentication _auth;
  BiometricAuthService([LocalAuthentication? auth]) : _auth = auth ?? LocalAuthentication();

  Future<bool> isSupported() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final deviceSupported = await _auth.isDeviceSupported();
      return canCheck && deviceSupported;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(biometricOnly: true),
      );
    } on PlatformException {
      return false;
    }
  }
}
