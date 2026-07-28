import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import 'router/app_router.dart';

class DeendoonApp extends ConsumerWidget {
  const DeendoonApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'Deendoon',
      debugShowCheckedModeBanner: false,
      theme: buildAppDarkTheme(),
      routerConfig: router,
    );
  }
}
