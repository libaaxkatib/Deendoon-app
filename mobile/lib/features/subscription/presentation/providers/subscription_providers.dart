import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/subscription_repository.dart';
import '../../domain/subscription.dart';
import '../../domain/subscription_plan.dart';
import '../../domain/subscription_storage.dart';

/// The tenant's own current Subscription — single record, not keyed by id
/// (same reasoning as `businessProfileProvider`: exactly one instance per
/// signed-in tenant). Independent from `subscriptionPlansProvider`/
/// `subscriptionStorageProvider` — same per-component loading/error
/// isolation pattern used across the app (e.g.
/// `professionalCollectionDetailProvider`/`...MessagesProvider`): a
/// failure loading Storage doesn't blank out an already-loaded
/// Subscription, and vice versa.
final subscriptionProvider = FutureProvider<Subscription>(
  (ref) => ref.watch(subscriptionRepositoryProvider).fetchSubscription(),
);

/// The catalog of active Subscription Plans — same for every tenant,
/// independent of the tenant's own current subscription.
final subscriptionPlansProvider = FutureProvider<List<SubscriptionPlan>>(
  (ref) => ref.watch(subscriptionRepositoryProvider).fetchPlans(),
);

/// The tenant's own current storage usage/limit/purchased add-ons.
final subscriptionStorageProvider = FutureProvider<SubscriptionStorage>(
  (ref) => ref.watch(subscriptionRepositoryProvider).fetchStorage(),
);

/// Manual Mobile-Money Subscription Payment Flow (Product Owner decision):
/// the platform's destination mobile-money number, shown on the "Send
/// Money" step. Null until a Platform Administrator has set one.
final subscriptionPaymentInfoProvider = FutureProvider<String?>(
  (ref) => ref.watch(subscriptionRepositoryProvider).fetchPaymentInfo(),
);
