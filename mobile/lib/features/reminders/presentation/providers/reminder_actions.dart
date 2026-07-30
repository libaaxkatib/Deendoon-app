import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/reminder_repository.dart';
import '../../domain/reminder.dart';
import '../../../../core/models/sent_message.dart';
import 'reminder_detail_providers.dart';
import 'reminder_list_provider.dart';

final reminderActionsProvider = Provider<ReminderActions>((ref) => ReminderActions(ref));

/// The real, backend-supported Reminder actions: create, update (also
/// backs Reschedule — same real `PUT` endpoint, see
/// `reminder_schedule_screen.dart`), delete, complete, and send. There is
/// no cancel and no retry endpoint anywhere in `ReminderCenterController`
/// or `routes/api.php` — confirmed by a full read of both — so neither is
/// implemented here (see the Sprint 14 summary's "Missing Backend Support
/// Required").
class ReminderActions {
  final Ref _ref;

  const ReminderActions(this._ref);

  ReminderRepository get _repository => _ref.read(reminderRepositoryProvider);

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
    final reminder = await _repository.createReminder(
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
    );
    _ref.invalidate(reminderListProvider);
    _ref.invalidate(reminderSummaryProvider);
    return reminder;
  }

  Future<Reminder> update({
    required String id,
    String? dueDate,
    String? amountDue,
    String? timingRule,
    String? customFireAt,
    List<String>? deliveryMethods,
    String? notes,
  }) async {
    final reminder = await _repository.updateReminder(
      id: id,
      dueDate: dueDate,
      amountDue: amountDue,
      timingRule: timingRule,
      customFireAt: customFireAt,
      deliveryMethods: deliveryMethods,
      notes: notes,
    );
    _ref.invalidate(reminderDetailProvider(id));
    _ref.invalidate(reminderListProvider);
    _ref.invalidate(reminderSummaryProvider);
    return reminder;
  }

  Future<Reminder> complete(String id) async {
    final reminder = await _repository.completeReminder(id);
    _ref.invalidate(reminderDetailProvider(id));
    _ref.read(reminderListProvider.notifier).replaceReminder(reminder);
    _ref.invalidate(reminderSummaryProvider);
    return reminder;
  }

  Future<void> delete(String id) async {
    await _repository.deleteReminder(id);
    _ref.invalidate(reminderDetailProvider(id));
    _ref.read(reminderListProvider.notifier).removeReminder(id);
    _ref.invalidate(reminderSummaryProvider);
  }

  Future<SentMessage> send({required String id, required String channel, required String templateId}) async {
    final sentMessage = await _repository.sendReminder(id: id, channel: channel, templateId: templateId);
    // `send` never mutates the reminder itself (no `completed_at`/status
    // change) — no invalidation needed beyond returning the result for
    // the caller to display.
    return sentMessage;
  }
}
