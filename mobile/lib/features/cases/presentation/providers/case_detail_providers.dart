import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/collection_case_repository.dart';
import '../../domain/case_history.dart';
import '../../domain/collection_case.dart';

/// Two independent, family-keyed providers per case id — same
/// per-component loading/error isolation pattern used throughout (Home
/// Dashboard, Debt Detail): a failure fetching history doesn't blank out
/// the already-loaded case.
final caseDetailProvider = FutureProvider.family<CollectionCase, String>(
  (ref, caseId) => ref.watch(collectionCaseRepositoryProvider).fetchCase(caseId),
);

final caseHistoryProvider = FutureProvider.family<CaseHistory, String>(
  (ref, caseId) => ref.watch(collectionCaseRepositoryProvider).fetchHistory(caseId),
);
