import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../debts/domain/debt.dart';
import '../../data/analytics_repository.dart';

String _isoDate(DateTime date) => date.toIso8601String().split('T').first;

/// Average Days detail view (mobile Item 10) — the real debts that fed
/// `ReportingService::averageDaysToPay()`'s calculation:
/// `GET /reports/debts?paidDateFrom=&paidDateTo=`, backed by
/// `ReportingService::debtsPaidWithin()` — the exact same population the
/// backend calculation itself uses (fully paid, with their last payment
/// falling inside the range), not a due-date approximation of it.
/// `perPage: 100` — same one-shot-request rationale as
/// `AnalyticsApi.agingAnalysis()`, no infinite-scroll UI for a detail
/// breakdown screen.
final averageDaysDebtsProvider =
    FutureProvider.family<List<Debt>, DateTimeRange>((ref, range) async {
      final page = await ref
          .read(analyticsRepositoryProvider)
          .fetchReportDebts(
            page: 1,
            paidDateFrom: _isoDate(range.start),
            paidDateTo: _isoDate(range.end),
            perPage: 100,
          );
      return page.debts;
    });
