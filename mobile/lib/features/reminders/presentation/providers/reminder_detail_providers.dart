import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/reminder_repository.dart';
import '../../domain/message_template.dart';
import '../../domain/reminder.dart';
import '../../domain/reminder_summary.dart';

final reminderDetailProvider = FutureProvider.family<Reminder, String>(
  (ref, reminderId) =>
      ref.watch(reminderRepositoryProvider).fetchReminder(reminderId),
);

final reminderSummaryProvider = FutureProvider<ReminderSummary>(
  (ref) => ref.watch(reminderRepositoryProvider).fetchSummary(),
);

/// Message templates for a given channel — independent, family-keyed so a
/// WhatsApp fetch failure doesn't affect an already-loaded SMS list (or
/// vice versa) if the user toggles channels.
final messageTemplatesProvider =
    FutureProvider.family<List<MessageTemplate>, String>(
      (ref, channel) => ref
          .watch(reminderRepositoryProvider)
          .fetchMessageTemplates(channel: channel),
    );
