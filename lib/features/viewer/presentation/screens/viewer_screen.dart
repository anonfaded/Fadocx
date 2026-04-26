import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:go_router/go_router.dart';
import 'package:fadocx/config/theme/theme_provider.dart';
import 'package:fadocx/features/viewer/data/providers/repository_providers.dart';
import 'package:fadocx/features/viewer/domain/entities/parsed_document_entity.dart';
import 'package:fadocx/features/viewer/presentation/widgets/text_document_viewer.dart';
import 'package:fadocx/features/viewer/presentation/widgets/modern_pdf_viewer.dart';
import 'package:fadocx/features/viewer/presentation/widgets/document_viewer_factory.dart';
import 'package:fadocx/features/viewer/presentation/widgets/lokit_document_viewer.dart';
import 'package:fadocx/features/viewer/presentation/providers/lokit_viewer_notifier.dart';
import 'package:fadocx/features/viewer/data/services/lokit_service.dart';
import 'package:fadocx/features/viewer/presentation/providers/document_viewer_notifier.dart';
import 'package:fadocx/features/home/presentation/widgets/home_drawer.dart';
import 'package:fadocx/features/home/presentation/providers/thumbnail_provider.dart';
import 'package:fadocx/features/settings/presentation/providers/settings_providers.dart';
import 'package:fadocx/core/services/thumbnail_generation_service.dart';

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
  static const double _kSidebarBottomOffset = 88;
  static const double _kSidebarRadius = 24.0;

  bool _controlsVisible = true;
  bool _isFullscreen = false;
  bool _invertColors = false;
  bool _textMode = false;
  bool _bottomMenuExpanded = false;
  bool _sidebarOpen = false;
  double _lokitZoom = 1.0;
  int _currentPage = 1;
  int _totalPages = 0;
  int? _documentWordCount;
  int? _documentLineCount;
  double _sidebarDragOffset = 0.0;
  double _textFontSize = 14;
  bool _textWordWrap = true;
  bool _textFontIsMonoFont = false;
  bool _syntaxHighlightEnabled = true;
  bool _sessionStarted = false; // Prevent double session start
  RecentFilesMutator? _savedMutator; // Saved before dispose for safe access
  String? _sessionFilePath; // Saved before dispose for safe access
  late AnimationController _menuController;
  late AnimationController _sidebarController;
  // Sheet selection state for bottom panel display
  double _sheetZoom = 1.0;
  String? _sheetCellRef;
  String _sheetCellValue = '';

  late AnimationController _topBarController;
  late AnimationController _bottomPanelController;
  late GlobalKey<State<ModernPdfViewer>> _pdfViewerKey;
  late GlobalKey<State<TextDocumentViewer>> _textViewerKey;
  late GlobalKey<State<LOKitDocumentViewer>> _lokitViewerKey;
  late GlobalKey _sheetViewerKey;
  static const double _kDragCloseThreshold = 100.0;

  bool _isPdfDocument() {
    final doc = ref.read(documentViewerProvider).document;
    return doc?.format.toUpperCase() == 'PDF';
  }

  bool _isSpreadsheet() {
    final format = ref.read(documentViewerProvider).document?.format.toUpperCase();
    return format == 'XLS' || format == 'XLSX' || format == 'CSV' || format == 'ODS';
  }

  double _topOverlayHeight(BuildContext context) => MediaQuery.viewPaddingOf(context).top + 40.0;

  double _bottomOverlayHeight() {
    if (!_controlsVisible) return 0.0;
    if (_isSpreadsheet()) return 76.0;
    return 56.0;
  }

  EdgeInsets _contentOverlayPadding(BuildContext context) {
    if (_isSpreadsheet()) {
      return EdgeInsets.only(
        top: _controlsVisible ? _topOverlayHeight(context) : 0.0,
        bottom: _bottomPanelController.value > 0.3 ? _bottomOverlayHeight() : 0.0,
      );
    }
    return EdgeInsets.zero;
  }

  Future<void> _setFullscreen(bool enabled) async {
    _isFullscreen = enabled;
    if (enabled) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  Future<void> _toggleFullscreen() async {
    // Only for spreadsheets
    if (!_isSpreadsheet()) return;
    
    final willShowControls = !_controlsVisible;
    setState(() {
      _controlsVisible = willShowControls;
      _isFullscreen = !willShowControls;
      if (!willShowControls) {
        _sidebarOpen = false;
        _bottomMenuExpanded = false;
      }
    });

    if (willShowControls) {
      _topBarController.forward();
      _bottomPanelController.forward();
      await _setFullscreen(false);
    } else {
      _topBarController.reverse();
      _bottomPanelController.reverse();
      _sidebarController.reverse();
      _menuController.reverse();
      await _setFullscreen(true);
    }
  }

  bool _isLOKitDocument() {
    final format = ref.read(documentViewerProvider).document?.format.toUpperCase();
    return format == 'PPT' ||
        format == 'PPTX' ||
        format == 'ODP' ||
        format == 'DOCX' ||
        format == 'DOC' ||
        format == 'RTF' ||
        format == 'ODT';
  }

  bool _isTextDocument() {
    const txtFormats = {'TXT', 'JAVA', 'PY', 'SH', 'HTML', 'MD', 'LOG', 'JSON', 'XML', 'FADREC'};
    final format = ref.read(documentViewerProvider).document?.format.toUpperCase() ?? '';
    return txtFormats.contains(format);
  }

  bool _canOpenSidebar() {
    if (!_controlsVisible) return false;
    if (_isPdfDocument()) {
      return _pdfViewerKey.currentState != null;
    }
    if (_isLOKitDocument()) {
      return _lokitViewerKey.currentState != null;
    }
    if (_isTextDocument()) {
      return _textViewerKey.currentState != null;
    }
    // Enable for spreadsheets — they have search in the factory-created viewer
    if (_isSpreadsheet()) {
      return true;
    }
    return false;
  }

    Widget? _resolveSidebarContent(BuildContext context) {
    if (_isPdfDocument()) {
      final viewerState = _pdfViewerKey.currentState as dynamic;
      return viewerState?.buildDrawerContent(context) as Widget?;
    }
    if (_isLOKitDocument()) {
      final viewerState = _lokitViewerKey.currentState as dynamic;
      return viewerState?.buildDrawerContent(context) as Widget?;
    }
    if (_isTextDocument()) {
      final viewerState = _textViewerKey.currentState as dynamic;
      return viewerState?.buildDrawerContent(context) as Widget?;
    }
    // Show simple search placeholder for spreadsheets
    if (_isSpreadsheet()) {
      return _buildSpreadsheetSearchPlaceholder(context);
    }
    return null;
  }

  /// Simple search placeholder for spreadsheet - minimal height for landscape
  Widget _buildSpreadsheetSearchPlaceholder(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Minimal thin search field
          TextField(
            autofocus: false,
            style: Theme.of(context).textTheme.bodySmall,
            decoration: InputDecoration(
              hintText: 'Find...',
              prefixIcon: const Icon(Icons.search, size: 16),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onChanged: (query) {
              if (query.isNotEmpty) {
                _performSheetSearch(query);
              }
            },
          ),
          const SizedBox(height: 4),
          // Scrollable results
          Expanded(
            child: _sheetSearchResults.isEmpty
                ? Center(child: Text('Type to find', style: Theme.of(context).textTheme.bodySmall))
                : ListView.builder(
                    itemCount: _sheetSearchResults.length.clamp(0, 30),
                    itemBuilder: (ctx, i) {
                      final r = _sheetSearchResults[i];
                      return InkWell(
                        onTap: () {
                          _jumpToSheetCell(r['row'] as int, r['col'] as int);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${_colLabel(r['col'] as int)}${(r['row'] as int) + 1}', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                              const SizedBox(width: 4),
                              Expanded(child: Text(r['value'] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _sheetSearchResults = [];

  void _performSheetSearch(String query) async {
    if (query.isEmpty) {
      setState(() => _sheetSearchResults.clear());
      return;
    }
    final doc = ref.read(documentViewerProvider).document;
    if (doc == null) return;
    
    final results = <Map<String, dynamic>>[];
    final q = query.toLowerCase();
    for (var si = 0; si < doc.sheets.length; si++) {
      final sheet = doc.sheets[si];
      for (var ri = 0; ri < sheet.rows.length; ri++) {
        for (var ci = 0; ci < sheet.rows[ri].length; ci++) {
          final cell = sheet.rows[ri][ci];
          if (cell.toLowerCase().contains(q)) {
            results.add({'row': ri, 'col': ci, 'value': cell});
            if (results.length >= 30) break;
          }
        }
        if (results.length >= 30) break;
      }
      if (results.length >= 30) break;
    }
    setState(() => _sheetSearchResults = results);
  }

  void _jumpToSheetCell(int row, int col) {
    final viewer = _sheetViewerKey.currentState as dynamic;
    if (viewer != null && viewer.scrollToCell != null) {
      viewer.scrollToCell(row, col);
    }
    if (_sidebarOpen) _closeSidebar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Cell ${_colLabel(col)}${row + 1}'), duration: const Duration(seconds: 1)),
    );
  }

  String _colLabel(int col) => String.fromCharCode(65 + (col % 26));

  void _toggleControls() {
    final willBeVisible = !_controlsVisible;
    setState(() {
      _controlsVisible = willBeVisible;
      _isFullscreen = false;
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
    if (_isLOKitDocument()) {
      (_lokitViewerKey.currentState as dynamic)?.toggleSidebar();
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
    if (_isPdfDocument()) {
      (_pdfViewerKey.currentState as dynamic)?.goToFirstPage();
    } else if (_isLOKitDocument()) {
      (_lokitViewerKey.currentState as dynamic)?.goToFirstPage();
    }
  }

  void _goToPreviousPage() {
    if (_isPdfDocument()) {
      (_pdfViewerKey.currentState as dynamic)?.goToPreviousPage();
    } else if (_isLOKitDocument()) {
      (_lokitViewerKey.currentState as dynamic)?.goToPreviousPage();
    }
  }

  void _goToNextPage() {
    if (_isPdfDocument()) {
      (_pdfViewerKey.currentState as dynamic)?.goToNextPage();
    } else if (_isLOKitDocument()) {
      (_lokitViewerKey.currentState as dynamic)?.goToNextPage();
    }
  }

  void _closeSidebar() {
    if (_isPdfDocument()) {
      (_pdfViewerKey.currentState as dynamic)?.toggleSidebar();
    }
    if (_isLOKitDocument()) {
      (_lokitViewerKey.currentState as dynamic)?.toggleSidebar();
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
    if (_isPdfDocument()) {
      (_pdfViewerKey.currentState as dynamic)?.goToLastPage();
    } else if (_isLOKitDocument()) {
      (_lokitViewerKey.currentState as dynamic)?.goToLastPage();
    }
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
                if (_isPdfDocument()) {
                  (_pdfViewerKey.currentState as dynamic)?.goToPage(pageNum);
                } else if (_isLOKitDocument()) {
                  (_lokitViewerKey.currentState as dynamic)?.goToPage(pageNum);
                }
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
    _lokitViewerKey = GlobalKey<State<LOKitDocumentViewer>>();
    _sheetViewerKey = GlobalKey();
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

    // Start in immersive mode by default for better UX
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Load document if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final docState = ref.read(documentViewerProvider);
      _log.d('initState: loading=, hasDoc=, hasError=');

      // Always update date opened first (awaited to prevent race with session)
      await ref.read(recentFilesMutatorProvider).updateDateOpened(widget.filePath);

      if (!docState.isLoading &&
          docState.document == null &&
          !docState.hasError) {
        _log.d('Loading document: ');
        ref
            .read(documentViewerProvider.notifier)
            .initializeAndLoad(widget.filePath, widget.fileName)
            .then((_) {
          _log.d('Document loaded, starting time tracking...');
          if (!_sessionStarted) {
            _sessionStarted = true;
            _savedMutator = ref.read(recentFilesMutatorProvider);
            _sessionFilePath = widget.filePath;
            _savedMutator!.startViewingSession(widget.filePath);
            _log.d('Time tracking started: ');
          }
        });
      } else {
        _log.d('Document already loaded, starting session...');
        if (!_sessionStarted) {
          _sessionStarted = true;
          _savedMutator = ref.read(recentFilesMutatorProvider);
          _sessionFilePath = widget.filePath;
          _savedMutator!.startViewingSession(widget.filePath);
        }
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
    _log.d('dispose: ending session for ');
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    // End viewing session using saved reference (ref is unsafe in dispose)
    if (_savedMutator != null && _sessionFilePath != null) {
      _savedMutator!.endViewingSession(_sessionFilePath!);
      _log.d('Session end triggered via saved ref');
    } else {
      _log.w('No saved mutator - session time NOT saved');
    }
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
      body: Stack(
        children: [
          Positioned.fill(
            child: docState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : docState.hasError
                    ? _buildErrorState(context, ref, docState)
                    : docState.document != null
                        ? Padding(
                            padding: _contentOverlayPadding(context),
                            child: _buildContentViewer(
                              document: docState.document!,
                            ),
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
                 top: _topOverlayHeight(context),
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
                top: 0,
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

          // Fullscreen exit button - visible only in true fullscreen
          if (_isFullscreen)
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton.small(
                onPressed: _toggleControls,
                child: const Icon(Icons.fullscreen_exit, size: 20),
              ),
            ),
        ],
      ),
    );
  }


  static String? _getHighlightLanguage(String format) => _languageForFormat(format);

  static String? _languageForFormat(String format) {
    switch (format) {
      case 'JAVA':
        return 'java';
      case 'PY':
        return 'python';
      case 'SH':
        return 'bash';
      case 'HTML':
        return 'xml';
      case 'MD':
        return 'markdown';
      case 'JSON':
        return 'json';
      case 'XML':
        return 'xml';
      case 'FADREC':
        return 'json';
      default:
        return null;
    }
  }

  Widget _buildContentViewer({required ParsedDocumentEntity document}) {
    final format = document.format.toUpperCase();
    _log.d(
      'Building viewer for format=$format rich=${document.hasRichDocument} '
      'fidelity=${document.fidelityLevel.name} warnings=${document.parseWarnings.length}',
    );

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

    // For LOKit-rendered documents (presentations and word docs)
    if (format == 'PPT' ||
        format == 'PPTX' ||
        format == 'ODP' ||
        format == 'ODS' ||
        format == 'DOCX' ||
        format == 'DOC' ||
        format == 'RTF' ||
        format == 'ODT' ||
        format == 'EPUB' ||
        format == 'OTT') {
      return LOKitDocumentViewer(
        key: _lokitViewerKey,
        filePath: widget.filePath,
        fileName: widget.fileName,
        onTap: _toggleControls,
        onPageChanged: (current, total) {
          if (total > 0) {
            setState(() {
              _currentPage = current;
              _totalPages = total;
            });
          }
        },
        onZoomChanged: (zoom) {
          if ((zoom - _lokitZoom).abs() > 0.01) {
            setState(() => _lokitZoom = zoom);
          }
        },
      );
    }

    // For text/code documents, use TextDocumentViewer with optional syntax highlighting
    const txtFormats = {'TXT', 'JAVA', 'PY', 'SH', 'HTML', 'MD', 'LOG', 'JSON', 'XML', 'FADREC'};
    if (txtFormats.contains(format)) {
      return TextDocumentViewer(
        key: _textViewerKey,
        textContent: document.searchableText,
        onTap: _toggleControls,
        onSearchHighlight: _onSearchHighlight,
        fontSize: _textFontSize,
        wordWrap: _textWordWrap,
        useMonoFont: _textFontIsMonoFont,
        language: _syntaxHighlightEnabled ? _languageForFormat(format) : null,
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
      onSheetSelectionChanged: (cellRef, value) {
        setState(() {
          _sheetCellRef = cellRef;
          _sheetCellValue = value;
        });
      },
      sheetViewerKey: _sheetViewerKey,
      sheetZoom: _sheetZoom,
    );
  }


  bool _isZoomed() {
    if (!_isLOKitDocument()) return false;
    return (_lokitZoom - 1.0).abs() > 0.05;
  }

  Widget _buildResetZoomButton() {
    if (!_isZoomed()) {
      return const SizedBox(width: 32, height: 32);
    }
    return IconButton(
      icon: const Icon(Icons.fit_screen),
      onPressed: () {
        (_lokitViewerKey.currentState as dynamic)?.resetZoom();
      },
      tooltip: 'Reset zoom',
      iconSize: 18,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      padding: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.primary,
    );
  }

  void _copyLOKitText() async {
    final lokitState = ref.read(lokitViewerProvider);
    final totalParts = lokitState.totalParts;
    final currentPage = lokitState.currentPart + 1;
    final isSinglePage = totalParts <= 1;

    if (isSinglePage) {
      _doExtractAndCopy(allPages: true, totalParts: totalParts, currentPage: currentPage);
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.copy_all, size: 20, color: Theme.of(ctx).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Copy Text'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choose what to copy:'),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.looks_one, color: Theme.of(ctx).colorScheme.primary),
              title: Text('Page $currentPage only'),
              contentPadding: EdgeInsets.zero,
              dense: true,
              onTap: () {
                Navigator.pop(ctx);
                _doExtractAndCopy(allPages: false, totalParts: totalParts, currentPage: currentPage);
              },
            ),
            ListTile(
              leading: Icon(Icons.copy_all, color: Theme.of(ctx).colorScheme.primary),
              title: Text('All $totalParts pages'),
              contentPadding: EdgeInsets.zero,
              dense: true,
              onTap: () {
                Navigator.pop(ctx);
                _doExtractAndCopy(allPages: true, totalParts: totalParts, currentPage: currentPage);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _doExtractAndCopy({required bool allPages, required int totalParts, required int currentPage}) async {
    final notifier = ref.read(lokitViewerProvider.notifier);
    final label = allPages ? 'all pages' : 'page $currentPage';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(strokeWidth: 2),
            const SizedBox(width: 16),
            Expanded(child: Text('Extracting text from $label...')),
          ],
        ),
      ),
    );

    try {
      final String text;
      if (allPages) {
        text = await notifier.extractAllText();
      } else {
        text = await LOKitService.extractPartText(part: currentPage - 1);
      }
      if (!mounted) return;
      Navigator.pop(context);

      if (text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No text content found')),
        );
        return;
      }

      final wordCount = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
      final pageLabel = allPages ? '$totalParts pages' : 'page $currentPage';

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.copy_all, size: 20, color: Theme.of(ctx).colorScheme.primary),
              const SizedBox(width: 8),
              const Text('Copy Text'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Text extracted from $pageLabel.'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.text_fields, size: 16, color: Theme.of(ctx).colorScheme.primary),
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
                      content: Text('Copied $wordCount words from $pageLabel'),
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
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
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
                          Align(
                            alignment: Alignment.centerRight,
                            child: _buildResetZoomButton(),
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
    final textContent = document.searchableText;
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
        (wordCount / _readingWordsPerMinute).ceil().clamp(1, 99999);
    final readingTimeStr = readingMinutes >= 60
        ? '${readingMinutes ~/ 60}h ${readingMinutes % 60}m read'
        : '$readingMinutes ${readingMinutes == 1 ? "minute" : "minutes"} read';

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        '$readingTimeStr • $wordCount words • $lineCount lines',
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

    // Capture brightness before async gap
    final brightnessName = Theme.of(context).brightness == Brightness.dark ? 'dark' : 'light';
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
            await hiveDatasource.saveThumbnail(file.id, thumbnailBytes, brightness: brightnessName);
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

    final text = doc.document!.searchableText;
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
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
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
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
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
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Main control row
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {}, // Absorb taps but don't hide controls
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 2,
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
                    // Sheet selection info row (spreadsheets only)
                    if (_isSpreadsheet())
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            if (_sheetCellRef != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _sheetCellRef!,
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _sheetCellValue.isEmpty ? 'Tap a cell to see value' : _sheetCellValue,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: _sheetCellValue.isEmpty
                                      ? Theme.of(context).colorScheme.outline
                                      : null,
                                ),
                              ),
                            ),
                            if (_sheetCellValue.isNotEmpty)
                              IconButton(
                                icon: Icon(Icons.copy, size: 14, color: Theme.of(context).colorScheme.primary),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: _sheetCellValue));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Copied'),
                                      duration: Duration(milliseconds: 800),
                                    ),
                                  );
                                },
                                tooltip: 'Copy value',
                              ),
                          ],
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
                            padding: const EdgeInsets.all(6),
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
     } else if (_isLOKitDocument()) {
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
     } else if (const {'TXT', 'JAVA', 'PY', 'SH', 'HTML', 'MD', 'LOG', 'JSON', 'XML', 'FADREC'}.contains(format)) {
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

    if (_isSpreadsheet()) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Zoom controls like text mode
          IconButton(
            icon: const Icon(Icons.remove, size: 14),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            onPressed: _sheetZoom > 0.3 ? () => setState(() => _sheetZoom = (_sheetZoom - 0.1).clamp(0.3, 3.0)) : null,
          ),
          SizedBox(
            width: 36,
            child: Center(
              child: Text(
                '${(_sheetZoom * 100).toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 14),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            onPressed: _sheetZoom < 3.0 ? () => setState(() => _sheetZoom = (_sheetZoom + 0.1).clamp(0.3, 3.0)) : null,
          ),
          const SizedBox(width: 8),
          // Fullscreen
          IconButton(
            icon: const Icon(Icons.fullscreen, size: 14),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            onPressed: _toggleFullscreen,
            tooltip: 'Toggle fullscreen',
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
    } else if (format == 'PPT' ||
        format == 'PPTX' ||
        format == 'ODP') {
      return Row(
        children: [
          Expanded(
            child: _buildTile(
              icon: Icons.copy_all,
              label: 'Copy',
              onTap: _copyLOKitText,
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
    } else if (const {'TXT', 'DOCX', 'DOC', 'RTF', 'ODT', 'JAVA', 'PY', 'SH', 'HTML', 'MD', 'LOG', 'JSON', 'XML', 'FADREC'}.contains(format)) {
      final hasSyntax = _getHighlightLanguage(format) != null;
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
          if (hasSyntax) ...[
            Expanded(
              child: _buildTile(
                icon: _syntaxHighlightEnabled ? Icons.code : Icons.code_outlined,
                label: 'Syntax',
                onTap: () => setState(() => _syntaxHighlightEnabled = !_syntaxHighlightEnabled),
              ),
            ),
            const SizedBox(width: 8),
          ],
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

    if (_isSpreadsheet()) {
      return Row(
        children: [
          Expanded(
            child: _buildTile(
              icon: Icons.edit_outlined,
              label: 'Edit',
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    icon: Icon(Icons.edit_outlined, color: Theme.of(ctx).colorScheme.primary),
                    title: const Text('Edit with Fadocx Engine'),
                    content: const Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Open this spreadsheet in the Fadocx rendering engine for a faithful visual preview with full formatting, charts, and layout fidelity.'),
                        SizedBox(height: 16),
                        Text(
                          'Note: Interactive editing is coming in a future update.',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Not Now'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Got It'),
                      ),
                    ],
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
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 100),
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
        ),
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
