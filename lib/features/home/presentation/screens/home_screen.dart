import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fadocx/core/utils/logger.dart';
import 'package:fadocx/config/routing/app_router.dart';
import 'package:fadocx/core/presentation/widgets/floating_dock_scaffold.dart';
import 'package:fadocx/features/settings/domain/entities/app_settings.dart';
import 'package:fadocx/features/settings/presentation/providers/settings_providers.dart';
import 'package:fadocx/features/home/presentation/providers/thumbnail_provider.dart';

/// Home screen - displays recent files and quick actions
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _dataLoaded = false;

  @override
  void initState() {
    super.initState();
    // OPTIMIZATION: Defer recent files loading to after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _dataLoaded = true);
      Future.microtask(() => ref.read(recentFilesProvider));
    });
  }

  Widget _buildAppBarContent(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // Icon on left with natural width
            Image.asset(
              'assets/fadocx_header_landscape_png.png',
              height: 32,
              fit: BoxFit.contain,
            ),
            // Text right next to icon
            Row(
              mainAxisSize: MainAxisSize.min,
              children: 'Fadocx'.split('').map((letter) {
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
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingDockScaffold(
      appBarContent: _buildAppBarContent(context),
      currentRoute: RouteNames.home,
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push(RouteNames.browse);
        },
        tooltip: 'Add document',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (!_dataLoaded) {
      // Show skeleton loader
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 88, 16, 100),
        children: List.generate(
          3,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildSkeletonItem(),
          ),
        ),
      );
    }

    return Consumer(
      builder: (context, ref, _) {
        final recentFiles = ref.watch(recentFilesProvider);
        return recentFiles.when(
          data: (files) => files.isEmpty
              ? _buildEmptyState(context)
              : _buildRecentFilesList(context, files),
          error: (error, st) => _buildErrorState(context, error),
          loading: () => ListView(
            padding: const EdgeInsets.fromLTRB(16, 88, 16, 100),
            children: List.generate(
              3,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildSkeletonItem(),
              ),
            ),
          ),
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
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'No documents yet',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Tap the + button to browse and import files',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentFilesList(BuildContext context, List<RecentFile> files) {
    // Show only recent 3-4 files
    final recentList = files.take(4).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 88, 16, 100),
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Files',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              TextButton(
                onPressed: () {
                  context.push(RouteNames.documents);
                },
                child: const Text('See All →'),
              ),
            ],
          ),
        ),
        // Recent files grid
        ...recentList.asMap().entries.map(
          (entry) {
            final index = entry.key;
            final file = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < recentList.length - 1 ? 8 : 0,
              ),
              child: _buildRecentFileItem(context, file),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentFileItem(BuildContext context, RecentFile file) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          log.i('Opening recent file: ${file.fileName}');
          context.push(
              '${RouteNames.viewer}?path=${file.filePath}&name=${file.fileName}');
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
            color: Theme.of(context).colorScheme.surface,
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                // Thumbnail
                _RecentFileThumbnail(file: file),
                const SizedBox(width: 8),
                // File info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        file.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${file.fileType.toUpperCase()} • ${file.formattedSize}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
                      size: 16,
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

  void _softDeleteRecentFile(RecentFile file) {
    ref.read(recentFilesMutatorProvider).softDeleteFile(file.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${file.fileName} moved to trash'),
        duration: const Duration(seconds: 2),
      ),
    );
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
                  _softDeleteRecentFile(file);
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
              Text('Error: $error'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonItem() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

/// Helper widget to display and trigger thumbnail generation for recent files
class _RecentFileThumbnail extends ConsumerStatefulWidget {
  final RecentFile file;

  const _RecentFileThumbnail({required this.file});

  @override
  ConsumerState<_RecentFileThumbnail> createState() =>
      _RecentFileThumbnailState();
}

class _RecentFileThumbnailState extends ConsumerState<_RecentFileThumbnail> {
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

    // Only watch the cache provider, don't trigger generation here
    final thumbnail = ref.watch(thumbnailProvider(widget.file.id));

    return thumbnail.when(
      data: (bytes) {
        if (bytes != null && !isPresentation) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.memory(
              bytes,
              width: 40,
              height: 56,
              fit: BoxFit.cover,
            ),
          );
        }
        // No thumbnail available or presentation format
        return _buildThumbPlaceholder(isPresentation);
      },
      loading: () => _buildThumbPlaceholder(isPresentation),
      error: (_, __) => _buildThumbPlaceholder(isPresentation),
    );
  }

  Widget _buildThumbPlaceholder(bool isPresentation) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: 40,
            height: 56,
            color: Theme.of(context)
                .colorScheme
                .primaryContainer
                .withValues(alpha: 0.3),
          ),
        ),
        if (isPresentation)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: Colors.black.withValues(alpha: 0.4),
              ),
              child: Tooltip(
                message: 'Coming Soon',
                child: Center(
                  child: Text(
                    '○',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.surface,
                      fontSize: 12,
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
}
