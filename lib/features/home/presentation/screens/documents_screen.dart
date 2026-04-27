import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fadocx/core/presentation/widgets/floating_dock_scaffold.dart';
import 'package:fadocx/features/settings/domain/entities/app_settings.dart';
import 'package:fadocx/features/settings/presentation/providers/settings_providers.dart';
import 'package:fadocx/config/routing/app_router.dart';
import 'package:logger/logger.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fadocx/features/home/presentation/providers/thumbnail_provider.dart';
import 'package:fadocx/features/home/presentation/widgets/file_action_bottom_sheet.dart';

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
  
  // For scroll-aware shader (industry standard pattern)
  final ScrollController _chipsScrollController = ScrollController();
  late ValueNotifier<double> _leftFadeOpacity;
  late ValueNotifier<double> _rightFadeOpacity;

  @override
  void initState() {
    super.initState();
    _selectedCategory = 'all';
    _searchAnimController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    
    // Initialize ValueNotifiers for scroll-aware fades (industry standard)
    _leftFadeOpacity = ValueNotifier(0.0);
    _rightFadeOpacity = ValueNotifier(1.0);
    
    // Listen to chips scroll - NO setState, just update ValueNotifiers
    _chipsScrollController.addListener(_updateChipsFadeOpacity);
  }
  
  void _updateChipsFadeOpacity() {
    final position = _chipsScrollController.position;
    final hasScroll = position.maxScrollExtent > 0;
    
    if (!hasScroll) {
      // No scrolling needed - hide both fades
      _leftFadeOpacity.value = 0.0;
      _rightFadeOpacity.value = 0.0;
      return;
    }
    
    // Smooth fade based on scroll distance (60px fade zone)
    final leftFade = (position.pixels / 60).clamp(0.0, 1.0);
    final rightFade = ((position.maxScrollExtent - position.pixels) / 60).clamp(0.0, 1.0);
    
    _leftFadeOpacity.value = leftFade;
    _rightFadeOpacity.value = rightFade;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchAnimController.dispose();
    _chipsScrollController.dispose();
    _leftFadeOpacity.dispose();
    _rightFadeOpacity.dispose();
    _debounce?.cancel();
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

  Widget _buildBody() {
    final recentFiles = ref.watch(recentFilesProvider);
    final isGridView = ref.watch(gridViewPreferenceProvider);

    return recentFiles.when(
      data: (files) => _buildDocumentsGrid(context, files, isGridView),
      error: (error, st) => _buildErrorState(context, error),
      loading: () => _buildSkeletonLoader(),
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
          IconButton(
            icon: const Icon(Icons.search, size: 20),
            onPressed: _enterSearchMode,
            padding: EdgeInsets.zero,
            constraints:
                const BoxConstraints(minWidth: 36, minHeight: 36),
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
        const SizedBox(width: 4),
        Text(
          '${_selectedFiles.length} selected',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 20),
          onPressed: _selectedFiles.isNotEmpty
              ? () => _deleteSelectedFiles()
              : null,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
      ],
    );
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

  // Helper method for iOS-style pill buttons
  Widget _buildPillButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }

  // Helper method to get time ago string
  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return '$mins ${mins == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
}
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
    // Filter files based on category and search
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

    // Sort files
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

    // Build category counts for dynamic sorting
    final categoryCounts = _buildCategoryCounts(allFiles);
    final sortedCategories = _getSortedCategories(categoryCounts);

    // Add top padding to account for AppBar (40px) + status bar
    final mediaQuery = MediaQuery.of(context);
    final topPadding = 40.0 + mediaQuery.padding.top;

    return Column(
      children: [
        // Top padding spacer to prevent content from hiding behind AppBar
        SizedBox(height: topPadding),

        // Category chips - fixed at top, scrollable horizontally
        // Using Stack-based gradient overlays (TikTok pattern) for better performance
        Container(
          color: Theme.of(context).colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: SizedBox(
              height: 36,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Scrollable chips list
                  ListView(
                    controller: _chipsScrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildCategoryChip(context, 'all', 'All', categoryCounts['all'] ?? 0),
                      ...sortedCategories.map((category) {
                        final label = _getCategoryLabel(category);
                        final count = categoryCounts[category] ?? 0;
                        return _buildCategoryChip(context, category, label, count);
                      }),
                    ],
                  ),
                  
                  // Left fade gradient (appears on scroll)
                  ValueListenableBuilder<double>(
                    valueListenable: _leftFadeOpacity,
                    builder: (context, opacity, _) {
                      return Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: 40,
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Theme.of(context).colorScheme.surface.withValues(alpha: opacity),
                                  Theme.of(context).colorScheme.surface.withValues(alpha: 0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  // Right fade gradient (appears on scroll)
                  ValueListenableBuilder<double>(
                    valueListenable: _rightFadeOpacity,
                    builder: (context, opacity, _) {
                      return Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        width: 40,
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerRight,
                                end: Alignment.centerLeft,
                                colors: [
                                  Theme.of(context).colorScheme.surface.withValues(alpha: opacity),
                                  Theme.of(context).colorScheme.surface.withValues(alpha: 0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),

        // Sort/Grid controls row - fixed at top (NOT scrollable)
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${filteredFiles.length} ${_selectedCategory == 'all' ? 'items' : _selectedCategory}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                ),
              ),
              if (_isSelecting && filteredFiles.isNotEmpty)
                GestureDetector(
                  onTap: () => _selectAll(filteredFiles),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Text(
                      _selectedFiles.length == filteredFiles.length
                          ? 'Deselect all'
                          : 'Select all',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 12,
                          ),
                    ),
                  ),
                ),
              // iOS-style pill for sort and grid toggle
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPillButton(
                      context,
                      icon: Icons.sort,
                      onPressed: () => _showSortSheet(context),
                    ),
                    Container(
                      width: 1,
                      height: 20,
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                    ),
                    _buildPillButton(
                      context,
                      icon: isGridView ? Icons.grid_view : Icons.list,
                      onPressed: () {
                        ref
                            .read(gridViewPreferenceProvider.notifier)
                            .toggleViewMode();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Scrollable content area - using CustomScrollView for proper lazy loading
        Expanded(
          child: RefreshIndicator(
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
            child: filteredFiles.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No ${_selectedCategory == 'all' ? 'items' : _selectedCategory} found',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Try adjusting your search or filters',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                              ),
                        ),
                      ],
                    ),
                  )
                : isGridView
                    ? CustomScrollView(
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
                            sliver: SliverGrid(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                                childAspectRatio: 0.714,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) =>
                                    _buildFileGridItem(context, filteredFiles[index]),
                                childCount: filteredFiles.length,
                              ),
                            ),
                          ),
                        ],
                      )
                    : CustomScrollView(
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) =>
                                    _buildFileListItem(context, filteredFiles[index]),
                                childCount: filteredFiles.length,
                              ),
                            ),
                          ),
                        ],
                      ),
          ),
        ),
      ],
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
      case 'scans':
        return Icons.document_scanner;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'pdf':
        return 'PDF';
      case 'documents':
        return 'Docs';
      case 'spreadsheets':
        return 'Sheets';
      case 'presentations':
        return 'Slides';
      case 'code':
        return 'Code';
      case 'scans':
        return 'Scans';
      case 'other':
        return 'Other';
      default:
        return category;
    }
  }

  Map<String, int> _buildCategoryCounts(List<RecentFile> files) {
    final counts = <String, int>{
      'all': files.length,
      'pdf': 0,
      'documents': 0,
      'spreadsheets': 0,
      'presentations': 0,
      'code': 0,
      'scans': 0,
      'other': 0,
    };

    for (final file in files) {
      final category = _getCategoryFromFileType(file.fileType);
      counts[category] = (counts[category] ?? 0) + 1;
    }

    return counts;
  }

  List<String> _getSortedCategories(Map<String, int> counts) {
    final categories = [
      'pdf',
      'documents',
      'spreadsheets',
      'presentations',
      'code',
      'scans',
      'other',
    ];

    // Sort by count descending, then by category order
    categories.sort((a, b) {
      final countDiff = (counts[b] ?? 0).compareTo(counts[a] ?? 0);
      if (countDiff != 0) return countDiff;
      return categories.indexOf(a).compareTo(categories.indexOf(b));
    });

    // Filter out empty categories
    return categories.where((cat) => (counts[cat] ?? 0) > 0).toList();
  }

  Widget _buildCategoryChip(
      BuildContext context, String category, String label, int count) {
    final isActive = _selectedCategory == category;
    final icon = _getCategoryIcon(category);
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedCategory = category),
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isActive
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              border: isActive
                  ? null
                  : Border.all(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                      width: 0.5,
                    ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: isActive
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.15)
                        : Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
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
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.sd_card_outlined, size: 9, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
                              const SizedBox(width: 2),
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
                              const SizedBox(width: 6),
                              Container(
                                width: 3,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                              ),
                               const SizedBox(width: 6),
                               Flexible(
                                 child: Row(
                                   mainAxisSize: MainAxisSize.min,
                                   children: [
                                     Icon(Icons.schedule_outlined, size: 9, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
                                     const SizedBox(width: 2),
                                     Flexible(
                                       child: Text(
                                         _getTimeAgo(file.dateOpened),
                                         style: Theme.of(context)
                                             .textTheme
                                             .labelSmall
                                             ?.copyWith(
                                               color: Theme.of(context)
                                                   .colorScheme
                                                   .onSurfaceVariant,
                                               fontSize: 9,
                                             ),
                                         overflow: TextOverflow.ellipsis,
                                       ),
                                     ),
                                   ],
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
                        child: Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                           child: Icon(Icons.more_vert,
                               size: 18,
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
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                          extractedText: file.extractedText,
                          brightness: Theme.of(context).brightness,
                        ),
                      ));

                       return thumbnail.when(
                         data: (bytes) {
                           if (bytes != null) {
                             return _buildRotatedStackedThumbnail(
                               Image.memory(
                                 bytes,
                                 width: 55,
                                 height: 76,
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
                   const SizedBox(width: 8),
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
                         Row(
                           children: [
                             Icon(
                               Icons.storage,
                               size: 10,
                               color: Theme.of(context).colorScheme.onSurfaceVariant,
                             ),
                             const SizedBox(width: 2),
                             Text(
                               file.formattedSize,
                               style: Theme.of(context)
                                   .textTheme
                                   .labelSmall
                                   ?.copyWith(
                                     color: Theme.of(context)
                                         .colorScheme
                                         .onSurfaceVariant,
                                     fontSize: 10,
                                   ),
                             ),
                             const SizedBox(width: 8),
                             Icon(
                               Icons.schedule_outlined,
                               size: 10,
                               color: Theme.of(context).colorScheme.onSurfaceVariant,
                             ),
                             const SizedBox(width: 2),
                             Text(
                               _getTimeAgo(file.dateOpened),
                               style: Theme.of(context)
                                   .textTheme
                                   .labelSmall
                                   ?.copyWith(
                                     color: Theme.of(context)
                                         .colorScheme
                                         .onSurfaceVariant,
                                     fontSize: 10,
                                   ),
                             ),
                           ],
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

  /// Build rotated stacked thumbnail for library list items
  Widget _buildRotatedStackedThumbnail(Widget child) {
    const double rotationAngle = -0.15; // ≈ -8.6 degrees (left tilt)
    const double layerOffset = 3.0;
    const double layerScale = 0.96;
    const double thumbnailWidth = 55.0;
    const double thumbnailHeight = 76.0;

    return SizedBox(
      width: thumbnailWidth,
      height: thumbnailHeight,
      child: Stack(
        alignment: Alignment.bottomCenter, // Anchor at BOTTOM
        clipBehavior: Clip.hardEdge, // Clip bottom overflow
        children: [
          // Back layer
          Transform.translate(
            offset: const Offset(layerOffset * 2, layerOffset * 2),
            child: Transform.rotate(
              angle: rotationAngle * 0.8,
              child: Container(
                width: thumbnailWidth * layerScale,
                height: thumbnailHeight * layerScale,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.black.withValues(alpha: 0.02),
                ),
              ),
            ),
          ),
          // Middle layer
          Transform.translate(
            offset: const Offset(layerOffset, layerOffset),
            child: Transform.rotate(
              angle: rotationAngle * 0.4,
              child: Container(
                width: thumbnailWidth * (layerScale + 0.02),
                height: thumbnailHeight * (layerScale + 0.02),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.black.withValues(alpha: 0.01),
                ),
              ),
            ),
          ),
          // Front layer
          Transform.rotate(
            angle: rotationAngle,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: child,
              ),
            ),
          ),
        ],
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
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'webp':
        return 'scans';
      default:
        return 'other';
    }
  }

  Widget _getFileIcon(String fileType, {double size = 24}) {
    final theme = Theme.of(context);
    IconData iconData;
    Color color;

    switch (fileType.toLowerCase()) {
      case 'pdf':
        iconData = Icons.picture_as_pdf;
        color = theme.colorScheme.error;
        break;
      case 'docx':
      case 'doc':
      case 'odt':
      case 'rtf':
      case 'txt':
        iconData = Icons.description;
        color = theme.colorScheme.primary;
        break;
      case 'xlsx':
      case 'xls':
      case 'ods':
      case 'csv':
        iconData = Icons.table_chart;
        color = theme.colorScheme.tertiary;
        break;
      case 'ppt':
      case 'pptx':
      case 'odp':
        iconData = Icons.slideshow;
        color = theme.colorScheme.error;
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
        color = theme.colorScheme.primary;
        break;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'webp':
        iconData = Icons.document_scanner;
        color = theme.colorScheme.secondary;
        break;
      default:
        iconData = Icons.insert_drive_file;
        color = theme.colorScheme.onSurfaceVariant;
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
    showFileActionBottomSheet(
      context: context,
      file: file,
      callbacks: FileActionCallbacks(
        onRename: () => _renameFile(file),
        onDuplicate: () => _duplicateFile(file),
        onExport: () => _exportFile(file),
        onCopyText: file.extractedText != null && file.extractedText!.isNotEmpty
            ? () => _copyExtractedText(file)
            : null,
        onConvert: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Convert feature coming soon!')),
          );
        },
        onUpload: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('FadDrive coming soon!')),
          );
        },
        onFileInfo: () => _showFileInfoDialog(context, file),
        onDelete: () => _softDeleteFile(file),
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
        child: SingleChildScrollView(
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
            _buildExportActionRow(
              icon: Icons.download,
              title: 'Save to Downloads',
              iconColor: Colors.green,
              subtitle: 'Download/Fadocx/${file.fileName}',
              onTap: () async {
                Navigator.pop(ctx);
                await _saveToDownloads(file);
              },
            ),
            _buildExportActionRow(
              icon: Icons.folder_open,
              title: 'Choose location',
              iconColor: Colors.blue,
              subtitle: 'Pick a custom save directory',
              onTap: () async {
                Navigator.pop(ctx);
                await _saveToCustomLocation(file);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildExportActionRow({
    required IconData icon,
    required String title,
    required Color iconColor,
    String? subtitle,
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
                      )),
                      if (subtitle != null)
                        Text(subtitle, style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<Directory> _getFadocxDownloadsDir() async {
    final dir = await getDownloadsDirectory();
    if (dir == null) {
      throw UnsupportedError('Downloads directory not available');
    }
    return Directory('${dir.path}/Fadocx');
  }

  Future<void> _saveToDownloads(RecentFile file) async {
    try {
      final downloadsDir = await _getFadocxDownloadsDir();
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

  Future<void> _saveToCustomLocation(RecentFile file) async {
    try {
      final directory = await FilePicker.getDirectoryPath(
        dialogTitle: 'Choose save location',
      );
      if (directory == null) return;

      final source = File(file.filePath);
      var dest = '$directory/${file.fileName}';
      var counter = 1;
      while (await File(dest).exists()) {
        final dot = file.fileName.lastIndexOf('.');
        final base = dot > 0 ? file.fileName.substring(0, dot) : file.fileName;
        final ext = dot > 0 ? file.fileName.substring(dot) : '';
        dest = '$directory/$base ($counter)$ext';
        counter++;
      }
      await source.copy(dest);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved to ${dest.split('/').last}')),
        );
      }
    } catch (e) {
      log.e('Failed to export file to custom location', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to export file')),
        );
      }
    }
  }


  void _copyExtractedText(RecentFile file) {
    final text = file.extractedText;
    if (text == null || text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied ${text.length} characters to clipboard'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
        child: SingleChildScrollView(
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
      final brightness = Theme.of(context).brightness;
      ref.read(generateAndCacheThumbnailProvider(
        (
          fileId: widget.file.id,
          filePath: widget.file.filePath,
          fileName: widget.file.fileName,
          fileType: widget.file.fileType,
          extractedText: widget.file.extractedText,
          brightness: brightness,
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
    final theme = Theme.of(context);
    IconData iconData;
    Color color;

    switch (fileType.toLowerCase()) {
      case 'pdf':
        iconData = Icons.picture_as_pdf;
        color = theme.colorScheme.error;
        break;
      case 'docx':
      case 'doc':
      case 'odt':
      case 'rtf':
      case 'txt':
        iconData = Icons.description;
        color = theme.colorScheme.primary;
        break;
      case 'xlsx':
      case 'xls':
      case 'ods':
      case 'csv':
        iconData = Icons.table_chart;
        color = theme.colorScheme.tertiary;
        break;
      case 'ppt':
      case 'pptx':
      case 'odp':
        iconData = Icons.slideshow;
        color = theme.colorScheme.error;
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
        color = theme.colorScheme.primary;
        break;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'webp':
        iconData = Icons.document_scanner;
        color = theme.colorScheme.secondary;
        break;
      default:
        iconData = Icons.insert_drive_file;
        color = theme.colorScheme.onSurfaceVariant;
    }

    return Icon(iconData, color: color, size: 40);
  }
}

extension _DocumentsScreenStateExtension on _DocumentsScreenState {}
