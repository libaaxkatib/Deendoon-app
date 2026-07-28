import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_typography.dart';

/// The Cases tab itself remains out of scope (still unbuilt — Sprint 11 is
/// Customers only), but the Customers module built this sprint needs a
/// real entry point somewhere. The already-approved Home Dashboard isn't
/// touched again here, so this still-placeholder Cases tab is where the
/// one genuine link into Customer List lives for now.
class CasesTabScreen extends StatelessWidget {
  const CasesTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cases')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Cases — coming soon', style: AppTypography.subheading),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.push('/customers'),
              child: const Text('Browse Customers'),
            ),
          ],
        ),
      ),
    );
  }
}
