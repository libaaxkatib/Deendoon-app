import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../core/biometrics/biometric_auth_service.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/retry_section.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/biometric_lock_provider.dart';

/// Mobile Fix #17: shown instead of the authenticated app shell whenever
/// `biometricLockProvider` is `true` (an already-restored session with
/// Biometric Login enabled). Prompts automatically on entry; a failed or
/// cancelled attempt stays locked with a visible Retry and a "Use Password
/// Instead" fallback that reuses the real login flow — this screen never
/// unlocks itself except via a genuine biometric success, and never signs
/// the user out on failure/cancellation.
class BiometricLockScreen extends ConsumerStatefulWidget {
  const BiometricLockScreen({super.key});

  @override
  ConsumerState<BiometricLockScreen> createState() =>
      _BiometricLockScreenState();
}

class _BiometricLockScreenState extends ConsumerState<BiometricLockScreen> {
  bool _authenticating = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }

  Future<void> _authenticate() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _authenticating = true;
      _failed = false;
    });

    final authenticated = await ref
        .read(biometricAuthServiceProvider)
        .authenticate(l10n.biometricLockPromptReason);

    if (!mounted) return;
    if (authenticated) {
      ref.read(biometricLockProvider.notifier).unlock();
      return;
    }
    setState(() {
      _authenticating = false;
      _failed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.fingerprint, size: 64),
                const SizedBox(height: 16),
                Text(
                  l10n.biometricLockTitle,
                  style: AppTypography.heading,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (_authenticating)
                  const Center(child: CircularProgressIndicator())
                else if (_failed) ...[
                  RetrySection(
                    message: l10n.biometricLockFailedMessage,
                    onRetry: _authenticate,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => context.go(RoutePaths.login),
                    child: Text(l10n.usePasswordInstead),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
