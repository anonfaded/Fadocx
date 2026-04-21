import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:logger/logger.dart';

class _SearchResult {
  final int page;
  final String snippet;
  final int charIndex;
  final int charLength;
  final List<PdfRect>? charRects;
  _SearchResult({required this.page, required this.snippet, this.charIndex = 0, this.charLength = 0, this.charRects});
}

/// Premium PDF Viewer with macOS/iOS dock-style Material3 UI
class ModernPdfViewer extends StatefulWidget {
  final String filePath;
  final String? fileName;
  final bool invertColors;
  final bool textMode;
  final VoidCallback? onInvertToggle;
  final VoidCallback? onTextModeToggle;
  final VoidCallback? onTap;
  final Function(int currentPage, int totalPages)? onPageChanged;
  final VoidCallback? onSearchHighlight;

  const ModernPdfViewer({
    required this.filePath,
    this.fileName,
    this.invertColors = false,
    this.textMode = false,
    this.onInvertToggle,
    this.onTextModeToggle,
    this.onTap,
    this.onPageChanged,
    this.onSearchHighlight,
    super.key,
  });

  @override
  State<ModernPdfViewer> createState() => _ModernPdfViewerState();
}

class _ModernPdfViewerState extends State<ModernPdfViewer> with TickerProviderStateMixin {
  static final log = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 50,
      colors: true,
      printEmojis: true,
    ),
  );

  final _controller = PdfViewerController();
  final _searchController = TextEditingController();
  final ValueNotifier<int> _drawerVersion = ValueNotifier<int>(0);
  late final AnimationController _highlightController;
  late final PageController _textModePageController;
  late final ScrollController _pagesScrollController;

  bool _showSidebar = false;
  int _currentPage = 1;
  int _totalPages = 0;
  PdfDocument? _document;
  bool _isControllerReady = false;

  PdfDocument? get pdfDocument => _document;

  // Search state
  int _currentSearchResult = -1;
  List<_SearchResult> _searchResults = [];
  bool _isSearching = false;
  String _currentQuery = '';
  int _searchCancellationToken = 0; // Incremented to cancel previous searches
  int _searchPagesChecked = 0; // Track progress during search

  // TOC state
  List<PdfOutlineNode>? _outlineNodes;
  bool _isLoadingOutline = false;

  // Text mode state - cache loaded page texts
  final Map<int, String> _pageTexts = {};
  bool _isLoadingAllPages = false;

  // Tap detection - track pointer position and time to distinguish taps from scrolls
  Offset? _tapStartPosition;
  DateTime? _tapStartTime;

  // Sidebar tabs: 0=Pages, 1=Search, 2=TOC, 3=Notes, 4=Bookmarks
  int _sidebarTab = 0;

   // Public getters for parent access
   int get currentPage => _currentPage;
   int get totalPages => _totalPages;
   bool get showSidebar => _showSidebar;

  @override
  void initState() {
    super.initState();
    _highlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _textModePageController = PageController(initialPage: 0);
    _textModePageController.addListener(_onPageChanged);
    _pagesScrollController = ScrollController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _highlightController.dispose();
    _textModePageController.dispose();
    _pagesScrollController.dispose();
    _drawerVersion.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ModernPdfViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // No need for page restoration anymore - ColorFilter no longer destroys PdfViewer widget
  }

  /// Scroll to a specific page in reader mode - INSTANT jump for better UX
  void _scrollToTextModePage(int pageNumber) {
    if (pageNumber < 1 || pageNumber > _totalPages) {
      log.w('_scrollToTextModePage rejected: page=$pageNumber, totalPages=$_totalPages');
      return;
    }
    try {
      // Use jumpToPage for instant navigation instead of animateToPage
      // This is much faster for large PDFs with many pages
      final index = pageNumber - 1; // PageView index is 0-based
      log.d('_scrollToTextModePage: jumping to page=$pageNumber (index=$index)');
      _textModePageController.jumpToPage(index);
      log.d('_scrollToTextModePage: jumped successfully to page=$pageNumber');
    } catch (e) {
      log.e('Failed to scroll to text mode page $pageNumber', error: e, stackTrace: StackTrace.current);
    }
  }

  void _onPageChanged() {
    if (!_textModePageController.hasClients) return;
    
    // Get current page from PageController
    final currentPage = (_textModePageController.page ?? 0).round() + 1;
    
    if (currentPage != _currentPage && mounted) {
      log.d('Page changed: $currentPage -> from $_currentPage total=$_totalPages');
      setState(() => _currentPage = currentPage);
      widget.onPageChanged?.call(_currentPage, _totalPages);
      
      // Auto-scroll sidebar to keep current page in view instantly (no delay)
      // This ensures accurate positioning without race conditions
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToActivePageInSidebar();
      });
    }
  }

  /// Auto-scroll sidebar to keep current page in view using instant jump for better performance
  void _scrollToActivePageInSidebar() {
    if (!_pagesScrollController.hasClients || _totalPages == 0) return;
    
    try {
      // Each page row is 18 (vertical padding: 12) + 12 (container height approximately)
      // Actually measure: margin(6+6) + container(12+12) + padding = ~48 pixels base
      // Add IconButton height when thumbnail visible: ~40 pixels
      // Total per item: ~88-100 pixels depending on thumbnail
      // For accurate positioning, use measured item height from first item or estimate
      
      // Use measured height of ~98 pixels per row as observed
      const itemHeight = 98.0;
      final targetOffset = (_currentPage - 1) * itemHeight;
      final maxExtent = _pagesScrollController.position.maxScrollExtent;
      
      log.d('Sidebar auto-scroll: page=$_currentPage, targetOffset=$targetOffset, maxExtent=$maxExtent');
      
      // Instantly jump to the target offset (teleport, no animation)
      // This is more performant than animate especially with many items
      if (targetOffset >= 0 && targetOffset <= maxExtent) {
        _pagesScrollController.jumpTo(targetOffset);
        log.d('Sidebar jumped to offset: $targetOffset');
      } else if (targetOffset > maxExtent) {
        // If target is beyond max, jump to max
        _pagesScrollController.jumpTo(maxExtent);
        log.d('Sidebar jumped to max extent: $maxExtent');
      }
    } catch (e) {
      log.w('Error scrolling sidebar to active page: $e');
    }
  }

  /// Build drawer content for display in ViewerScreen's sidebar.
  Widget buildDrawerContent(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _drawerVersion,
      builder: (context, _, __) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildSidebarTab(
                            context, 'Pages', Icons.pages, 0,
                            badgeText: '$_currentPage',
                            showBadge: true,
                          ),
                          _buildSidebarTab(
                            context, 'Search', Icons.search, 1,
                            badgeText: _searchResults.isNotEmpty ? '${_searchResults.length}' : null,
                            showBadge: _searchResults.isNotEmpty,
                          ),
                          _buildSidebarTab(
                            context, 'TOC', Icons.list, 2,
                            badgeText: _outlineNodes != null ? '${_outlineNodes!.length}' : null,
                            showBadge: _outlineNodes != null && _outlineNodes!.isNotEmpty,
                          ),
                          _buildSidebarTab(
                            context, 'Notes', Icons.note, 3,
                            comingSoon: true,
                          ),
                          _buildSidebarTab(
                            context, 'Bookmarks', Icons.bookmark, 4,
                            comingSoon: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _sidebarTab == 0
                  ? _buildPagesTab()
                  : _sidebarTab == 1
                      ? _buildSearchTab()
                      : _sidebarTab == 2
                          ? _buildTocTab()
                          : _sidebarTab == 3
                              ? _buildComingSoonTab('Notes', 'Add notes and annotations to PDF pages')
                              : _buildComingSoonTab('Bookmarks', 'Save and organize your favorite pages'),
            ),
          ],
        );
      },
    );
  }

  void _goToPage(int page) {
    log.d('_goToPage called: page=$page, totalPages=$_totalPages, isReady=$_isControllerReady');
    if (page < 1 || page > _totalPages || !_isControllerReady) {
      log.w('_goToPage rejected: invalid params');
      return;
    }
    try {
      log.d('Calling controller.goToPage($page)');
      _controller.goToPage(pageNumber: page);
      // Notify parent about page change
      widget.onPageChanged?.call(_currentPage, _totalPages);
    } catch (e) {
      log.e('Failed to navigate to page $page', error: e, stackTrace: StackTrace.current);
    }
  }

  // Public methods for parent to call
  void goToPage(int page) {
    log.d('goToPage called: page=$page, textMode=${widget.textMode}');
    if (widget.textMode) {
      log.d('Using text mode navigation');
      _scrollToTextModePage(page);
    } else {
      log.d('Using normal mode navigation (PdfViewer)');
      _goToPage(page);
    }
  }

  void goToFirstPage() {
    if (widget.textMode) {
      _scrollToTextModePage(1);
    } else {
      _goToPage(1);
    }
  }

  void goToPreviousPage() {
    if (widget.textMode) {
      _scrollToTextModePage((_currentPage - 1).clamp(1, _totalPages));
    } else if (_currentPage > 1) {
      _goToPage(_currentPage - 1);
    }
  }

  void goToNextPage() {
    if (widget.textMode) {
      _scrollToTextModePage((_currentPage + 1).clamp(1, _totalPages));
    } else if (_currentPage < _totalPages) {
      _goToPage(_currentPage + 1);
    }
  }

  void goToLastPage() {
    if (widget.textMode) {
      _scrollToTextModePage(_totalPages);
    } else {
      _goToPage(_totalPages);
    }
  }

  void toggleSidebar() {
    setState(() => _showSidebar = !_showSidebar);
  }

  Future<Map<String, dynamic>> extractAllText([void Function(int current, int total)? onProgress]) async {
    if (_document == null) {
      return {'text': '', 'wordCount': 0, 'pageCount': 0};
    }

    final allText = StringBuffer();
    int totalWords = 0;
    final totalPages = _document!.pages.length;

    for (int i = 0; i < totalPages; i++) {
      try {
        final pageText = await _document!.pages[i].loadText();
        if (pageText != null) {
          final text = ((pageText as dynamic).fullText ?? '') as String;
          if (text.isNotEmpty) {
            if (allText.isNotEmpty) {
              allText.writeln();
              allText.writeln();
            }
            allText.write(text);
            totalWords += text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
          }
        }
      } catch (_) {}

      // Report progress
      onProgress?.call(i + 1, totalPages);
    }

    return {
      'text': allText.toString(),
      'wordCount': totalWords,
      'pageCount': totalPages,
    };
  }

  Future<void> _showCopyDialog() async {
    if (_document == null) return;

    int currentPage = 0;
    int totalPages = _document!.pages.length;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Copy PDF Text'),
          content: FutureBuilder<Map<String, dynamic>>(
            future: extractAllText((current, total) {
              if (mounted) {
                setState(() {
                  currentPage = current;
                  totalPages = total;
                });
              }
            }),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SizedBox(
                  height: 120,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          currentPage > 0
                              ? 'Extracting text... ($currentPage/$totalPages pages)'
                              : 'Extracting text...',
                        ),
                        if (currentPage > 0) ...[
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: currentPage / totalPages,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }

            if (snapshot.hasError) {
              return const SizedBox(
                height: 100,
                child: Center(
                  child: Text('Error extracting text'),
                ),
              );
            }

            final data = snapshot.data;
            final text = data?['text'] ?? '';
            final wordCount = data?['wordCount'] ?? 0;

            return SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Word count: $wordCount',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.4,
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        text.isEmpty ? 'No text found in PDF' : text,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FutureBuilder<Map<String, dynamic>>(
            future: extractAllText(),
            builder: (context, snapshot) {
              final text = snapshot.data?['text'] ?? '';
              return TextButton(
                onPressed: text.isNotEmpty
                    ? () async {
                        await Clipboard.setData(ClipboardData(text: text));
                        Navigator.of(dialogContext).pop();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Full PDF text copied to clipboard'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    : null,
                child: const Text('Copy All'),
              );
            },
          ),
        ],
      ),
    ),
  );
}

  Future<void> _loadAllPageTexts() async {
    if (_document == null || _isLoadingAllPages) return;
    if (_pageTexts.length == _totalPages) return; // Already loaded all

    setState(() => _isLoadingAllPages = true);

    try {
      for (int i = 0; i < _totalPages; i++) {
        if (!mounted) break;
        if (_pageTexts.containsKey(i)) continue; // Skip already loaded

        try {
          final page = _document!.pages[i];
          final pageText = await page.loadText();
          if (pageText != null && mounted) {
            final text = ((pageText as dynamic).fullText ?? '') as String;
            if (mounted) {
              setState(() {
                _pageTexts[i] = text;
              });
            }
          } else if (mounted) {
            setState(() {
              _pageTexts[i] = ''; // Empty page
            });
          }
        } catch (e) {
          log.d('Error loading text for page $i: $e');
          if (mounted) {
            setState(() {
              _pageTexts[i] = ''; // Mark as loaded but empty
            });
          }
        }
      }
    } catch (e) {
      log.e('Error in _loadAllPageTexts: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingAllPages = false);
      }
    }
  }

  /// Load page text on-demand with robust fallback strategy
  Future<void> _extractAllPageTextsComprehensive() async {
    if (_document == null) return;

    try {
      log.i('🔄 Starting comprehensive text extraction for all $_totalPages pages...');
      
      // Extract text from all pages systematically with PdfViewer rendering
      for (int pageIndex = 0; pageIndex < _totalPages; pageIndex++) {
        if (!mounted) break;
        
        try {
          log.d('📄 Extracting page ${pageIndex + 1}/$_totalPages...');
          final page = _document!.pages[pageIndex];
          
          // Render page at screen resolution using PdfViewer's logic
          // This initializes the page engine properly
          await page.render(
            width: 600,
            height: 847,
          );
          
          // Small delay to allow page initialization
          await Future.delayed(const Duration(milliseconds: 50));
          
          // Now extract text - page should be properly initialized
          final pageText = await page.loadText();
          
          if (pageText != null) {
            final fullText = ((pageText as dynamic).fullText ?? '') as String;
            final trimmedText = fullText.trim();
            if (mounted) {
              setState(() => _pageTexts[pageIndex] = trimmedText);
            }
            log.d('✅ Page ${pageIndex + 1}: Extracted ${trimmedText.length} chars');
          } else {
            // Page has no text content - cache as empty
            if (mounted) {
              setState(() => _pageTexts[pageIndex] = '');
            }
            log.w('⚠️ Page ${pageIndex + 1}: No text content (scanned image?)');
          }
        } catch (e) {
          log.e('❌ Page ${pageIndex + 1} extraction error: $e');
          if (mounted) {
            setState(() => _pageTexts[pageIndex] = '');
          }
        }
      }
      
      log.i('✅ Text extraction complete: ${_pageTexts.length}/$_totalPages pages');
    } catch (e) {
      log.e('❌ Comprehensive extraction failed: $e');
    } finally {
      // Done loading - hide loader
      if (mounted) {
        setState(() => _isLoadingAllPages = false);
      }
    }
  }

  Future<void> _loadPageTextOnDemand(int pageIndex) async {
    if (_document == null) return;
    if (_pageTexts.containsKey(pageIndex)) return; // Already loaded

    try {
      log.d('📄 Extracting text for page ${pageIndex + 1}');
      final page = _document!.pages[pageIndex];
      
      // Simple direct extraction - page should already be rendered by PdfViewer
      final pageText = await page.loadText();
      
      if (pageText != null) {
        final fullText = ((pageText as dynamic).fullText ?? '') as String;
        if (mounted) {
          setState(() => _pageTexts[pageIndex] = fullText.trim());
        }
        log.d('✅ Page ${pageIndex + 1}: Extracted (${fullText.length} chars)');
      } else {
        if (mounted) {
          setState(() => _pageTexts[pageIndex] = '');
        }
        log.w('⚠️ Page ${pageIndex + 1}: No text found');
      }
    } catch (e) {
      log.e('❌ Page ${pageIndex + 1} extraction error: $e');
      if (mounted) {
        setState(() => _pageTexts[pageIndex] = '');
      }
    }
  }

  Future<void> _performSearch(String query) async {
    // If query is empty, immediately clear all results and stop any active search
    if (query.isEmpty || _document == null) {
      // Invalidate any running search by incrementing token
      _searchCancellationToken++;
      
      if (mounted) {
        setState(() {
          _searchResults = [];
          _currentSearchResult = -1;
          _isSearching = false;
          _currentQuery = '';
          _searchPagesChecked = 0;
        });
      }
      _highlightController.reset();
      return;
    }

    // Increment token to cancel any previous searches
    final searchToken = ++_searchCancellationToken;

    // Immediately show loading state
    if (mounted) {
      setState(() {
        _isSearching = true;
        _currentQuery = query;
        _searchResults = [];
        _currentSearchResult = -1;
        _searchPagesChecked = 0;
      });
    }

    final results = <_SearchResult>[];
    final lowerQuery = query.toLowerCase();
    final totalPages = _document!.pages.length;
    bool isSearchCancelled = false;

    try {
      for (int i = 0; i < totalPages; i++) {
        // Check if this search was cancelled
        if (searchToken != _searchCancellationToken) {
          log.d('Search cancelled at page $i');
          isSearchCancelled = true;
          break;
        }

        try {
          final pageText = await _document!.pages[i].loadText();
          if (pageText != null) {
            final text = ((pageText as dynamic).fullText ?? '') as String;
            if (text.toLowerCase().contains(lowerQuery)) {
              final idx = text.toLowerCase().indexOf(lowerQuery);
              final start = (idx - 40).clamp(0, text.length);
              final end = (idx + query.length + 40).clamp(0, text.length);
              var snippet = text.substring(start, end);
              if (start > 0) snippet = '...$snippet';
              if (end < text.length) snippet = '$snippet...';
              final charIdx = idx;
              final charLen = query.length;
              final pageCharRects = ((pageText as dynamic).charRects as List?)?.cast<PdfRect>();
              results.add(_SearchResult(
                page: i + 1,
                snippet: snippet,
                charIndex: charIdx,
                charLength: charLen,
                charRects: pageCharRects,
              ));
              // When first result found, immediately navigate and show it
              if (results.length == 1 && _currentSearchResult == -1) {
                if (mounted && searchToken == _searchCancellationToken) {
                  setState(() {
                    _searchResults = results;
                    _currentSearchResult = 0;
                    _searchPagesChecked = i + 1;
                  });
                  _goToPage(results[0].page);
                }
              }
            }
          }
        } catch (_) {}

        // Update progress every 3 pages for real-time feel
        if ((i + 1) % 3 == 0 || i == totalPages - 1) {
          if (searchToken == _searchCancellationToken && mounted) {
            setState(() {
              _searchPagesChecked = i + 1;
              _searchResults = results;
              _isSearching = i < totalPages - 1; // Still searching if not at last page
            });
          }
        }
      }
    } catch (e) {
      log.e('Search error: $e', error: e);
      isSearchCancelled = true;
    }

    // Final update - always mark search as complete if this is still the current search
    // This fires regardless of whether it was cancelled, ensuring _isSearching is always set to false
    if (searchToken == _searchCancellationToken && mounted) {
      setState(() {
        if (!isSearchCancelled) {
          _searchResults = results;
        }
        _isSearching = false;
        _searchPagesChecked = totalPages;
      });
      log.d('Search complete: found ${results.length} results in $totalPages pages');
    }
  }

  void _nextSearchResult() async {
    if (_searchResults.isEmpty) return;
    final idx = (_currentSearchResult + 1) % _searchResults.length;
    if (idx >= 0 && idx < _searchResults.length) {
      await _goToSearchResult(idx);
    }
  }

  void _previousSearchResult() async {
    if (_searchResults.isEmpty) return;
    final idx = (_currentSearchResult - 1 + _searchResults.length) % _searchResults.length;
    if (idx >= 0 && idx < _searchResults.length) {
      setState(() {
        _currentSearchResult = idx;
        _goToPage(_searchResults[_currentSearchResult].page);
        _triggerHighlight();
      });
    }
  }

  void _triggerHighlight() {
    _highlightController.forward();
    widget.onSearchHighlight?.call();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) _highlightController.reverse();
    });
  }

  Future<void> _goToSearchResult(int index) async {
    if (index < 0 || index >= _searchResults.length) return;
    
    // Auto-collapse sidebar if open
    if (_showSidebar) {
      setState(() => _showSidebar = false);
    }

    final result = _searchResults[index];
    final pageNum = result.page;
    setState(() => _currentSearchResult = index);

    try {
      final charRects = result.charRects;
      final idx = result.charIndex;
      final len = result.charLength;

      if (charRects != null && idx >= 0 && idx < charRects.length && len > 0) {
        final startIdx = idx.clamp(0, charRects.length - 1);
        final endIdx = (idx + len - 1).clamp(0, charRects.length - 1);

        // Calculate bounding box of the match
        double left = charRects[startIdx].left;
        double top = charRects[startIdx].top;
        double right = charRects[startIdx].right;
        double bottom = charRects[startIdx].bottom;

        for (int i = startIdx + 1; i <= endIdx; i++) {
          left = left.clamp(double.negativeInfinity, charRects[i].left);
          top = top.clamp(charRects[i].top, double.infinity);
          right = right.clamp(charRects[i].right, double.infinity);
          bottom = bottom.clamp(double.negativeInfinity, charRects[i].bottom);
        }

        final pdfRect = PdfRect(left, bottom, right, top);
        
        await _controller.goToRectInsidePage(
          pageNumber: pageNum,
          rect: pdfRect,
          anchor: PdfPageAnchor.center,
        );
        
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;
        _triggerHighlight();
        return;
      }
    } catch (_) {}
    
    _goToPage(pageNum);
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _triggerHighlight();
  }

  List<Widget> _buildPageOverlays(BuildContext context, Rect pageRect, PdfPage page) {
    final overlays = <Widget>[];
    if (_currentSearchResult == -1) return overlays;
    final result = _searchResults[_currentSearchResult];
    if (result.page != page.pageNumber) return overlays;

    final charRects = result.charRects;
    final idx = result.charIndex;
    final len = result.charLength;

    if (charRects != null && idx >= 0 && idx < charRects.length && len > 0) {
      final startIdx = idx.clamp(0, charRects.length - 1);
      final endIdx = (idx + len - 1).clamp(0, charRects.length - 1);

      final highlightRects = <Rect>[];
      for (int i = startIdx; i <= endIdx; i++) {
        final pdfRect = charRects[i];
        highlightRects.add(pdfRect.toRect(page: page, scaledPageSize: pageRect.size));
      }

      // Add the global page dimmer with holes for highlights, wrapped in an animation
      overlays.add(
        Positioned.fill(
          child: ListenableBuilder(
            listenable: _highlightController,
            builder: (context, child) {
              if (_highlightController.value == 0) return const SizedBox.shrink();
              return Opacity(
                opacity: _highlightController.value,
                child: child,
              );
            },
            child: IgnorePointer(
              child: Stack(
                children: [
                  // The focus dimmer with holes
                  _PageFocusDimmer(
                    rects: highlightRects,
                    opacity: 0.55,
                  ),
                  // Subtle highlights above the dimmer
                  ...highlightRects.map((rect) => Positioned(
                        left: rect.left,
                        top: rect.top,
                        width: rect.width,
                        height: rect.height,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(
                              color: Colors.yellow.withValues(alpha: 0.5),
                              width: 1,
                            ),
                            color: Colors.yellow.withValues(alpha: 0.1),
                          ),
                        ),
                      )),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return overlays;
  }

  Widget _buildPdfViewer() {
    // ROOT CAUSE FIX: Always wrap in ColorFiltered with conditional colorFilter
    // This keeps the PdfViewer widget stable and prevents _state from becoming null
    // when invertColors changes. See: https://github.com/espresso3389/pdfrx/issues/277
    
    final invertColorFilter = const ColorFilter.matrix([
      -1, 0, 0, 0, 255,
      0, -1, 0, 0, 255,
      0, 0, -1, 0, 255,
      0, 0, 0, 1, 0,
    ]);

    final viewer = PdfViewer.file(
      widget.filePath,
      controller: _controller,
      params: PdfViewerParams(
        textSelectionParams: widget.invertColors
            ? null
            : const PdfTextSelectionParams(
                enabled: true,
                enableSelectionHandles: true,
              ),
        matchTextColor: Colors.transparent,
        activeMatchTextColor: Colors.transparent,
        pageOverlaysBuilder: _buildPageOverlays,
        panEnabled: true,
        scaleEnabled: true,
        interactionEndFrictionCoefficient: 0.1,
        onPageChanged: (pageNumber) {
          // Extract text from pages the viewer is rendering
          // Only extract from pages around the current page to avoid bottleneck
          if (pageNumber != null && pageNumber > 0) {
            log.d('🐛 PdfViewer rendered page: $pageNumber');
            setState(() => _currentPage = pageNumber);
            widget.onPageChanged?.call(_currentPage, _totalPages);
            
            // Extract text from pages around current page (only those PdfViewer rendered)
            _loadPageTextOnDemand(pageNumber - 1).ignore(); // Current (convert 1-based to 0-based)
            if (pageNumber > 1) _loadPageTextOnDemand(pageNumber - 2).ignore(); // Previous
            if (pageNumber < _totalPages) _loadPageTextOnDemand(pageNumber).ignore(); // Next
          }
        },
        onViewerReady: (document, controller) async {
          log.d('PDF document loaded: ${document.pages.length} pages');
          setState(() {
            _document = document;
            _totalPages = document.pages.length;
            _isLoadingOutline = true;
            _pageTexts.clear();
            _isControllerReady = true;
            _isLoadingAllPages = true; // Show loader while extracting text
          });

          log.i('Document ready: $_totalPages pages - starting comprehensive text extraction');
          widget.onPageChanged?.call(_currentPage, _totalPages);

          // Extract all page texts systematically with proper rendering
          _extractAllPageTextsComprehensive().ignore();

          // Load outline in background
          try {
            final outline = await document.loadOutline();
            if (mounted) {
              setState(() {
                _outlineNodes = outline;
                _isLoadingOutline = false;
              });
            }
          } catch (e) {
            log.d('Error loading outline: $e');
            if (mounted) {
              setState(() => _isLoadingOutline = false);
            }
          }
        },
        onGeneralTap: (context, controller, details) {
          if (details.type == PdfViewerGeneralTapType.tap) {
            widget.onTap?.call();
          }
          return false;
        },
      ),
    );

    // Always use ColorFiltered with RepaintBoundary to maintain widget stability
    // and improve rendering performance. The colorFilter property changes dynamically
    // instead of rebuilding the entire widget tree.
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: RepaintBoundary(
        child: ColorFiltered(
          colorFilter: widget.invertColors ? invertColorFilter : const ColorFilter.mode(Colors.transparent, BlendMode.lighten),
          child: viewer,
        ),
      ),
    );
  }

  Widget _buildTextMode() {
    if (_document == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Build page card widget (text loads on-demand)
    Widget buildPageCard(int index) {
      // Load this page's text on-demand (will be instant if already loaded)
      _loadPageTextOnDemand(index);
      
      final pageText = _pageTexts[index];
      final isLoaded = pageText != null;

      // Wrap entire card in Listener to detect taps everywhere
      return Listener(
        onPointerDown: (event) {
          _tapStartPosition = event.position;
          _tapStartTime = DateTime.now();
        },
        onPointerUp: (event) {
          // Detect if this was a tap (not a scroll)
          if (_tapStartPosition != null && _tapStartTime != null) {
            final duration = DateTime.now().difference(_tapStartTime!);
            final distance = (_tapStartPosition! - event.position).distance;
            
            // Tap = press < 200ms with < 10px movement
            if (duration.inMilliseconds < 200 && distance < 10) {
              log.d('✓ TAP detected on page ${index + 1}');
              widget.onTap?.call();
            }
          }
          _tapStartPosition = null;
          _tapStartTime = null;
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page header with copy button
              GestureDetector(
                onTap: () {
                  log.d('Header tap detected on page ${index + 1}');
                  widget.onTap?.call();
                },
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Page ${index + 1}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    if (isLoaded && pageText.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.copy),
                        iconSize: 18,
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          await Clipboard.setData(ClipboardData(text: pageText));
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Page ${index + 1} text copied to clipboard'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        tooltip: 'Copy page text',
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Page content
              if (!isLoaded)
                // Loading state for individual page
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                )
              else if (pageText.isEmpty)
                // Empty page - text couldn't be extracted
                GestureDetector(
                  onTap: () {
                    log.d('Empty page tap detected on page ${index + 1}');
                    widget.onTap?.call();
                  },
                  child: Text(
                    'Text cannot be extracted from this page',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                )
              else
                // Page text - SelectableText handles text selection, outer Listener handles taps
                Expanded(
                  child: SingleChildScrollView(
                    child: SelectableText(
                      pageText,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.6,
                          ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        // Loading indicator overlay
        if (_isLoadingAllPages)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(12),
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Loading page texts...',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ],
              ),
            ),
          ),

        // PageView for page-based navigation with SafeArea top padding
        SafeArea(
          child: PageView.builder(
            controller: _textModePageController,
            itemCount: _totalPages,
            itemBuilder: (context, index) => buildPageCard(index),
          ),
        ),
      ],
    );
  }

  // iOS-style row for search results with snippet
  Widget _buildSearchResultRow(BuildContext context, _SearchResult result, int resultIndex, bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
            : Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _goToSearchResult(resultIndex),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.description,
                        size: 18, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Page ${result.page}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right,
                        size: 18, color: Theme.of(context).colorScheme.outline),
                  ],
                ),
                const SizedBox(height: 8),
                _buildHighlightedSnippet(context, result.snippet),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightedSnippet(BuildContext context, String snippet) {
    if (_currentQuery.isEmpty) return const SizedBox.shrink();
    final lowerText = snippet.toLowerCase();
    final lowerQuery = _currentQuery.toLowerCase();
    final idx = lowerText.indexOf(lowerQuery);
    if (idx == -1) {
      return Text(snippet,
          style: Theme.of(context).textTheme.bodySmall,
          maxLines: 2,
          overflow: TextOverflow.ellipsis);
    }
    final before = snippet.substring(0, idx);
    final match = snippet.substring(idx, idx + _currentQuery.length);
    final after = snippet.substring(idx + _currentQuery.length);
    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: Theme.of(context).textTheme.bodySmall,
        children: [
          TextSpan(text: before),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber[700], // Strong yellow for better contrast
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                match,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
              ),
            ),
          ),
          TextSpan(text: after),
        ],
      ),
    );
  }

  // Build page thumbnail preview
  Widget _buildPageThumbnail(BuildContext context, int page) {
    if (_document == null) {
      return Container(
        width: 50,
        height: 65,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
            child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    return Container(
      width: 50,
      height: 65,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: PdfPageView(
        document: _document,
        pageNumber: page,
        alignment: Alignment.center,
      ),
    );
  }

  // iOS-style row for pages
  Widget _buildPageRow(BuildContext context, int page, bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
            : Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            log.d('Page row tapped: page=$page, textMode=${widget.textMode}');
            // Use public goToPage() which handles both text mode and normal mode
            goToPage(page);
            setState(() => _showSidebar = false);
            log.d('Navigated to page $page, closing sidebar');
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildPageThumbnail(context, page),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Page $page',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w500,
                          color: isActive
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                ),
                Icon(Icons.chevron_right,
                    size: 20, color: Theme.of(context).colorScheme.outline),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPagesTab() {
    // Schedule scroll after frame to ensure ListView is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      log.d('Pages tab built, current page=$_currentPage total=$_totalPages');
      _scrollToActivePageInSidebar();
    });
    
    return ListView.builder(
      controller: _pagesScrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _totalPages,
      itemBuilder: (context, index) {
        final page = index + 1;
        final isActive = page == _currentPage;
        return _buildPageRow(context, page, isActive);
      },
    );
  }

  Widget _buildSearchTab() {
    // Wrap in SingleChildScrollView to handle overflow when keyboard appears
    // The search input, progress indicator, and result counter are fixed-height widgets
    // that can cause overflow when the sidebar height shrinks due to keyboard
    return Column(
      children: [
        SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search PDF...',
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.search,
                          color: Theme.of(context).colorScheme.primary),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _performSearch('');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: (value) {
                      setState(() {});
                      // Clear results immediately if search is empty, otherwise search
                      if (value.isEmpty) {
                        _performSearch('');
                      } else {
                        _performSearch(value);
                      }
                    },
                  ),
                ),
              ),
              if (_isSearching)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _document != null ? _searchPagesChecked / _document!.pages.length : 0,
                          minHeight: 4,
                          backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation(Theme.of(context).colorScheme.primary),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            'Searching $_searchPagesChecked/${_document?.pages.length ?? 0}',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                          const Spacer(),
                          if (_searchResults.isNotEmpty)
                            Text(
                              '${_searchResults.length} result${_searchResults.length == 1 ? '' : 's'}',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              if (_searchResults.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: !_isSearching
                      ? Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surface
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outline
                                  .withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              children: [
                                Text(
                                  '${_currentSearchResult + 1}/${_searchResults.length}',
                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.arrow_upward),
                                  iconSize: 18,
                                  onPressed: _previousSearchResult,
                                  tooltip: 'Previous',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.arrow_downward),
                                  iconSize: 18,
                                  onPressed: _nextSearchResult,
                                  tooltip: 'Next',
                                ),
                              ],
                            ),
                          ),
                        )
                      : SizedBox.shrink(),
                ),
            ],
          ),
        ),
        Expanded(
          child: _searchController.text.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search, size: 48, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
                      const SizedBox(height: 12),
                      Text(
                        'Search in PDF',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'Find text across all pages',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                )
              : _searchResults.isEmpty && !_isSearching
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off, size: 48, color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          Text(
                            'No results found',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Try a different search term',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.7),
                                ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        // Bounds check to prevent RangeError if list changed
                        if (index < 0 || index >= _searchResults.length) {
                          return const SizedBox.shrink();
                        }
                        final result = _searchResults[index];
                        final isActive = index == _currentSearchResult;
                        return _buildSearchResultRow(context, result, index, isActive);
                      },
                    ),
        ),
      ],
    );
  }

  // Build recursive TOC outline tree
  Widget _buildOutlineNode(
      BuildContext context, PdfOutlineNode node, int level) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: EdgeInsets.only(
              left: (level * 16).toDouble(), top: 6, bottom: 6, right: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (node.dest != null) {
                  // Use goToPage() instead of goToDest() to avoid unwanted zoom
                  // goToDest() applies zoom level from PDF destination, we only want page navigation
                  _controller.goToPage(pageNumber: node.dest!.pageNumber);
                  setState(() => _showSidebar = false);
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.bookmark_outline,
                        size: 18, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        node.title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.chevron_right,
                        size: 20, color: Theme.of(context).colorScheme.outline),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (node.children.isNotEmpty)
          ...node.children
              .map((child) => _buildOutlineNode(context, child, level + 1)),
      ],
    );
  }

  Widget _buildTocTab() {
    if (_isLoadingOutline) {
      return Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    if (_outlineNodes == null || _outlineNodes!.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.list_alt, size: 48, color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              'No table of contents available',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'This PDF does not contain a table of contents',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.7),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _outlineNodes!.length,
      itemBuilder: (context, index) {
        return _buildOutlineNode(context, _outlineNodes![index], 0);
      },
    );
  }

  Widget _buildComingSoonTab(String title, String description) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.schedule,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '$title - Coming Soon',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'This feature is under development and will be available in a future update.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.7),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

   // ignore: unused_element
  Widget _buildBottomDock() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => setState(() => _showSidebar = !_showSidebar),
                tooltip: 'Sidebar',
              ),
              IconButton(
                icon: const Icon(Icons.content_copy),
                onPressed: _document != null ? _showCopyDialog : null,
                tooltip: 'Copy PDF Text',
              ),
              IconButton(
                icon: const Icon(Icons.first_page),
                onPressed: _currentPage > 1 ? () => _goToPage(1) : null,
                tooltip: 'First',
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed:
                    _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
                tooltip: 'Previous',
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$_currentPage',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      '$_totalPages',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                            fontSize: 10,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _currentPage < _totalPages
                    ? () => _goToPage(_currentPage + 1)
                    : null,
                tooltip: 'Next',
              ),
              IconButton(
                icon: const Icon(Icons.last_page),
                onPressed: _currentPage < _totalPages
                    ? () => _goToPage(_totalPages)
                    : null,
                tooltip: 'Last',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarTab(
      BuildContext context, String label, IconData icon, int index, {
        bool comingSoon = false,
        String? badgeText,
        bool showBadge = false,
      }) {
    final isActive = _sidebarTab == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        clipBehavior: Clip.none,
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() {
                  _sidebarTab = index;
                  _drawerVersion.value++; // Notify ValueListenableBuilder to rebuild drawer
                }),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 18,
                        color: comingSoon
                            ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.4)
                            : isActive
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outline,
                      ),
                      Text(
                        label,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              color: comingSoon
                                  ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.4)
                                  : isActive
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.outline,
                              fontWeight:
                                  isActive ? FontWeight.w600 : FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (showBadge && badgeText != null)
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: comingSoon
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badgeText,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: comingSoon
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSecondary,
                    ),
                  ),
                ),
              ),
            if (comingSoon && !showBadge)
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.schedule,
                    size: 8,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
         // Main content - PDF/Text viewer fills entire screen
         // NOTE: Tap handling is done by parent ViewerScreen via GestureDetector
         // We don't use GestureDetector here to avoid interference with scrolling
          Container(
            color: Colors.transparent,
            child: widget.textMode ? _buildTextMode() : _buildPdfViewer(),
          ),
        // Sidebar overlay is rendered by ViewerScreen so taps do not
        // interfere with the viewer-wide tap gesture.
      ],
    );
  }
}

/// A painter that dims the whole page but keeps specific rects bright
class _PageFocusDimmer extends StatelessWidget {
  final List<Rect> rects;
  final double opacity;

  const _PageFocusDimmer({required this.rects, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _FocusClipper(rects),
      child: Container(
        color: Colors.black.withValues(alpha: opacity),
      ),
    );
  }
}

/// Clips everything EXCEPT the provided rects
class _FocusClipper extends CustomClipper<Path> {
  final List<Rect> rects;

  _FocusClipper(this.rects);

  @override
  Path getClip(Size size) {
    // 1. Create a path for the full page
    final fullPagePath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    
    // 2. Create a path for all the highlight holes combined
    final holesPath = Path();
    for (final rect in rects) {
      holesPath.addRRect(RRect.fromRectAndRadius(
        rect.inflate(2), // Inflate slightly for better breathing room
        const Radius.circular(4),
      ));
    }

    // 3. Subtract the holes from the full page to create the dimmer with transparent windows
    // PathOperation.difference is much safer than evenOdd when rects might overlap
    return Path.combine(PathOperation.difference, fullPagePath, holesPath);
  }

  @override
  bool shouldReclip(_FocusClipper oldClipper) => rects != oldClipper.rects;
}


