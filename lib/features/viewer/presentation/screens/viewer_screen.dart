import 'dart:ui';
import 'package:flutter/material.dart';
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
    with SingleTickerProviderStateMixin {
  static const double _kTapMovementThreshold = 5;
  static const double _kSidebarTopOffset = 56;
  static const double _kSidebarBottomOffset = 88;

  bool _invertColors = false;
  bool _textMode = false;
  bool _controlsVisible = true;
  bool _bottomMenuExpanded = false;
  int _currentPage = 1;
  int _totalPages = 0;
  late AnimationController _menuController;
  late GlobalKey<State<ModernPdfViewer>> _pdfViewerKey;
  Offset? _pointerDownPosition;
  bool _pointerMoved = false;

  void _toggleControls() {
    setState(() {
      _controlsVisible = !_controlsVisible;
      _bottomMenuExpanded = false;
      _menuController.reverse();
    });
  }

  void _handleViewerPointerDown(PointerDownEvent event) {
    _pointerDownPosition = event.position;
    _pointerMoved = false;
  }

  void _handleViewerPointerMove(PointerMoveEvent event) {
    final pointerDownPosition = _pointerDownPosition;
    if (pointerDownPosition == null || _pointerMoved) {
      return;
    }

    if ((event.position - pointerDownPosition).distance >=
        _kTapMovementThreshold) {
      _pointerMoved = true;
    }
  }

  void _handleViewerPointerUp(PointerUpEvent event) {
    final pointerDownPosition = _pointerDownPosition;
    if (pointerDownPosition == null) {
      return;
    }

    final isTap =
        !_pointerMoved &&
        (event.position - pointerDownPosition).distance <
            _kTapMovementThreshold;

    _pointerDownPosition = null;
    _pointerMoved = false;

    if (!isTap) {
      return;
    }

    if (_bottomMenuExpanded) {
      return;
    }

    _toggleControls();
  }

  void _handleViewerPointerCancel(PointerCancelEvent event) {
    _pointerDownPosition = null;
    _pointerMoved = false;
  }

  bool get _showSidebarDrawer {
    final viewerState = _pdfViewerKey.currentState as dynamic;
    return _controlsVisible && (viewerState?.showSidebar ?? false);
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
    if (mounted) {
      setState(() {});
    }
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
  void dispose() {
    _menuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final docState = ref.watch(documentViewerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          Positioned.fill(
            child: Listener(
              onPointerDown: _handleViewerPointerDown,
              onPointerMove: _handleViewerPointerMove,
              onPointerUp: _handleViewerPointerUp,
              onPointerCancel: _handleViewerPointerCancel,
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
          ),

          if (_showSidebarDrawer)
            Positioned(
              top: _kSidebarTopOffset,
              bottom: _kSidebarBottomOffset,
              left: 0,
              child: _buildSidebarDrawer(context, isDark),
            ),

          if (_controlsVisible)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildFloatingTopBar(context, isDark),
            ),

          if (_controlsVisible)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildFloatingBottomPanel(context, isDark),
            ),
        ],
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
        onInvertToggle: () {
          setState(() => _invertColors = !_invertColors);
        },
        onTextModeToggle: () {
          setState(() => _textMode = !_textMode);
        },
        onPageChanged: (current, total) {
          setState(() {
            _currentPage = current;
            _totalPages = total;
          });
        },
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
    return Stack(
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
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
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
    );
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
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
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
                      onTap: !_bottomMenuExpanded ? _toggleControls : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
mainAxisSize: MainAxisSize.min,
                                children: [
                                  CustomHamburgerIcon(
                                    onPressed: _toggleSidebar,
                                    sidebarOpen: _showSidebarDrawer,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap:
                                          _currentPage > 1 ? _goToFirstPage : null,
                                      borderRadius: BorderRadius.circular(8),
                                      child: Icon(
                                        Icons.first_page,
                                        size: 16,
                                        color: _currentPage > 1
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant
                                                .withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _currentPage > 1
                                          ? _goToPreviousPage
                                          : null,
                                      borderRadius: BorderRadius.circular(8),
                                      child: Icon(
                                        Icons.chevron_left,
                                        size: 16,
                                        color: _currentPage > 1
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant
                                                .withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap:
                                      _totalPages > 1 ? _showGoToPageDialog : null,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primaryContainer
                                          .withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '$_currentPage/$_totalPages',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _currentPage < _totalPages
                                          ? _goToNextPage
                                          : null,
                                      borderRadius: BorderRadius.circular(8),
                                      child: Icon(
                                        Icons.chevron_right,
                                        size: 16,
                                        color: _currentPage < _totalPages
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant
                                                .withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _currentPage < _totalPages
                                          ? _goToLastPage
                                          : null,
                                      borderRadius: BorderRadius.circular(8),
                                      child: Icon(
                                        Icons.last_page,
                                        size: 16,
                                        color: _currentPage < _totalPages
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant
                                                .withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _toggleBottomMenu,
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    _bottomMenuExpanded
                                        ? Icons.expand_more
                                        : Icons.expand_less,
                                    size: 20,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_bottomMenuExpanded) ...[
                      Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.2),
                      ),
                      // Invert colors option
                      _buildMenuOption(
                        context,
                        icon: _invertColors
                            ? Icons.brightness_high
                            : Icons.brightness_low,
                        label: 'Invert Colors',
                        isActive: _invertColors,
                        onTap: () {
                          setState(() => _invertColors = !_invertColors);
                        },
                      ),
                      Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.2),
                      ),
                      // Text/PDF mode option
                      _buildMenuOption(
                        context,
                        icon: _textMode
                            ? Icons.picture_as_pdf
                            : Icons.text_snippet,
                        label: _textMode ? 'PDF Mode' : 'Text Mode',
                        isActive: _textMode,
                        onTap: () {
                          setState(() => _textMode = !_textMode);
                        },
                      ),
                      Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.2),
                      ),
                      // Theme toggle option
                      _buildMenuOption(
                        context,
                        icon: Theme.of(context).brightness == Brightness.dark
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined,
                        label: 'Toggle Theme',
                        isActive: false,
                        onTap: () async {
                          final notifier =
                              ref.read(themeModeProvider.notifier);
                          notifier.toggleThemeMode();
                          final mode = ref.read(themeModeProvider);
                          final box = Hive.box<HiveAppSettings>(
                              HiveDatasource.settingsBoxName);
                          final settings =
                              box.values.firstOrNull ?? HiveAppSettings();
                          await box.put(0,
                              settings.copyWith(theme: mode.value));
                        },
                      ),
                    ],
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

    return SafeArea(
      child: GestureDetector(
        onTap: () {},
        behavior: HitTestBehavior.opaque,
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: width,
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
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.2),
                  ),
                ),
                child: drawerContent,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: isActive
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
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
