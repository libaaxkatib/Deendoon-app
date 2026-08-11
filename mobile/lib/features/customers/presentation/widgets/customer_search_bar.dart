import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/deendoon_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Debounces keystrokes before firing a real `GET /customers?search=...`
/// call (via [onChanged]) — the debounce only delays *when* the network
/// request fires, it never filters already-fetched results client-side.
class CustomerSearchBar extends StatefulWidget {
  final ValueChanged<String> onChanged;

  const CustomerSearchBar({super.key, required this.onChanged});

  @override
  State<CustomerSearchBar> createState() => _CustomerSearchBarState();
}

class _CustomerSearchBarState extends State<CustomerSearchBar> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Cheap rebuild-on-keystroke, only to show/hide the clear ("x") button —
    // the actual search request still only fires from the debounced timer.
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => widget.onChanged(value.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextField(
      controller: _controller,
      onChanged: _onChanged,
      style: TextStyle(color: context.colors.textPrimary),
      decoration: InputDecoration(
        hintText: l10n.customerSearchHint,
        prefixIcon: Icon(Icons.search, color: context.colors.textSecondary),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                icon: Icon(Icons.close, color: context.colors.textSecondary),
                onPressed: () {
                  _controller.clear();
                  _debounce?.cancel();
                  widget.onChanged('');
                  setState(() {});
                },
              ),
        filled: true,
        fillColor: context.colors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
      onSubmitted: (value) {
        _debounce?.cancel();
        widget.onChanged(value.trim());
      },
    );
  }
}
