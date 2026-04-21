import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fadocx/config/theme/app_theme.dart';
import 'package:fadocx/core/utils/logger.dart';
import 'package:fadocx/features/settings/presentation/providers/settings_providers.dart';
import 'package:fadocx/features/settings/domain/entities/app_settings.dart';

/// Document model for organization
class DeviceDocument {
  final String path;
  final String name;
  final String extension;
  final DateTime modified;
  final int fileSizeBytes;
  final String category;

  DeviceDocument({
    required this.path,
    required this.name,
    required this.extension,
    required this.modified,
    required this.fileSizeBytes,
    required this.category,
  });

  String get displaySize {
    if (fileSizeBytes < 1024) return '${fileSizeBytes}B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)}KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

/// Full-screen import documents screen with device-wide scanning
class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({super.key});

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen>
    with WidgetsBindingObserver {
  late String _selectedCategory;
  final Set<String> _selectedFilePaths = {};
  bool _isLoading = true;
  String? _error;
  bool _openedManageAllFilesSettings = false;
  bool _isGridView = false;
  String _searchQuery = '';
  bool _isSearchExpanded = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final Map<String, List<DeviceDocument>> _documentsByCategory = {
    'all': [],
    'pdf': [],
    'documents': [],
    'spreadsheets': [],
    'presentations': [],
    'other': [],
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedCategory = 'all';
    _checkAndRequestPermissions();
  }

  String _formatDate(DateTime date) {
    final day = date.day;
    final suffix = (day % 10 == 1 && day != 11) ? 'st' :
                   (day % 10 == 2 && day != 12) ? 'nd' :
                   (day % 10 == 3 && day != 13) ? 'rd' : 'th';
    return '$day$suffix ${DateFormat('MMMM yyyy').format(date)}';
  }

  String _getShortPath(String fullPath) {
    final home = Platform.isAndroid ? '/storage/emulated/0' : Platform.environment['HOME'] ?? '';
    if (fullPath.startsWith(home)) {
      return '~${fullPath.substring(home.length)}';
    }
    return fullPath;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _openedManageAllFilesSettings) {
      _openedManageAllFilesSettings = false;
      _recheckManageExternalStoragePermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _selectedFilePaths.isEmpty,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          log.i('Browse screen popped with ${_selectedFilePaths.length} selected files');
          return;
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: GestureDetector(
            onTap: () {}, // Absorb taps
            child: Stack(
              children: [
                // Shadow below the top bar
                Positioned(
                  bottom: -8,
                  left: 0,
                  right: 0,
                  height: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.black.withValues(alpha: 0.3)
                              : Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
                // Main top bar with rounded bottom corners
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(context)
                                .colorScheme
                                .surface
                                .withValues(alpha: 0.95)
                            : Theme.of(context)
                                .colorScheme
                                .surface
                                .withValues(alpha: 0.92),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context)
                                .colorScheme
                                .outline
                                .withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: SizedBox(
                          height: 40,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chevron_left),
                                  onPressed: () {
                                    log.i('Back button pressed');
                                    context.pop();
                                  },
                                  tooltip: 'Back',
                                  iconSize: 20,
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                                const SizedBox(width: 8),
                                // Animated search bar
                                Expanded(
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    transitionBuilder: (child, animation) {
                                      return SizeTransition(
                                        sizeFactor: animation,
                                        axis: Axis.horizontal,
                                        child: child,
                                      );
                                    },
                                    child: _isSearchExpanded
                                        ? Container(
                                            key: const ValueKey('search_input'),
                                            constraints: const BoxConstraints(maxWidth: double.infinity),
                                            child: TextField(
                                              controller: _searchController,
                                              focusNode: _searchFocusNode,
                                              decoration: InputDecoration(
                                                hintText: 'Search documents...',
                                                border: InputBorder.none,
                                                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                                suffixIcon: IconButton(
                                                  icon: const Icon(Icons.clear),
                                                  onPressed: () {
                                                    _searchController.clear();
                                                    setState(() => _searchQuery = '');
                                                  },
                                                ),
                                              ),
                                              onChanged: (value) {
                                                setState(() => _searchQuery = value.toLowerCase());
                                              },
                                            ),
                                          )
                                        : const SizedBox.shrink(key: ValueKey('search_placeholder')),
                                  ),
                                ),
                                // Title or search icon
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: _isSearchExpanded
                                      ? const SizedBox.shrink()
                                      : Text(
                                          'Import Documents',
                                          key: const ValueKey('title'),
                                          style: Theme.of(context).textTheme.titleMedium,
                                        ),
                                ),
                                // Search toggle button
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: IconButton(
                                    key: ValueKey(_isSearchExpanded),
                                    icon: Icon(_isSearchExpanded ? Icons.close : Icons.search),
                                    onPressed: () {
                                      setState(() {
                                        if (_isSearchExpanded) {
                                          _isSearchExpanded = false;
                                          _searchController.clear();
                                          _searchQuery = '';
                                          _searchFocusNode.unfocus();
                                        } else {
                                          _isSearchExpanded = true;
                                          WidgetsBinding.instance.addPostFrameCallback((_) {
                                            _searchFocusNode.requestFocus();
                                          });
                                        }
                                      });
                                    },
                                    tooltip: _isSearchExpanded ? 'Close search' : 'Search documents',
                                    iconSize: 20,
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                                // Grid/List toggle
                                IconButton(
                                  icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
                                  onPressed: () {
                                    setState(() => _isGridView = !_isGridView);
                                  },
                                  tooltip: _isGridView ? 'Switch to list view' : 'Switch to grid view',
                                  iconSize: 20,
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        body: _buildBody(),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _pickFilesManually,
          icon: const Icon(Icons.manage_search_sharp),
          label: const Text('Browse'),
          tooltip: 'Import additional files manually',
        ),
        bottomNavigationBar: _selectedFilePaths.isNotEmpty
            ? _buildBottomImportBar(context)
            : null,
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildSkeletonChip(),
                _buildSkeletonChip(),
                _buildSkeletonChip(),
                _buildSkeletonChip(),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: 8,
              itemBuilder: (context, index) {
                return _buildSkeletonListItem();
              },
            ),
          ),
        ],
      );
    }

