import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

/// Premium PDF Viewer with macOS/iOS dock-style Material3 UI
class ModernPdfViewer extends StatefulWidget {
  final String filePath;
  final String? fileName;

  const ModernPdfViewer({
    required this.filePath,
    this.fileName,
    super.key,
  });

  @override
  State<ModernPdfViewer> createState() => _ModernPdfViewerState();
}

class _ModernPdfViewerState extends State<ModernPdfViewer> {
  final _controller = PdfViewerController();
  final _searchController = TextEditingController();

  bool _showControls = true;
  bool _showSidebar = false;
  bool _invertColors = false;
  bool _textMode = false;
  int _currentPage = 1;
  int _totalPages = 0;
  PdfDocument? _document;

  // Search state
  int _currentSearchResult = -1;
  List<int> _searchResultPages = [];
  bool _isSearching = false;

  // TOC state
  List<PdfOutlineNode>? _outlineNodes;
  bool _isLoadingOutline = false;

  // Sidebar tabs: 0=Pages, 1=Search, 2=TOC
  int _sidebarTab = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    if (page < 1 || page > _totalPages) return;
    _controller.goToPage(pageNumber: page);
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty || _document == null) {
      setState(() {
        _searchResultPages = [];
        _currentSearchResult = -1;
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    final results = <int>{};
    for (int i = 0; i < _document!.pages.length; i++) {
      try {
        final pageText = await _document!.pages[i].loadText();
        if (pageText != null) {
          final text = ((pageText as dynamic).fullText ?? '') as String;
          if (text.toLowerCase().contains(query.toLowerCase())) {
            results.add(i + 1);
          }
        }
      } catch (_) {}
    }

    setState(() {
      _searchResultPages = results.toList()..sort();
      if (_searchResultPages.isNotEmpty) {
        _currentSearchResult = 0;
        _goToPage(_searchResultPages[0]);
      } else {
        _currentSearchResult = -1;
      }
      _isSearching = false;
    });
  }

  void _nextSearchResult() {
    if (_searchResultPages.isEmpty) return;
    setState(() {
      _currentSearchResult =
          (_currentSearchResult + 1) % _searchResultPages.length;
      _goToPage(_searchResultPages[_currentSearchResult]);
    });
  }

  void _previousSearchResult() {
    if (_searchResultPages.isEmpty) return;
    setState(() {
      _currentSearchResult =
          (_currentSearchResult - 1 + _searchResultPages.length) %
              _searchResultPages.length;
      _goToPage(_searchResultPages[_currentSearchResult]);
    });
  }

  Widget _buildPdfViewer() {
    final viewer = PdfViewer.file(
      widget.filePath,
      controller: _controller,
      params: PdfViewerParams(
        textSelectionParams: const PdfTextSelectionParams(enabled: true),
        loadingBannerBuilder: (context, bytesDownloaded, totalBytes) =>
            const Center(child: CircularProgressIndicator()),
        onViewerReady: (document, controller) async {
          setState(() {
            _document = document;
            _totalPages = document.pages.length;
            _isLoadingOutline = true;
          });

          // Load outline/TOC in background
          try {
            final outline = await document.loadOutline();
            if (mounted) {
              setState(() {
                _outlineNodes = outline;
                _isLoadingOutline = false;
              });
            }
          } catch (_) {
            if (mounted) {
              setState(() => _isLoadingOutline = false);
            }
          }
        },
        onPageChanged: (pageNumber) {
          if (pageNumber != null) {
            setState(() => _currentPage = pageNumber);
          }
        },
      ),
    );

    if (_invertColors) {
      return ColorFiltered(
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.difference),
        child: viewer,
      );
    }
    return viewer;
  }

  Widget _buildTextMode() {
    if (_document == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _totalPages,
      itemBuilder: (context, index) {
        final page = _document!.pages[index];
        return FutureBuilder<dynamic>(
          future: page.loadText(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(8),
                child: LinearProgressIndicator(),
              );
            }
            final pageText = snapshot.data;
            final text = ((pageText as dynamic).fullText ?? '') as String;
            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Page ${index + 1}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    text.isEmpty ? '(No text on this page)' : text,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(height: 1),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // iOS-style row for search results
  Widget _buildSearchResultRow(BuildContext context, int page, bool isActive) {
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
            _goToPage(page);
            setState(
                () => _currentSearchResult = _searchResultPages.indexOf(page));
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.description,
                    size: 20, color: Theme.of(context).colorScheme.primary),
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
            _goToPage(page);
            setState(() => _showSidebar = false);
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
    return ListView.builder(
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
    return Column(
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
                if (value.isNotEmpty) {
                  _performSearch(value);
                }
              },
            ),
          ),
        ),
        if (_isSearching)
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              height: 40,
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
        if (_searchResultPages.isNotEmpty && !_isSearching)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Container(
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
                      '${_currentSearchResult + 1}/${_searchResultPages.length}',
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
            ),
          ),
        Expanded(
          child: _searchResultPages.isEmpty &&
                  _searchController.text.isNotEmpty &&
                  !_isSearching
              ? Center(
                  child: Text(
                    'No results found',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _searchResultPages.length,
                  itemBuilder: (context, index) {
                    final page = _searchResultPages[index];
                    final isActive = index == _currentSearchResult;
                    return _buildSearchResultRow(context, page, isActive);
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
                  _controller.goToDest(node.dest!);
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
        child: Text(
          'No table of contents available',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
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

  Widget _buildSidebar() {
    return Material(
      elevation: 0,
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () {}, // Prevent sidebar from closing on tap
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
            minWidth: 280,
          ),
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildSidebarTab(
                                  context, 'Pages', Icons.pages, 0),
                              _buildSidebarTab(
                                  context, 'Search', Icons.search, 1),
                              _buildSidebarTab(context, 'TOC', Icons.list, 2),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _showSidebar = false),
                        iconSize: 20,
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _sidebarTab == 0
                    ? _buildPagesTab()
                    : _sidebarTab == 1
                        ? _buildSearchTab()
                        : _buildTocTab(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarTab(
      BuildContext context, String label, IconData icon, int index) {
    final isActive = _sidebarTab == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
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
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _sidebarTab = index),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: isActive
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                  ),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          color: isActive
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(preferredSize: Size.zero, child: Container()),
      body: Stack(
        children: [
          // Main content - PDF/Text viewer fills entire screen
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (!_showSidebar) {
                setState(() => _showControls = !_showControls);
              }
            },
            child: _textMode ? _buildTextMode() : _buildPdfViewer(),
          ),
          // Bottom dock - navigation and menu
          if (_showControls && !_textMode)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: _buildBottomDock(),
            ),
          // Sidebar overlay
          if (_showSidebar)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: _buildSidebar(),
            ),
        ],
      ),
    );
  }
}
