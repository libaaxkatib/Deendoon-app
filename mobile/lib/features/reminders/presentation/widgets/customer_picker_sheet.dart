import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../customers/data/customer_repository.dart';
import '../../../customers/domain/customer.dart';
import '../../../customers/presentation/widgets/customer_card.dart';

/// Lightweight customer picker for Reminder Scheduling's "Related To"
/// field — reuses the real `GET /customers?search=` (Sprint 11) rather
/// than a fabricated lookup. Shows only the first page of matches for a
/// given search term (not the full infinite-scroll Customer List
/// experience) — a deliberate, smaller scope for a modal picker.
Future<Customer?> showCustomerPickerSheet(BuildContext context) {
  return showModalBottomSheet<Customer>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _CustomerPickerSheet(),
  );
}

class _CustomerPickerSheet extends ConsumerStatefulWidget {
  const _CustomerPickerSheet();

  @override
  ConsumerState<_CustomerPickerSheet> createState() => _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends ConsumerState<_CustomerPickerSheet> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<Customer>? _results;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    setState(() => _loading = true);
    try {
      final page = await ref.read(customerRepositoryProvider).fetchCustomers(page: 1, search: query);
      if (mounted) setState(() => _results = page.customers);
    } catch (_) {
      if (mounted) setState(() => _results = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(value.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Select Customer', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              onChanged: _onChanged,
              decoration: const InputDecoration(hintText: 'Search by name or phone', prefixIcon: Icon(Icons.search)),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : (_results?.isEmpty ?? true)
                      ? const Center(child: Text('No customers found', style: AppTypography.body))
                      : ListView.separated(
                          controller: scrollController,
                          itemCount: _results!.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final customer = _results![index];
                            return CustomerCard(customer: customer, onTap: () => Navigator.of(context).pop(customer));
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
