import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider that injects the saved theme string before ThemeModeNotifier builds.
/// Overridden in main() with the persisted theme from Hive.
final initialThemeProvider = Provider<String>((ref) => 'dark');

/// Theme mode notifier - manages dark/light/system theme
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final saved = ref.watch(initialThemeProvider);
    return _fromString(saved);
  }

  void toggleThemeMode() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
  }

  void setThemeModeFromString(String theme) {
    state = _fromString(theme);
  }

  ThemeMode _fromString(String theme) {
    switch (theme.toLowerCase()) {
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.dark;
    }
  }
}

/// Global theme mode provider
final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

extension ThemeModeExt on ThemeMode {
  String get displayName {
    switch (this) {
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.system:
        return 'System';
    }
  }

  String get value {
    switch (this) {
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.light:
        return 'light';
      case ThemeMode.system:
        return 'system';
    }
  }
}
