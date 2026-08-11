import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/localization/locale_provider.dart';
import '../core/localization/somali_fallback_delegates.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_mode_provider.dart';
import '../l10n/generated/app_localizations.dart';
import 'router/app_router.dart';

class DeendoonApp extends ConsumerWidget {
  const DeendoonApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Deendoon',
      debugShowCheckedModeBanner: false,
      theme: buildAppLightTheme(),
      darkTheme: buildAppDarkTheme(),
      themeMode: themeMode,
      routerConfig: router,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        SomaliMaterialLocalizationsDelegate(),
        SomaliCupertinoLocalizationsDelegate(),
      ],
    );
  }
}
