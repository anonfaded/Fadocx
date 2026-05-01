import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fadocx/config/routing/app_router.dart';
import 'package:fadocx/config/theme/app_theme.dart';
import 'package:fadocx/core/presentation/widgets/floating_dock_scaffold.dart';
import 'package:fadocx/features/settings/domain/entities/app_settings.dart';
import 'package:fadocx/features/settings/presentation/providers/settings_providers.dart';
import 'package:fadocx/l10n/app_localizations.dart';
import 'package:logger/logger.dart';

final log = Logger();

/// Trash screen - displays deleted/soft-deleted files
class TrashScreen extends ConsumerStatefulWidget {
  const TrashScreen({super.key});

  @override
  ConsumerState<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends ConsumerState<TrashScreen> {
  final Set<String> _selectedFiles = {};
  bool _isSelectionMode = false;

  @override
  Widget build(BuildContext context) {
    return FloatingDockScaffold(
      appBarContent: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Back button on the left
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => context.pop(),
                tooltip: 'Back',
                iconSize: 20,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
            ),
            // Centered title
            Center(
              child: Text(
                AppLocalizations.of(context)!.trashTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
      currentRoute: RouteNames.trash,
      showBottomDock: false,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final trashFiles = ref.watch(trashFilesProvider);

    return trashFiles.when(
      data: (files) => RefreshIndicator(
        onRefresh: () async {
          log.d('Manual refresh of trash');
          ref.invalidate(trashFilesProvider);
          // Wait for the provider to be refreshed
          await ref.read(trashFilesProvider.future);
        },
        child: files.isEmpty
            ? _buildEmptyState(context)
            : _buildTrashList(context, files),
      ),
      error: (error, st) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(trashFilesProvider);
          await ref.read(trashFilesProvider.future);
        },
        child: _buildErrorState(context, error),
      ),
      loading: () => _buildSkeletonLoader(),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delete_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.trashEmpty,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.trashEmptySubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.trashErrorLoading,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrashList(BuildContext context, List<RecentFile> files) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 88, 16, 100),
      children: [
        // Header with selection toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _isSelectionMode
                  ? AppLocalizations.of(context)!.trashFilesSelected(files.length)
                  : '${files.length} ${AppLocalizations.of(context)!.trashFilesLabel}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (_isSelectionMode)
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedFiles.clear();
                        _isSelectionMode = false;
                      });
                    },
                    child: Text(AppLocalizations.of(context)!.cancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.delete_forever),
                    label: Text(AppLocalizations.of(context)!.trashDeletePermanently),
                    onPressed: _selectedFiles.isEmpty
                        ? null
                        : () => _showPermanentDeleteConfirmation(context),
                  ),
                ],
              )
            else
              FilledButton.tonal(
                onPressed: () {
                  setState(() {
                    _isSelectionMode = true;
                  });
                },
                child: const Text('Select'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        // Trash files list
        Column(
          children: files.asMap().entries.map((entry) {
            final index = entry.key;
            final file = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < files.length - 1 ? 8 : 0,
              ),
              child: _buildTrashItem(context, file),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTrashItem(BuildContext context, RecentFile file) {
    final isSelected = _selectedFiles.contains(file.id);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isSelectionMode
            ? () {
                setState(() {
                  if (isSelected) {
                    _selectedFiles.remove(file.id);
                  } else {
                    _selectedFiles.add(file.id);
                  }
                  if (_selectedFiles.isEmpty) {
                    _isSelectionMode = false;
                  }
                });
              }
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                : Theme.of(context).colorScheme.surface,
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                if (_isSelectionMode)
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  )
                else
                  const SizedBox(width: 0),
                if (_isSelectionMode) const SizedBox(width: 8),
                // File icon
                _buildFileIcon(file.fileType),
                const SizedBox(width: 8),
                // File info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${file.fileType.toUpperCase()} • ${file.formattedSize}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                // Actions - only visible when not in selection mode
                if (!_isSelectionMode)
                  IconButton(
                    icon: Icon(Icons.more_vert,
                        size: 18,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                    onPressed: () => _showFileActionBottomSheet(context, file),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFileIcon(String fileType) {
    IconData iconData;
    Color color;

    switch (fileType.toLowerCase()) {
      case 'pdf':
        iconData = Icons.picture_as_pdf;
        color = AppColors.categoryPdf;
        break;
      case 'docx':
      case 'doc':
      case 'odt':
      case 'rtf':
      case 'txt':
        iconData = Icons.description;
        color = AppColors.categoryDoc;
        break;
      case 'xlsx':
      case 'xls':
      case 'ods':
      case 'csv':
        iconData = Icons.table_chart;
        color = AppColors.categorySheet;
        break;
      case 'ppt':
      case 'pptx':
      case 'odp':
        iconData = Icons.slideshow;
        color = AppColors.categorySlide;
        break;
      default:
        iconData = Icons.insert_drive_file;
        color = AppColors.categoryDefault;
    }

    return Icon(iconData, color: color, size: 24);
  }

  Widget _buildSkeletonLoader() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 88, 16, 100),
      children: List.generate(
        6,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _restoreFile(String fileId) async {
    final mutator = ref.read(recentFilesMutatorProvider);
    await mutator.restoreFromTrash(fileId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.trashFileRestored)),
      );
    }
  }

  void _showFileActionBottomSheet(BuildContext context, RecentFile file) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Restore action
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.restore, size: 20),
                title: Text(AppLocalizations.of(context)!.restore),
                onTap: () {
                  Navigator.pop(context);
                  _restoreFile(file.id);
                },
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
            // Delete permanently action
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.delete_forever,
                    color: Colors.red, size: 20),
                title: Text(AppLocalizations.of(context)!.trashDeletePermanently,
                    style: const TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showPermanentDeleteConfirmation(context, file);
                },
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showPermanentDeleteConfirmation(BuildContext context,
      [RecentFile? singleFile]) {
    final filesCount = singleFile != null ? 1 : _selectedFiles.length;
    String confirmText = '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.trashDeletePermanentlyConfirm),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.trashDeletePermanentlyMessage(filesCount),
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.trashDeleteTypeConfirm,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 8),
                TextField(
                  onChanged: (value) {
                    setState(() {
                      confirmText = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.trashDeleteHint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.delete_forever),
                label: Text(AppLocalizations.of(context)!.trashDeletePermanently),
                onPressed: confirmText == 'DELETE'
                    ? () async {
                        Navigator.pop(context);
                        await _permanentlyDeleteFiles(singleFile);
                      }
                    : null,
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _permanentlyDeleteFiles(RecentFile? singleFile) async {
    final mutator = ref.read(recentFilesMutatorProvider);
    final fileIds =
        singleFile != null ? [singleFile.id] : _selectedFiles.toList();

    for (final fileId in fileIds) {
      await mutator.permanentlyDeleteFile(fileId);
    }

    if (mounted) {
      setState(() {
        _selectedFiles.clear();
        _isSelectionMode = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.trashFilesPermanentlyDeleted(fileIds.length),
          ),
        ),
      );
    }
  }
}
