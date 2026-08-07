import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/biometrics/biometric_auth_service.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/retry_section.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../data/settings_repository.dart';
import '../../domain/system_settings.dart';
import '../providers/settings_providers.dart';

/// Settings (Sprint 2). §General (Language) is fully local — persisted via
/// `LocaleStorage`, no backend involved. §Notifications and §Business are
/// real, wired to `GET/PUT /admin/settings/preferences` (FR-069) via
/// `SettingsRepository`. §Security's Change Password reuses the existing
/// `/account/change-password` route; Biometric Login is a real device
/// capability check + real biometric prompt, persisted locally only (see
/// `BiometricAuthService`'s doc comment for the app-launch-enforcement
/// scope boundary). Default Currency/Default Date Format are intentionally
/// absent: BC-005 fixes V1 to a single currency per tenant (not
/// configurable) and no configurable date-format requirement exists
/// anywhere in the approved SRS — see FR-069's exhaustive preference list.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _creditLimitController = TextEditingController();
  final _softLimitController = TextEditingController();
  final _whatsappDaysController = TextEditingController();
  final _smsDaysController = TextEditingController();
  final _callDaysController = TextEditingController();
  final _thresholdDaysController = TextEditingController();

  bool _prefilled = false;
  bool _creditLimitReminderEnabled = true;
  bool _pushEnabled = false;
  bool _reminderEnabled = false;
  bool _paymentEnabled = false;
  bool _isSaving = false;
  String? _error;
  String? _successMessage;

  @override
  void dispose() {
    _creditLimitController.dispose();
    _softLimitController.dispose();
    _whatsappDaysController.dispose();
    _smsDaysController.dispose();
    _callDaysController.dispose();
    _thresholdDaysController.dispose();
    super.dispose();
  }

  void _prefillFromExisting(SystemSettings settings) {
    if (_prefilled) return;
    _prefilled = true;
    _creditLimitController.text = settings.defaultCreditLimit;
    _creditLimitReminderEnabled = settings.creditLimitReminderEnabled;
    _softLimitController.text = settings.softLimitWarningThreshold ?? '';
    _whatsappDaysController.text = settings.whatsappReminderDays.join(', ');
    _smsDaysController.text = settings.smsReminderDays.join(', ');
    _callDaysController.text = settings.callReminderDays.join(', ');
    _thresholdDaysController.text = settings.professionalCollectionThresholdDays?.toString() ?? '';
    _pushEnabled = settings.pushNotificationsEnabled;
    _reminderEnabled = settings.reminderNotificationsEnabled;
    _paymentEnabled = settings.paymentNotificationsEnabled;
  }

  /// Returns null on success, or a validation error message.
  (List<int>?, String?) _parseDays(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return (const [], null);

    final days = <int>[];
    for (final token in trimmed.split(',')) {
      final value = int.tryParse(token.trim());
      if (value == null || value < 1 || value > 365) {
        return (null, AppLocalizations.of(context).enterValidNumber);
      }
      days.add(value);
    }
    return (days, null);
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) return;

    final l10n = AppLocalizations.of(context);
    final (whatsappDays, whatsappError) = _parseDays(_whatsappDaysController.text);
    final (smsDays, smsError) = _parseDays(_smsDaysController.text);
    final (callDays, callError) = _parseDays(_callDaysController.text);
    final daysError = whatsappError ?? smsError ?? callError;
    if (daysError != null) {
      setState(() => _error = daysError);
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
      _successMessage = null;
    });

    try {
      final softLimitText = _softLimitController.text.trim();
      final thresholdText = _thresholdDaysController.text.trim();

      await ref.read(settingsRepositoryProvider).updateSettings(
            defaultCreditLimit: _creditLimitController.text.trim(),
            creditLimitReminderEnabled: _creditLimitReminderEnabled,
            softLimitWarningThreshold: softLimitText.isEmpty ? null : softLimitText,
            whatsappReminderDays: whatsappDays!,
            smsReminderDays: smsDays!,
            callReminderDays: callDays!,
            professionalCollectionThresholdDays: thresholdText.isEmpty ? null : int.tryParse(thresholdText),
            pushNotificationsEnabled: _pushEnabled,
            reminderNotificationsEnabled: _reminderEnabled,
            paymentNotificationsEnabled: _paymentEnabled,
          );

      ref.invalidate(settingsProvider);
      if (!mounted) return;
      setState(() => _successMessage = l10n.settingsSavedSuccessfully);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionHeader(title: l10n.sectionGeneral),
          const SizedBox(height: 8),
          const _LanguageCard(),
          const SizedBox(height: 24),
          SectionHeader(title: l10n.sectionSecurity),
          const SizedBox(height: 8),
          AppCard(
            onTap: () => context.push('/account/change-password'),
            child: Row(
              children: [
                Expanded(child: Text(l10n.changePassword, style: AppTypography.body)),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const _BiometricLoginTile(),
          const SizedBox(height: 24),
          settingsAsync.when(
            loading: () => const SectionLoading(),
            error: (error, _) => Center(
              child: RetrySection(
                message: l10n.couldNotLoadSettings,
                onRetry: () => ref.invalidate(settingsProvider),
              ),
            ),
            data: (settings) {
              _prefillFromExisting(settings);
              return Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionHeader(title: l10n.sectionNotifications),
                    const SizedBox(height: 8),
                    AppCard(
                      child: Column(
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(l10n.pushNotifications, style: AppTypography.body),
                            value: _pushEnabled,
                            onChanged: (value) => setState(() => _pushEnabled = value),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(l10n.reminderNotifications, style: AppTypography.body),
                            value: _reminderEnabled,
                            onChanged: (value) => setState(() => _reminderEnabled = value),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(l10n.paymentNotifications, style: AppTypography.body),
                            value: _paymentEnabled,
                            onChanged: (value) => setState(() => _paymentEnabled = value),
                          ),
                          const SizedBox(height: 4),
                          Text(l10n.notificationsDisclosure, style: AppTypography.caption),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SectionHeader(title: l10n.sectionBusiness),
                    const SizedBox(height: 8),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _creditLimitController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(labelText: l10n.defaultCreditLimit),
                            validator: (value) {
                              final trimmed = value?.trim() ?? '';
                              if (trimmed.isEmpty) return l10n.fieldRequired;
                              final parsed = double.tryParse(trimmed);
                              if (parsed == null || parsed < 0 || parsed > 9999999999.99) {
                                return l10n.enterValidNumber;
                              }
                              return null;
                            },
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(l10n.creditLimitReminderEnabled, style: AppTypography.body),
                            value: _creditLimitReminderEnabled,
                            onChanged: (value) => setState(() => _creditLimitReminderEnabled = value),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _softLimitController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(labelText: l10n.softLimitWarningThreshold),
                            validator: (value) {
                              final trimmed = value?.trim() ?? '';
                              if (trimmed.isEmpty) return null;
                              final parsed = double.tryParse(trimmed);
                              if (parsed == null || parsed < 0 || parsed > 100) {
                                return l10n.enterValueBetween0And100;
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _whatsappDaysController,
                            decoration: InputDecoration(
                              labelText: l10n.whatsappReminderDays,
                              hintText: l10n.reminderDaysHint,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _smsDaysController,
                            decoration: InputDecoration(
                              labelText: l10n.smsReminderDays,
                              hintText: l10n.reminderDaysHint,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _callDaysController,
                            decoration: InputDecoration(
                              labelText: l10n.callReminderDays,
                              hintText: l10n.reminderDaysHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppCard(
                      child: TextFormField(
                        controller: _thresholdDaysController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: l10n.professionalCollectionThresholdDays),
                        validator: (value) {
                          final trimmed = value?.trim() ?? '';
                          if (trimmed.isEmpty) return null;
                          final parsed = int.tryParse(trimmed);
                          if (parsed == null || parsed < 1 || parsed > 365) return l10n.enterValidNumber;
                          return null;
                        },
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ],
                    if (_successMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(_successMessage!, style: const TextStyle(color: Colors.green)),
                    ],
                    const SizedBox(height: 24),
                    PrimaryButton(label: l10n.saveChanges, isLoading: _isSaving, onPressed: _save),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LanguageCard extends ConsumerWidget {
  const _LanguageCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);

    return AppCard(
      child: Row(
        children: [
          Expanded(child: Text(l10n.language, style: AppTypography.body)),
          DropdownButton<String>(
            value: locale.languageCode,
            underline: const SizedBox.shrink(),
            items: [
              DropdownMenuItem(value: 'en', child: Text(l10n.languageEnglish)),
              DropdownMenuItem(value: 'so', child: Text(l10n.languageSomali)),
            ],
            onChanged: (languageCode) {
              if (languageCode != null) {
                ref.read(localeProvider.notifier).setLanguageCode(languageCode);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _BiometricLoginTile extends ConsumerWidget {
  const _BiometricLoginTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final supportedAsync = ref.watch(biometricSupportedProvider);

    return supportedAsync.when(
      loading: () => const AppCard(child: SizedBox(height: 24, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))),
      error: (_, _) => _unsupportedCard(l10n),
      data: (supported) {
        if (!supported) return _unsupportedCard(l10n);

        final enabledAsync = ref.watch(biometricEnabledProvider);
        return AppCard(
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.biometricLogin, style: AppTypography.body),
            value: enabledAsync.value ?? false,
            onChanged: enabledAsync.isLoading
                ? null
                : (value) async {
                    if (!value) {
                      await ref.read(biometricEnabledProvider.notifier).setEnabled(false);
                      return;
                    }
                    final authenticated = await ref
                        .read(biometricAuthServiceProvider)
                        .authenticate(l10n.biometricLogin);
                    if (authenticated) {
                      await ref.read(biometricEnabledProvider.notifier).setEnabled(true);
                    }
                  },
          ),
        );
      },
    );
  }

  Widget _unsupportedCard(AppLocalizations l10n) {
    return AppCard(
      child: Row(
        children: [
          Expanded(child: Text(l10n.biometricLogin, style: AppTypography.body)),
          Text(l10n.comingSoon, style: AppTypography.caption),
        ],
      ),
    );
  }
}
