import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:logger/logger.dart';
import 'package:fadocx/core/services/storage_service.dart';
import 'package:fadocx/config/routing/app_router.dart';
import 'package:fadocx/core/presentation/widgets/floating_dock_scaffold.dart';
import 'package:fadocx/features/settings/domain/entities/app_settings.dart';
import 'package:fadocx/features/settings/presentation/providers/settings_providers.dart';
import 'package:fadocx/features/home/presentation/providers/thumbnail_provider.dart';
import 'package:fadocx/features/home/presentation/widgets/home_drawer.dart';

final log = Logger();

/// Home screen - displays recent files and quick actions
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with TickerProviderStateMixin {
  bool _dataLoaded = false;
  bool _sidebarOpen = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _sidebarController;
  
  double _sidebarDragOffset = 0.0; // Track horizontal drag position
  
  static const double _kSidebarTopOffset = 87; // Increased to clear app bar
  static const double _kSidebarBottomOffset = 88;
  static const double _kSidebarRadius = 24.0;
  static const double _kDragCloseThreshold = 100.0; // Distance to trigger close

  @override
  void initState() {
    super.initState();
    _sidebarController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    // OPTIMIZATION: Defer recent files loading to after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _dataLoaded = true);
      Future.microtask(() => ref.read(recentFilesProvider));
    });
  }
  
  @override
  void dispose() {
    _sidebarController.dispose();
    super.dispose();
  }
  
  void _toggleSidebar() {
    setState(() => _sidebarOpen = !_sidebarOpen);
    if (_sidebarOpen) {
      _sidebarController.forward();
    } else {
      _sidebarController.reverse();
    }
  }
  
  void _closeSidebar() {
    setState(() => _sidebarOpen = false);
    _sidebarController.reverse();
  }
  
  void _handleSidebarDragUpdate(DragUpdateDetails details) {
    setState(() {
      _sidebarDragOffset += details.delta.dx;
      // Clamp offset to not move right past 0
      _sidebarDragOffset = _sidebarDragOffset.clamp(-500, 0.0);
    });
  }
  
  void _handleSidebarDragEnd(DragEndDetails details) {
    // If dragged left more than threshold, close the sidebar
    if (_sidebarDragOffset.abs() > _kDragCloseThreshold) {
      setState(() => _sidebarOpen = false);
      _sidebarController.reverse();
      // Reset drag offset after animation completes so sidebar animates smoothly from current position
      Future.delayed(const Duration(milliseconds: 260), () {
        if (mounted && !_sidebarOpen) {
          setState(() => _sidebarDragOffset = 0.0);
        }
      });
    } else {
      // Snap back to open position
      setState(() => _sidebarDragOffset = 0.0);
    }
  }

  Widget _buildAppBarContent(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // Hamburger menu
            AnimatedHamburgerIcon(
              onPressed: _toggleSidebar,
              isOpen: _sidebarOpen,
            ),
            const SizedBox(width: 12),
            // Logo icon
            Image.asset(
              'assets/fadocx_header_landscape_png.png',
              height: 32,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 6),
            // App title
            Text(
              'Fadocx',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          FloatingDockScaffold(
            appBarContent: _buildAppBarContent(context),
            currentRoute: RouteNames.home,
            body: _buildBody(),
          ),
          
          // Scrim overlay with dimming and tap-to-close - controlled by sidebar state
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !_sidebarOpen,
              child: AnimatedBuilder(
                animation: _sidebarController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _sidebarController.value,
                    child: GestureDetector(
                      onTap: _closeSidebar,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.45),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Sidebar with slide-in animation and drag support
          AnimatedBuilder(
            animation: _sidebarController,
            builder: (context, child) {
              return Positioned(
                top: _kSidebarTopOffset - _kSidebarRadius,
                bottom: _kSidebarBottomOffset - _kSidebarRadius,
                left: 0,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(-1.0, 0.0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _sidebarController,
                    curve: Curves.easeOutCubic,
                  )),
                  child: IgnorePointer(
                    ignoring: !_sidebarOpen,
                    child: _buildSidebarDrawer(context, isDark),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (!_dataLoaded) {
      // Show skeleton loader
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 88, 16, 24),
        children: List.generate(
          5,
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
        final showRecentFiles = ref.watch(showRecentFilesProvider);
        final appSettings = ref.watch(appSettingsProvider);
        return recentFiles.when(
          data: (files) => _buildHomeContent(context, files, showRecentFiles, appSettings.value),
          error: (error, st) => _buildErrorState(context, error),
          loading: () => ListView(
            padding: const EdgeInsets.fromLTRB(16, 88, 16, 24),
            children: List.generate(
              5,
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

  Widget _buildHomeContent(BuildContext context, List<RecentFile> files, bool showRecentFiles, AppSettings? appSettings) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 88, 16, 24),
      children: [
        // Action Cards Section - 2 cards in one row
        Row(
          children: [
            // Scan to Extract Text card
            Expanded(
              child: _buildActionCard(
                context,
                title: 'Scan to Extract Text',
                description: 'Extract text from documents using OCR',
                icon: Icons.document_scanner,
                onTap: () {
                  log.i('Navigating to scanner');
                  context.push(RouteNames.scanner);
                },
              ),
            ),
            const SizedBox(width: 12),
            // Import a Document card
            Expanded(
              child: _buildActionCard(
                context,
                title: 'Import a Document',
                description: 'Browse and import files from your device',
                icon: Icons.folder_open,
                onTap: () {
                  log.i('Navigating to browse');
                  context.push(RouteNames.browse);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Recent Files Section - show header only when not onboarding
        if (showRecentFiles && (files.isNotEmpty || (appSettings != null && appSettings.hasImportedSampleFiles))) ...[
          Row(
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('See All'),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (files.isNotEmpty) ...[
            ...files.take(4).toList().asMap().entries.map(
              (entry) {
                final index = entry.key;
                final file = entry.value;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index < (files.take(4).toList().length - 1) ? 8 : 0,
                  ),
                  child: _buildRecentFileItem(context, file),
                );
              },
            ),
          ] else
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_open_outlined,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'No recent files',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
        ] else if (appSettings == null || !appSettings.hasImportedSampleFiles)
          _buildEmptyRecentState(context)
        // Don't show any onboarding after samples are imported
        // Just show the action cards above
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return _ModernActionCard(
      title: title,
      description: description,
      icon: icon,
      onTap: onTap,
    );
  }

  Widget _buildEmptyRecentState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
          width: 1.5,
        ),
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                ],
              ),
            ),
            child: Icon(
              Icons.lightbulb_outline,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Welcome to Fadocx',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Start by exploring our curated sample files or upload your own documents to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Color.lerp(Theme.of(context).colorScheme.primary, const Color(0xFF8B5CF6), 0.3)!,
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _importSampleFiles(context),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.download_for_offline,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Import Sample Files',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'or',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              children: [
                TextSpan(
                  text: 'scan',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Color.lerp(Theme.of(context).colorScheme.primary, const Color(0xFF3B82F6), 0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: ' or '),
                TextSpan(
                  text: 'import',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Color.lerp(Theme.of(context).colorScheme.primary, const Color(0xFF10B981), 0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: ' your own documents'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _importSampleFiles(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final theme = Theme.of(context);

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Importing sample files...'),
            ],
          ),
        ),
      );

      // Get the Fadocx samples directory using storage service
      final sampleDir = await StorageService.getCategoryDir('Samples');

      // Create samples directory if it doesn't exist
      if (!await sampleDir.exists()) {
        await sampleDir.create(recursive: true);
      }

      // List of sample files to copy
      final sampleFiles = [
        'assets/samples/file-example_PDF_1MB.pdf',
        'assets/samples/10rows_xlsx.xlsx',
        'assets/samples/big_txt.txt',
      ];

      int importedCount = 0;

      // Copy each sample file
      for (final assetPath in sampleFiles) {
        try {
          final fileName = assetPath.split('/').last;
          final targetPath = '${sampleDir.path}/$fileName';

          // Load asset as bytes
          final byteData = await rootBundle.load(assetPath);
          final bytes = byteData.buffer.asUint8List();

          // Write to file
          final file = File(targetPath);
          await file.writeAsBytes(bytes);

          // Get file info
          final fileStat = await file.stat();
          final fileSizeBytes = fileStat.size;
          final fileExtension = fileName.split('.').last.toLowerCase();
          final now = DateTime.now();

          // Create RecentFile entry
          final recentFile = RecentFile(
            id: const Uuid().v4(),
            filePath: targetPath,
            fileName: fileName,
            fileType: fileExtension,
            fileSizeBytes: fileSizeBytes,
            dateOpened: now,
            dateModified: now,
            pagePosition: 0,
            syncStatus: 'local',
          );

          // Add to recent files database
          final mutator = ref.read(recentFilesMutatorProvider);
          await mutator.addRecentFile(recentFile);

          importedCount++;
          log.i('Imported sample file: $fileName');
        } catch (e) {
          log.e('Failed to import sample file $assetPath: $e');
        }
      }

      // Close loading dialog
      if (!mounted) return;
      navigator.pop();

      // Show success message
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('$importedCount sample files imported successfully!'),
          action: SnackBarAction(
            label: 'View Files',
            onPressed: () {
              if (mounted) {
                context.push(RouteNames.documents);
              }
            },
          ),
        ),
      );

      // Refresh the recent files provider to show the imported files
      ref.invalidate(recentFilesProvider);

      // Mark that user has imported sample files
      final settingsMutator = ref.read(settingsMutatorProvider);
      await settingsMutator.updateHasImportedSampleFiles(true);

    } catch (e) {
      // Close loading dialog if open
      if (!mounted) return;
      navigator.pop();

      // Show error message
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Failed to import sample files: $e'),
          backgroundColor: theme.colorScheme.error,
        ),
      );

      log.e('Error importing sample files: $e');
    }
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

  Widget _buildSidebarDrawer(BuildContext context, bool isDark) {
    final maxWidth = MediaQuery.of(context).size.width * 0.8;
    final width = maxWidth < 280 ? maxWidth : 280.0;
    final theme = Theme.of(context);
    final bgColor = isDark
        ? theme.colorScheme.surface.withValues(alpha: 0.95)
        : theme.colorScheme.surface.withValues(alpha: 0.93);
    final borderColor = theme.colorScheme.outline.withValues(alpha: 0.2);

    return GestureDetector(
      onTap: () {}, // Absorb taps to prevent propagation
      behavior: HitTestBehavior.opaque,
      onHorizontalDragUpdate: _handleSidebarDragUpdate,
      onHorizontalDragEnd: _handleSidebarDragEnd,
      child: Transform.translate(
        offset: Offset(_sidebarDragOffset, 0),
        child: SizedBox(
          width: width + 20,
          child: ClipPath(
            clipper: _SidebarClipper(
              sidebarWidth: width,
              radius: _kSidebarRadius,
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 1. Background and Flares with blurred appearance
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _InvertedCornerSidebarPainter(
                        color: bgColor,
                        borderColor: borderColor,
                        radius: _kSidebarRadius,
                        sidebarWidth: width,
                      ),
                    ),
                  ),
                  // 2. Content (Sheet)
                  Positioned(
                    left: 0,
                    top: _kSidebarRadius,
                    bottom: _kSidebarRadius,
                    width: width,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: _HomeDrawerContent(
                          onClose: _closeSidebar,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
    log.d(
        '🖼️  [Thumbnail Widget] Initializing for file: ${widget.file.fileName}');

    // Skip thumbnail generation for presentation formats (not yet supported)
    final type = widget.file.fileType.toLowerCase();
    if (type == 'ppt' || type == 'pptx' || type == 'odp') {
      log.d(
          '🖼️  [Thumbnail Widget] Skipping generation for presentation format: $type');
      return;
    }

    // Watching the generation provider in build() will auto-trigger generation
    log.d('🖼️  [Thumbnail Widget] Generation will be triggered via provider watch');
  }

  @override
  Widget build(BuildContext context) {
    final isPresentation = _isPresentationFormat(widget.file.fileType);

    // Watch BOTH: the cache and the generation provider
    // This way when generation completes and saves, we automatically refresh
    final thumbnail = ref.watch(thumbnailProvider(widget.file.id));
    // Watch generation provider to auto-refresh when thumbnail generation completes
    ref.watch(generateAndCacheThumbnailProvider(
      (
        fileId: widget.file.id,
        filePath: widget.file.filePath,
        fileName: widget.file.fileName,
        fileType: widget.file.fileType,
      ),
    ));

    return thumbnail.when(
      data: (bytes) {
        if (bytes != null && !isPresentation) {
          log.d(
              '🖼️  [Thumbnail Widget] ✓ Displaying thumbnail for ${widget.file.fileName} (${bytes.length} bytes)');
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
        log.d(
            '🖼️  [Thumbnail Widget] ⚠️  No thumbnail available or presentation format, showing placeholder');
        return _buildThumbPlaceholder(isPresentation);
      },
      loading: () {
        log.d('🖼️  [Thumbnail Widget] Loading thumbnail...');
        return _buildThumbPlaceholder(isPresentation);
      },
      error: (error, stack) {
        log.e('🖼️  [Thumbnail Widget] Error loading thumbnail: $error');
        return _buildThumbPlaceholder(isPresentation);
      },
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

/// Modern Android-style Action Card with vertical layout and chevron
class _ModernActionCard extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _ModernActionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_ModernActionCard> createState() => _ModernActionCardState();
}

class _ModernActionCardState extends State<_ModernActionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isScanning = widget.icon == Icons.document_scanner;

    // Different gradient colors for each card with better contrast
    final gradientColors = isScanning
        ? [
            Color.lerp(primaryColor, const Color(0xFF3B82F6), 0.3)!,
            Color.lerp(primaryColor, const Color(0xFF6366F1), 0.2)!,
          ]
        : [
            Color.lerp(primaryColor, const Color(0xFF10B981), 0.3)!,
            Color.lerp(primaryColor, const Color(0xFF059669), 0.2)!,
          ];

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                _controller.forward().then((_) {
                  _controller.reverse();
                  widget.onTap();
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.1),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Container(
                  height: 140, // Reduced height now that content is more compact
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Stack(
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Icon container with better contrast
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                widget.icon,
                                size: 24,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Text content - left aligned
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Title with better contrast
                                Text(
                                  widget.title,
                                  textAlign: TextAlign.left,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        height: 1.1,
                                        letterSpacing: 0.2,
                                      ),
                                ),
                                const SizedBox(height: 4),

                                // Description with better contrast - no ellipsis
                                Text(
                                  widget.description,
                                  textAlign: TextAlign.left,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Colors.white.withValues(alpha: 0.9),
                                        height: 1.3,
                                        fontSize: 12,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Chevron icon closer to top right corner
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: Colors.white.withValues(alpha: 0.8),
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
      },
    );
  }
}

class _HomeDrawerContent extends ConsumerWidget {
  final VoidCallback onClose;

  const _HomeDrawerContent({required this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return HomeDrawer(onClose: onClose);
  }
}

class _InvertedCornerSidebarPainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  final double radius;
  final double sidebarWidth;

  _InvertedCornerSidebarPainter({
    required this.color,
    required this.borderColor,
    required this.radius,
    required this.sidebarWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final path = Path();
    
    // Top flare flaring UP from sidebar top (0, radius) to screen edge (0, 0)
    path.moveTo(0, 0);
    // Smooth S-curve transition
    path.cubicTo(
      0, radius * 0.4, 
      radius * 0.1, radius, 
      radius, radius
    );
    
    // Top edge
    path.lineTo(sidebarWidth - 16, radius);
    path.arcToPoint(Offset(sidebarWidth, radius + 16), radius: const Radius.circular(16), clockwise: true);
    
    // Right side
    path.lineTo(sidebarWidth, size.height - radius - 16);
    path.arcToPoint(Offset(sidebarWidth - 16, size.height - radius), radius: const Radius.circular(16), clockwise: true);
    
    // Bottom edge
    path.lineTo(radius, size.height - radius);
    
    // Bottom flare flaring DOWN from sidebar bottom (0, h-radius) to screen edge (0, h)
    path.cubicTo(
      radius * 0.1, size.height - radius,
      0, size.height - radius * 0.4,
      0, size.height
    );
    
    path.lineTo(0, 0);
    path.close();
    
    canvas.drawShadow(path, Colors.black, 10, false);
    canvas.drawPath(path, paint);
    
    // Border for the visible part
    final borderPath = Path();
    borderPath.moveTo(0, 0);
    borderPath.cubicTo(0, radius * 0.4, radius * 0.1, radius, radius, radius);
    borderPath.lineTo(sidebarWidth - 16, radius);
    borderPath.arcToPoint(Offset(sidebarWidth, radius + 16), radius: const Radius.circular(16), clockwise: true);
    borderPath.lineTo(sidebarWidth, size.height - radius - 16);
    borderPath.arcToPoint(Offset(sidebarWidth - 16, size.height - radius), radius: const Radius.circular(16), clockwise: true);
    borderPath.lineTo(radius, size.height - radius);
    borderPath.cubicTo(radius * 0.1, size.height - radius, 0, size.height - radius * 0.4, 0, size.height);
    
    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _InvertedCornerSidebarPainter oldDelegate) => 
    oldDelegate.color != color || oldDelegate.borderColor != borderColor;
}

/// Custom clipper that matches the exact shape of the sidebar with flares
class _SidebarClipper extends CustomClipper<Path> {
  final double sidebarWidth;
  final double radius;

  _SidebarClipper({
    required this.sidebarWidth,
    required this.radius,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    
    // Top flare flaring UP from sidebar top (0, radius) to screen edge (0, 0)
    path.moveTo(0, 0);
    // Smooth S-curve transition
    path.cubicTo(
      0, radius * 0.4, 
      radius * 0.1, radius, 
      radius, radius
    );
    
    // Top edge
    path.lineTo(sidebarWidth - 16, radius);
    path.arcToPoint(Offset(sidebarWidth, radius + 16), radius: const Radius.circular(16), clockwise: true);
    
    // Right side
    path.lineTo(sidebarWidth, size.height - radius - 16);
    path.arcToPoint(Offset(sidebarWidth - 16, size.height - radius), radius: const Radius.circular(16), clockwise: true);
    
    // Bottom edge
    path.lineTo(radius, size.height - radius);
    
    // Bottom flare flaring DOWN from sidebar bottom (0, h-radius) to screen edge (0, h)
    path.cubicTo(
      radius * 0.1, size.height - radius,
      0, size.height - radius * 0.4,
      0, size.height
    );
    
    path.lineTo(0, 0);
    path.close();
    
    return path;
  }

  @override
  bool shouldReclip(covariant _SidebarClipper oldClipper) =>
    oldClipper.sidebarWidth != sidebarWidth || oldClipper.radius != radius;
}
