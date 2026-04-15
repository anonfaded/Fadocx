import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fadocx/core/utils/logger.dart';
import 'package:fadocx/config/routing/app_router.dart';
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
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.appName),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: AppLocalizations.of(context)!.settings,
            onPressed: () {
              log.d('Opening settings');
              context.go(RouteNames.settings);
            },
          ),
        ],
      ),
      body: recentFiles.when(
        data: (files) {
          log.d('Recent files loaded: ${files.length}');

          if (files.isEmpty) {
            return _buildEmptyState(context);
          }

          return _buildRecentFilesList(context, files);
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
          _showOpenFileDialog(context);
        },
        tooltip: AppLocalizations.of(context)!.openFileTooltip,
      ),
    );
  }

  /// Build empty state UI
  Widget _buildEmptyState(BuildContext context) {
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
              _showOpenFileDialog(context);
            },
          ),
        ],
      ),
    );
  }

  /// Build recent files list
  Widget _buildRecentFilesList(BuildContext context, List<RecentFile> files) {
    return Column(
      children: [
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

  /// Build individual file list tile
  Widget _buildFileListTile(
    BuildContext context,
    RecentFile file,
    int index,
    WidgetRef ref,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: _getFileIcon(file.fileType),
        title: Text(
          file.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${file.fileType.toUpperCase()} • ${file.formattedSize}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Opened: ${_formatDate(file.dateOpened)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          itemBuilder: (context) => <PopupMenuEntry<String>>[
            const PopupMenuItem(
              value: 'open',
              child: Row(
                children: [
                  Icon(Icons.open_in_new, size: 20),
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
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Remove', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'open') {
              log.i('Opening file: ${file.fileName}');
              _openFile(context, file);
            } else if (value == 'remove') {
              log.i('Removing file from recent: ${file.id}');
              _removeFileWithRef(context, ref, file);
            }
          },
        ),
        onTap: () {
          log.i('Tapped file: ${file.fileName}');
          _openFile(context, file);
        },
      ),
    );
  }

  /// Get icon for file type
  Widget _getFileIcon(String fileType) {
    IconData iconData;
    Color color;

    switch (fileType.toLowerCase()) {
      case 'pdf':
        iconData = Icons.picture_as_pdf;
        color = const Color(0xFFE53935);
        break;
      case 'docx':
        iconData = Icons.description;
        color = const Color(0xFF2196F3);
        break;
      case 'xlsx':
        iconData = Icons.table_chart;
        color = const Color(0xFF43A047);
        break;
      case 'csv':
        iconData = Icons.grid_3x3;
        color = const Color(0xFFFB8C00);
        break;
      default:
        iconData = Icons.insert_drive_file;
        color = const Color(0xFF90A4AE);
    }

    return Icon(iconData, color: color);
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
  Future<void> _showOpenFileDialog(BuildContext context) async {
    log.i('Opening file picker');
    
    try {
      // Use FilePicker to select files from device  
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'xlsx', 'csv', 'txt'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final filePath = file.path;
        final fileName = file.name;
        
        if (filePath != null && filePath.isNotEmpty) {
          log.i('✅ File selected: $fileName');
          log.d('File path: $filePath');
          
          if (context.mounted) {
            // Navigate to viewer with selected file
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
  void _navigateToViewer(BuildContext context, String filePath, String fileName) {
    log.d('Navigating to viewer: $filePath');
    context.push('${RouteNames.viewer}?path=$filePath&name=$fileName');
  }

  /// Open file from recent files list
  void _openFile(BuildContext context, RecentFile file) {
    log.i('Opening file: ${file.fileName} from path: ${file.filePath}');
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
