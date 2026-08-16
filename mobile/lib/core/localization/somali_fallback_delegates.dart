import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Flutter's own `GlobalMaterialLocalizations`/`GlobalCupertinoLocalizations`
/// do not ship Somali translations (`so` is not one of the ~80 locales
/// Flutter's material/cupertino libraries support out of the box) — without
/// these fallbacks, switching to Somali crashes every widget that requires
/// `MaterialLocalizations`/`CupertinoLocalizations` (e.g. `TextField`).
///
/// This falls back to the English implementation for framework chrome
/// strings only (things like the text-selection toolbar's "Cut"/"Copy").
/// Every string this app actually owns still renders in real Somali via
/// `AppLocalizations` — only Flutter's own untranslated internals fall
/// back to English, which is the standard, documented way to add a
/// locale Flutter doesn't ship itself.
class SomaliMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const SomaliMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'so';

  @override
  Future<MaterialLocalizations> load(Locale locale) {
    return SynchronousFuture<MaterialLocalizations>(
      const DefaultMaterialLocalizations(),
    );
  }

  @override
  bool shouldReload(
    covariant LocalizationsDelegate<MaterialLocalizations> old,
  ) => false;
}

class SomaliCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const SomaliCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'so';

  @override
  Future<CupertinoLocalizations> load(Locale locale) {
    return SynchronousFuture<CupertinoLocalizations>(
      const DefaultCupertinoLocalizations(),
    );
  }

  @override
  bool shouldReload(
    covariant LocalizationsDelegate<CupertinoLocalizations> old,
  ) => false;
}
