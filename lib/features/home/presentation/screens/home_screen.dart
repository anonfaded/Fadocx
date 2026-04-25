import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
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
  late AnimationController _skeletonShimmerController;
  late Animation<double> _skeletonShimmer;
  
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
    _skeletonShimmerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _skeletonShimmer = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _skeletonShimmerController, curve: Curves.easeInOut),
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
    _skeletonShimmerController.dispose();
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

  Widget _buildSkeletonLoading(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + 56;
    final bottomPadding = MediaQuery.of(context).padding.bottom + 80;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(12, topPadding + 8, 12, bottomPadding),
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      child: Column(
        children: [
          _buildSkeletonStats(),
          const SizedBox(height: 12),
          _buildSkeletonActionCards(),
          const SizedBox(height: 14),
          _buildSkeletonRecentHeader(),
          const SizedBox(height: 8),
          ...List.generate(4, (index) => _buildSkeletonRecentItem(index)),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (!_dataLoaded) {
      return _buildSkeletonLoading(context);
    }

    return Consumer(
      builder: (context, ref, _) {
        final recentFiles = ref.watch(recentFilesProvider);
        final showRecentFiles = ref.watch(showRecentFilesProvider);
        final appSettings = ref.watch(appSettingsProvider);
        return recentFiles.when(
          data: (files) => _buildHomeContent(context, files, showRecentFiles, appSettings.value),
          error: (error, st) => _buildErrorState(context, error),
          loading: () => _buildSkeletonLoading(context),
        );
      },
    );
  }

  Widget _buildHomeContent(BuildContext context, List<RecentFile> files, bool showRecentFiles, AppSettings? appSettings) {
    final topPadding = MediaQuery.of(context).padding.top + 56;
    final bottomPadding = MediaQuery.of(context).padding.bottom + 80;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(12, topPadding + 8, 12, bottomPadding),
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Stats Card
          _buildStatsCard(context, files, appSettings),
          const SizedBox(height: 12),

          // Action Cards Section
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  context,
                  title: 'Scan to Extract Text',
                  description: 'Extract text from documents using OCR',
                  icon: Icons.document_scanner,
                  cardType: 'scan',
                  onTap: () {
                    log.i('Navigating to scanner');
                    context.push(RouteNames.scanner);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionCard(
                  context,
                  title: 'Import a Document',
                  description: 'Browse and import files from your device',
                  icon: Icons.folder_open,
                  cardType: 'import',
                  onTap: () {
                    log.i('Navigating to browse');
                    context.push(RouteNames.browse);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Recent Files Section
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
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required String cardType,
    required VoidCallback onTap,
  }) {
    return _ModernActionCard(
      title: title,
      description: description,
      icon: icon,
      cardType: cardType,
      onTap: onTap,
    );
  }

  Widget _buildStatsCard(BuildContext context, List<RecentFile> files, AppSettings? appSettings) {
    final filesCount = files.length;
    final totalSizeBytes = files.fold<int>(0, (sum, f) => sum + f.fileSizeBytes);
    
    // Format storage properly - show in MB if < 1GB, else GB
    String formattedStorage;
    const kb = 1024.0;
    const mb = kb * 1024;
    const gb = mb * 1024;
    if (totalSizeBytes >= gb) {
      formattedStorage = '${(totalSizeBytes / gb).toStringAsFixed(1)} GB';
    } else if (totalSizeBytes >= mb) {
      formattedStorage = '${(totalSizeBytes / mb).toStringAsFixed(1)} MB';
    } else if (totalSizeBytes >= kb) {
      formattedStorage = '${(totalSizeBytes / kb).toStringAsFixed(1)} KB';
    } else {
      formattedStorage = '$totalSizeBytes B';
    }
    
    // Calculate total time spent across all files
    final totalTimeMs = files.fold<int>(0, (sum, f) => sum + f.totalTimeSpentMs);
    String formattedTime;
    final totalSeconds = totalTimeMs ~/ 1000;
    final totalMinutes = totalSeconds ~/ 60;
    final totalHours = totalMinutes ~/ 60;
    if (totalHours > 0) {
      final remainingMinutes = totalMinutes % 60;
      formattedTime = '${totalHours}h ${remainingMinutes}m';
    } else if (totalMinutes > 0) {
      formattedTime = '${totalMinutes}m';
    } else if (totalSeconds > 0) {
      formattedTime = '${totalSeconds}s';
    } else {
      formattedTime = '0s';
    }
    
    final lastFile = files.isNotEmpty ? files.first : null;
    log.d('[STATS] files count=${files.length}, lastFile=${lastFile?.fileName ?? "null"}, dates: ${files.map((f) => "${f.fileName}=${f.dateOpened.toIso8601String()}").join(" | ")}');
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: theme.colorScheme.surfaceContainerLow,
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stat row with dividers between items
          IntrinsicHeight(
            child: Row(
              children: [
                // Documents
                Expanded(
                  child: _buildStatPill(
                    context,
                    icon: Icons.description_outlined,
                    value: filesCount.toString(),
                    label: 'Documents',
                    color: theme.colorScheme.primary,
                  ),
                ),
                VerticalDivider(width: 1, indent: 8, endIndent: 8, color: theme.colorScheme.outline.withValues(alpha: 0.12)),
                // Storage
                Expanded(
                  child: _buildStatPill(
                    context,
                    icon: Icons.pie_chart_outline,
                    value: formattedStorage,
                    label: 'Storage Used',
                    color: theme.colorScheme.tertiary,
                  ),
                ),
                VerticalDivider(width: 1, indent: 8, endIndent: 8, color: theme.colorScheme.outline.withValues(alpha: 0.12)),
                // Reading Time
                Expanded(
                  child: _buildStatPill(
                    context,
                    icon: Icons.menu_book_outlined,
                    value: formattedTime,
                    label: 'Time Read',
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
          if (lastFile != null) ...[
            const SizedBox(height: 12),
            Divider(height: 1, color: theme.colorScheme.outline.withValues(alpha: 0.08)),
            const SizedBox(height: 8),
            // Last opened row button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  log.i('Opening last file: ${lastFile.fileName}');
                  if (!lastFile.isRead) {
                    ref.read(recentFilesMutatorProvider).markAsRead(lastFile.id);
                  }
                  context.push(
                      '${RouteNames.viewer}?path=${Uri.encodeComponent(lastFile.filePath)}&name=${Uri.encodeComponent(lastFile.fileName)}');
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        Icons.history,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Last Opened: ',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          lastFile.fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildStatPill(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildEmptyRecentState(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.4,
        ),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
            width: 1,
          ),
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: Icon(
                Icons.lightbulb_outline,
                size: 28,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Welcome to Fadocx',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'Explore sample files or import your own documents',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _importSampleFiles(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.download_for_offline,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Import Sample Files',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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
          if (!file.isRead) {
            ref.read(recentFilesMutatorProvider).markAsRead(file.id);
          }
          context.push(
              '${RouteNames.viewer}?path=${Uri.encodeComponent(file.filePath)}&name=${Uri.encodeComponent(file.fileName)}');
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
                Text('In trash: yes (deleted at: ${file.deletedAt != null ? _formatDateTime(file.deletedAt!) : 'unknown'})'),
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
      buffer.writeln('In trash: yes (deleted at: ${file.deletedAt != null ? _formatDateTime(file.deletedAt!) : 'unknown'})');
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

  Widget _buildSkeletonStats() {
    final shimmer = _skeletonShimmer.value;
    final theme = Theme.of(context);
    final baseColor = theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4);
    final highlightColor = theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7);
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.12),
          width: 1,
        ),
        color: theme.colorScheme.surfaceContainerLow,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSkeletonStat(baseColor, highlightColor, shimmer),
          _buildSkeletonStat(baseColor, highlightColor, shimmer),
          _buildSkeletonStat(baseColor, highlightColor, shimmer),
        ],
      ),
    );
  }

  Widget _buildSkeletonActionCards() {
    // Slate colors for dark theme action cards
    final slateDark = const Color(0xFF2C3E50);
    final slateLight = const Color(0xFF34495E);
    final emerald = const Color(0xFF16A085);
    final emeraldLight = const Color(0xFF27AE60);
    
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 96,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [emerald, emeraldLight],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 96,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [slateDark, slateLight],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonRecentHeader() {
    final theme = Theme.of(context);
    final baseColor = theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4);
    final highlightColor = theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7);
    final shimmer = _skeletonShimmer.value;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          width: 80,
          height: 16,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment(shimmer - 1, 0),
              end: Alignment(shimmer, 0),
              colors: [baseColor, highlightColor, baseColor],
            ),
          ),
        ),
        Container(
          width: 50,
          height: 12,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment(shimmer - 1, 0),
              end: Alignment(shimmer, 0),
              colors: [baseColor, highlightColor, baseColor],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonRecentItem(int index) {
    final theme = Theme.of(context);
    final baseColor = theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4);
    final highlightColor = theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7);
    final shimmer = _skeletonShimmer.value;
    
    return Padding(
      padding: EdgeInsets.only(bottom: index < 3 ? 8 : 0),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.08),
            width: 1,
          ),
          color: theme.colorScheme.surfaceContainerLow,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment(shimmer - 1, 0),
                  end: Alignment(shimmer, 0),
                  colors: [baseColor, highlightColor, baseColor],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 12,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: LinearGradient(
                        begin: Alignment(shimmer - 1, 0),
                        end: Alignment(shimmer, 0),
                        colors: [baseColor, highlightColor, baseColor],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 80,
                    height: 10,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: LinearGradient(
                        begin: Alignment(shimmer - 1, 0),
                        end: Alignment(shimmer, 0),
                        colors: [baseColor, highlightColor, baseColor],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonStat(Color baseColor, Color highlightColor, double shimmer) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment(shimmer - 1, 0),
              end: Alignment(shimmer, 0),
              colors: [baseColor, highlightColor, baseColor],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 28,
          height: 14,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment(shimmer - 1, 0),
              end: Alignment(shimmer, 0),
              colors: [baseColor, highlightColor, baseColor],
            ),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 36,
          height: 10,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment(shimmer - 1, 0),
              end: Alignment(shimmer, 0),
              colors: [baseColor, highlightColor, baseColor],
            ),
          ),
        ),
      ],
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
              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
    final type = widget.file.fileType.toLowerCase();
    if (type == 'ppt' || type == 'pptx' || type == 'odp') {
      return;
    }
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
          return ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.memory(
              bytes,
              width: 40,
              height: 56,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              filterQuality: FilterQuality.high,
            ),
          );
        }
        return _buildThumbPlaceholder(isPresentation);
      },
      loading: () => _buildThumbPlaceholder(isPresentation),
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
  final String cardType; // 'scan' or 'import'
  final VoidCallback onTap;

  const _ModernActionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.cardType,
    required this.onTap,
  });

  @override
  State<_ModernActionCard> createState() => _ModernActionCardState();
}

