import 'dart:async';
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

class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen>
    with SingleTickerProviderStateMixin {
  late String _selectedCategory;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  late AnimationController _searchAnimController;
  Timer? _debounce;

  final Set<String> _selectedFiles = {};
  bool _isSelecting = false;
  String _sortBy = 'latest';

  @override
  void initState() {
    super.initState();
    _selectedCategory = 'all';
    _searchAnimController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchAnimController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _enterSearchMode() {
    setState(() => _isSearching = true);
    _searchAnimController.forward();
  }

  void _exitSearchMode() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _isSearching = false;
    });
    _searchAnimController.reverse();
    FocusScope.of(context).unfocus();
  }

  void _enterSelectionMode(String fileId) {
    setState(() {
      _isSelecting = true;
      _selectedFiles.add(fileId);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelecting = false;
      _selectedFiles.clear();
    });
  }

  void _toggleFileSelection(String fileId) {
    setState(() {
      if (_selectedFiles.contains(fileId)) {
        _selectedFiles.remove(fileId);
        if (_selectedFiles.isEmpty) {
          _isSelecting = false;
        }
      } else {
        _selectedFiles.add(fileId);
      }
    });
  }

  void _selectAll(List<RecentFile> files) {
    setState(() {
      if (_selectedFiles.length == files.length) {
        _selectedFiles.clear();
        _isSelecting = false;
      } else {
        _selectedFiles.clear();
        _selectedFiles.addAll(files.map((f) => f.id));
        _isSelecting = true;
      }
    });
  }

  Future<void> _deleteSelectedFiles() async {
    final count = _selectedFiles.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete selected?'),
        content: Text('Move $count ${count == 1 ? 'file' : 'files'} to trash? You can restore them later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ids = _selectedFiles.toList();
    for (final id in ids) {
      ref.read(recentFilesMutatorProvider).softDeleteFile(id);
    }
    _exitSelectionMode();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$count ${count == 1 ? 'item' : 'items'} moved to trash'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
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
    if (_isSelecting) {
      return _buildSelectionAppBar(context);
    }
    return _buildNormalAppBar(context);
  }

  Widget _buildNormalAppBar(BuildContext context) {
    return Row(
      children: [
        if (!_isSearching)
          const SizedBox(width: 40),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _isSearching
                ? Row(
                    key: const ValueKey('search'),
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, size: 20),
                        onPressed: _exitSearchMode,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                            minWidth: 36, minHeight: 36),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: 'Search library...',
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 8),
                          ),
                          style: Theme.of(context).textTheme.bodyMedium,
                          onChanged: (v) {
                            _debounce?.cancel();
                            _debounce = Timer(
                                const Duration(milliseconds: 200), () {
                              setState(() => _searchQuery = v);
                            });
                          },
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                              minWidth: 36, minHeight: 36),
                        ),
                    ],
                  )
                : Center(
                    key: const ValueKey('title'),
                    child: Text(
                      'Library',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
          ),
        ),
        if (!_isSearching)
          SizedBox(
            width: 40,
            child: IconButton(
              icon: const Icon(Icons.search, size: 20),
              onPressed: _enterSearchMode,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ),
      ],
    );
  }

  Widget _buildSelectionAppBar(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.close, size: 20),
          onPressed: _exitSelectionMode,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
        Expanded(
          child: Text(
            '${_selectedFiles.length} selected',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.select_all, size: 20),
          onPressed: () {
            final recentFiles = ref.read(recentFilesProvider);
            recentFiles.whenData((files) => _selectAll(files));
          },
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
          onPressed: _deleteSelectedFiles,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
      ],
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
      padding: const EdgeInsets.fromLTRB(16, 80, 16, 100),
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
                'No Library Items',
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
              Text('Error loading library: $error'),
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
    switch (_sortBy) {
      case 'latest':
        filteredFiles.sort((a, b) => b.dateOpened.compareTo(a.dateOpened));
      case 'oldest':
        filteredFiles.sort((a, b) => a.dateOpened.compareTo(b.dateOpened));
      case 'largest':
        filteredFiles.sort((a, b) => b.fileSizeBytes.compareTo(a.fileSizeBytes));
      case 'smallest':
        filteredFiles.sort((a, b) => a.fileSizeBytes.compareTo(b.fileSizeBytes));
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
        padding: const EdgeInsets.fromLTRB(12, 80, 12, 100),
        children: [
          SizedBox(
            height: 34,
            child: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.transparent,
                  Colors.white,
                  Colors.white,
                  Colors.transparent,
                ],
                stops: [0.0, 0.05, 0.95, 1.0],
              ).createShader(bounds),
              blendMode: BlendMode.dstIn,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildCategoryChip(context, 'all', 'All'),
                    _buildCategoryChip(context, 'pdf', 'PDF'),
                    _buildCategoryChip(context, 'documents', 'Docs'),
                    _buildCategoryChip(context, 'spreadsheets', 'Sheets'),
                    _buildCategoryChip(context, 'presentations', 'Slides'),
                    _buildCategoryChip(context, 'code', 'Code'),
                    _buildCategoryChip(context, 'other', 'Other'),
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 2),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        '${filteredFiles.length} ${_selectedCategory == 'all' ? 'items' : _selectedCategory}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color:
                                  Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      if (_isSelecting && filteredFiles.isNotEmpty)
                        GestureDetector(
                          onTap: () => _selectAll(filteredFiles),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Text(
                              _selectedFiles.length == filteredFiles.length
                                  ? 'Deselect all'
                                  : 'Select all',
                              style:
                                  Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color:
                                            Theme.of(context).colorScheme.primary,
                                      ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.sort, size: 20),
                  onPressed: () => _showSortSheet(context),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                IconButton(
                  icon:
                      Icon(isGridView ? Icons.grid_view : Icons.list, size: 20),
                  onPressed: () {
                    ref
                        .read(gridViewPreferenceProvider.notifier)
                        .toggleViewMode();
                  },
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ),

          if (filteredFiles.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'No ${_selectedCategory == 'all' ? 'items' : _selectedCategory} found',
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
                childAspectRatio: 0.714,
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

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'all':
        return Icons.apps;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'documents':
        return Icons.description;
      case 'spreadsheets':
        return Icons.table_chart;
      case 'presentations':
        return Icons.slideshow;
      case 'code':
        return Icons.code;
      default:
        return Icons.insert_drive_file;
    }
  }

  Widget _buildCategoryChip(
      BuildContext context, String category, String label) {
    final isActive = _selectedCategory == category;
    final icon = _getCategoryIcon(category);
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () => setState(() => _selectedCategory = category),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isActive
                ? Theme.of(context).colorScheme.secondaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isActive
                  ? Theme.of(context).colorScheme.onSecondaryContainer
                  : Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive
                      ? Theme.of(context).colorScheme.onSecondaryContainer
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileGridItem(BuildContext context, RecentFile file) {
    final isSelected = _selectedFiles.contains(file.id);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isSelecting
            ? () => _toggleFileSelection(file.id)
            : () => _openFile(file),
        onLongPress: () {
          if (!_isSelecting) {
            _enterSelectionMode(file.id);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              width: isSelected ? 2.0 : 1.0,
            ),
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.15)
                : Theme.of(context).colorScheme.surface,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    if (_isSelecting)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: AnimatedOpacity(
                          opacity: _isSelecting ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .surface
                                      .withValues(alpha: 0.8),
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            child: isSelected
                                ? Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary,
                                  )
                                : null,
                          ),
                        ),
                      ),
                    if (!file.isRead)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade600,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
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
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 10,
                                ),
                          ),
                          Row(
                            children: [
                              Icon(Icons.sd_card_outlined, size: 10, color: Theme.of(context).colorScheme.onSurfaceVariant),
                              const SizedBox(width: 3),
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
                        ],
                      ),
                    ),
                    if (!_isSelecting)
                      GestureDetector(
                        onTap: () =>
                            _showFileActionBottomSheet(context, file),
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Icon(Icons.more_vert,
                              size: 20,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
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
    final isSelected = _selectedFiles.contains(file.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isSelecting
              ? () => _toggleFileSelection(file.id)
              : () => _openFile(file),
          onLongPress: () {
            if (!_isSelecting) {
              _enterSelectionMode(file.id);
            }
          },
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
                width: isSelected ? 2.0 : 1.0,
              ),
              color: isSelected
                  ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.15)
                  : Theme.of(context).colorScheme.surface,
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  if (_isSelecting)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: AnimatedOpacity(
                        opacity: _isSelecting ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.outline,
                            ),
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check,
                                  size: 14,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimary,
                                )
                              : null,
                        ),
                      ),
                    ),
                  Consumer(
                    builder: (context, ref, _) {
                      final thumbnail = ref.watch(thumbnailProvider(file.id));

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
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${file.fileType.toUpperCase()} • ${file.formattedSize}',
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
                  if (!_isSelecting)
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
    if (!file.isRead) {
      ref.read(recentFilesMutatorProvider).markAsRead(file.id);
    }
    final encodedPath = Uri.encodeComponent(file.filePath);
    final encodedName = Uri.encodeComponent(file.fileName);
    context.push(
        '${RouteNames.viewer}?path=$encodedPath&name=$encodedName');
  }

  void _showFileActionBottomSheet(BuildContext context, RecentFile file) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Column(
                children: [
                  Text(
                    file.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'File actions and management',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _buildActionRow(
              icon: Icons.edit_outlined,
              title: 'Rename',
              iconColor: Theme.of(context).colorScheme.primary,
              subtitle: 'Change file name',
              onTap: () {
                Navigator.pop(ctx);
                _renameFile(file);
              },
            ),
            _buildActionRow(
              icon: Icons.content_copy,
              title: 'Duplicate',
              iconColor: Colors.blue,
              showChevron: true,
              onTap: () {
                Navigator.pop(ctx);
                _duplicateFile(file);
              },
            ),
            _buildActionRow(
              icon: Icons.save_alt,
              title: 'Export / Save As',
              iconColor: Colors.green,
              subtitle: 'Save a copy to Downloads',
              showChevron: true,
              onTap: () {
                Navigator.pop(ctx);
                _exportFile(file);
              },
            ),
            _buildActionRow(
              icon: Icons.info_outline,
              title: 'File info',
              iconColor: Colors.grey,
              onTap: () {
                Navigator.pop(ctx);
                _showFileInfoDialog(context, file);
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 6),
              child: Divider(height: 1, color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
            ),
            _buildActionRow(
              icon: Icons.delete_outline,
              title: 'Delete',
              iconColor: Colors.red,
              titleColor: Colors.red,
              onTap: () {
                Navigator.pop(ctx);
                _softDeleteFile(file);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow({
    required IconData icon,
    required String title,
    required Color iconColor,
    String? subtitle,
    bool showChevron = false,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: titleColor,
                      )),
                      if (subtitle != null)
                        Text(subtitle, style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        )),
                    ],
                  ),
                ),
                if (showChevron)
                  Icon(Icons.chevron_right, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _renameFile(RecentFile file) async {
    final dot = file.fileName.lastIndexOf('.');
    final baseName = dot > 0 ? file.fileName.substring(0, dot) : file.fileName;
    final extension = dot > 0 ? file.fileName.substring(dot) : '';
    final controller = TextEditingController(text: baseName);

    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename file'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'File name',
            suffixText: extension,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (newName == null || newName.trim().isEmpty || newName.trim() == baseName) return;

    final fullNewName = '${newName.trim()}$extension';
    final sourceFile = File(file.filePath);
    final dir = sourceFile.parent.path;
    final newPath = '$dir/$fullNewName';

    if (await File(newPath).exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A file with this name already exists')),
        );
      }
      return;
    }

    try {
      await sourceFile.rename(newPath);
      final mutator = ref.read(recentFilesMutatorProvider);
      final updatedFile = RecentFile(
        id: file.id,
        filePath: newPath,
        fileName: fullNewName,
        fileType: file.fileType,
        fileSizeBytes: file.fileSizeBytes,
        dateOpened: file.dateOpened,
        dateModified: await File(newPath).lastModified(),
        pagePosition: file.pagePosition,
        syncStatus: file.syncStatus,
        isRead: file.isRead,
      );
      await mutator.removeRecentFile(file.id);
      await mutator.addRecentFile(updatedFile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Renamed to $fullNewName')),
        );
      }
    } catch (e) {
      log.e('Failed to rename file', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to rename file')),
        );
      }
    }
  }

  Future<void> _exportFile(RecentFile file) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Export', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            ),
            _buildActionRow(
              icon: Icons.download,
              title: 'Save to Downloads',
              iconColor: Colors.green,
              subtitle: 'Download/Fadocx/${file.fileName}',
              onTap: () async {
                Navigator.pop(ctx);
                await _saveToDownloads(file);
              },
            ),
            _buildActionRow(
              icon: Icons.drive_file_rename_outline,
              title: 'Save with new name',
              iconColor: Colors.blue,
              subtitle: 'Save a copy with a different name',
              onTap: () async {
                Navigator.pop(ctx);
                await _saveToDownloadsWithName(file);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _saveToDownloads(RecentFile file) async {
    try {
      final downloadsDir = Directory('/storage/emulated/0/Download/Fadocx');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }
      final source = File(file.filePath);
      final dest = '${downloadsDir.path}/${file.fileName}';
      var finalDest = dest;
      var counter = 1;
      while (await File(finalDest).exists()) {
        final dot = file.fileName.lastIndexOf('.');
        final base = dot > 0 ? file.fileName.substring(0, dot) : file.fileName;
        final ext = dot > 0 ? file.fileName.substring(dot) : '';
        finalDest = '${downloadsDir.path}/$base ($counter)$ext';
        counter++;
      }
      await source.copy(finalDest);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved to Download/Fadocx/${finalDest.split('/').last}')),
        );
      }
    } catch (e) {
      log.e('Failed to export file', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to export file')),
        );
      }
    }
  }

  Future<void> _saveToDownloadsWithName(RecentFile file) async {
    final dot = file.fileName.lastIndexOf('.');
    final baseName = dot > 0 ? file.fileName.substring(0, dot) : file.fileName;
    final extension = dot > 0 ? file.fileName.substring(dot) : '';
    final controller = TextEditingController(text: '${baseName}_copy');

    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save with new name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'File name',
            suffixText: extension,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName == null || newName.trim().isEmpty) return;

    try {
      final downloadsDir = Directory('/storage/emulated/0/Download/Fadocx');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }
      final source = File(file.filePath);
      final dest = '${downloadsDir.path}/${newName.trim()}$extension';
      await source.copy(dest);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved to Download/Fadocx/${newName.trim()}$extension')),
        );
      }
    } catch (e) {
      log.e('Failed to export file', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to export file')),
        );
      }
    }
  }


  void _softDeleteFile(RecentFile file) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete file?'),
        content: Text('Move "${file.fileName}" to trash? You can restore it later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(recentFilesMutatorProvider).softDeleteFile(file.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${file.fileName} moved to trash'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
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

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(width: 40, height: 4, decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              )),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Sort by', style: Theme.of(ctx).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            ),
            _buildSortOption(ctx, 'latest', Icons.schedule, 'Latest first'),
            _buildSortOption(ctx, 'oldest', Icons.history, 'Oldest first'),
            _buildSortOption(ctx, 'largest', Icons.file_download, 'Largest size'),
            _buildSortOption(ctx, 'smallest', Icons.file_upload, 'Smallest size'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(BuildContext context, String value, IconData icon, String label) {
    final isActive = _sortBy == value;
    return ListTile(
      leading: Icon(icon, size: 20, color: isActive ? Theme.of(context).colorScheme.primary : null),
      title: Text(label, style: TextStyle(
        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
        color: isActive ? Theme.of(context).colorScheme.primary : null,
      )),
      trailing: isActive ? Icon(Icons.check, size: 18, color: Theme.of(context).colorScheme.primary) : null,
      onTap: () {
        setState(() => _sortBy = value);
        Navigator.pop(context);
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      dense: true,
    );
  }

  Widget _buildSkeletonLoader() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 80, 16, 100),
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
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant,
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
