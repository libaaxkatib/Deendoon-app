// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settingsTitle => 'Settings';

  @override
  String get sectionGeneral => 'General';

  @override
  String get sectionNotifications => 'Notifications';

  @override
  String get sectionSecurity => 'Security';

  @override
  String get sectionBusiness => 'Business';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSomali => 'Somali';

  @override
  String get pushNotifications => 'Push Notifications';

  @override
  String get reminderNotifications => 'Reminder Notifications';

  @override
  String get paymentNotifications => 'Payment Notifications';

  @override
  String get notificationsDisclosure => 'Saved to your business preferences.';

  @override
  String get changePassword => 'Change Password';

  @override
  String get biometricLogin => 'Biometric Login';

  @override
  String get biometricNotSupported => 'Not supported on this device';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get defaultCreditLimit => 'Default Credit Limit';

  @override
  String get creditLimitReminderEnabled => 'Credit Limit Reminder';

  @override
  String get softLimitWarningThreshold => 'Soft Limit Warning Threshold (%)';

  @override
  String get whatsappReminderDays => 'WhatsApp Reminder Days';

  @override
  String get smsReminderDays => 'SMS Reminder Days';

  @override
  String get callReminderDays => 'Call Reminder Days';

  @override
  String get reminderDaysHint => 'Comma-separated days, e.g. 1, 3, 7';

  @override
  String get professionalCollectionThresholdDays =>
      'Professional Collection Threshold (Days)';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get settingsSavedSuccessfully => 'Settings updated successfully';

  @override
  String get couldNotLoadSettings => 'Could not load Settings.';

  @override
  String get retry => 'Retry';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get enterValidNumber => 'Enter a valid number';

  @override
  String get enterValueBetween0And100 => 'Enter a value between 0 and 100';
}
