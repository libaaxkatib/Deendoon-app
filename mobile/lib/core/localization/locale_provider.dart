import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/locale_storage.dart';

/// Settings §General — Language (English/Somali only, per approved scope).
/// `initial` is set once at startup in `main.dart` from the persisted
/// value (if any) via a provider override, so the very first frame
/// already renders in the restored language with no flash of the
/// wrong locale.
class LocaleNotifier extends Notifier<Locale> {
  final Locale initial;

  LocaleNotifier({this.initial = const Locale('en')});

  @override
  Locale build() => initial;

  Future<void> setLanguageCode(String languageCode) async {
    state = Locale(languageCode);
    await ref.read(localeStorageProvider).saveLanguageCode(languageCode);
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);