class _ModernActionCardState extends State<_ModernActionCard>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;
  late AnimationController _binaryController;
  late Animation<double> _binaryAnimation;

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

    // Shimmer animation for continuous subtle effect
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // Binary animation for extraction card
    _binaryController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();

    _binaryAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _binaryController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _shimmerController.dispose();
    _binaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isScanning = widget.cardType == 'scan';

    // Use theme colors with better contrast and visual appeal
    final gradientColors = isScanning
        ? [
            const Color(0xFF16A085),  // Emerald
            const Color(0xFF27AE60),  // Green
          ]
        : [
            const Color(0xFF2C3E50),  // Deep blue-gray
            const Color(0xFF34495E),  // Slate
          ];

    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _shimmerAnimation, _binaryAnimation]),
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
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      // Animation background (bottom layer) - small black section on right
                      if (isScanning)
                        Positioned.fill(
                          child: IgnorePointer(
                            ignoring: true,
                            child: CustomPaint(
                              painter: _BinaryDigitsPainter(
                                progress: _binaryAnimation.value,
                              ),
                            ),
                          ),
                        )
                      else
                        Positioned.fill(
                            child: IgnorePointer(
                              ignoring: true,
                              child: CustomPaint(
                                painter: _IconAnimationPainter(
                                  progress: _binaryAnimation.value,
                                  preserveIdentity: true,
                                ),
                              ),
                            ),
                          ),

                      // Main content (top layer) - left aligned, overlaid on animation
                      LayoutBuilder(builder: (context, constraints) {
                        // Reserve right-side space based on diagonal start so text fits
                        final diagStartX = constraints.maxWidth * 0.85; // matches painter diagonal
                        final rightReserve = (constraints.maxWidth - diagStartX).clamp(32.0, constraints.maxWidth * 0.35);
                        return Padding(
                          padding: EdgeInsets.fromLTRB(6, 6, rightReserve + 6, 6),
                          child: ConstrainedBox(
                            // restore compact card height (previously 120)
                            constraints: BoxConstraints(minHeight: 96),
                            child: SizedBox(
                              width: constraints.maxWidth - rightReserve - 12,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      widget.icon,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  // Title - keep compact: single line with ellipsis if needed
                                  Text(
                                    widget.title,
                                    textAlign: TextAlign.left,
                                    softWrap: false,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          fontSize: 13,
                                          height: 1.15,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  // Description - keep to 2 lines to avoid tall cards
                                  Text(
                                    widget.description,
                                    textAlign: TextAlign.left,
                                    softWrap: true,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: Colors.white.withValues(alpha: 0.9),
                                          fontSize: 11,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),

                      // Chevron arrow (top right)
                      Positioned(
                        top: 8,
                        right: 10,
                        child: Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
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

// Binary digits painter for extraction card - shows animated 0s and 1s on pitch black background (diagonal right)
class _BinaryDigitsPainter extends CustomPainter {
  final double progress;

  _BinaryDigitsPainter({
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Diagonal cut path - small black area (top-right to bottom-left)
    final diagRect = Path();
    diagRect.moveTo(size.width, 0);
    diagRect.lineTo(size.width * 0.85, 0);  // Consistent with import card
    diagRect.lineTo(size.width * 0.65, size.height);  // Consistent with import card
    diagRect.lineTo(size.width, size.height);
    diagRect.close();

    final blackPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    canvas.drawPath(diagRect, blackPaint);

    // Clip animation to only appear in black area
    canvas.save();
    canvas.clipPath(diagRect);

    // Draw animated binary digits (0s and 1s) in 2 columns with offset
    const textStyle = TextStyle(
      color: Colors.white,
      fontSize: 10,
      fontFamily: 'monospace',
      fontWeight: FontWeight.bold,
      letterSpacing: 0.8,
    );

    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);

    // Seamless binary sequence
    const binarySequence = '0110101001101011010110100110';
    const spacing = 12.0;
    const colWidth = 15.0;

    // Slow animation - progress moves downward continuously
    final totalHeight = spacing * 20; // Enough rows to cover size.height
    final scrollOffset = progress * totalHeight;

    // Draw in 2 columns with offset so they don't sync
    for (int col = 0; col < 2; col++) {
      // Offset second column by half spacing for async animation
      final colOffset = col == 0 ? 0 : spacing / 2;
      
      for (int row = 0; row < 20; row++) {
        // Static digit assignment per row/column - remove progress shift to stop swapping
        final digitIndex = ((row + col * 13) + (progress * binarySequence.length).round()) % binarySequence.length;
        final digit = binarySequence[digitIndex];

        // Y position moves downward smoothly with wrapping
        double yPos = (row * spacing + colOffset + scrollOffset) % totalHeight;
        
        final xPos = (size.width * 0.82) + (col * colWidth);

        // Fade in/out at edges for seamless effect
        final distanceFromCenter = (yPos - size.height / 2).abs();
        final opacity = (1 - (distanceFromCenter / (size.height / 2))).clamp(0.0, 1.0);

        textPainter.text = TextSpan(
          text: digit,
          style: textStyle.copyWith(
            color: Colors.white.withValues(alpha: opacity * 0.75),
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(xPos - textPainter.width / 2, yPos - textPainter.height / 2),
        );
      }
    }

    canvas.restore();  // Restore clipping
  }

  @override
  bool shouldRepaint(_BinaryDigitsPainter oldDelegate) => oldDelegate.progress != progress;
}

// Icon animation painter for import card - shows animated Material document icons on black background (diagonal right)
class _IconAnimationPainter extends CustomPainter {
  final double progress;
  final bool preserveIdentity;

  _IconAnimationPainter({
    required this.progress,
    this.preserveIdentity = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Diagonal cut path - small black area (top-right to bottom-left)
    final diagRect = Path();
    diagRect.moveTo(size.width, 0);
    diagRect.lineTo(size.width * 0.85, 0);  // Even smaller
    diagRect.lineTo(size.width * 0.65, size.height);  // Much smaller
    diagRect.lineTo(size.width, size.height);
    diagRect.close();

    final blackPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    canvas.drawPath(diagRect, blackPaint);

    // Clip animation to only appear in black area
    canvas.save();
    canvas.clipPath(diagRect);

    // Draw animated Material Design icons with 2 columns for consistency
    const iconSpacing = 24.0;
    const colWidth = 22.0;

    // Document type icons to use - real Material icons for different file types
    const iconList = [
      Icons.picture_as_pdf,   // PDF
      Icons.table_chart,      // Spreadsheet/Sheet
      Icons.description,      // Word/Document
      Icons.code,             // Code/Programming
      Icons.slideshow,        // PowerPoint/Presentation
      Icons.image,            // Image
      Icons.text_fields,      // Text
      Icons.folder,           // Folder
    ];

    // Compute rows needed to fill the visible height
    const rows = 12;
    const totalHeight = rows * iconSpacing;

    // Use same perceived speed as binary: move by totalHeight per animation progress unit
    final scrollOffset = progress * totalHeight;

    // Draw in 2 columns with offset (matching scan card pattern)
    for (int col = 0; col < 2; col++) {
      // Offset second column by half spacing for async animation
      final colOffset = col == 0 ? 0.0 : iconSpacing / 2;

      for (int i = 0; i < rows; i++) {
        // Static icon assignment per logical row - strictly index based
        final iconIndex = (i + col * 3) % iconList.length;

        // Y position moves downward smoothly with wrapping
        double yPos = (i * iconSpacing + colOffset + scrollOffset) % totalHeight;
        if (yPos < -iconSpacing) yPos += totalHeight;

        final xPos = (size.width * 0.80) + (col * colWidth);

        // Fade in/out at edges for seamless effect
        final distanceFromCenter = (yPos - size.height / 2).abs();
        final opacity = (1 - (distanceFromCenter / (size.height / 2))).clamp(0.0, 1.0);

        // Draw icon as a real Material glyph
        _drawIconGlyph(canvas, Offset(xPos, yPos), iconList[iconIndex], opacity);
      }
    }

    canvas.restore();  // Restore clipping
  }

  void _drawIconGlyph(Canvas canvas, Offset center, IconData icon, double opacity) {
    // Render actual Material Design icons using TextPainter
    final textPainter = TextPainter(
      textDirection: ui.TextDirection.ltr,
    );

    // Create Material icon text span with proper styling
    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        inherit: false,
        color: Colors.white.withValues(alpha: opacity * 0.85),
        fontSize: 14.0,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
      ),
    );

    textPainter.layout();
    
    // Draw the icon centered at the given position
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(_IconAnimationPainter oldDelegate) => oldDelegate.progress != progress;
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
