import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../domain/message_template.dart';
import '../domain/reminder.dart';
import '../domain/reminder_page.dart';
import '../domain/reminder_summary.dart';
import '../../../core/models/sent_message.dart';

final reminderApiProvider = Provider<ReminderApi>(
  (ref) => ReminderApi(ref.read(dioProvider)),
);

/// Thin wrapper around `GET/POST/PUT/PATCH/DELETE /reminders*` and the
/// message-template/render endpoints it depends on for Send — mirrors
/// `App\Http\Controllers\ReminderCenterController` and the relevant parts
/// of `MessageController` exactly.
///
/// `GET /reminders` supports exactly one filter, `tab`
/// (all/today/upcoming/overdue/completed) — there is no `status`,
/// `customer_id`, `debt_id`, `case_id`, `reminder_type`,
/// `delivery_channel`, date-range, or `search` parameter anywhere on this
/// endpoint (see the Sprint 14 summary's "Missing Backend Support
/// Required"). There is no cancel and no retry endpoint — only
/// `complete`, `destroy`, and `send` mutate a reminder beyond plain
/// create/update.
class ReminderApi {
  final Dio _dio;

  const ReminderApi(this._dio);

  Future<ReminderSummary> summary() async {
    final response = await _dio.get('reminders/summary');
    return ReminderSummary.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<ReminderPage> list({required int page, String? tab}) async {
    final response = await _dio.get(
      'reminders',
      queryParameters: {'page': page, 'tab': ?tab},
    );
    return ReminderPage.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<Reminder> show(String id) async {
    final response = await _dio.get('reminders/$id');
    return Reminder.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// `StoreReminderRequest` — the exact real field set, nothing invented:
  /// type, related_entity_type, related_entity_id, related_case_id
  /// (optional), due_date, amount_due (optional), timing_rule,
  /// custom_fire_at (required only if timing_rule is 'custom'),
  /// delivery_methods (non-empty), notes (optional).
  Future<Reminder> create({
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
  }) async {
    final response = await _dio.post(
      'reminders',
      data: {
        'type': type,
        'related_entity_type': relatedEntityType,
        'related_entity_id': relatedEntityId,
        'related_case_id': ?relatedCaseId,
        'due_date': dueDate,
        'amount_due': ?amountDue,
        'timing_rule': timingRule,
        'custom_fire_at': ?customFireAt,
        'delivery_methods': deliveryMethods,
        'notes': ?notes,
      },
    );
    return Reminder.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// `UpdateReminderRequest` — identical field set, all `sometimes`; an
  /// omitted field is left unchanged server-side. Used for both plain
  /// Edit and Reschedule (Mobile_UI_V1_Frozen.md §7.5 — one screen, two
  /// entry points, same real `PUT` endpoint).
  Future<Reminder> update({
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
  }) async {
    final response = await _dio.put(
      'reminders/$id',
      data: {
        'type': ?type,
        'related_entity_type': ?relatedEntityType,
        'related_entity_id': ?relatedEntityId,
        'related_case_id': ?relatedCaseId,
        'due_date': ?dueDate,
        'amount_due': ?amountDue,
        'timing_rule': ?timingRule,
        'custom_fire_at': ?customFireAt,
        'delivery_methods': ?deliveryMethods,
        'notes': ?notes,
      },
    );
    return Reminder.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _dio.delete('reminders/$id');
  }

  Future<Reminder> complete(String id) async {
    final response = await _dio.patch('reminders/$id/complete');
    return Reminder.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<Reminder> checkIn(String id) async {
    final response = await _dio.patch('reminders/$id/check-in');
    return Reminder.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<SentMessage> send({
    required String id,
    required String channel,
    required String templateId,
  }) async {
    final response = await _dio.post(
      'reminders/$id/send',
      data: {'channel': channel, 'template_id': templateId},
    );
    return SentMessage.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<List<MessageTemplate>> messageTemplates({String? channel}) async {
    final response = await _dio.get(
      'message-templates',
      queryParameters: {'channel': ?channel},
    );
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((e) => MessageTemplate.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `POST /messages/render` — read-only preview, does not send anything.
  /// Returns `{rendered_text, recipient_name, recipient_phone}`; the
  /// backend resolves the customer server-side regardless of the
  /// reminder's `related_entity_type` (`MessageRenderingService::
  /// resolveCustomer()`), so this is the most reliable source for the
  /// Message Preview screen's recipient row — more reliable than the
  /// client re-deriving it from `related_entity_type`/`related_entity_id`.
  Future<Map<String, dynamic>> renderMessage({
    required String templateId,
    required String reminderId,
    String? phoneNumberId,
  }) async {
    final response = await _dio.post(
      'messages/render',
      data: {
        'template_id': templateId,
        'reminder_id': reminderId,
        'phone_number_id': ?phoneNumberId,
      },
    );
    return response.data['data'] as Map<String, dynamic>;
  }
}
