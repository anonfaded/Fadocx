import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fadocx/core/utils/logger.dart';
import 'package:fadocx/config/routing/app_router.dart';
import 'package:fadocx/features/home/presentation/widgets/bottom_nav_dock.dart';
import 'package:fadocx/features/settings/domain/entities/app_settings.dart';
import 'package:fadocx/features/settings/presentation/providers/settings_providers.dart';
import 'package:fadocx/l10n/app_localizations.dart';

/// Home screen - displays recent files and navigation
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    log.d('Building HomeScreen');

    final recentFiles = ref.watch(recentFilesProvider);

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
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context)!.appName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: recentFiles.when(
        data: (files) {
          log.d('Recent files loaded: ${files.length}');

          if (files.isEmpty) {
            return _buildEmptyState(context, ref);
          }

          return _buildRecentFilesList(context, files, ref);
        },
        loading: () {
          log.d('Loading recent files...');
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading recent files...'),
              ],
            ),
          );
        },
        error: (error, st) {
          log.e('Error loading recent files', error, st);
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(recentFilesProvider);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_circle),
        label: Text(AppLocalizations.of(context)!.openFile),
        onPressed: () {
          log.i('Open file button pressed');
          _showOpenFileDialog(context, ref);
        },
        tooltip: AppLocalizations.of(context)!.openFileTooltip,
      ),
      bottomNavigationBar: BottomNavDock(
        currentRoute: RouteNames.home,
      ),
    );
  }

  /// Build empty state UI
  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context)!.emptyTitle,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.emptyMessage,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FilledButton.tonalIcon(
            icon: const Icon(Icons.folder_open),
            label: Text(AppLocalizations.of(context)!.startBrowsing),
            onPressed: () {
              log.i('Start browsing pressed from empty state');
              _showOpenFileDialog(context, ref);
            },
          ),
        ],
      ),
    );
  }

  /// Build recent files list
  Widget _buildRecentFilesList(
      BuildContext context, List<RecentFile> files, WidgetRef ref) {
    return Column(
      children: [
        // BROWSE SECTION
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  log.i('Browse files button pressed');
                  _showOpenFileDialog(context, ref);
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.folder_open,
                        size: 24,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Browse Files',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Open documents from your device',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // SCANNER SECTION
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .tertiaryContainer
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .tertiary
                    .withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  log.i('Scan documents button pressed');
                  context.go('/scanner');
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.camera_alt_outlined,
                        size: 24,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Scan Documents',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Use camera to scan and extract text',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // RECENT FILES SECTION
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.recentFiles,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                '${files.length}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Consumer(
            builder: (context, ref, _) {
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: files.length,
                itemBuilder: (context, index) {
                  final file = files[index];
                  return _buildFileListTile(context, file, index, ref);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// Build individual file list tile with enhanced styling
  Widget _buildFileListTile(
    BuildContext context,
    RecentFile file,
    int index,
    WidgetRef ref,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            log.i('Tapped file: ${file.fileName}');
            _openFile(context, ref, file);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                width: 0.5,
              ),
              color: isDark ? Colors.grey[900] : Colors.grey[50],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: accentColor.withValues(alpha: 0.1),
                    ),
                    child: Center(
                      child: _getFileIcon(file.fileType, size: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          file.fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              file.fileType.toUpperCase(),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: accentColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.circle,
                                size: 3, color: Colors.grey[500]),
                            const SizedBox(width: 8),
                            Text(
                              file.formattedSize,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Opened ${_formatDate(file.dateOpened)}',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert,
                        size: 20, color: Colors.grey[600]),
                    itemBuilder: (context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem(
                        value: 'open',
                        child: Row(
                          children: [
                            Icon(Icons.open_in_new, size: 18),
                            SizedBox(width: 8),
                            Text('Open'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'remove',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Remove', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'open') {
                        log.i('Opening file: ${file.fileName}');
                        _openFile(context, ref, file);
                      } else if (value == 'remove') {
                        log.i('Removing file from recent: ${file.id}');
                        _removeFileWithRef(context, ref, file);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Get icon for file type with size support
  Widget _getFileIcon(String fileType, {double size = 24}) {
    IconData iconData;
    Color color;

    switch (fileType.toLowerCase()) {
      case 'pdf':
        iconData = Icons.picture_as_pdf;
        color = const Color(0xFFE53935);
        break;
      case 'docx':
      case 'doc':
        iconData = Icons.description;
        color = const Color(0xFF2196F3);
        break;
      case 'xlsx':
      case 'xls':
        iconData = Icons.table_chart;
        color = const Color(0xFF43A047);
        break;
      case 'csv':
        iconData = Icons.grid_3x3;
        color = const Color(0xFFFB8C00);
        break;
      case 'ppt':
      case 'pptx':
      case 'odp':
        iconData = Icons.slideshow;
        color = const Color(0xFFD32F2F);
        break;
      default:
        iconData = Icons.insert_drive_file;
        color = const Color(0xFF90A4AE);
    }

    return Icon(iconData, color: color, size: size);
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  /// Show file picker and handle file selection
  Future<void> _showOpenFileDialog(BuildContext context, WidgetRef ref) async {
    log.i('Opening file picker');

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'docx',
          'doc',
          'odt',
          'rtf',
          'xlsx',
          'xls',
          'ods',
          'csv',
          'odp',
          'ppt',
          'pptx',
          'txt'
        ],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final pickedFile = result.files.first;
        final filePath = pickedFile.path;
        final fileName = pickedFile.name;

        if (filePath != null && filePath.isNotEmpty) {
          log.i('✅ File selected: $fileName at $filePath');

          // Get file size and save to recent files
          int fileSizeBytes = pickedFile.size;
          try {
            final stat = await File(filePath).stat();
            fileSizeBytes = stat.size;
          } catch (_) {}

          final fileExtension = fileName.split('.').last.toLowerCase();
          final now = DateTime.now();
          final recentFile = RecentFile(
            id: filePath, // use path as stable ID to prevent duplicates
            filePath: filePath,
            fileName: fileName,
            fileType: fileExtension,
            fileSizeBytes: fileSizeBytes,
            dateOpened: now,
            dateModified: now,
            pagePosition: 0,
            syncStatus: 'local',
          );

          await ref.read(recentFilesMutatorProvider).addRecentFile(recentFile);
          ref.invalidate(recentFilesProvider);
          log.i('Recent file saved: $fileName');

          if (context.mounted) {
            _navigateToViewer(context, filePath, fileName);
          }
        } else {
          log.w('File path is null or empty');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not get file path')),
            );
          }
        }
      } else {
        log.d('File picker cancelled');
      }
    } catch (e, st) {
      log.e('Error opening file picker', e, st);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Navigate to viewer screen
  void _navigateToViewer(
      BuildContext context, String filePath, String fileName) {
    log.d('Navigating to viewer: $filePath');
    context.push('${RouteNames.viewer}?path=$filePath&name=$fileName');
  }

  /// Open file from recent files list — updates dateOpened
  void _openFile(BuildContext context, WidgetRef ref, RecentFile file) {
    log.i('Opening file: ${file.fileName} from path: ${file.filePath}');
    // Update dateOpened so it bubbles to the top of the list
    final updated = RecentFile(
      id: file.id,
      filePath: file.filePath,
      fileName: file.fileName,
      fileType: file.fileType,
      fileSizeBytes: file.fileSizeBytes,
      dateOpened: DateTime.now(),
      dateModified: file.dateModified,
      pagePosition: file.pagePosition,
      syncedAt: file.syncedAt,
      syncStatus: file.syncStatus,
    );
    ref.read(recentFilesMutatorProvider).addRecentFile(updated);
    _navigateToViewer(context, file.filePath, file.fileName);
  }

  /// Remove file from recent files (with WidgetRef)
  Future<void> _removeFileWithRef(
    BuildContext context,
    WidgetRef ref,
    RecentFile file,
  ) async {
    try {
      log.i('Removing file from recent: ${file.id}');

      // Call the mutator to delete the file
      await ref.read(recentFilesMutatorProvider).removeRecentFile(file.id);

      // Refresh the recent files list
      ref.invalidate(recentFilesProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${file.fileName} removed from recent files'),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      log.i('✅ File removed successfully: ${file.id}');
    } catch (e, st) {
      log.e('Error removing file', e, st);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
