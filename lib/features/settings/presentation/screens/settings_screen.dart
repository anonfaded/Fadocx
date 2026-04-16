import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fadocx/core/utils/logger.dart';
import 'package:fadocx/config/theme/theme_provider.dart';
import 'package:fadocx/features/settings/presentation/providers/settings_providers.dart';
import 'package:fadocx/features/settings/presentation/providers/locale_provider.dart';
import 'package:fadocx/features/settings/domain/entities/app_settings.dart';
import 'package:fadocx/l10n/app_localizations.dart';

/// Settings screen - comprehensive app configuration
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    log.d('Building SettingsScreen');

    final settings = ref.watch(appSettingsProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settingsTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            try {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                context.go('/');
              }
            } catch (e) {
              log.e('Error navigating back', e);
              context.go('/');
            }
          },
        ),
      ),
      body: settings.when(
        data: (appSettings) {
          if (appSettings == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          return ListView(
            children: [
              // THEME SECTION
              _buildSectionHeader(context, 'Appearance'),
              _buildThemeSelector(context, ref, themeMode),
              const Divider(),

              // LANGUAGE SECTION
              _buildSectionHeader(context, 'Language & Region'),
              _buildLanguageSelector(context, ref, appSettings),
              const Divider(),

              // NOTIFICATIONS SECTION
              _buildSectionHeader(context, 'Notifications'),
              _buildNotificationToggle(context, ref, appSettings),
              const Divider(),

              // ABOUT SECTION
              _buildSectionHeader(context, 'About'),
              _buildAboutTile(context, appSettings),
              _buildCredits(context),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  AppLocalizations.of(context)!.privacyDescription,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),

              // DATA MANAGEMENT SECTION
              _buildSectionHeader(context, 'Data Management'),
              _buildClearRecentFilesButton(context, ref),
              _buildClearSettingsButton(context, ref),

              const SizedBox(height: 32),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, st) {
          log.e('Error loading settings', error, st);
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error loading settings: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(appSettingsProvider);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Build section header
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  /// Build theme selector
  Widget _buildThemeSelector(
      BuildContext context, WidgetRef ref, ThemeMode currentTheme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.theme,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              Text(
                currentTheme.displayName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildThemeButton(context, ref, ThemeMode.dark, currentTheme),
              _buildThemeButton(context, ref, ThemeMode.light, currentTheme),
              _buildThemeButton(context, ref, ThemeMode.system, currentTheme),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  /// Build individual theme button
  Widget _buildThemeButton(
    BuildContext context,
    WidgetRef ref,
    ThemeMode mode,
    ThemeMode currentTheme,
  ) {
    final isSelected = currentTheme == mode;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: FilledButton.tonal(
          onPressed: () async {
            try {
              log.i('Changing theme to: ${mode.displayName}');
              // Update provider (UI changes instantly)
              ref.read(themeModeProvider.notifier).setThemeMode(mode);
              // Save to persistent storage (non-blocking)
              await ref.read(settingsMutatorProvider).updateTheme(mode.value);
              log.i('✅ Theme changed to ${mode.displayName}');
            } catch (e, st) {
              log.e('Error changing theme', e, st);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Error: $e'), backgroundColor: Colors.red),
                );
              }
            }
          },
          style: FilledButton.styleFrom(
            backgroundColor: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surface,
            foregroundColor: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurface,
          ),
          child: Text(mode.displayName),
        ),
      ),
    );
  }

  /// Build language selector with real-time switching
  Widget _buildLanguageSelector(
    BuildContext context,
    WidgetRef ref,
    AppSettings appSettings,
  ) {
    final currentLocale = ref.watch(localeProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppLocalizations.of(context)!.language,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          DropdownButton<String>(
            value: currentLocale.languageCode,
            items: [
              DropdownMenuItem(
                value: 'en',
                child: Text(AppLocalizations.of(context)!.languageEnglish),
              ),
              DropdownMenuItem(
                value: 'ur',
                child: Text(AppLocalizations.of(context)!.languageUrdu),
              ),
            ],
            onChanged: (value) async {
              if (value != null && value != currentLocale.languageCode) {
                try {
                  log.i('Changing language to: $value');

                  // Update locale in real-time
                  ref.read(localeProvider.notifier).setLocale(value);

                  // Update settings (non-blocking)
                  await ref.read(settingsMutatorProvider).updateLanguage(value);

                  // Show confirmation
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          value == 'en'
                              ? 'Language changed to English'
                              : 'زبان اردو میں تبدیل ہو گئی',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e, st) {
                  log.e('Error changing language', e, st);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }

  /// Build notification toggle
  Widget _buildNotificationToggle(
    BuildContext context,
    WidgetRef ref,
    AppSettings appSettings,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Enable Notifications (Phase 2)',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          Switch(
            value: appSettings.enableNotifications,
            onChanged: (value) {
              log.i('Toggling notifications: $value');
              ref.read(settingsMutatorProvider).updateNotifications(value);
            },
          ),
        ],
      ),
    );
  }

  /// Build about tile
  Widget _buildAboutTile(BuildContext context, AppSettings appSettings) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.appVersion,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Fadocx v1.0.0 (Build 1)',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ],
      ),
    );
  }

  /// Build credits section
  Widget _buildCredits(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About Fadocx',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.aboutDescription,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Text(
            'Built with:',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Text(
            '• Flutter + Dart\n'
            '• Riverpod (State Management)\n'
            '• Hive (Local Database)\n'
            '• Go Router (Navigation)\n'
            '• All Open Source',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  /// Build clear recent files button
  Widget _buildClearRecentFilesButton(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: FilledButton.tonal(
        onPressed: () {
          _showClearConfirmDialog(
            context,
            'Clear Recent Files',
            'This will remove all recent files from your list.',
            () {
              log.i('Clearing recent files');
              ref.read(recentFilesMutatorProvider).clearAllRecentFiles();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Recent files cleared'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          );
        },
        child: Text(AppLocalizations.of(context)!.clearRecentFiles),
      ),
    );
  }

  /// Build clear settings button (Phase 2+)
  Widget _buildClearSettingsButton(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: FilledButton.tonal(
        onPressed: () {
          _showClearConfirmDialog(
            context,
            'Reset All Settings',
            'This will reset all app settings to defaults.',
            () {
              log.i('Resetting all settings');
              ref.read(settingsMutatorProvider).clearSettings();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings reset to defaults'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          );
        },
        child: const Text('Reset All Settings'),
      ),
    );
  }

  /// Show confirmation dialog
  void _showClearConfirmDialog(
    BuildContext context,
    String title,
    String message,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: onConfirm,
            child: Text(AppLocalizations.of(context)!.ok),
          ),
        ],
      ),
    );
  }
}
