import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fadocx/config/theme/theme_provider.dart';
import 'package:fadocx/config/routing/app_router.dart';
import 'package:fadocx/core/presentation/widgets/floating_dock_scaffold.dart';
import 'package:fadocx/features/settings/presentation/providers/settings_providers.dart';
import 'package:fadocx/features/settings/presentation/providers/locale_provider.dart';
import 'package:fadocx/l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final themeMode = ref.watch(themeModeProvider);

    return FloatingDockScaffold(
      appBarContent: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Center(
            child: Text(
              AppLocalizations.of(context)!.settingsTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ),
      ),
      currentRoute: RouteNames.settings,
      body: settings.when(
        data: (appSettings) {
          if (appSettings == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 80, 16, 100),
            children: [
              _buildSectionHeader(context, 'Appearance'),
              _buildSettingsGroup(context, [
                _SettingsRow(
                  icon: Icons.palette_outlined,
                  title: 'Theme',
                  value: _getThemeDisplayName(context, themeMode),
                  onTap: () => _showThemePicker(context, ref, themeMode),
                ),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(context, 'Language'),
              _buildSettingsGroup(context, [
                _SettingsRow(
                  icon: Icons.language,
                  title: 'Language',
                  value: _getLanguageDisplayName(context, ref),
                  onTap: () => _showLanguagePicker(context, ref),
                ),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(context, 'Storage'),
              _buildSettingsGroup(context, [
                _SettingsRow(
                  icon: Icons.folder_outlined,
                  title: 'Documents Size',
                  value: '~12.4 MB',
                  onTap: () => _showStorageInfo(context),
                ),
                _divider(context),
                _SettingsRow(
                  icon: Icons.settings_backup_restore,
                  title: 'Custom Storage',
                  value: 'Coming Soon',
                  isComingSoon: true,
                  onTap: null,
                ),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(context, 'About'),
              _buildSettingsGroup(context, [
                _SettingsRow(
                  icon: Icons.info_outline,
                  title: 'Version',
                  value: '1.0.0 (Build 1)',
                  onTap: () => _showVersionInfo(context),
                ),
                _divider(context),
                _SettingsRow(
                  icon: Icons.code,
                  title: 'Source Code',
                  onTap: () => _copyToClipboard(
                      context, 'https://github.com/anonfaded/Fadocx'),
                ),
                _divider(context),
                _SettingsRow(
                  icon: Icons.email_outlined,
                  title: 'Contact',
                  value: 'contact@fadseclab.com',
                  onTap: () =>
                      _copyToClipboard(context, 'contact@fadseclab.com'),
                ),
                _divider(context),
                _SettingsRow(
                  icon: Icons.shield_outlined,
                  title: 'Privacy Policy',
                  onTap: () => _showPrivacyPolicy(context),
                ),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(context, 'Danger Zone', color: Colors.red),
              _buildDangerGroup(context, [
                _DangerRow(
                  icon: Icons.delete_outline,
                  title: 'Clear Recent Files',
                  subtitle: 'Remove all recent files',
                  confirmText: 'DELETE',
                  onConfirm: () {
                    ref.read(recentFilesMutatorProvider).clearAllRecentFiles();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Recent files cleared')),
                    );
                  },
                ),
                _divider(context),
                _DangerRow(
                  icon: Icons.restore,
                  title: 'Reset Settings',
                  subtitle: 'Restore all settings to defaults',
                  confirmText: 'RESET',
                  onConfirm: () {
                    ref.read(settingsMutatorProvider).clearSettings();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Settings reset to defaults')),
                    );
                  },
                ),
              ]),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(appSettingsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title,
      {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color ?? Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
      ),
    );
  }

  Widget _buildSettingsGroup(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.08),
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDangerGroup(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.2),
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _divider(BuildContext context) {
    return Divider(
      height: 1,
      indent: 56,
      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.08),
    );
  }

  String _getThemeDisplayName(BuildContext context, ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return AppLocalizations.of(context)!.themeDark;
      case ThemeMode.light:
        return AppLocalizations.of(context)!.themeLight;
      case ThemeMode.system:
        return AppLocalizations.of(context)!.themeSystem;
    }
  }

  String _getLanguageDisplayName(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    return locale.languageCode == 'en'
        ? AppLocalizations.of(context)!.languageEnglish
        : AppLocalizations.of(context)!.languageUrdu;
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Copied: $text'), duration: const Duration(seconds: 2)),
    );
  }

  void _showStorageInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          decoration: _bottomSheetDecoration(context),
          child: ListView(
            controller: scrollController,
            children: [
              Center(child: _handle(context)),
              const SizedBox(height: 8),
              Center(
                  child: Text('Storage',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold))),
              const SizedBox(height: 20),
              SizedBox(height: 140, child: _storageChart()),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: _storageChip(
                        Icons.picture_as_pdf, 'PDFs', '4.8 MB', Colors.red)),
                const SizedBox(width: 8),
                Expanded(
                    child: _storageChip(
                        Icons.table_chart, 'Sheets', '4.2 MB', Colors.green)),
                const SizedBox(width: 8),
                Expanded(
                    child: _storageChip(
                        Icons.description, 'Docs', '3.4 MB', Colors.blue)),
              ]),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lock_outline,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Documents are stored in a private folder, hidden from other apps and file managers. Only Fadocx can access them.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 20, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Delete documents from Danger Zone in Settings',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _storageChart() => TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.scale(
              scale: 0.8 + (0.2 * value),
              child: PieChart(PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 35,
                sections: [
                  PieChartSectionData(
                      color: Colors.red,
                      value: 40,
                      title: '40%',
                      titleStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                      radius: 45),
                  PieChartSectionData(
                      color: Colors.green,
                      value: 35,
                      title: '35%',
                      titleStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                      radius: 45),
                  PieChartSectionData(
                      color: Colors.blue,
                      value: 25,
                      title: '25%',
                      titleStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                      radius: 45),
                ],
              )))));

  Widget _storageChip(IconData icon, String label, String size, Color color) =>
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10)),
        child: Column(children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          Text(size,
              style:
                  TextStyle(fontSize: 10, color: color.withValues(alpha: 0.7))),
        ]),
      );

  void _showThemePicker(
      BuildContext context, WidgetRef ref, ThemeMode current) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: _bottomSheetDecoration(context),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _handle(context),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Choose Theme',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              _ThemeOption(
                icon: Icons.dark_mode,
                title: AppLocalizations.of(context)!.themeDark,
                isSelected: current == ThemeMode.dark,
                onTap: () {
                  ref
                      .read(themeModeProvider.notifier)
                      .setThemeMode(ThemeMode.dark);
                  ref.read(settingsMutatorProvider).updateTheme('dark');
                  Navigator.pop(context);
                },
              ),
              _ThemeOption(
                icon: Icons.light_mode,
                title: AppLocalizations.of(context)!.themeLight,
                isSelected: current == ThemeMode.light,
                onTap: () {
                  ref
                      .read(themeModeProvider.notifier)
                      .setThemeMode(ThemeMode.light);
                  ref.read(settingsMutatorProvider).updateTheme('light');
                  Navigator.pop(context);
                },
              ),
              _ThemeOption(
                icon: Icons.settings_brightness,
                title: AppLocalizations.of(context)!.themeSystem,
                isSelected: current == ThemeMode.system,
                onTap: () {
                  ref
                      .read(themeModeProvider.notifier)
                      .setThemeMode(ThemeMode.system);
                  ref.read(settingsMutatorProvider).updateTheme('system');
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: _bottomSheetDecoration(context),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _handle(context),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Select Language',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              _LanguageOption(
                flag: '🇺🇸',
                title: AppLocalizations.of(context)!.languageEnglish,
                isSelected: ref.read(localeProvider).languageCode == 'en',
                onTap: () {
                  ref.read(localeProvider.notifier).setLocale('en');
                  ref.read(settingsMutatorProvider).updateLanguage('en');
                  Navigator.pop(context);
                },
              ),
              _LanguageOption(
                flag: '🇵🇰',
                title: AppLocalizations.of(context)!.languageUrdu,
                isSelected: ref.read(localeProvider).languageCode == 'ur',
                onTap: () {
                  ref.read(localeProvider.notifier).setLocale('ur');
                  ref.read(settingsMutatorProvider).updateLanguage('ur');
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _bottomSheetDecoration(BuildContext context) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Theme.of(context).colorScheme.surface,
          Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
    );
  }

  Widget _handle(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  void _showVersionInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: _bottomSheetDecoration(context),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _handle(context),
              const SizedBox(height: 8),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.tertiary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.description,
                    size: 40, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                'Fadocx',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Version 1.0.0 (Build 1)',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'com.fadseclab.fadocx',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Clipboard.setData(const ClipboardData(
                      text:
                          'Fadocx v1.0.0 (Build 1)\nPackage: com.fadseclab.fadocx',
                    ));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard')),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy Info'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: _bottomSheetDecoration(context),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            children: [
              Center(child: _handle(context)),
              const SizedBox(height: 16),
              Center(
                child: Icon(
                  Icons.shield,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Privacy Policy',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: 24),
              _policyItem(
                context,
                Icons.wifi_off,
                '100% Offline',
                'All processing happens on your device. No internet required.',
              ),
              _policyItem(
                context,
                Icons.storage,
                'Local Storage Only',
                'Your documents stay on your device. Nothing is uploaded.',
              ),
              _policyItem(
                context,
                Icons.psychology,
                'On-Device AI',
                'Uses OpenCV + Tesseract for OCR. AI runs locally.',
              ),
              _policyItem(
                context,
                Icons.code,
                'Open Source',
                'Code is public. Audit it yourself on GitHub.',
              ),
              _policyItem(
                context,
                Icons.block,
                'No Ads',
                'No advertisements. No tracking. No analytics.',
              ),
              _policyItem(
                context,
                Icons.lock,
                'Your Data, Your Rules',
                'You own your documents. Delete anytime.',
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'We believe in privacy by design.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Fadocx is built with transparency. Your documents are your business - not ours.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _copyToClipboard(
                      context, 'https://github.com/anonfaded/Fadocx'),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('View Source Code'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _policyItem(
      BuildContext context, IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                color: Theme.of(context).colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedListView extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets padding;

  const AnimatedListView({
    super.key,
    required this.children,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: padding,
      children: children,
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback? onTap;
  final bool showChevron;
  final bool isComingSoon;

  const _SettingsRow({
    required this.icon,
    required this.title,
    this.value,
    this.onTap,
    this.showChevron = true,
    this.isComingSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              if (isComingSoon)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    value ?? 'Coming Soon',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onTertiaryContainer,
                        ),
                  ),
                )
              else if (value != null)
                Text(
                  value!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              if (showChevron && onTap != null && !isComingSoon)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DangerRow extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String confirmText;
  final VoidCallback onConfirm;

  const _DangerRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.confirmText,
    required this.onConfirm,
  });

  @override
  State<_DangerRow> createState() => _DangerRowState();
}

class _DangerRowState extends State<_DangerRow> {
  final _controller = TextEditingController();
  bool _confirmed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showDangerDialog(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon, size: 20, color: Colors.red),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.red,
                          ),
                    ),
                    Text(
                      widget.subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDangerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type "${widget.confirmText}" to confirm:'),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: widget.confirmText,
              ),
              onChanged: (v) =>
                  setState(() => _confirmed = v == widget.confirmText),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _confirmed ? widget.onConfirm : null,
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.primary),
      ),
      title: Text(title),
      trailing: isSelected
          ? Icon(Icons.check_circle,
              color: Theme.of(context).colorScheme.primary)
          : Icon(Icons.circle_outlined,
              color: Theme.of(context).colorScheme.outline),
      onTap: onTap,
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String flag;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.flag,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 28)),
      title: Text(title),
      trailing: isSelected
          ? Icon(Icons.check_circle,
              color: Theme.of(context).colorScheme.primary)
          : Icon(Icons.circle_outlined,
              color: Theme.of(context).colorScheme.outline),
      onTap: onTap,
    );
  }
}
