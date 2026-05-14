import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider that injects the saved language before LocaleNotifier builds.
/// Overridden in main() with the persisted language from Hive.
final initialLocaleProvider = Provider<String>((ref) => 'en');

/// Notifier to manage locale changes
class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() => Locale(ref.watch(initialLocaleProvider));

  /// Change locale in real-time
  void setLocale(String languageCode) {
    state = Locale(languageCode);
  }

  /// Get current language code
  String getCurrentLanguageCode() {
    return state.languageCode;
  }
}

/// Provider for current locale (language) - supports real-time switching
final localeProvider =
    NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);
