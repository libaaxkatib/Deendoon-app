import 'package:flutter/material.dart';

/// Wraps `showModalBottomSheet` content with the two things every sheet in
/// this app needs and, until Mobile Fix #5, inconsistently forgot: the OS
/// system inset (Android's gesture/3-button navigation bar, iOS's home
/// indicator) via [SafeArea], and a scroll view so content taller than the
/// available height — e.g. a short device with the keyboard open — scrolls
/// instead of overflowing or having its bottom button pushed off-screen.
/// `showModalBottomSheet` applies neither of these automatically; wrapping
/// here once, rather than at each of the ~12 call sites, keeps every sheet
/// correct by construction instead of relying on each one remembering to
/// add both. `viewInsets.bottom` (the keyboard) is deliberately still
/// handled explicitly — [SafeArea] alone does not account for it.
class BottomSheetContent extends StatelessWidget {
  final Widget child;

  const BottomSheetContent({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: child,
      ),
    );
  }
}
