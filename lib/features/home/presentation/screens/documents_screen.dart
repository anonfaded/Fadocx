import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fadocx/core/presentation/widgets/floating_dock_scaffold.dart';
import 'package:fadocx/features/settings/domain/entities/app_settings.dart';
import 'package:fadocx/features/settings/presentation/providers/settings_providers.dart';
import 'package:fadocx/config/routing/app_router.dart';
import 'package:fadocx/config/theme/app_theme.dart';
import 'package:logger/logger.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:fadocx/features/home/presentation/providers/thumbnail_provider.dart';

final log = Logger();

/// Documents screen - displays all imported documents with category filtering
class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  late String _selectedCategory;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedCategory = 'all';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    return Center(
      child: Text(
        'Documents',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
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
    List<RecentFile> filteredFiles = allFiles;
    if (_selectedCategory != 'all') {
      filteredFiles = allFiles
          .where(
              (f) => _getCategoryFromFileType(f.fileType) == _selectedCategory)
          .toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filteredFiles = filteredFiles
          .where((f) =>
              f.fileName.toLowerCase().contains(q) ||
              f.fileType.toLowerCase().contains(q))
          .toList();
    }

    return RefreshIndicator(
      onRefresh: () async {
        try {
          final hiveDatasource = ref.read(hiveDatasourceProvider);
          await hiveDatasource.clearThumbnailCache();
          log.i('Thumbnail cache cleared on refresh');
        } catch (e) {
          log.e('Error clearing thumbnail cache: $e');
        }
        ref.invalidate(recentFilesProvider);
        await ref.read(recentFilesProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 88, 12, 100),
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search documents...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),

          // Compact category chips
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCategoryChip(context, 'all', 'All', Icons.apps),
                _buildCategoryChip(context, 'pdf', 'PDF', Icons.picture_as_pdf),
                _buildCategoryChip(context, 'documents', 'Docs', Icons.description),
                _buildCategoryChip(context, 'spreadsheets', 'Sheets', Icons.table_chart),
                _buildCategoryChip(context, 'presentations', 'Slides', Icons.slideshow),
                _buildCategoryChip(context, 'code', 'Code', Icons.code),
                _buildCategoryChip(context, 'other', 'Other', Icons.file_present),
              ],
            ),
          ),

          // Count + view toggle
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filteredFiles.length} ${_selectedCategory == 'all' ? 'documents' : _selectedCategory}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                IconButton(
                  icon: Icon(isGridView ? Icons.grid_view : Icons.list, size: 20),
                  onPressed: () {
                    ref.read(gridViewPreferenceProvider.notifier).toggleViewMode();
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ),

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
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.62,
              ),
              itemCount: filteredFiles.length,
              itemBuilder: (context, index) =>
                  _buildFileGridItem(context, filteredFiles[index]),
            )
          else
            ...filteredFiles
                .map((f) => _buildFileListItem(context, f)),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(
      BuildContext context, String category, String label, IconData icon) {
    final isActive = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 12)),
        avatar: Icon(icon, size: 14),
        selected: isActive,
        onSelected: (selected) {
          setState(() => _selectedCategory = category);
        },
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        labelPadding: const EdgeInsets.only(left: 2, right: 6),
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
                                  alignment: Alignment.topCenter,
                                  width: double.infinity,
                                  height: double.infinity,
                                  filterQuality: FilterQuality.high,
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
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 4, 2, 4),
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
                                  fontSize: 10,
                                ),
                          ),
                          Text(
                            file.formattedSize,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  fontSize: 9,
                                ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showFileActionBottomSheet(context, file),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(Icons.more_vert,
                            size: 14,
                            color: Theme.of(context).colorScheme.onSurfaceVariant),
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

  Widget _buildFileListItem(BuildContext context, RecentFile file) {
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
                      final generation =
                          ref.watch(generateAndCacheThumbnailProvider(
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
                                alignment: Alignment.topCenter,
                                filterQuality: FilterQuality.high,
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
        color: Theme.of(context)
            .colorScheme
            .primaryContainer
            .withValues(alpha: 0.3),
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
      case 'java':
      case 'py':
      case 'sh':
      case 'html':
      case 'md':
      case 'json':
      case 'xml':
      case 'log':
        return 'code';
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
      case 'java':
      case 'py':
      case 'sh':
      case 'html':
      case 'md':
      case 'json':
      case 'xml':
      case 'log':
        iconData = Icons.code;
        color = AppColors.categoryDoc;
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
            // Duplicate action
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: const Icon(Icons.copy, size: 20),
                title: const Text('Duplicate'),
                onTap: () {
                  Navigator.pop(context);
                  _duplicateFile(file);
                },
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
            // File info action
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: const Icon(Icons.info_outline, size: 20),
                title: const Text('File info'),
                onTap: () {
                  Navigator.pop(context);
                  _showFileInfoDialog(context, file);
                },
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
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

  void _showFileInfoDialog(BuildContext context, RecentFile file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('File info'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Name: ${file.fileName}'),
              const SizedBox(height: 8),
              Text('Type: ${file.fileType.toUpperCase()}'),
              const SizedBox(height: 8),
              Text('Size: ${file.formattedSize}'),
              const SizedBox(height: 8),
              SelectableText('Location: ${file.filePath}'),
              const SizedBox(height: 8),
              Text('Date opened: ${_formatDateTime(file.dateOpened)}'),
              const SizedBox(height: 8),
              Text('Last modified: ${_formatDateTime(file.dateModified)}'),
              if (file.isDeleted) ...[
                const SizedBox(height: 8),
                Text(
                    'In trash: yes (deleted at: ${file.deletedAt != null ? _formatDateTime(file.deletedAt!) : 'unknown'})'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final text = _buildFileInfoText(file);
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              await Clipboard.setData(ClipboardData(text: text));
              navigator.pop();
              messenger.showSnackBar(
                const SnackBar(content: Text('File info copied')),
              );
            },
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final day = dt.day;
    final suffix = (day % 100 >= 11 && day % 100 <= 13)
        ? 'th'
        : (day % 10 == 1)
            ? 'st'
            : (day % 10 == 2)
                ? 'nd'
                : (day % 10 == 3)
                    ? 'rd'
                    : 'th';
    final datePart = DateFormat('MMMM yyyy').format(dt);
    final timePart = DateFormat('h:mm a').format(dt);
    return '$day$suffix $datePart, $timePart';
  }

  String _buildFileInfoText(RecentFile file) {
    final buffer = StringBuffer();
    buffer.writeln('Name: ${file.fileName}');
    buffer.writeln('Type: ${file.fileType.toUpperCase()}');
    buffer.writeln('Size: ${file.formattedSize}');
    buffer.writeln('Location: ${file.filePath}');
    buffer.writeln('Date opened: ${_formatDateTime(file.dateOpened)}');
    buffer.writeln('Last modified: ${_formatDateTime(file.dateModified)}');
    if (file.isDeleted) {
      buffer.writeln(
          'In trash: yes (deleted at: ${file.deletedAt != null ? _formatDateTime(file.deletedAt!) : 'unknown'})');
    }
    return buffer.toString();
  }

  Future<void> _duplicateFile(RecentFile file) async {
    try {
      final src = File(file.filePath);
      if (!await src.exists()) {
        throw Exception('Source file does not exist');
      }

      final dir = src.parent.path;
      final originalName = src.path.split('/').last;
      final dot = originalName.lastIndexOf('.');
      final base = dot > 0 ? originalName.substring(0, dot) : originalName;
      final ext = dot > 0 ? originalName.substring(dot) : '';

      String candidateName(String suffixIndex) => '$base$suffixIndex$ext';

      String suffix = ' (copy)';
      String newName = candidateName(suffix);
      int counter = 2;
      while (await File('$dir/$newName').exists()) {
        newName = candidateName(' (copy $counter)');
        counter++;
      }

      final destPath = '$dir/$newName';
      final copied = await src.copy(destPath);

      // Create recent file entry for the duplicated file
      final mutator = ref.read(recentFilesMutatorProvider);
      final newRecent = RecentFile(
        id: const Uuid().v4(),
        filePath: copied.path,
        fileName: newName,
        fileType: file.fileType,
        fileSizeBytes: await copied.length(),
        dateOpened: DateTime.now(),
        dateModified: await copied.lastModified(),
        pagePosition: 0,
        syncStatus: 'local',
        isDeleted: false,
      );

      await mutator.addRecentFile(newRecent);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Duplicated as $newName')),
        );
      }
    } catch (e) {
      log.e('Failed to duplicate file', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to duplicate file: $e')),
        );
      }
    }
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

      ],
    );
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
      case 'java':
      case 'py':
      case 'sh':
      case 'html':
      case 'md':
      case 'json':
      case 'xml':
      case 'log':
        iconData = Icons.code;
        color = AppColors.categoryDoc;
        break;
      default:
        iconData = Icons.insert_drive_file;
        color = AppColors.categoryDefault;
    }

    return Icon(iconData, color: color, size: 40);
  }
}

extension _DocumentsScreenStateExtension on _DocumentsScreenState {}