    if (_error != null) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Scan failed',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _error ?? 'Unknown error occurred',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Retry Scan'),
                onPressed: () {
                  log.i('Retry scan button pressed');
                  _checkAndRequestPermissions();
                },
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                icon: const Icon(Icons.folder_open),
                label: const Text('Import Files Manually'),
                onPressed: _pickFilesManually,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Helper text
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Select the document(s) you want to import',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        // Category tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildCategoryTab('all', 'All', Icons.folder),
              _buildCategoryTab('pdf', 'PDFs', Icons.picture_as_pdf),
              _buildCategoryTab('documents', 'Docs', Icons.description),
              _buildCategoryTab('spreadsheets', 'Sheets', Icons.table_chart),
              _buildCategoryTab('presentations', 'Slides', Icons.slideshow),
              _buildCategoryTab('other', 'Other', Icons.insert_drive_file),
            ],
          ),
        ),
        const Divider(height: 1),
        // Documents list/grid
        Expanded(
          child: _buildDocumentsView(),
        ),
      ],
    );
  }

  Widget _buildCategoryTab(
      String categoryKey, String label, IconData icon) {
    final isActive = _selectedCategory == categoryKey;
    final count = _documentsByCategory[categoryKey]?.length ?? 0;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isActive,
        onSelected: (selected) {
          setState(() => _selectedCategory = categoryKey);
        },
        avatar: Icon(icon, size: 16),
        label: Text('$label ($count)'),
        backgroundColor: Colors.transparent,
        selectedColor:
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        side: BorderSide(
          color: isActive
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildDocumentsView() {
    final documents = _documentsByCategory[_selectedCategory] ?? [];
    final filteredDocuments = _searchQuery.isEmpty
        ? documents
        : documents.where((doc) =>
            doc.name.toLowerCase().contains(_searchQuery) ||
            doc.extension.toLowerCase().contains(_searchQuery)).toList();

    if (filteredDocuments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? 'No documents found' : 'No documents match your search',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Try a different search term',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 32),
            FilledButton.icon(
              icon: const Icon(Icons.folder_open),
              label: const Text('Import Files Manually'),
              onPressed: _pickFilesManually,
            ),
          ],
        ),
      );
    }

    if (_isGridView) {
      return GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.0,
        ),
        itemCount: filteredDocuments.length,
        itemBuilder: (context, index) {
          return _buildDocumentGridItem(filteredDocuments[index]);
        },
      );
    } else {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: filteredDocuments.length,
        itemBuilder: (context, index) {
          return _buildDocumentListItem(filteredDocuments[index]);
        },
      );
    }
  }

  Widget _buildDocumentListItem(DeviceDocument doc) {
    final isSelected = _selectedFilePaths.contains(doc.path);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedFilePaths.remove(doc.path);
              } else {
                _selectedFilePaths.add(doc.path);
              }
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isSelected
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                  : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _getFileIcon(doc.extension, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doc.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.storage,
                                  size: 14,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  doc.displaySize,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.calendar_today,
                                  size: 14,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDate(doc.modified),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.folder,
                                  size: 14,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    _getShortPath(doc.path.substring(0, doc.path.lastIndexOf('/'))),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
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

  Widget _buildDocumentGridItem(DeviceDocument doc) {
    final isSelected = _selectedFilePaths.contains(doc.path);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedFilePaths.remove(doc.path);
            } else {
              _selectedFilePaths.add(doc.path);
            }
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _getFileIcon(doc.extension, size: 32),
                    const SizedBox(height: 6),
                    Text(
                      doc.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.storage,
                          size: 10,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          doc.displaySize,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 10,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          _formatDate(doc.modified),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder,
                          size: 10,
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            _getShortPath(doc.path.substring(0, doc.path.lastIndexOf('/'))),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomImportBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 12 + MediaQuery.of(context).viewPadding.bottom,
      ),
      child: Row(
        children: [
          Text(
            '${_selectedFilePaths.length} selected',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const Spacer(),
          TextButton.icon(
            icon: const Icon(Icons.close),
            label: const Text('Clear'),
            onPressed: () {
              setState(() => _selectedFilePaths.clear());
            },
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            icon: const Icon(Icons.download),
            label: const Text('Import'),
            onPressed: _importSelectedFiles,
          ),
        ],
      ),
    );
  }

  Widget _getFileIcon(String extension, {double size = 24}) {
    IconData iconData;
    Color color;

    switch (extension.toLowerCase()) {
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

  String _getCategory(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'pdf';
      case 'docx':
      case 'doc':
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

  Future<void> _checkAndRequestPermissions() async {
    log.i('📋 Checking file access permissions...');
    
    try {
      if (await Permission.manageExternalStorage.isGranted) {
        log.i('✓ MANAGE_EXTERNAL_STORAGE already granted');
        await _scanDeviceForDocuments();
        return;
      }

      // Request MANAGE_ALL_FILES (Android 11+) - REQUIRED for full document scanning
      log.i('🔐 Requesting MANAGE_ALL_FILES permission (Android 11+)...');
      final status = await Permission.manageExternalStorage.request();
      
      if (status.isGranted) {
        log.i('✓ MANAGE_ALL_FILES permission granted');
        await _scanDeviceForDocuments();
        return;
      }

      // Legacy Android fallback (Android 10 and below).
      final legacyStorageStatus = await Permission.storage.request();
      if (legacyStorageStatus.isGranted) {
        log.i('✓ Legacy storage permission granted');
        await _scanDeviceForDocuments();
        return;
      }
      
      // If MANAGE_ALL_FILES rejected, show dialog to open settings
      if (status.isDenied || status.isPermanentlyDenied) {
        log.w('⚠️  MANAGE_ALL_FILES permission rejected/denied');
        
        setState(() {
          _error = 'All files access permission is required to scan documents.\nPlease enable it in app settings.';
          _isLoading = false;
        });
        
        // Show dialog with "Open Settings" option
        _showOpenSettingsDialog();
        return;
      }
    } catch (e) {
      log.w('⚠️  Error checking permissions: $e');
      setState(() {
        _error = 'Error checking permissions: $e';
        _isLoading = false;
      });
    }
  }

  void _showOpenSettingsDialog() {
    const platform = MethodChannel('com.fadseclab.fadocx/app_settings');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'All files access permission is required to scan all documents on your device. '
          'Tap "Open Settings" to enable it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await platform.invokeMethod('openManageAllFilesSettings');
                _openedManageAllFilesSettings = true;
                if (context.mounted) {
                  Navigator.pop(context);
                }
              } catch (e) {
                log.e('Failed to open settings: $e');
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _recheckManageExternalStoragePermission() async {
    try {
      final status = await Permission.manageExternalStorage.status;
      final legacyStorageStatus = await Permission.storage.status;

      if (status.isGranted || legacyStorageStatus.isGranted) {
        log.i('✓ Storage permission granted after returning from settings');
        await _scanDeviceForDocuments();
        return;
      }

      log.w('⚠️  Storage permission still not granted after returning from settings');
      if (!mounted) return;
      setState(() {
        _error = 'All files access is still disabled for this app. '
            'If the toggle remains grayed out, your device policy/OEM ROM is blocking this permission for the installed build.';
        _isLoading = false;
      });
    } catch (e) {
      log.w('⚠️  Failed to re-check storage permission: $e');
    }
  }

  Future<void> _scanDeviceForDocuments() async {
    log.i('🔍 Starting device document scan...');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final allDocs = <DeviceDocument>[];
      final pathsToScan = <Directory>[];

      // Try to get Downloads directory
      try {
        final downloads = await getDownloadsDirectory();
        if (downloads != null) {
          pathsToScan.add(downloads);
        }
      } catch (e) {
        log.d('⚠️  Could not get downloads dir: $e');
      }

      // Try to get app documents directory (for sample files)
      try {
        final appDocs = await getApplicationDocumentsDirectory();
        final sampleDir = Directory('${appDocs.path}/Fadocx Samples');
        if (await sampleDir.exists()) {
          pathsToScan.add(sampleDir);
          log.i('✓ Added Fadocx Samples directory to scan: ${sampleDir.path}');
        }
      } catch (e) {
        log.d('⚠️  Could not get app documents dir: $e');
      }

      // Try to get common user documents paths
      final commonDocPaths = [
        '/storage/emulated/0/Documents',
        '/storage/emulated/0/Download',
      ];

      for (final path in commonDocPaths) {
        final dir = Directory(path);
        final exists = await dir.exists();
        if (exists && !pathsToScan.any((d) => d.path == path)) {
          pathsToScan.add(dir);
        }
      }

      if (pathsToScan.isEmpty) {
        log.w('⚠️  No document directories found');
        setState(() {
          _error = 'No document directories found on device';
          _isLoading = false;
        });
        return;
      }

      for (final dir in pathsToScan) {
        try {
          if (!await dir.exists()) {
            continue;
          }

          final countBefore = allDocs.length;
          await _scanDirectoryRecursive(dir, allDocs, maxDepth: 3);
          final found = allDocs.length - countBefore;

          if (found > 0) {
            log.i('✓ Found $found documents in ${dir.path}');
          }
        } catch (e) {
          log.w('⚠️  Error scanning ${dir.path}: $e');
        }
      }

      log.d('📊 Total documents found: ${allDocs.length}');

      // Organize by category
      for (final category in _documentsByCategory.keys) {
        _documentsByCategory[category] = [];
      }

      for (final doc in allDocs) {
        _documentsByCategory[doc.category]?.add(doc);
        _documentsByCategory['all']?.add(doc);
      }

      // Log category breakdown
      for (final entry in _documentsByCategory.entries) {
        if (entry.value.isNotEmpty) {
          log.i('📑 ${entry.key}: ${entry.value.length} documents');
        }
      }

      // Sort by modified date (newest first)
      for (final docs in _documentsByCategory.values) {
        docs.sort((a, b) => b.modified.compareTo(a.modified));
      }

      setState(() {
        _isLoading = false;
      });

      log.i('✅ Scan complete: Found ${allDocs.length} total documents');
    } catch (e) {
      log.e('❌ Error scanning device: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _scanDirectoryRecursive(
    Directory dir,
    List<DeviceDocument> docs, {
    int currentDepth = 0,
    int maxDepth = 4,
  }) async {
    if (currentDepth > maxDepth) {
      return; // Stop recursing
    }

    try {
      // Get directory name for filtering
      final dirName = dir.path.split('/').last;
      
      // Skip system directories to improve performance
      if (dirName.startsWith('.') || 
          dirName.startsWith('__') ||
          {'cache', 'tmp', 'temp'}.contains(dirName.toLowerCase())) {
        return;
      }

      // Use followLinks: false to avoid symlink issues
      final entities = await dir.list(followLinks: false).toList();
      log.d('📍 Depth $currentDepth: "${dir.path}" has ${entities.length} items');

      final supportedTypes = {
        'pdf',
        'doc',
        'docx',
        'odt',
        'rtf',
        'txt',
        'xlsx',
        'xls',
        'ods',
        'csv',
        'ppt',
        'pptx',
        'odp'
      };

      for (final entity in entities) {
        try {
          final entityName = entity.path.split('/').last;
          
          if (entity is File) {
            log.d('  📄 File: $entityName');
            
            // Skip hidden files
            if (entityName.startsWith('.')) {
              log.d('    ⏭️  Skipping hidden file');
              continue;
            }
            
            // Extract extension safely
            final lastDot = entityName.lastIndexOf('.');
            final ext = lastDot > 0 ? entityName.substring(lastDot + 1).toLowerCase() : '';

            if (supportedTypes.contains(ext)) {
              try {
                final stat = await entity.stat();
                final doc = DeviceDocument(
                  path: entity.path,
                  name: entityName,
                  extension: ext,
                  modified: stat.modified,
                  fileSizeBytes: stat.size,
                  category: _getCategory(ext),
                );
                docs.add(doc);
                log.i('    ✓ Added: $entityName (${doc.displaySize})');
              } catch (e) {
                log.w('    ⚠️  Could not stat: $e');
              }
            } else {
              log.d('    ⏭️  Skipped (ext: $ext)');
            }
          } else if (entity is Directory) {
            log.d('  📁 Directory: $entityName');
            
            if (currentDepth >= maxDepth) {
              log.d('    ⏭️  Max depth reached');
              continue;
            }
            
            // Skip system directories
            if (entityName.startsWith('.') || 
                entityName.startsWith('__') ||
                {'cache', 'tmp', 'temp'}.contains(entityName.toLowerCase())) {
              log.d('    ⏭️  System directory');
              continue;
            }
            
            // Recurse into subdirectories
            await _scanDirectoryRecursive(
              entity,
              docs,
              currentDepth: currentDepth + 1,
              maxDepth: maxDepth,
            );
          } else {
            log.d('  ❓ Other type: ${entity.runtimeType} - $entityName');
          }
        } catch (e) {
          log.w('  ⚠️  Error: $e');
        }
      }
    } catch (e) {
      log.w('⚠️  Error scanning ${dir.path}: $e');
    }
  }

  Future<void> _pickFilesManually() async {
    log.i('📂 Opening file picker...');
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'odt',
          'rtf',
          'txt',
          'xlsx',
          'xls',
          'ods',
          'csv',
          'ppt',
          'pptx',
          'odp',
        ],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          for (final file in result.files) {
            if (file.path != null) {
              _selectedFilePaths.add(file.path!);
              log.d('  ✓ Selected: ${file.name}');
            }
          }
        });
        log.i('✅ Added ${result.files.length} files via file picker');
      } else {
        log.i('ℹ️  File picker cancelled by user');
      }
    } catch (e) {
      log.e('❌ Error picking files: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _importSelectedFiles() async {
    if (_selectedFilePaths.isEmpty) {
      log.w('⚠️  Import called but no files selected');
      return;
    }

    log.i('📥 Starting import of ${_selectedFilePaths.length} file(s)...');

    try {
      final mutator = ref.read(recentFilesMutatorProvider);
      final now = DateTime.now();
      int imported = 0;

      for (final filePath in _selectedFilePaths) {
        try {
          final fileName = filePath.split('/').last;
          final fileExtension = _getFileExtension(fileName);

          int fileSizeBytes = 0;
          try {
            final file = File(filePath);
            fileSizeBytes = await file.length();
          } catch (e) {
            log.w('⚠️  Could not calculate file size for $filePath: $e');
          }

          final recentFile = RecentFile(
            id: DateTime.now().millisecondsSinceEpoch.toString() +
                _selectedFilePaths.toList().indexOf(filePath).toString(),
            filePath: filePath,
            fileName: fileName,
            fileType: fileExtension,
            fileSizeBytes: fileSizeBytes,
            dateOpened: now,
            dateModified: now,
            pagePosition: 0,
            syncStatus: 'local',
          );

          await mutator.addRecentFile(recentFile);
          imported++;
          log.d('  ✓ Imported: $fileName');
        } catch (e) {
          log.e('  ❌ Failed to import file: $e');
        }
      }

      if (mounted) {
        final message = 'Imported $imported file${imported > 1 ? 's' : ''}';
        log.i('✅ $message');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        context.pop();
      }
    } catch (e) {
      log.e('❌ Error importing files: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error importing files: $e')),
        );
      }
    }
  }

  String _getFileExtension(String fileName) {
    return fileName.split('.').last;
  }

  Widget _buildSkeletonChip() {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        height: 32,
        width: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Theme.of(context).colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildSkeletonListItem() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.3),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 16,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.5),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 12,
              width: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
