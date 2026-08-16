import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/professional_collection_repository.dart';
import '../../domain/professional_collection_summary.dart';

/// Home Dashboard's Professional Collection summary card —
/// `GET /professional-requests/summary`. Independent from the Dashboard's
/// own 4 providers (`dashboard_providers.dart`) — same per-component
/// loading/error isolation rationale.
final professionalCollectionSummaryProvider =
    FutureProvider<ProfessionalCollectionSummary>(
      (ref) =>
          ref.watch(professionalCollectionRepositoryProvider).fetchSummary(),
    );
