import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fadocx/config/theme/theme_provider.dart';
import 'package:fadocx/features/settings/data/datasources/hive_datasource.dart';
import 'package:fadocx/features/settings/data/models/hive_models.dart';
import 'package:fadocx/features/viewer/domain/entities/parsed_document_entity.dart';
import 'package:fadocx/features/viewer/presentation/widgets/document_viewer_factory.dart';
import 'package:fadocx/features/viewer/presentation/widgets/modern_pdf_viewer.dart';
import 'package:fadocx/features/viewer/presentation/providers/document_viewer_notifier.dart';
import 'package:fadocx/features/home/presentation/widgets/home_drawer.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ViewerScreen extends ConsumerStatefulWidget {
  final String filePath;
  final String fileName;

  const ViewerScreen({
    required this.filePath,
    required this.fileName,
    super.key,
  });

  @override
  ConsumerState<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends ConsumerState<ViewerScreen>
    with TickerProviderStateMixin {
  static const double _kSidebarTopOffset = 56;
  static const double _kSidebarBottomOffset = 88;
  static const double _kSidebarRadius = 24.0;

  bool _controlsVisible = true;
  bool _invertColors = false;
  bool _textMode = false;
  bool _bottomMenuExpanded = false;
  bool _sidebarOpen = false;
  int _currentPage = 1;
  int _totalPages = 0;
  late AnimationController _menuController;
  late AnimationController _sidebarController;
  late AnimationController _topBarController;
  late AnimationController _bottomPanelController;
  late GlobalKey<State<ModernPdfViewer>> _pdfViewerKey;

  void _toggleControls() {
    final willBeVisible = !_controlsVisible;
    setState(() {
      _controlsVisible = willBeVisible;
      if (!willBeVisible) {
        _sidebarOpen = false;
        _bottomMenuExpanded = false;
      }
    });
    // Animate top/bottom together
    if (willBeVisible) {
      _topBarController.forward();
      _bottomPanelController.forward();
    } else {
      _topBarController.reverse();
      _bottomPanelController.reverse();
      _sidebarController.reverse();
      _menuController.reverse();
    }
  }

  void _toggleBottomMenu() {
    setState(() {
      _bottomMenuExpanded = !_bottomMenuExpanded;
    });
    if (_bottomMenuExpanded) {
      _menuController.forward();
    } else {
      _menuController.reverse();
    }
  }

  void _toggleSidebar() {
    (_pdfViewerKey.currentState as dynamic)?.toggleSidebar();
    setState(() {
      _sidebarOpen = !_sidebarOpen;
    });
    if (_sidebarOpen) {
      _sidebarController.forward();
    } else {
      _sidebarController.reverse();
    }
  }

  void _onSearchHighlight() {
    if (!_sidebarOpen) return;
    (_pdfViewerKey.currentState as dynamic)?.toggleSidebar();
    setState(() => _sidebarOpen = false);
    _sidebarController.reverse();
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        (_pdfViewerKey.currentState as dynamic)?.toggleSidebar();
        setState(() => _sidebarOpen = true);
        _sidebarController.forward();
      }
    });
  }

  void _goToFirstPage() {
    (_pdfViewerKey.currentState as dynamic)?.goToFirstPage();
  }

  void _goToPreviousPage() {
    (_pdfViewerKey.currentState as dynamic)?.goToPreviousPage();
  }

  void _goToNextPage() {
    (_pdfViewerKey.currentState as dynamic)?.goToNextPage();
  }

  void _goToLastPage() {
    (_pdfViewerKey.currentState as dynamic)?.goToLastPage();
  }

  void _showGoToPageDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Go to Page'),
        content: TextField(
          controller: textController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Enter page number (1-$_totalPages)',
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final pageNum = int.tryParse(textController.text);
              if (pageNum != null && pageNum >= 1 && pageNum <= _totalPages) {
                (_pdfViewerKey.currentState as dynamic)?.goToPage(pageNum);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Please enter a number between 1 and $_totalPages'),
                  ),
                );
              }
            },
            child: const Text('Go'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _pdfViewerKey = GlobalKey<State<ModernPdfViewer>>();
    _menuController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _sidebarController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _topBarController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _bottomPanelController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    // Set initial values NOW in constructor (before first build)
    // This ensures controls visible on first frame
    _topBarController.value = 1.0;
    _bottomPanelController.value = 1.0;
    _sidebarController.value = 0.0;

    // Load document if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final docState = ref.read(documentViewerProvider);
      if (!docState.isLoading &&
          docState.document == null &&
          !docState.hasError) {
        ref
            .read(documentViewerProvider.notifier)
            .initializeAndLoad(widget.filePath, widget.fileName);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update system UI overlay when theme changes
    _updateSystemUIOverlay();
  }

  void _updateSystemUIOverlay() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: surfaceColor,
        statusBarBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: surfaceColor,
      ),
    );
  }

  @override
  void dispose() {
    _menuController.dispose();
    _sidebarController.dispose();
    _topBarController.dispose();
    _bottomPanelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final docState = ref.watch(documentViewerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: docState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : docState.hasError
                      ? _buildErrorState(context, ref, docState)
                      : docState.document != null
                          ? _buildContentViewer(
                              document: docState.document!,
                            )
                          : const Center(child: Text('No content')),
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
                    child: _sidebarOpen && _controlsVisible
                        ? _buildSidebarDrawer(context, isDark)
                        : const SizedBox.shrink(),
                  ),
                );
              },
            ),

            // Always show top/bottom panels - let controller handle visibility
            AnimatedBuilder(
              animation: _topBarController,
              builder: (context, child) {
                return Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -1.0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _topBarController,
                      curve: Curves.easeOutCubic,
                    )),
                    child: _buildFloatingTopBar(context, isDark),
                  ),
                );
              },
            ),

            // Bottom panel with slide animation
            AnimatedBuilder(
              animation: _bottomPanelController,
              builder: (context, child) {
                return Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 1.0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _bottomPanelController,
                      curve: Curves.easeOutCubic,
                    )),
                    child: _buildFloatingBottomPanel(context, isDark),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentViewer({required ParsedDocumentEntity document}) {
    // For PDFs, use ModernPdfViewer with GlobalKey to access navigation
    if (document.format.toUpperCase() == 'PDF') {
      return ModernPdfViewer(
        key: _pdfViewerKey,
        filePath: widget.filePath,
        fileName: widget.fileName,
        invertColors: _invertColors,
        textMode: _textMode,
        onTap: _toggleControls,
        onInvertToggle: () {
          setState(() => _invertColors = !_invertColors);
        },
        onTextModeToggle: () {
          setState(() => _textMode = !_textMode);
        },
        onPageChanged: (current, total) {
          if (total > 0) {
            setState(() {
              _currentPage = current;
              _totalPages = total;
            });
          }
        },
        onSearchHighlight: _onSearchHighlight,
      );
    }
    // For other document types, use the factory
    return DocumentViewerFactory.createViewer(
      document: document,
      filePath: widget.filePath,
      invertColors: _invertColors,
      textMode: _textMode,
      onInvertToggle: () {
        setState(() => _invertColors = !_invertColors);
      },
      onTextModeToggle: () {
        setState(() => _textMode = !_textMode);
      },
    );
  }

  Widget _buildFloatingTopBar(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () {}, // Absorb taps to prevent triggering PDF tap
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
                    color: isDark
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
                color: isDark
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
                            onPressed: () => context.pop(),
                            tooltip: 'Back',
                            iconSize: 20,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.fileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
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
    );
  }

  Widget _buildIconButton(
    BuildContext context,
    IconData icon,
    VoidCallback? onTap,
  ) {
    return SizedBox(
      width: 32,
      height: 32,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Icon(
            icon,
            size: 16,
            color: onTap != null
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator(BuildContext context) {
    return GestureDetector(
      onTap: _totalPages > 1 ? _showGoToPageDialog : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '$_currentPage/$_totalPages',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      ),
    );
  }

  Widget _buildTile({required IconData icon, required String label, required VoidCallback onTap}) {
    return Material(color: Colors.transparent, child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: Container(padding: EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12)), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 20), SizedBox(height: 4), Text(label, style: Theme.of(context).textTheme.labelSmall)]))));
  }

  void _copyPdfText() async {
    final viewerState = _pdfViewerKey.currentState as dynamic;
    if (viewerState == null) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Extracting text from all pages...'),
          ],
        ),
      ),
    );

    try {
      final extractMethod = viewerState.extractAllText;
      if (extractMethod == null) {
        Navigator.pop(context);
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Text extraction not available')),
        );
        return;
      }

      final result = await extractMethod() as Map<String, dynamic>;
      if (!mounted) return;
      Navigator.pop(context);

      final text = result['text'] as String;
      final wordCount = result['wordCount'] as int;
      final pageCount = result['pageCount'] as int;

      if (text.isEmpty) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('No text found in this PDF')),
        );
        return;
      }

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.copy_all,
                  size: 20, color: Theme.of(ctx).colorScheme.primary),
              const SizedBox(width: 8),
              const Text('Copy All Text'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'This will extract text from all $pageCount pages and copy to clipboard.'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.text_fields,
                        size: 16, color: Theme.of(ctx).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      '$wordCount words found',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(ctx).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                await Clipboard.setData(ClipboardData(text: text));
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Copied $wordCount words from $pageCount pages'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy'),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Widget _buildFloatingBottomPanel(BuildContext context, bool isDark) {
    return Stack(
      children: [
        // Shadow above the bottom panel
        Positioned(
          top: -8,
          left: 0,
          right: 0,
          height: 8,
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
          ),
        ),
        // Bottom panel container
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              decoration: BoxDecoration(
              color: isDark
                  ? Theme.of(context)
                      .colorScheme
                      .surface
                      .withValues(alpha: 0.95)
                  : Theme.of(context)
                      .colorScheme
                      .surface
                      .withValues(alpha: 0.92),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(
                top: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: null, // Removed tap-to-toggle from bottom panel
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
child: Row(
                          children: [
                            // Left: hamburger
                            AnimatedHamburgerIcon(
                              onPressed: _toggleSidebar,
                              isOpen: _sidebarOpen,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            // Center: nav controls in Expanded
                            Expanded(
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildIconButton(
                                      context,
                                      Icons.first_page,
                                      _currentPage > 1 ? _goToFirstPage : null,
                                    ),
                                    _buildIconButton(
                                      context,
                                      Icons.chevron_left,
                                      _currentPage > 1 ? _goToPreviousPage : null,
                                    ),
                                    _buildPageIndicator(context),
                                    _buildIconButton(
                                      context,
                                      Icons.chevron_right,
                                      _currentPage < _totalPages ? _goToNextPage : null,
                                    ),
                                    _buildIconButton(
                                      context,
                                      Icons.last_page,
                                      _currentPage < _totalPages ? _goToLastPage : null,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Right: expand button
                            _buildIconButton(
                              context,
                              _bottomMenuExpanded
                                  ? Icons.expand_more
                                  : Icons.expand_less,
                              _toggleBottomMenu,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizeTransition(
                      sizeFactor: CurvedAnimation(
                        parent: _menuController,
                        curve: Curves.easeInOutCubic,
                      ),
                      axisAlignment: -1.0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Divider(height: 1, indent: 16, endIndent: 16, color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
                          Padding(padding: EdgeInsets.all(12), child: Row(children: [
                            Expanded(child: _buildTile(icon: Icons.copy_all, label: 'Copy', onTap: _copyPdfText)),
                            SizedBox(width: 8),
                            Expanded(child: _buildTile(icon: _invertColors ? Icons.brightness_high : Icons.brightness_low, label: 'Invert', onTap: () => setState(() => _invertColors = !_invertColors))),
                            SizedBox(width: 8),
                            Expanded(child: _buildTile(icon: _textMode ? Icons.picture_as_pdf : Icons.text_snippet, label: _textMode ? 'PDF' : 'Text', onTap: () => setState(() => _textMode = !_textMode))),
                            SizedBox(width: 8),
                            Expanded(child: _buildTile(icon: Theme.of(context).brightness == Brightness.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, label: 'Theme', onTap: () async {
                              final notifier = ref.read(themeModeProvider.notifier);
                              notifier.toggleThemeMode();
                              final mode = ref.read(themeModeProvider);
                              final box = Hive.box<HiveAppSettings>(HiveDatasource.settingsBoxName);
                              final settings = box.values.firstOrNull ?? HiveAppSettings();
                              await box.put(0, settings.copyWith(theme: mode.value));
                            })),
                          ])),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarDrawer(BuildContext context, bool isDark) {
    final viewerState = _pdfViewerKey.currentState as dynamic;
    final drawerContent = viewerState?.buildDrawerContent(context) as Widget?;
    if (drawerContent == null) {
      return const SizedBox.shrink();
    }

    final maxWidth = MediaQuery.of(context).size.width * 0.8;
    final width = maxWidth < 280 ? maxWidth : 280.0;
    final theme = Theme.of(context);
    final bgColor = isDark
        ? theme.colorScheme.surface.withValues(alpha: 0.95)
        : theme.colorScheme.surface.withValues(alpha: 0.92);
    final borderColor = theme.colorScheme.outline.withValues(alpha: 0.2);

    return GestureDetector(
      onTap: () {},
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
            // 2. Content (Sheet) - Body starts at x=0
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
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                    ),
                    child: drawerContent,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(
      BuildContext context, WidgetRef ref, ParsedDocumentState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              state.error ?? 'Error loading document',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              ref
                  .read(documentViewerProvider.notifier)
                  .initializeAndLoad(widget.filePath, widget.fileName);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
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
