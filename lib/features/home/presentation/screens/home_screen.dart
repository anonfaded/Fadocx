import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fadocx/core/utils/logger.dart';
import 'package:fadocx/config/routing/app_router.dart';
import 'package:fadocx/core/presentation/widgets/floating_dock_scaffold.dart';
import 'package:fadocx/features/settings/domain/entities/app_settings.dart';
import 'package:fadocx/features/settings/presentation/providers/settings_providers.dart';
import 'package:fadocx/features/home/presentation/providers/thumbnail_provider.dart';
import 'package:fadocx/features/home/presentation/widgets/home_drawer.dart';

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
  
  static const double _kSidebarTopOffset = 56;
  static const double _kSidebarBottomOffset = 88;
  static const double _kSidebarRadius = 24.0;

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
            const SizedBox(width: 8),
            // Logo icon on left with natural width
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
          // Sidebar with slide-in animation
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
                  child: _sidebarOpen ? _buildSidebarDrawer(context, isDark) : const SizedBox.shrink(),
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
        return recentFiles.when(
          data: (files) => _buildHomeContent(context, files, showRecentFiles),
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

  Widget _buildHomeContent(BuildContext context, List<RecentFile> files, bool showRecentFiles) {
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

        // Recent Files Section - only show if enabled
        if (showRecentFiles && files.isNotEmpty) ...[
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
          _buildEmptyRecentState(context),
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
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'No Recent Files',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Scan or import documents to get started',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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

  Widget _buildSidebarDrawer(BuildContext context, bool isDark) {
    final maxWidth = MediaQuery.of(context).size.width * 0.8;
    final width = maxWidth < 280 ? maxWidth : 280.0;
    final theme = Theme.of(context);
    final bgColor = isDark
        ? theme.colorScheme.surface.withValues(alpha: 0.95)
        : theme.colorScheme.surface.withValues(alpha: 0.92);
    final borderColor = theme.colorScheme.outline.withValues(alpha: 0.2);

    return GestureDetector(
      onTap: () {}, // Absorb taps to prevent propagation
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width + 20,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 1. Background and Flares
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

/// Modern Compact Action Card with layered icon effect
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
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.01).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHover(bool hovering) {
    setState(() => _isHovered = hovering);
    if (hovering) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isScanning = widget.icon == Icons.document_scanner;

    final gradientStart = isScanning
        ? Color.lerp(primaryColor, const Color(0xFF3B82F6), 0.4)!
        : Color.lerp(primaryColor, const Color(0xFF10B981), 0.4)!;
    final gradientEnd = isScanning
        ? Color.lerp(primaryColor, const Color(0xFF8B5CF6), 0.3)!
        : Color.lerp(primaryColor, const Color(0xFF0EA5E9), 0.3)!;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: MouseRegion(
            onEnter: (_) => _onHover(true),
            onExit: (_) => _onHover(false),
            child: GestureDetector(
              onTapDown: (_) => _controller.forward(),
              onTapUp: (_) {
                _controller.reverse();
                widget.onTap();
              },
              onTapCancel: () => _controller.reverse(),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.06),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        gradientStart,
                        gradientEnd,
                      ],
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Icon on top
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: _isHovered ? 8 : 0),
                            duration: const Duration(milliseconds: 300),
                            builder: (context, offset, _) {
                              return Transform.translate(
                                offset: Offset(0, -offset * 0.1),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    widget.icon,
                                    size: 32,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),

                          // Text content below
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Title
                              Text(
                                widget.title,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                              ),
                              const SizedBox(height: 6),

                              // Description
                              Text(
                                widget.description,
                                textAlign: TextAlign.center,
                                maxLines: 3,
                                overflow: TextOverflow.clip,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color:
                                          Colors.white.withValues(alpha: 0.8),
                                      fontSize: 12,
                                      height: 1.3,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
