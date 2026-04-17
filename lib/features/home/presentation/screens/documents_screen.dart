import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fadocx/core/presentation/widgets/floating_dock_scaffold.dart';
import 'package:fadocx/features/settings/domain/entities/app_settings.dart';
import 'package:fadocx/features/settings/presentation/providers/settings_providers.dart';
import 'package:fadocx/config/routing/app_router.dart';
import 'package:fadocx/config/theme/app_theme.dart';
import 'package:fadocx/core/utils/logger.dart';
import 'package:fadocx/features/home/presentation/providers/thumbnail_provider.dart';

/// Documents screen - displays all imported documents with category filtering
class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = 'all';
  }

  @override
  Widget build(BuildContext context) {
    return FloatingDockScaffold(
      appBarContent: _buildAppBarContent(context),
      currentRoute: RouteNames.documents,
      body: _buildBody(),
    );
  }

  Widget _buildAppBarContent(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: 'Documents'.split('').map((letter) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                letter,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final isGridView = ref.watch(gridViewPreferenceProvider);

    return Consumer(
      builder: (context, ref, _) {
        final recentFiles = ref.watch(recentFilesProvider);

        return recentFiles.when(
          data: (files) => files.isEmpty
              ? _buildEmptyState(context)
              : _buildDocumentsGrid(context, files, isGridView),
          error: (error, st) => _buildErrorState(context, error),
          loading: () => _buildSkeletonLoader(),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 88, 16, 100),
      children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 80,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 24),
              Text(
                'No Documents',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Browse and import documents to get started',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.folder_open),
                label: const Text('Browse Files'),
                onPressed: () {
                  log.i('Browse files from empty state');
                  context.push(RouteNames.browse);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 100),
      children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading documents: $error'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentsGrid(
      BuildContext context, List<RecentFile> allFiles, bool isGridView) {
    // Filter files by category
    List<RecentFile> filteredFiles = allFiles;
    if (_selectedCategory != 'all') {
      filteredFiles = allFiles
          .where(
              (f) => _getCategoryFromFileType(f.fileType) == _selectedCategory)
          .toList();
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Clear thumbnail cache for fresh thumbnails
        try {
          final hiveDatasource = ref.read(hiveDatasourceProvider);
          await hiveDatasource.clearThumbnailCache();
          log.i('📦 Thumbnail cache cleared on refresh');
        } catch (e) {
          log.e('Error clearing thumbnail cache: $e');
        }
        
        // Invalidate the provider to force a refresh
        ref.invalidate(recentFilesProvider);
        // Wait for the new data to be fetched
        await ref.read(recentFilesProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 88, 16, 100),
        children: [
          // Category filter tabs
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCategoryChip(context, 'all', 'All', Icons.apps),
                _buildCategoryChip(context, 'pdf', 'PDF', Icons.picture_as_pdf),
                _buildCategoryChip(
                    context, 'documents', 'Docs', Icons.description),
                _buildCategoryChip(
                    context, 'spreadsheets', 'Sheets', Icons.table_chart),
                _buildCategoryChip(
                    context, 'other', 'Other', Icons.file_present),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // View toggle + sort
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${filteredFiles.length} ${_selectedCategory == 'all' ? 'Documents' : 'Files'}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(isGridView ? Icons.grid_view : Icons.list),
                    onPressed: () {
                      ref
                          .read(gridViewPreferenceProvider.notifier)
                          .toggleViewMode();
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Documents grid/list
          if (filteredFiles.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'No ${_selectedCategory == 'all' ? 'documents' : _selectedCategory} found',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            )
          else if (isGridView)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.75,
              ),
              itemCount: filteredFiles.length,
              itemBuilder: (context, index) =>
                  _buildFileGridItem(context, filteredFiles[index]),
            )
          else
            Column(
              children: filteredFiles
                  .asMap()
                  .entries
                  .map((e) => _buildFileListItem(context, e.value, e.key))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(
      BuildContext context, String category, String label, IconData icon) {
    final isActive = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
        selected: isActive,
        onSelected: (selected) {
          setState(() => _selectedCategory = category);
        },
        backgroundColor: Colors.transparent,
        selectedColor:
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        side: BorderSide(
          color: isActive
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _buildFileGridItem(BuildContext context, RecentFile file) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openFile(file),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
            color: Theme.of(context).colorScheme.surface,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail section
              Expanded(
                child: Stack(
                  children: [
                    Consumer(
                      builder: (context, ref, _) {
                        final thumbnail = ref.watch(thumbnailProvider(file.id));
                        return thumbnail.when(
                          data: (bytes) {
                            if (bytes != null) {
                              return ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                                child: Image.memory(
                                  bytes,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              );
                            }
                            return _buildThumbnailPlaceholder(context, file);
                          },
                          loading: () =>
                              _buildThumbnailPlaceholder(context, file),
                          error: (err, st) =>
                              _buildThumbnailPlaceholder(context, file),
                        );
                      },
                    ),
                    // File type icon overlay (bottom right)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surface
                              .withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: _getFileIcon(file.fileType, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
              // Info and actions section
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            file.fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            file.formattedSize,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  fontSize: 11,
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.more_vert,
                          size: 18,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                      onPressed: () =>
                          _showFileActionBottomSheet(context, file),
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 40, minHeight: 40),
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

  Widget _buildFileListItem(BuildContext context, RecentFile file, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openFile(file),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.2),
              ),
              color: Theme.of(context).colorScheme.surface,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                   // Thumbnail preview
                   Consumer(
                     builder: (context, ref, _) {
                       final thumbnail = ref.watch(thumbnailProvider(file.id));
                       
                       // Watch generation to trigger and refresh when complete
                       // (result is unused intentionally - just triggers watching)
                       // ignore: unused_local_variable
                       final generation = ref.watch(generateAndCacheThumbnailProvider(
                         (
                           fileId: file.id,
                           filePath: file.filePath,
                           fileName: file.fileName,
                           fileType: file.fileType,
                         ),
                       ));
                      
                      return thumbnail.when(
                        data: (bytes) {
                          if (bytes != null) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                bytes,
                                width: 50,
                                height: 70,
                                fit: BoxFit.cover,
                              ),
                            );
                          }
                          return _buildListThumbnailPlaceholder(context, file);
                        },
                        loading: () =>
                            _buildListThumbnailPlaceholder(context, file),
                        error: (err, st) =>
                            _buildListThumbnailPlaceholder(context, file),
                      );
                    },
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
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${file.fileType.toUpperCase()} • ${file.formattedSize}',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                        ),
                      ],
                    ),
                  ),
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
      ),
    );
  }

  Widget _buildThumbnailPlaceholder(BuildContext context, RecentFile file) {
    return _ThumbnailPlaceholder(file: file);
  }

  Widget _buildListThumbnailPlaceholder(BuildContext context, RecentFile file) {
    return Container(
      width: 50,
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Center(
        child: _getFileIcon(file.fileType, size: 24),
      ),
    );
  }

  String _getCategoryFromFileType(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return 'pdf';
      case 'doc':
      case 'docx':
      case 'odt':
      case 'rtf':
      case 'txt':
        return 'documents';
      case 'xlsx':
      case 'xls':
      case 'ods':
      case 'csv':
        return 'spreadsheets';
      case 'ppt':
      case 'pptx':
      case 'odp':
        return 'presentations';
      default:
        return 'other';
    }
  }

  Widget _getFileIcon(String fileType, {double size = 24}) {
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

    return Icon(iconData, color: color, size: size);
  }

  void _openFile(RecentFile file) {
    log.i('Opening file: ${file.fileName}');
    context.push(
        '${RouteNames.viewer}?path=${file.filePath}&name=${file.fileName}');
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
            // Delete action
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: Colors.red, size: 20),
                title:
                    const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _softDeleteFile(file);
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

  void _softDeleteFile(RecentFile file) {
    ref.read(recentFilesMutatorProvider).softDeleteFile(file.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${file.fileName} moved to trash'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 88, 16, 100),
      children: List.generate(
        6,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 80,
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
}

/// Helper widget to trigger thumbnail generation once via side effect
class _ThumbnailPlaceholder extends ConsumerStatefulWidget {
  final RecentFile file;

  const _ThumbnailPlaceholder({required this.file});

  @override
  ConsumerState<_ThumbnailPlaceholder> createState() =>
      _ThumbnailPlaceholderState();
}

class _ThumbnailPlaceholderState extends ConsumerState<_ThumbnailPlaceholder> {
  @override
  void initState() {
    super.initState();
    // Skip thumbnail generation for presentation formats (not yet supported)
    final type = widget.file.fileType.toLowerCase();
    if (type == 'ppt' || type == 'pptx' || type == 'odp') {
      return;
    }
    // Trigger thumbnail generation once via side effect
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(generateAndCacheThumbnailProvider(
        (
          fileId: widget.file.id,
          filePath: widget.file.filePath,
          fileName: widget.file.fileName,
          fileType: widget.file.fileType,
        ),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final isPresentation = _isPresentationFormat(widget.file.fileType);

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            color: Theme.of(context)
                .colorScheme
                .primaryContainer
                .withValues(alpha: 0.3),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildThumbnailIcon(widget.file.fileType),
                const SizedBox(height: 8),
                Text(
                  widget.file.fileType.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
        // Coming Soon badge for presentations
        if (isPresentation)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                color: Colors.black.withValues(alpha: 0.4),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Coming Soon',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  bool _isPresentationFormat(String fileType) {
    final type = fileType.toLowerCase();
    return type == 'ppt' || type == 'pptx' || type == 'odp';
  }

  Widget _buildThumbnailIcon(String fileType) {
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

    return Icon(iconData, color: color, size: 40);
  }
}

extension _DocumentsScreenStateExtension on _DocumentsScreenState {}
