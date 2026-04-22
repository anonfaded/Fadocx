import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:fadocx/config/theme/theme_provider.dart';
import 'package:fadocx/features/viewer/data/providers/repository_providers.dart';
import 'package:fadocx/features/viewer/domain/entities/parsed_document_entity.dart';
import 'package:fadocx/features/viewer/presentation/widgets/text_document_viewer.dart';
import 'package:fadocx/features/viewer/presentation/widgets/modern_pdf_viewer.dart';
import 'package:fadocx/features/viewer/presentation/widgets/document_viewer_factory.dart';
import 'package:fadocx/features/viewer/presentation/providers/document_viewer_notifier.dart';
import 'package:fadocx/features/home/presentation/widgets/home_drawer.dart';
import 'package:fadocx/features/home/presentation/providers/thumbnail_provider.dart';
import 'package:fadocx/core/services/thumbnail_generation_service.dart';
import 'package:fadocx/features/settings/presentation/providers/settings_providers.dart';

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
  static final _log = Logger();
  static const int _readingWordsPerMinute = 200;
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
  int? _documentWordCount;
  int? _documentLineCount;
  double _sidebarDragOffset = 0.0;
  double _textFontSize = 14;
  bool _textWordWrap = true;
  bool _textFontIsMonoFont = false;
  late AnimationController _menuController;
  late AnimationController _sidebarController;
  late AnimationController _topBarController;
  late AnimationController _bottomPanelController;
  late GlobalKey<State<ModernPdfViewer>> _pdfViewerKey;
  late GlobalKey<State<TextDocumentViewer>> _textViewerKey;
  static const double _kDragCloseThreshold = 100.0;

  bool _isPdfDocument() {
    final doc = ref.read(documentViewerProvider).document;
    return doc?.format.toUpperCase() == 'PDF';
  }

  bool _isTextDocument() {
    final format =
        ref.read(documentViewerProvider).document?.format.toUpperCase();
    return format == 'TXT' || format == 'DOCX' || format == 'DOC';
  }

  bool _canOpenSidebar() {
    if (!_controlsVisible) return false;
    if (_isPdfDocument()) {
      return _pdfViewerKey.currentState != null;
    }
    if (_isTextDocument()) {
      return _textViewerKey.currentState != null;
    }
    return false;
  }

  Widget? _resolveSidebarContent(BuildContext context) {
    if (_isPdfDocument()) {
      final viewerState = _pdfViewerKey.currentState as dynamic;
      return viewerState?.buildDrawerContent(context) as Widget?;
    }
    if (_isTextDocument()) {
      final viewerState = _textViewerKey.currentState as dynamic;
      return viewerState?.buildDrawerContent(context) as Widget?;
    }
    return null;
  }

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
    if (!_canOpenSidebar()) {
      _log.d('Sidebar toggle ignored: no sidebar content available yet.');
      return;
    }
    if (_isPdfDocument()) {
      (_pdfViewerKey.currentState as dynamic)?.toggleSidebar();
    }
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
    if (_isPdfDocument()) {
      final viewerState = _pdfViewerKey.currentState as dynamic;
      final isSidebarOpen = viewerState?.showSidebar as bool? ?? false;
      if (isSidebarOpen) {
        viewerState?.toggleSidebar();
      }
    }
    setState(() => _sidebarOpen = false);
    _sidebarController.reverse();
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        if (_isPdfDocument()) {
          final viewerState = _pdfViewerKey.currentState as dynamic;
          final isSidebarOpen = viewerState?.showSidebar as bool? ?? false;
          if (!isSidebarOpen) {
            viewerState?.toggleSidebar();
          }
        }
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

  void _closeSidebar() {
    if (_isPdfDocument()) {
      (_pdfViewerKey.currentState as dynamic)?.toggleSidebar();
    }
    setState(() => _sidebarOpen = false);
    _sidebarController.reverse();
  }

  void _handleSidebarDragUpdate(DragUpdateDetails details) {
    setState(() {
      _sidebarDragOffset += details.delta.dx;
      _sidebarDragOffset = _sidebarDragOffset.clamp(-500, 0.0);
    });
  }

  void _handleSidebarDragEnd(DragEndDetails details) {
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
      setState(() => _sidebarDragOffset = 0.0);
    }
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
    _textViewerKey = GlobalKey<State<TextDocumentViewer>>();
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
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
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

            // Scrim overlay with dimming and tap-to-close - controlled by sidebar state
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !_sidebarOpen || !_controlsVisible,
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
                      child: _controlsVisible
                          ? _buildSidebarDrawer(context, isDark)
                          : const SizedBox.shrink(),
                    ),
                  ),
                );
              },
            ),

            // Always show top/bottom panels - let controller handle visibility
            AnimatedBuilder(
              animation: _topBarController,
              builder: (context, child) {
                return Positioned(
                  top: MediaQuery.of(context).padding.top,
                  left: 0,
                  right: 0,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -2.0),
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
    final format = document.format.toUpperCase();

    // For PDFs, use ModernPdfViewer with GlobalKey to access navigation
    if (format == 'PDF') {
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
        initialWordCount: document.wordCount,
        initialLineCount: document.lineCount,
        onTextStatsChanged: (wordCount, lineCount) {
          if (!mounted) return;
          setState(() {
            _documentWordCount = wordCount;
            _documentLineCount = lineCount;
          });
          _cachePdfTextStats(document, wordCount, lineCount);
        },
      );
    }

    // For TXT/DOCX/DOC, use TextDocumentViewer with tap controls
    if (format == 'TXT' || format == 'DOCX' || format == 'DOC') {
      return TextDocumentViewer(
        key: _textViewerKey,
        textContent: document.textContent,
        onTap: _toggleControls,
        onSearchHighlight: _onSearchHighlight,
        fontSize: _textFontSize,
        wordWrap: _textWordWrap,
        useMonoFont: _textFontIsMonoFont,
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
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
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
                          ),
                          const Align(
                            alignment: Alignment.centerRight,
                            child: SizedBox(
                              width: 32,
                              height: 32,
                            ),
                          ),
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 420),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    widget.fileName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  _buildTimeToRead(context),
                                ],
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

  Widget _buildTimeToRead(BuildContext context) {
    final docState = ref.watch(documentViewerProvider);
    if (docState.document == null) {
      return const SizedBox.shrink();
    }

    final document = docState.document!;
    final textContent = document.textContent ?? '';
    final hasEmbeddedText = textContent.isNotEmpty;
    final wordCount = hasEmbeddedText
        ? textContent.split(RegExp(r'\s+')).length
        : (document.wordCount ?? _documentWordCount);
    final lineCount = hasEmbeddedText
        ? textContent.split(RegExp(r'\r\n|\r|\n')).length
        : (document.lineCount ?? _documentLineCount);

    if (wordCount == null || lineCount == null || wordCount == 0) {
      return const SizedBox.shrink();
    }

    final readingMinutes =
        (wordCount / _readingWordsPerMinute).ceil().clamp(1, 999);
    final minuteLabel = readingMinutes == 1 ? 'minute' : 'minutes';

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        '$readingMinutes $minuteLabel read • $wordCount words • $lineCount lines',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }

  Future<void> _cachePdfTextStats(
    ParsedDocumentEntity document,
    int wordCount,
    int lineCount,
  ) async {
    if (document.format.toUpperCase() != 'PDF') return;
    if (document.wordCount == wordCount && document.lineCount == lineCount) {
      return;
    }

    final cachedDocument = document.copyWith(
      wordCount: wordCount,
      lineCount: lineCount,
      parsedAt: DateTime.now(),
    );

    try {
      final repository = ref.read(documentParsingRepositoryProvider);
      await repository.cacheParsing(widget.filePath, cachedDocument);

      final thumbnailBytes = await ThumbnailGenerationService.generateThumbnail(
        widget.filePath,
        widget.fileName,
        'pdf',
        cachedDocument: cachedDocument,
      );
      if (thumbnailBytes != null) {
        final hiveDatasource = ref.read(hiveDatasourceProvider);
        final recentFiles = await hiveDatasource.getRecentFiles();
        for (final file in recentFiles) {
          if (file.filePath == widget.filePath) {
            await hiveDatasource.saveThumbnail(file.id, thumbnailBytes);
            ref.invalidate(thumbnailProvider(file.id));
            break;
          }
        }
      }
    } catch (e, st) {
      _log.w('Failed to cache PDF text stats', error: e, stackTrace: st);
    }
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
                : Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(alpha: 0.5),
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
          color: Theme.of(context)
              .colorScheme
              .primaryContainer
              .withValues(alpha: 0.3),
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

  Widget _buildTile(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20),
              const SizedBox(height: 4),
              Text(label, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ),
      ),
    );
  }

  void _copyPdfText() async {
    final viewerState = _pdfViewerKey.currentState as dynamic;
    if (viewerState == null) return;

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
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Text extraction not available')),
          );
        }
        return;
      }

      final result = await extractMethod() as Map<String, dynamic>;
      if (mounted) {
        Navigator.pop(context);
      }

      final text = result['text'] as String;
      final wordCount = result['wordCount'] as int;
      final pageCount = result['pageCount'] as int;

      if (text.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No text found in this PDF')),
          );
        }
        return;
      }

      if (mounted) {
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Copied $wordCount words from $pageCount pages'),
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
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _copyDocumentText() async {
    // For TXT/DOCX/DOC, copy all content
    final doc = ref.watch(documentViewerProvider);
    if (doc.document == null) return;

    final text = doc.document!.textContent ?? '';
    if (text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No text content available')),
        );
      }
      return;
    }

    final wordCount = text.split(RegExp(r'\s+')).length;
    final lineCount = text.split('\n').length;

    if (mounted) {
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
              Text('This will copy the entire document content to clipboard.'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.text_fields,
                            size: 16, color: Theme.of(ctx).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          '$wordCount words',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(ctx).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.format_list_numbered,
                            size: 16, color: Theme.of(ctx).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          '$lineCount lines',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(ctx).colorScheme.primary,
                          ),
                        ),
                      ],
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('Copied $wordCount words from $lineCount lines'),
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
    }
  }

  Widget _buildFloatingBottomPanel(BuildContext context, bool isDark) {
    final canOpenSidebar = _canOpenSidebar();

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
                    // Main control row
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {}, // Absorb taps but don't hide controls
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            // Left: hamburger
                            Opacity(
                              opacity: canOpenSidebar ? 1.0 : 0.5,
                              child: IgnorePointer(
                                ignoring: !canOpenSidebar,
                                child: AnimatedHamburgerIcon(
                                  onPressed: _toggleSidebar,
                                  isOpen: _sidebarOpen,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            // Center: format-specific nav controls
                            Expanded(
                              child: Center(
                                child: _buildFormatSpecificControls(context),
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
                    // Expandable menu
                    SizeTransition(
                      sizeFactor: CurvedAnimation(
                        parent: _menuController,
                        curve: Curves.easeInOutCubic,
                      ),
                      axisAlignment: -1.0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                            color: Theme.of(context)
                                .colorScheme
                                .outline
                                .withValues(alpha: 0.2),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: _buildExpandedMenuContent(context),
                          ),
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

  /// Build format-specific controls for the center of the panel
  Widget _buildFormatSpecificControls(BuildContext context) {
    final docState = ref.watch(documentViewerProvider);
    if (docState.document == null) return const SizedBox.shrink();

    final format = docState.document!.format.toUpperCase();

    if (format == 'PDF') {
      return Row(
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
      );
    } else if (format == 'TXT' || format == 'DOCX' || format == 'DOC') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIconButton(
            context,
            Icons.remove,
            _textFontSize > 10
                ? () => setState(
                    () => _textFontSize = (_textFontSize - 1).clamp(10, 24))
                : null,
          ),
          SizedBox(
            width: 50,
            child: Center(
              child: Text(
                '${_textFontSize.toStringAsFixed(0)}pt',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ),
          _buildIconButton(
            context,
            Icons.add,
            _textFontSize < 24
                ? () => setState(
                    () => _textFontSize = (_textFontSize + 1).clamp(10, 24))
                : null,
          ),
          const SizedBox(width: 8),
          _buildIconButton(
            context,
            _textWordWrap ? Icons.wrap_text : Icons.text_fields,
            () => setState(() => _textWordWrap = !_textWordWrap),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  /// Build the expanded menu content (Copy, Invert, TextMode, Theme buttons)
  Widget _buildExpandedMenuContent(BuildContext context) {
    final docState = ref.watch(documentViewerProvider);
    if (docState.document == null) return const SizedBox.shrink();

    final format = docState.document!.format.toUpperCase();

    if (format == 'PDF') {
      return Row(
        children: [
          Expanded(
            child: _buildTile(
              icon: Icons.copy_all,
              label: 'Copy',
              onTap: _copyPdfText,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTile(
              icon:
                  _invertColors ? Icons.brightness_high : Icons.brightness_low,
              label: 'Invert',
              onTap: () => setState(
                () => _invertColors = !_invertColors,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTile(
              icon: _textMode ? Icons.picture_as_pdf : Icons.text_snippet,
              label: _textMode ? 'PDF' : 'Text',
              onTap: () => setState(
                () => _textMode = !_textMode,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTile(
              icon: Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              label: 'Theme',
              onTap: () {
                ref.read(themeModeProvider.notifier).toggleThemeMode();
              },
            ),
          ),
        ],
      );
    } else if (format == 'TXT' || format == 'DOCX' || format == 'DOC') {
      return Row(
        children: [
          Expanded(
            child: _buildTile(
              icon: Icons.copy_all,
              label: 'Copy',
              onTap: _copyDocumentText,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTile(
              icon: Icons.font_download,
              label: 'Font',
              onTap: () {
                // Toggle font between Mono and Ubuntu
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Font Style'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          title: const Text('Monospace (Courier)'),
                          trailing: _textFontIsMonoFont
                              ? Icon(Icons.check,
                                  color: Theme.of(ctx).colorScheme.primary)
                              : null,
                          onTap: () {
                            setState(() => _textFontIsMonoFont = true);
                            Navigator.pop(ctx);
                          },
                        ),
                        ListTile(
                          title: const Text('System (Ubuntu)'),
                          trailing: !_textFontIsMonoFont
                              ? Icon(Icons.check,
                                  color: Theme.of(ctx).colorScheme.primary)
                              : null,
                          onTap: () {
                            setState(() => _textFontIsMonoFont = false);
                            Navigator.pop(ctx);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTile(
              icon: Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              label: 'Theme',
              onTap: () {
                ref.read(themeModeProvider.notifier).toggleThemeMode();
              },
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildSidebarDrawer(BuildContext context, bool isDark) {
    final drawerContent = _resolveSidebarContent(context);
    if (drawerContent == null) {
      return const SizedBox.shrink();
    }

    final maxWidth = MediaQuery.of(context).size.width * 0.8;
    final width = maxWidth < 280 ? maxWidth : 280.0;
    final theme = Theme.of(context);
    final bgColor = isDark
        ? theme.colorScheme.surface.withValues(alpha: 0.95)
        : theme.colorScheme.surface.withValues(alpha: 0.93);
    final borderColor = theme.colorScheme.outline.withValues(alpha: 0.2);

    return GestureDetector(
      onTap: () {},
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
    path.cubicTo(0, radius * 0.4, radius * 0.1, radius, radius, radius);

    // Top edge
    path.lineTo(sidebarWidth - 16, radius);
    path.arcToPoint(Offset(sidebarWidth, radius + 16),
        radius: const Radius.circular(16), clockwise: true);

    // Right side
    path.lineTo(sidebarWidth, size.height - radius - 16);
    path.arcToPoint(Offset(sidebarWidth - 16, size.height - radius),
        radius: const Radius.circular(16), clockwise: true);

    // Bottom edge
    path.lineTo(radius, size.height - radius);

    // Bottom flare flaring DOWN from sidebar bottom (0, h-radius) to screen edge (0, h)
    path.cubicTo(radius * 0.1, size.height - radius, 0,
        size.height - radius * 0.4, 0, size.height);

    path.lineTo(0, 0);
    path.close();

    canvas.drawShadow(path, Colors.black, 10, false);
    canvas.drawPath(path, paint);

    // Border for the visible part
    final borderPath = Path();
    borderPath.moveTo(0, 0);
    borderPath.cubicTo(0, radius * 0.4, radius * 0.1, radius, radius, radius);
    borderPath.lineTo(sidebarWidth - 16, radius);
    borderPath.arcToPoint(Offset(sidebarWidth, radius + 16),
        radius: const Radius.circular(16), clockwise: true);
    borderPath.lineTo(sidebarWidth, size.height - radius - 16);
    borderPath.arcToPoint(Offset(sidebarWidth - 16, size.height - radius),
        radius: const Radius.circular(16), clockwise: true);
    borderPath.lineTo(radius, size.height - radius);
    borderPath.cubicTo(radius * 0.1, size.height - radius, 0,
        size.height - radius * 0.4, 0, size.height);

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
    path.cubicTo(0, radius * 0.4, radius * 0.1, radius, radius, radius);

    // Top edge
    path.lineTo(sidebarWidth - 16, radius);
    path.arcToPoint(Offset(sidebarWidth, radius + 16),
        radius: const Radius.circular(16), clockwise: true);

    // Right side
    path.lineTo(sidebarWidth, size.height - radius - 16);
    path.arcToPoint(Offset(sidebarWidth - 16, size.height - radius),
        radius: const Radius.circular(16), clockwise: true);

    // Bottom edge
    path.lineTo(radius, size.height - radius);

    // Bottom flare flaring DOWN from sidebar bottom (0, h-radius) to screen edge (0, h)
    path.cubicTo(radius * 0.1, size.height - radius, 0,
        size.height - radius * 0.4, 0, size.height);

    path.lineTo(0, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant _SidebarClipper oldClipper) =>
      oldClipper.sidebarWidth != sidebarWidth || oldClipper.radius != radius;
}
