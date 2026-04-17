import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fadocx/core/utils/logger.dart';
import 'package:fadocx/config/theme/theme_provider.dart';
import 'package:fadocx/config/routing/app_router.dart';
import 'package:fadocx/features/home/presentation/widgets/bottom_nav_dock.dart';
import 'package:fadocx/features/settings/presentation/providers/settings_providers.dart';
import 'package:fadocx/features/settings/presentation/providers/locale_provider.dart';
import 'package:fadocx/features/settings/domain/entities/app_settings.dart';
import 'package:fadocx/l10n/app_localizations.dart';

/// Settings screen - comprehensive app configuration with card-based layout
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    log.d('Building SettingsScreen');

    final settings = ref.watch(appSettingsProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Material(
          elevation: 0,
          color: Colors.transparent,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surface
                      .withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: Text(
                          AppLocalizations.of(context)!.settingsTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      child: Container(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: settings.when(
        data: (appSettings) {
          if (appSettings == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // APPEARANCE SECTION
                _buildSectionTitle(context, 'Appearance'),
                _buildThemeCard(context, ref, themeMode),
                const SizedBox(height: 24),

                // LANGUAGE & REGION SECTION
                _buildSectionTitle(context, 'Language & Region'),
                _buildLanguageCard(context, ref, appSettings),
                const SizedBox(height: 24),

                // ABOUT SECTION
                _buildSectionTitle(context, 'About'),
                _buildAboutCard(context, appSettings),
                const SizedBox(height: 24),

                // DATA MANAGEMENT SECTION
                _buildSectionTitle(context, 'Data Management'),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        context,
                        icon: Icons.history,
                        title: 'Clear Recent',
                        description: 'Remove all recent files',
                        onTap: () => _showClearConfirmDialog(
                          context,
                          'Clear Recent Files',
                          'This will remove all recent files from your list.',
                          () {
                            log.i('Clearing recent files');
                            ref
                                .read(recentFilesMutatorProvider)
                                .clearAllRecentFiles();
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Recent files cleared'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionCard(
                        context,
                        icon: Icons.restore,
                        title: 'Reset Settings',
                        description: 'Restore defaults',
                        onTap: () => _showClearConfirmDialog(
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
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
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
      bottomNavigationBar: BottomNavDock(
        currentRoute: RouteNames.settings,
      ),
    );
  }

  /// Build section title
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  /// Build theme card with button options
  Widget _buildThemeCard(
      BuildContext context, WidgetRef ref, ThemeMode currentTheme) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.theme,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildThemeButton(context, ref, ThemeMode.dark, currentTheme),
              const SizedBox(width: 8),
              _buildThemeButton(context, ref, ThemeMode.light, currentTheme),
              const SizedBox(width: 8),
              _buildThemeButton(context, ref, ThemeMode.system, currentTheme),
            ],
          ),
        ],
      ),
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
      child: FilledButton.tonal(
        onPressed: () async {
          try {
            log.i('Changing theme to: ${mode.displayName}');
            ref.read(themeModeProvider.notifier).setThemeMode(mode);
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
    );
  }

  /// Build language selector card
  Widget _buildLanguageCard(
    BuildContext context,
    WidgetRef ref,
    AppSettings appSettings,
  ) {
    final currentLocale = ref.watch(localeProvider);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppLocalizations.of(context)!.language,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
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
                  ref.read(localeProvider.notifier).setLocale(value);
                  await ref.read(settingsMutatorProvider).updateLanguage(value);
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


  /// Build about section card
  Widget _buildAboutCard(BuildContext context, AppSettings appSettings) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.appVersion,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Fadocx v1.0.0 (Build 1)',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            'About Fadocx',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.aboutDescription,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Text(
            'Built with:',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
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
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.privacyDescription,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  /// Build action card (for Clear Recent, Reset Settings)
  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
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
