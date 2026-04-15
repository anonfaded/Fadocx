import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fadocx/core/utils/logger.dart';

/// Theme mode notifier - manages dark/light/system theme
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    log.d('ThemeModeNotifier initialized');
    // Load theme from settings when app starts
    // The theme gets synced from settings provider after initialization
    return ThemeMode.dark;
  }

  /// Toggle between dark and light theme
  void toggleThemeMode() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    log.i('Theme toggled to: ${state.name}');
  }

  /// Set specific theme mode
  void setThemeMode(ThemeMode mode) {
    state = mode;
    log.i('Theme set to: ${mode.name}');
  }

  /// Set theme based on string value
  void setThemeModeFromString(String theme) {
    switch (theme.toLowerCase()) {
      case 'dark':
        state = ThemeMode.dark;
        break;
      case 'light':
        state = ThemeMode.light;
        break;
      case 'system':
        state = ThemeMode.system;
        break;
      default:
        state = ThemeMode.dark;
    }
    log.d('Theme set from string: $theme → ${state.name}');
  }
}

/// Global theme mode provider
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

/// Extension for ThemeMode convenience
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
