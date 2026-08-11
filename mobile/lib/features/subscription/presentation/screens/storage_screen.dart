import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/deendoon_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/retry_section.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/storage_addon.dart';
import '../../domain/subscription_storage.dart';
import '../providers/subscription_actions.dart';
import '../providers/subscription_providers.dart';
import '../widgets/request_storage_addon_sheet.dart';

/// The only 4 valid `storage_package` values — mirrors
/// `StorageAddonRequestRequest`'s closed validation enum exactly (same
/// "hardcode the backend's own closed enum, since there's no discovery
/// endpoint for it" precedent as `_statusFilters` in
/// `professional_collection_list_screen.dart`). Deliberately NOT paired
/// with a price or GB figure here: `StorageAddonService::PACKAGES` (the
/// sole source of `storage_size`/`monthly_price`) is server-private and
/// never serialized to the client before a request is submitted — the
/// backend only returns those numbers on the *created* request. Showing an
/// invented price here would duplicate business logic this app must never
/// own.
const _storagePackages = <String>['10gb', '25gb', '50gb', '100gb'];

String _packageLabel(String storagePackage) => storagePackage.toUpperCase();

/// Business Owner Storage — usage/allowance overview
/// (`GET /subscription/storage` + the plan's own base allowance from
/// `GET /subscription`), the real active Storage Add-ons, and the real
/// Storage Add-on Request flow (`POST /subscription/storage-addon-request`
/// + `POST /subscription/storage-addon-requests/{id}/cancel`).
///
/// A just-submitted pending request is held in local screen state only —
/// there is no Business-Owner-facing endpoint that lists pending Storage
/// Add-on requests (`purchased_addons` is active-only), so Cancel is only
/// ever offered for a request created in this session. Leaving and
/// re-opening this screen loses that local state, matching what the
/// backend actually exposes rather than fabricating a reconstructed
/// pending request.
class StorageScreen extends ConsumerStatefulWidget {
  const StorageScreen({super.key});

  @override
  ConsumerState<StorageScreen> createState() => _StorageScreenState();
}

class _StorageScreenState extends ConsumerState<StorageScreen> {
  String? _selectedPackage;
  StorageAddon? _pendingAddon;

  void _onPackageSelected(String storagePackage) {
    setState(() => _selectedPackage = _selectedPackage == storagePackage ? null : storagePackage);
  }

  /// Opens the real request sheet. On genuine success (the sheet only pops
  /// with a real `StorageAddon` after `SubscriptionActions.
  /// requestStorageAddon` actually succeeds), holds that add-on locally so
  /// Cancel can be offered, and shows it as Pending — never as active, and
  /// never with an increased storage allowance (the allowance figures above
  /// come straight from `subscriptionStorageProvider`, unaffected by a
  /// still-pending request).
  Future<void> _onRequestAddon(String storagePackage) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final label = _packageLabel(storagePackage);
    final addon = await showRequestStorageAddonSheet(context, storagePackage, label);
    if (addon == null || !mounted) return;

    setState(() {
      _selectedPackage = null;
      _pendingAddon = addon;
    });
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.storageAddonRequestSubmittedMessage(label))),
    );
  }

  Future<void> _onCancelPendingAddon() async {
    final addon = _pendingAddon;
    if (addon == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(subscriptionActionsProvider).cancelStorageAddon(addon.id);
      if (mounted) setState(() => _pendingAddon = null);
      messenger.showSnackBar(SnackBar(content: Text(l10n.storageAddonRequestCancelledMessage)));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  /// Phase 5 Step 7 integration fix: if the locally-held pending add-on has
  /// since been approved (its id now appears in the freshly-fetched
  /// `purchasedAddons`, which is active-only), clear it — otherwise a
  /// refresh after approval would show the same add-on twice, once as
  /// "Active" in the list above and once as a stale "Pending" card below,
  /// which is actively misleading. This only detects *approval* (the
  /// approved id becomes visible in real data this screen already fetches)
  /// — it still cannot detect a *rejection*, since there is no per-id
  /// endpoint to check a specific request's status. That narrower gap is
  /// the documented, unavoidable Storage Pending-Request Limitation.
  void _reconcilePendingAddon(AsyncValue<SubscriptionStorage> storageAsync) {
    final addon = _pendingAddon;
    if (addon == null) return;
    final activeIds = storageAsync.valueOrNull?.purchasedAddons.map((a) => a.id).toSet();
    if (activeIds != null && activeIds.contains(addon.id)) {
      setState(() => _pendingAddon = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    ref.listen(subscriptionStorageProvider, (previous, next) => _reconcilePendingAddon(next));
    final storageAsync = ref.watch(subscriptionStorageProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.storageTitle)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(subscriptionStorageProvider);
          ref.invalidate(subscriptionProvider);
          await ref.read(subscriptionStorageProvider.future);
        },
        child: storageAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: RetrySection(
                message: l10n.storageLoadError,
                onRetry: () => ref.invalidate(subscriptionStorageProvider),
              ),
            ),
          ),
          data: (storage) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _StorageOverviewCard(storage: storage),
              const SizedBox(height: 24),
              SectionHeader(title: l10n.storageActiveAddonsHeading),
              const SizedBox(height: 8),
              _ActiveAddonsSection(addons: storage.purchasedAddons),
              if (_pendingAddon != null) ...[
                const SizedBox(height: 16),
                _PendingAddonCard(addon: _pendingAddon!, onCancel: _onCancelPendingAddon),
              ],
              const SizedBox(height: 24),
              SectionHeader(title: l10n.storageAvailablePackagesHeading),
              const SizedBox(height: 8),
              _AvailablePackagesSection(selectedPackage: _selectedPackage, onSelect: _onPackageSelected),
              if (_selectedPackage != null) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _onRequestAddon(_selectedPackage!),
                  child: Text(l10n.storageRequestAddonButton(_packageLabel(_selectedPackage!))),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StorageOverviewCard extends ConsumerWidget {
  final SubscriptionStorage storage;

  const _StorageOverviewCard({required this.storage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final subscriptionAsync = ref.watch(subscriptionProvider);

    final String baseStorageText;
    if (subscriptionAsync.hasValue) {
      final baseLimit = subscriptionAsync.value!.plan?.storageLimit;
      baseStorageText = baseLimit == null ? l10n.subscriptionUnlimitedLabel : '$baseLimit GB';
    } else if (subscriptionAsync.isLoading) {
      baseStorageText = '…';
    } else {
      baseStorageText = '—';
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.storageOverviewHeading, style: AppTypography.subheading.copyWith(color: context.colors.textPrimary)),
          Divider(height: 32, color: context.colors.background),
          _InfoRow(label: l10n.storageUsedLabel, value: _formatFileSize(storage.storageUsageBytes)),
          const SizedBox(height: 12),
          _InfoRow(label: l10n.storageBaseAllowanceLabel, value: baseStorageText),
          const SizedBox(height: 12),
          _InfoRow(
            label: l10n.storageEffectiveAllowanceLabel,
            value: storage.storageLimitGb == null ? l10n.subscriptionUnlimitedLabel : '${storage.storageLimitGb} GB',
          ),
          const SizedBox(height: 12),
          _InfoRow(
            label: l10n.storageRemainingAllowanceLabel,
            value: storage.remainingStorageGb == null
                ? l10n.subscriptionUnlimitedLabel
                : '${storage.remainingStorageGb!.toStringAsFixed(2)} GB',
          ),
        ],
      ),
    );
  }
}

