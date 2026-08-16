import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/reference_data_repository.dart';
import '../../domain/reference_data_item.dart';

/// Reference Data category constants — must match
/// `App\Enums\ReferenceDataCategory` exactly.
class ReferenceDataCategory {
  static const transferReason = 'transfer_reason';
  static const requestedService = 'requested_service';
}

/// Family-keyed by category so Reasons and Requested Services load and
/// error independently — same pattern as
/// `professional_collection_detail_providers.dart`. The endpoint returns
/// every configured value regardless of `isActive`; only active values
/// should be offered as selectable options.
final referenceDataProvider =
    FutureProvider.family<List<ReferenceDataItem>, String>(
      (ref, category) =>
          ref.watch(referenceDataRepositoryProvider).fetchCategory(category),
    );
