import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fadocx/config/theme/theme_provider.dart';
import 'package:fadocx/config/routing/app_router.dart';
import 'package:fadocx/core/presentation/widgets/floating_dock_scaffold.dart';
import 'package:fadocx/core/presentation/widgets/update_available_sheet.dart';
import 'package:fadocx/core/presentation/widgets/link_tile.dart';
import 'package:fadocx/core/presentation/constants.dart';
import 'package:fadocx/core/services/update_check_service.dart';
import 'package:fadocx/core/services/storage_service.dart';
import 'package:fadocx/features/settings/presentation/providers/settings_providers.dart';
import 'package:fadocx/features/settings/presentation/providers/locale_provider.dart';
import 'package:fadocx/l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final themeMode = ref.watch(themeModeProvider);
    final packageInfoAsync = ref.watch(packageInfoProvider);

    return FloatingDockScaffold(
      appBarContent: SafeArea(
        bottom: false,
        child: Center(
          child: Text(
            AppLocalizations.of(context)!.settingsTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
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
            padding: const EdgeInsets.fromLTRB(16, 88, 16, 100),
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
                Consumer(
                  builder: (context, ref, _) {
                    final recentFilesAsync = ref.watch(recentFilesProvider);
                    return recentFilesAsync.when(
                      loading: () => Column(children: [
                        _SettingsRow(
                          icon: Icons.folder_outlined,
                          title: 'Documents Size',
                          value: 'Calculating...',
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
                      error: (error, stack) => Column(children: [
                        _SettingsRow(
                          icon: Icons.folder_outlined,
                          title: 'Documents Size',
                          value: 'Unknown',
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
                      data: (files) {
                        final activeFiles = files.where((f) => !f.isDeleted).toList();
                        final totalBytes = activeFiles.fold<int>(0, (sum, f) => sum + f.fileSizeBytes);
                        final totalCount = activeFiles.length;
                        final value = '${StorageService.formatBytes(totalBytes)} • $totalCount files';
                        return Column(children: [
                          _SettingsRow(
                            icon: Icons.folder_outlined,
                            title: 'Documents Size',
                            value: value,
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
                        ]);
                      },
                    );
                  },
                ),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(context, 'Updates'),
              _buildSettingsGroup(context, [
                Consumer(
                  builder: (context, ref, _) {
                    final settings = ref.watch(appSettingsProvider);
                    final enabled = settings.when(
                      data: (s) => s?.autoUpdateCheck ?? true,
                      loading: () => true,
                      error: (_, __) => true,
                    );

                    return _buildAutoUpdateRow(context, ref, enabled);
                  },
                ),
                _divider(context),
                _buildCheckUpdatesRow(context, ref),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(context, 'Security'),
              _buildSettingsGroup(context, [
                _SettingsRow(
                  icon: Icons.lock_outline,
                  title: 'App Lock',
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
                  value: packageInfoAsync.when(
                    data: (info) => 'v${info.version}+${info.buildNumber}',
                    loading: () => '...',
                    error: (_, __) => 'Unknown',
                  ),
                  onTap: () => packageInfoAsync.whenData(
                    (info) => _showVersionInfo(context, info),
                  ),
                ),
                _divider(context),
                LinkTile.url(
                  icon: SimpleIcons.github,
                  title: 'Source Code',
                  value: 'https://github.com/anonfaded/Fadocx',
                ),
                _divider(context),
                LinkTile.email(
                  icon: Icons.email_outlined,
                  title: 'Contact',
                  value: 'contact@fadseclab.com',
                ),
                _divider(context),
                LinkTile.url(
                  icon: SimpleIcons.discord,
                  title: 'Join Community',
                  value: 'https://discord.gg/kvAZvdkuuN',
                ),
                _divider(context),
                _SettingsRow(
                  icon: Icons.shield_outlined,
                  title: 'Privacy Policy',
                  onTap: () => _showPrivacyPolicy(context),
                ),
                _divider(context),
                _patreonRow(context),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(context, 'More from FadSec Lab'),
              _buildSettingsGroup(context, [
                _otherAppCard(
                  context,
                  imageAsset: 'assets/other_apps/fadcam.png',
                  name: 'FadCam',
                  description:
                      'Privacy-focused Android multimedia suite: background video recording, '
                      'dashcam, screen recorder, live streaming & remote control — '
                      'ad-free & open-source.',
                  platformIcons: [SimpleIcons.android],
                  url: 'https://github.com/anonfaded/FadCam',
                ),
                _divider(context),
                _otherAppCard(
                  context,
                  imageAsset: 'assets/other_apps/qurancli.png',
                  name: 'QuranCLI',
                  description:
                      'Your Terminal Companion for the Holy Quran: Read, Listen & Generate '
                      'Subtitles for Video Editing!',
                  platformIcons: [Icons.window, SimpleIcons.linux, SimpleIcons.apple],
                  url: 'https://github.com/anonfaded/QuranCLI',
                  platformNote: 'macOS coming soon',
                ),
                _divider(context),
                _otherAppCard(
                  context,
                  imageAsset: 'assets/other_apps/fadcrypt.png',
                  name: 'FadCrypt',
                  description:
                      'Advanced and elegant cross-platform app locker — files, folders, '
                      'and applications all protected with military-grade AES-256-GCM encryption. '
                      'Open-source, completely free, no telemetry!',
                  platformIcons: [Icons.window, SimpleIcons.linux, SimpleIcons.apple],
                  url: 'https://github.com/anonfaded/FadCrypt',
                  platformNote: 'macOS coming soon',
                ),
                _divider(context),
                _otherAppCard(
                  context,
                  imageAsset: 'assets/other_apps/fadcat.png',
                  name: 'FadCat',
                  description:
                      'Lightweight, feature-rich, cross-platform Android logcat replacement — '
                      'no Android Studio bloat. Bundles ADB for supported architectures, runs '
                      'in GUI, CLI, or MCP server mode.',
                  platformIcons: [Icons.window, SimpleIcons.linux, SimpleIcons.apple],
                  url: 'https://github.com/anonfaded/FadCat',
                  iconBgColor: Colors.black.withValues(alpha: 0.2),
                ),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(context, 'Danger Zone', color: Colors.red),
              _buildDangerGroup(context, [
                _DangerRow(
                  icon: Icons.delete_outline,
                  title: 'Trash',
                  subtitle: 'View deleted files',
                  confirmText: '',
                  onConfirm: () {
                    context.push(RouteNames.trash);
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
              const SizedBox(height: 32),
              _buildFooter(context),
              const SizedBox(height: 48),
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
          child: Consumer(
            builder: (context, ref, _) {
              final recentFilesAsync = ref.watch(recentFilesProvider);
              return recentFilesAsync.when(
                loading: () => ListView(
                  controller: scrollController,
                  children: [
                    Center(child: _handle(context)),
                    const SizedBox(height: 8),
                    Center(
                      child: Text('Storage',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 20),
                    Column(
                      children: [
                        SizedBox(height: 140, child: Center(child: CircularProgressIndicator())),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(child: _storageChip(Icons.picture_as_pdf, 'PDFs', 'Calculating...', Colors.red)),
                          const SizedBox(width: 8),
                          Expanded(child: _storageChip(Icons.table_chart, 'Sheets', 'Calculating...', Colors.green)),
                          const SizedBox(width: 8),
                          Expanded(child: _storageChip(Icons.description, 'Docs', 'Calculating...', Colors.blue)),
                        ]),
                      ],
                    ),
                  ],
                ),
                error: (error, stack) => ListView(
                  controller: scrollController,
                  children: [
                    Center(child: _handle(context)),
                    const SizedBox(height: 8),
                    Center(
                      child: Text('Storage',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text('Failed to load storage data',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ),
                  ],
                ),
                data: (files) {
                  final stats = _computeCategoryStats(files);
                  return ListView(
                    controller: scrollController,
                    children: [
                      Center(child: _handle(context)),
                      const SizedBox(height: 8),
                      Center(
                        child: Text('Storage',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 20),
                      Builder(
                        builder: (context) {
                          final slices = <String, int>{};
                          for (final entry in stats.entries) {
                            slices[_labelForFolder(entry.key)] = entry.value['bytes'] ?? 0;
                          }
                          return Column(
                            children: [
                              SizedBox(height: 140, child: _storageChartFromMap(context, slices)),
                              const SizedBox(height: 12),
                              Row(children: [
                                Expanded(child: _storageChip(Icons.picture_as_pdf, 'PDFs', '${StorageService.formatBytes(stats['PDFs']?['bytes'] ?? 0)} • ${stats['PDFs']?['count'] ?? 0} files', Colors.red)),
                                const SizedBox(width: 8),
                                Expanded(child: _storageChip(Icons.table_chart, 'Sheets', '${StorageService.formatBytes(stats['Spreadsheets']?['bytes'] ?? 0)} • ${stats['Spreadsheets']?['count'] ?? 0} files', Colors.green)),
                                const SizedBox(width: 8),
                                Expanded(child: _storageChip(Icons.description, 'Docs', '${StorageService.formatBytes(stats['Documents']?['bytes'] ?? 0)} • ${stats['Documents']?['count'] ?? 0} files', Colors.blue)),
                              ]),
                              const SizedBox(height: 12),
                              Row(children: [
                                Expanded(child: _storageChip(Icons.slideshow, 'Presentations', '${StorageService.formatBytes(stats['Presentations']?['bytes'] ?? 0)} • ${stats['Presentations']?['count'] ?? 0} files', Colors.orange)),
                                const SizedBox(width: 8),
                                Expanded(child: _storageChip(Icons.code, 'Code', '${StorageService.formatBytes(stats['Code']?['bytes'] ?? 0)} • ${stats['Code']?['count'] ?? 0} files', Colors.purple)),
                                const SizedBox(width: 8),
                                Expanded(child: _storageChip(Icons.document_scanner, 'Scans', '${StorageService.formatBytes(stats['Scans']?['bytes'] ?? 0)} • ${stats['Scans']?['count'] ?? 0} files', Colors.cyan)),
                              ]),
                              const SizedBox(height: 12),
                              Row(children: [
                                Expanded(child: _storageChip(Icons.insert_drive_file, 'Other', '${StorageService.formatBytes(stats['Other']?['bytes'] ?? 0)} • ${stats['Other']?['count'] ?? 0} files', Colors.teal)),
                              ]),
                            ],
                          );
                        },
                      ),
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
                            const SizedBox(height: 12),
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
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _storageChartFromMap(BuildContext context, Map<String, int> slices) {
    final total = slices.values.fold<int>(0, (p, e) => p + e);
    if (total == 0) {
      return Center(child: Text('No documents', style: Theme.of(context).textTheme.bodySmall));
    }

    final sections = <PieChartSectionData>[];
    int idx = 0;
    slices.forEach((label, value) {
      final color = _colorForIndex(idx);
      final percent = value / total * 100;
      sections.add(PieChartSectionData(
        color: color,
        value: value.toDouble(),
        title: '${percent.toStringAsFixed(percent >= 10 ? 0 : 1)}%',
        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
        radius: 45,
        showTitle: percent >= 0.1, // hide extremely tiny labels
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 1),
      ));
      idx++;
    });

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: PieChart(PieChartData(sectionsSpace: 2, centerSpaceRadius: 35, sections: sections)),
        ),
      ),
    );
  }

  Color _colorForIndex(int idx) {
    const palette = [Colors.red, Colors.green, Colors.blue, Colors.orange, Colors.purple, Colors.teal, Colors.grey];
    return palette[idx % palette.length];
  }

  /// Compute category stats from recent files list (Hive data)
  /// Groups files by type and returns {category: {'bytes': X, 'count': Y}}
  Map<String, Map<String, int>> _computeCategoryStats(List<dynamic> files) {
    final stats = <String, Map<String, int>>{
      'PDFs': {'bytes': 0, 'count': 0},
      'Spreadsheets': {'bytes': 0, 'count': 0},
      'Documents': {'bytes': 0, 'count': 0},
      'Presentations': {'bytes': 0, 'count': 0},
      'Code': {'bytes': 0, 'count': 0},
      'Scans': {'bytes': 0, 'count': 0},
      'Other': {'bytes': 0, 'count': 0},
    };

    for (final file in files) {
      if (file.isDeleted) continue;
      final category = _categoryForFileType(file.fileType);
      stats[category]?['bytes'] = ((stats[category]?['bytes'] ?? 0) + file.fileSizeBytes).toInt();
      stats[category]?['count'] = ((stats[category]?['count'] ?? 0) + 1).toInt();
    }

    return stats;
  }

  String _categoryForFileType(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return 'PDFs';
      case 'xlsx':
      case 'xls':
      case 'ods':
      case 'csv':
        return 'Spreadsheets';
      case 'docx':
      case 'doc':
      case 'odt':
      case 'rtf':
      case 'txt':
      case 'ott':
      case 'epub':
        return 'Documents';
      case 'ppt':
      case 'pptx':
      case 'odp':
        return 'Presentations';
      case 'java':
      case 'py':
      case 'sh':
      case 'html':
      case 'md':
      case 'log':
      case 'json':
      case 'xml':
        return 'Code';
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'webp':
      case 'bmp':
        return 'Scans';
      default:
        return 'Other';
    }
  }

  String _labelForFolder(String folder) {
    switch (folder) {
      case StorageService.pdfsFolder:
        return 'PDFs';
      case StorageService.spreadsheetsFolder:
        return 'Sheets';
      case StorageService.documentsFolder:
        return 'Docs';
      case StorageService.codeFolder:
        return 'Code';
      case StorageService.presentationsFolder:
        return 'Presentations';
      case StorageService.imagesFolder:
        return 'Images';
      case StorageService.scansFolder:
        return 'Scans';
      case StorageService.trashFolder:
        return 'Trash';
      default:
        return folder;
    }
  }

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

  Widget _buildAutoUpdateRow(BuildContext context, WidgetRef ref, bool enabled) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
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
                  Icons.system_update_outlined,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Auto Update Check',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    Text(
                      enabled ? 'Enabled' : 'Disabled',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 48,
                child: Switch(
                  value: enabled,
                  onChanged: (value) {
                    ref.read(settingsMutatorProvider).updateAutoUpdateCheck(value);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showThemePicker(BuildContext context, WidgetRef ref, ThemeMode current) {
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

  Widget _buildCheckUpdatesRow(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _manualUpdateCheck(context, ref),
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
                  Icons.cloud_download_outlined,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Check for Updates',
                  style: Theme.of(context).textTheme.bodyLarge,
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

  void _manualUpdateCheck(BuildContext context, WidgetRef ref) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Checking for updates…'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
      final result = await UpdateCheckService.checkForUpdate(
        currentVersion: currentVersion,
      );

      if (!context.mounted) return;
      Navigator.pop(context); // dismiss loading

      if (result.errorOccurred) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No internet connection. Check your network and try again.')),
        );
      } else if (result.isUpdateAvailable) {
        UpdateAvailableSheet.show(
          context,
          currentVersion: currentVersion,
          stableVersion: result.stableVersion,
          stableUrl: result.stableUrl,
          betaVersion: result.betaVersion,
          betaUrl: result.betaUrl,
          hasStableUpdate: result.hasStableUpdate,
          hasBetaUpdate: result.hasBetaUpdate,
        );
      } else {
        _showUpToDateDialog(context, currentVersion, result.betaVersion);
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // dismiss loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No internet connection. Check your network and try again.')),
      );
    }
  }

  void _showUpToDateDialog(BuildContext context, String version, String? betaVersion) {
    final hasNewerBeta = betaVersion != null && UpdateCheckService.isNewerThan(version, betaVersion);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, size: 32, color: Colors.green),
            ),
            const SizedBox(height: 16),
            Text(
              'You\'re up to date',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'v$version is the latest version.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            if (hasNewerBeta) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.science_outlined, size: 16, color: Theme.of(context).colorScheme.tertiary),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Beta v$betaVersion available',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
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

  void _showVersionInfo(BuildContext context, PackageInfo packageInfo) {
    final appName = packageInfo.appName;
    final version = packageInfo.version;
    final buildNumber = packageInfo.buildNumber;
    final packageName = packageInfo.packageName;
    final versionString = 'Version $version (Build $buildNumber)';
    final isBeta = packageName.endsWith('.beta');
    final iconAsset = isBeta ? 'assets/fadocx_beta.png' : 'assets/fadocx.png';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  iconAsset,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              appName,
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
                versionString,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              packageName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(
                    text: '$appName v$version (Build $buildNumber)\nPackage: $packageName',
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
                'No advertisements. No tracking. No analytics. No crash logs. Zero telemetry.',
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
              _buildPolicyLink(context,
                icon: SimpleIcons.github,
                label: 'View Source Code',
                url: 'https://github.com/anonfaded/Fadocx',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPolicyLink(BuildContext context, {required IconData icon, required String label, required String url}) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (ctx) => _LinkSheet(
              title: label,
              value: url,
              onOpen: () {
                Navigator.pop(ctx);
                _openUrl(url);
              },
              onCopy: () {
                _copyToClipboard(context, url);
                Navigator.pop(ctx);
              },
            ),
          );
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.primary,
          side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  void _openUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Widget _patreonRow(BuildContext context) {
    const goldColor = Color(0xFFD4A017);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showPatreonSheet(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: goldColor.withValues(alpha: isDark ? 0.12 : 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: goldColor.withValues(alpha: isDark ? 0.3 : 0.25),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: goldColor.withValues(alpha: isDark ? 0.2 : 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  SimpleIcons.patreon,
                  size: 20,
                  color: goldColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Support Development',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: goldColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      'Unlock exclusive benefits',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: goldColor.withValues(alpha: 0.7),
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: goldColor.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Made with', style: TextStyle(color: muted, fontSize: 13)),
              const SizedBox(width: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Image.asset(
                  'assets/other_apps/palestine.png',
                  width: 18, height: 18,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 6),
              Text('at', style: TextStyle(color: muted, fontSize: 13)),
              const SizedBox(width: 6),
              SizedBox(
                width: 40, height: 18,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: Image.asset(
                    'assets/other_apps/fadseclab.png',
                    width: 40, height: 18,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text('in', style: TextStyle(color: muted, fontSize: 13)),
              const SizedBox(width: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Image.asset(
                  'assets/other_apps/pakistan.png',
                  width: 18, height: 18,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (ctx) => _LinkSheet(
                title: 'FadSec Lab',
                value: 'https://fadseclab.com',
                onOpen: () {
                  Navigator.pop(ctx);
                  _openUrl('https://fadseclab.com');
                },
                onCopy: () {
                  _copyToClipboard(context, 'https://fadseclab.com');
                  Navigator.pop(ctx);
                },
              ),
            );
          },
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              '© 2024 – 2026 FadSec Lab · GPLv3 · fadseclab.com',
              style: theme.textTheme.labelSmall?.copyWith(
                color: muted.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _otherAppCard(
    BuildContext context, {
    required String imageAsset,
    required String name,
    required String description,
    required List<IconData> platformIcons,
    required String url,
    Color? iconBgColor,
    String? platformNote,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBgColor ?? (isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.04)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                imageAsset,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    ...platformIcons.map((icon) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
                    )),
                    if (platformNote != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 2),
                        child: Text(
                          platformNote,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) => _LinkSheet(
                        title: name,
                        value: url,
                        onOpen: () {
                          Navigator.pop(ctx);
                          _openUrl(url);
                        },
                        onCopy: () {
                          _copyToClipboard(context, url);
                          Navigator.pop(ctx);
                        },
                      ),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Visit GitHub',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.open_in_new,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPatreonSheet(BuildContext context) {
    const patreonUrl = 'https://patreon.com/c/fadedx';
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: brightness == Brightness.dark
              ? const Color(0xFF1C1C1E)
              : const Color(0xFFF2F2F7),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        ),
        padding: EdgeInsets.only(
          top: 6,
          bottom: MediaQuery.of(context).padding.bottom + 6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 36,
              height: 5,
              margin: const EdgeInsets.only(top: 4, bottom: 12),
              decoration: BoxDecoration(
                color: brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            // Patreon icon + title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
              child: Column(
                children: [
                  Icon(SimpleIcons.patreon, size: 40, color: const Color(0xFFD4A017)),
                  const SizedBox(height: 12),
                  Text(
                    'Support Development',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Explanation
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                patreonDescription,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            // Visit Patreon
            _sheetAction(context,
              icon: SimpleIcons.patreon,
              label: 'Visit Patreon',
              onTap: () {
                Navigator.pop(ctx);
                _openUrl(patreonUrl);
              },
            ),
            const SizedBox(height: 8),
            // Copy link
            _sheetAction(context,
              icon: Icons.content_copy,
              label: 'Copy Link',
              onTap: () {
                _copyToClipboard(context, patreonUrl);
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // Helper for sheet action buttons (shared between sheets)
  Widget _sheetAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final brightness = Theme.of(context).brightness;
    final bgColor = brightness == Brightness.dark
        ? const Color(0xFF2C2C2E)
        : Colors.white;
    final textColor = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          color: bgColor,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 20, color: textColor),
                    const SizedBox(width: 10),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
  final bool isComingSoon;

  const _SettingsRow({
    required this.icon,
    required this.title,
    this.value,
    this.onTap,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    if (value != null && !isComingSoon) ...[
                      const SizedBox(height: 2),
                      Text(
                        value!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ],
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
                    'Coming Soon',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onTertiaryContainer,
                        ),
                  ),
                ),
              if (true && onTap != null && !isComingSoon)
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
    // If confirmText is empty, just directly navigate (like Trash)
    if (widget.confirmText.isEmpty) {
      widget.onConfirm();
      return;
    }

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

/// Reusable bottom sheet for a link with Copy and Open actions.
class _LinkSheet extends StatelessWidget {
  final String title;
  final String value;
  final VoidCallback onCopy;
  final VoidCallback onOpen;

  const _LinkSheet({
    required this.title,
    required this.value,
    required this.onCopy,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Container(
      decoration: BoxDecoration(
        color: brightness == Brightness.dark
            ? const Color(0xFF1C1C1E)
            : const Color(0xFFF2F2F7),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      ),
      padding: EdgeInsets.only(
        top: 6,
        bottom: MediaQuery.of(context).padding.bottom + 6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 5,
            margin: const EdgeInsets.only(top: 4, bottom: 12),
            decoration: BoxDecoration(
              color: brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(height: 16),
          _SheetAction(
            icon: Icons.content_copy,
            label: 'Copy',
            onTap: onCopy,
          ),
          const SizedBox(height: 8),
          _SheetAction(
            icon: Icons.open_in_browser,
            label: 'Open in Browser',
            onTap: onOpen,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final bgColor = brightness == Brightness.dark
        ? const Color(0xFF2C2C2E)
        : Colors.white;
    final textColor = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          color: bgColor,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 20, color: textColor),
                    const SizedBox(width: 10),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
