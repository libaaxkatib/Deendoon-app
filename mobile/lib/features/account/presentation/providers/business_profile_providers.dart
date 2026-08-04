import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/business_profile_repository.dart';
import '../../domain/business_profile.dart';

/// The tenant's own Business Profile — single record, not keyed by id
/// (same reasoning as `reminderSummaryProvider`: exactly one instance per
/// signed-in tenant).
final businessProfileProvider = FutureProvider<BusinessProfile>(
  (ref) => ref.watch(businessProfileRepositoryProvider).fetchBusinessProfile(),
);
