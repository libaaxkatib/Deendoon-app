import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../debts/domain/debt.dart';
import '../../data/analytics_repository.dart';

String _isoDate(DateTime date) => date.toIso8601String().split('T').first;

/// Collection Rate detail view (mobile Item 9) — the real debts that fed
/// the "Amount Became Due" half of `CollectionRateService::rateFor()`'s
/// formula: `GET /reports/debts?dateFrom=&dateTo=` (due-date range),
/// the exact same filter `ReportController::debtsQuery()` already applies.
/// `perPage: 100` — same one-shot-request rationale as
/// `AnalyticsApi.agingAnalysis()`, no infinite-scroll UI for a detail
/// breakdown screen.
final collectionRateDebtsProvider =
    FutureProvider.family<List<Debt>, DateTimeRange>((ref, range) async {
      final page = await ref
          .read(analyticsRepositoryProvider)
          .fetchReportDebts(
            page: 1,
            dateFrom: _isoDate(range.start),
            dateTo: _isoDate(range.end),
            perPage: 100,
          );
      return page.debts;
    });
