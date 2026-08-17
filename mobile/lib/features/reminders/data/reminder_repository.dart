import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../domain/message_template.dart';
import '../domain/reminder.dart';
import '../domain/reminder_page.dart';
import '../domain/reminder_summary.dart';
import '../../../core/models/sent_message.dart';
import 'reminder_api.dart';

final reminderRepositoryProvider = Provider<ReminderRepository>(
  (ref) => ReminderRepository(ref.read(reminderApiProvider)),
);

/// Translates raw Dio failures into `ApiException` — same pattern as
/// every other repository in the app. No caching, no business logic.
class ReminderRepository {
  final ReminderApi _api;

  const ReminderRepository(this._api);

  Future<ReminderSummary> fetchSummary() => _guard(() => _api.summary());

  Future<ReminderPage> fetchReminders({required int page, String? tab}) =>
      _guard(() => _api.list(page: page, tab: tab));

  Future<Reminder> fetchReminder(String id) => _guard(() => _api.show(id));

  Future<Reminder> createReminder({
    required String type,
    required String relatedEntityType,
    required String relatedEntityId,
    String? relatedCaseId,
    required String dueDate,
    String? amountDue,
    required String timingRule,
    String? customFireAt,
    required List<String> deliveryMethods,
    String? notes,
  }) => _guard(
    () => _api.create(
      type: type,
      relatedEntityType: relatedEntityType,
      relatedEntityId: relatedEntityId,
      relatedCaseId: relatedCaseId,
      dueDate: dueDate,
      amountDue: amountDue,
      timingRule: timingRule,
      customFireAt: customFireAt,
      deliveryMethods: deliveryMethods,
      notes: notes,
    ),
  );

  Future<Reminder> updateReminder({
    required String id,
    String? type,
    String? relatedEntityType,
    String? relatedEntityId,
    String? relatedCaseId,
    String? dueDate,
    String? amountDue,
    String? timingRule,
    String? customFireAt,
    List<String>? deliveryMethods,
    String? notes,
  }) => _guard(
    () => _api.update(
      id: id,
      type: type,
      relatedEntityType: relatedEntityType,
      relatedEntityId: relatedEntityId,
      relatedCaseId: relatedCaseId,
      dueDate: dueDate,
      amountDue: amountDue,
      timingRule: timingRule,
      customFireAt: customFireAt,
      deliveryMethods: deliveryMethods,
      notes: notes,
    ),
  );

  Future<void> deleteReminder(String id) => _guard(() => _api.delete(id));

  Future<Reminder> completeReminder(String id) =>
      _guard(() => _api.complete(id));

  Future<Reminder> checkInReminder(String id) => _guard(() => _api.checkIn(id));

  Future<SentMessage> sendReminder({
    required String id,
    required String channel,
    required String templateId,
  }) =>
      _guard(() => _api.send(id: id, channel: channel, templateId: templateId));

  Future<List<MessageTemplate>> fetchMessageTemplates({String? channel}) =>
      _guard(() => _api.messageTemplates(channel: channel));

  Future<Map<String, dynamic>> renderMessage({
    required String templateId,
    required String reminderId,
    String? phoneNumberId,
  }) => _guard(
    () => _api.renderMessage(
      templateId: templateId,
      reminderId: reminderId,
      phoneNumberId: phoneNumberId,
    ),
  );

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
