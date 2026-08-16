/// Mirrors `App\Http\Resources\SystemSettingResource` exactly — the real
/// field shape returned by `GET/PUT /admin/settings/preferences` (FR-069).
/// Same `admin-only` Gate as Business Profile, reachable by the Business
/// Owner under the current one-account-per-tenant model.
///
/// `whatsappReminderDays`/`smsReminderDays`/`callReminderDays` are three
/// separate per-channel day-offset lists on the backend — there is no
/// single unified "default reminder days" field, so this model exposes
/// the real per-channel shape rather than inventing one that doesn't
/// match the schema.
///
/// `notificationSettings` is a structurally-flexible JSON column with no
/// backend-approved key shape (per `UpdateSystemPreferencesRequest`'s own
/// doc comment) and, per `SystemSetting`'s model doc comment, currently
/// has no consumer anywhere in the backend — toggles built on it persist
/// a real preference but do not yet gate any actual notification
/// delivery. See the Sprint 2 report for the full disclosure.
class SystemSettings {
  final String id;
  final String defaultCreditLimit;
  final bool creditLimitReminderEnabled;
  final String? softLimitWarningThreshold;
  final List<int> whatsappReminderDays;
  final List<int> smsReminderDays;
  final List<int> callReminderDays;
  final int? professionalCollectionThresholdDays;
  final bool pushNotificationsEnabled;
  final bool reminderNotificationsEnabled;
  final bool paymentNotificationsEnabled;

  const SystemSettings({
    required this.id,
    required this.defaultCreditLimit,
    required this.creditLimitReminderEnabled,
    required this.softLimitWarningThreshold,
    required this.whatsappReminderDays,
    required this.smsReminderDays,
    required this.callReminderDays,
    required this.professionalCollectionThresholdDays,
    required this.pushNotificationsEnabled,
    required this.reminderNotificationsEnabled,
    required this.paymentNotificationsEnabled,
  });

  factory SystemSettings.fromJson(Map<String, dynamic> json) {
    final notificationSettings =
        json['notification_settings'] as Map<String, dynamic>?;

    return SystemSettings(
      id: json['id'].toString(),
      defaultCreditLimit: json['default_credit_limit'].toString(),
      creditLimitReminderEnabled: json['credit_limit_reminder_enabled'] as bool,
      softLimitWarningThreshold: json['soft_limit_warning_threshold']
          ?.toString(),
      whatsappReminderDays: _intList(json['whatsapp_reminder_days']),
      smsReminderDays: _intList(json['sms_reminder_days']),
      callReminderDays: _intList(json['call_reminder_days']),
      professionalCollectionThresholdDays:
          (json['professional_collection_threshold_days'] as num?)?.toInt(),
      pushNotificationsEnabled:
          notificationSettings?['push_enabled'] as bool? ?? false,
      reminderNotificationsEnabled:
          notificationSettings?['reminder_enabled'] as bool? ?? false,
      paymentNotificationsEnabled:
          notificationSettings?['payment_enabled'] as bool? ?? false,
    );
  }

  static List<int> _intList(dynamic value) {
    if (value is! List) return const [];
    return value.map((e) => (e as num).toInt()).toList();
  }
}