class _ActiveAddonsSection extends StatelessWidget {
  final List<StorageAddon> addons;

  const _ActiveAddonsSection({required this.addons});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (addons.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(l10n.storageNoActiveAddonsMessage, style: AppTypography.body.copyWith(color: context.colors.textPrimary)),
      );
    }
    return Column(
      children: [
        for (final addon in addons) ...[
          _AddonCard(addon: addon),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _AddonCard extends StatelessWidget {
  final StorageAddon addon;

  const _AddonCard({required this.addon});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _packageLabel(addon.storagePackage),
                style: AppTypography.subheading.copyWith(color: context.colors.textPrimary),
              ),
              StatusBadge(status: addon.status),
            ],
          ),
          Divider(height: 24, color: context.colors.background),
          _InfoRow(label: l10n.storageSizeLabel, value: '${addon.storageSize} GB'),
          const SizedBox(height: 8),
          _InfoRow(label: l10n.subscriptionMonthlyPriceLabel, value: addon.monthlyPrice),
          if (addon.startedAt != null) ...[
            const SizedBox(height: 8),
            _InfoRow(label: l10n.storageStartedOnLabel, value: _formatDate(addon.startedAt)),
          ],
          if (addon.expiresAt != null) ...[
            const SizedBox(height: 8),
            _InfoRow(label: l10n.storageExpiresOnLabel, value: _formatDate(addon.expiresAt)),
          ],
        ],
      ),
    );
  }
}

/// Shown only for the lifetime of `_StorageScreenState._pendingAddon` —
/// see the screen-level doc comment for why this can't be backed by a
/// provider/refetch.
class _PendingAddonCard extends StatelessWidget {
  final StorageAddon addon;
  final VoidCallback onCancel;

  const _PendingAddonCard({required this.addon, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  l10n.storageAddonTitleLabel(_packageLabel(addon.storagePackage)),
                  style: AppTypography.subheading.copyWith(color: context.colors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(status: addon.status),
            ],
          ),
          Divider(height: 24, color: context.colors.background),
          _InfoRow(label: l10n.subscriptionMonthlyPriceLabel, value: addon.monthlyPrice),
          const SizedBox(height: 8),
          _InfoRow(label: l10n.subscriptionPaymentReferenceLabel, value: addon.paymentReference),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onCancel, child: Text(l10n.subscriptionCancelRequestButton)),
        ],
      ),
    );
  }
}

class _AvailablePackagesSection extends StatelessWidget {
  final String? selectedPackage;
  final ValueChanged<String> onSelect;

  const _AvailablePackagesSection({required this.selectedPackage, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final storagePackage in _storagePackages)
          ChoiceChip(
            label: Text(_packageLabel(storagePackage)),
            selected: selectedPackage == storagePackage,
            onSelected: (_) => onSelect(storagePackage),
            selectedColor: AppColors.primary.withValues(alpha: 0.2),
            labelStyle: TextStyle(color: selectedPackage == storagePackage ? AppColors.primary : context.colors.textSecondary),
            backgroundColor: context.colors.surface,
            side: BorderSide.none,
          ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.caption.copyWith(color: context.colors.textSecondary)),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTypography.body.copyWith(color: AppColors.primary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

String _formatDate(DateTime? date) => date == null ? '—' : date.toIso8601String().split('T').first;

/// Same rounding/unit convention as `formatFileSize`
/// (`documents/presentation/widgets/document_type_icon.dart`) — duplicated
/// locally, matching this codebase's existing precedent
/// (`bulk_import_screen.dart`'s and `subscription_screen.dart`'s own copies).
String _formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}
