import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

/// Professional PDF viewer using pdfrx (PDFium backend)
/// Features: zoom/pan, text selection, dark invert, text mode, sidebar, page nav
class ModernPdfViewer extends StatefulWidget {
  final String filePath;

  const ModernPdfViewer({
    required this.filePath,
    super.key,
  });

  @override
  State<ModernPdfViewer> createState() => _ModernPdfViewerState();
}

class _ModernPdfViewerState extends State<ModernPdfViewer> {
  final _controller = PdfViewerController();
  final _pageController = TextEditingController();

  bool _showControls = true;
  bool _showSidebar = false;
  bool _invertColors = false;
  bool _textMode = false;
  int _currentPage = 1;
  int _totalPages = 0;
  PdfDocument? _document;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    if (page < 1 || page > _totalPages) return;
    _controller.goToPage(pageNumber: page);
  }

  void _showGoToPageDialog() {
    _pageController.value = TextEditingValue(
      text: _currentPage.toString(),
      selection: TextSelection(
          baseOffset: 0, extentOffset: _currentPage.toString().length),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Go to Page'),
        content: TextField(
          controller: _pageController,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Page number',
            helperText: '1 – $_totalPages',
          ),
          onSubmitted: (value) {
            final page = int.tryParse(value);
            if (page != null && page >= 1 && page <= _totalPages) {
              Navigator.pop(ctx);
              _goToPage(page);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final page = int.tryParse(_pageController.text);
              if (page != null && page >= 1 && page <= _totalPages) {
                Navigator.pop(ctx);
                _goToPage(page);
              }
            },
            child: const Text('Go'),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfViewer() {
    final viewer = PdfViewer.file(
      widget.filePath,
      controller: _controller,
      params: PdfViewerParams(
        textSelectionParams: const PdfTextSelectionParams(
          enabled: true,
        ),
        loadingBannerBuilder: (context, bytesDownloaded, totalBytes) =>
            const Center(child: CircularProgressIndicator()),
        onViewerReady: (document, controller) async {
          setState(() {
            _document = document;
            _totalPages = document.pages.length;
          });
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
            // pageText can be either PdfPageText (v1.x) or PdfPageRawText (v2.x)
            // Both have a text/fullText property we can access via dynamic
            final text = (pageText?.fullText ?? pageText?.text ?? '') as String;
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
                  const SizedBox(height: 4),
                  SelectableText(
                    text.isEmpty ? '(No text on this page)' : text,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Divider(height: 32),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Material(
        elevation: 2,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _showSidebar ? Icons.menu_open : Icons.menu,
                  ),
                  onPressed: () => setState(() => _showSidebar = !_showSidebar),
                  tooltip: 'Page thumbnails',
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      _totalPages > 0
                          ? '$_currentPage / $_totalPages'
                          : 'Loading…',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _invertColors
                        ? Icons.brightness_high
                        : Icons.brightness_low,
                  ),
                  onPressed: () =>
                      setState(() => _invertColors = !_invertColors),
                  tooltip: _invertColors ? 'Normal colors' : 'Invert colors',
                ),
                IconButton(
                  icon: Icon(
                    _textMode ? Icons.picture_as_pdf : Icons.text_snippet,
                  ),
                  onPressed: () => setState(() => _textMode = !_textMode),
                  tooltip: _textMode ? 'PDF mode' : 'Text mode',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDock() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.first_page),
                  onPressed: _currentPage > 1 ? () => _goToPage(1) : null,
                  tooltip: 'First page',
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _currentPage > 1
                      ? () => _goToPage(_currentPage - 1)
                      : null,
                  tooltip: 'Previous page',
                ),
                InkWell(
                  onTap: _showGoToPageDialog,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Text(
                      '$_currentPage / $_totalPages',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _currentPage < _totalPages
                      ? () => _goToPage(_currentPage + 1)
                      : null,
                  tooltip: 'Next page',
                ),
                IconButton(
                  icon: const Icon(Icons.last_page),
                  onPressed: _currentPage < _totalPages
                      ? () => _goToPage(_totalPages)
                      : null,
                  tooltip: 'Last page',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Positioned(
      left: 0,
      top: 0,
      bottom: 0,
      width: 76,
      child: Material(
        elevation: 4,
        child: Column(
          children: [
            SafeArea(
              bottom: false,
              child: SizedBox(
                height: 48,
                child: Row(
                  children: [
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() => _showSidebar = false),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _totalPages,
                itemBuilder: (context, index) {
                  final page = index + 1;
                  final isActive = page == _currentPage;
                  return GestureDetector(
                    onTap: () {
                      _goToPage(page);
                      setState(() => _showSidebar = false);
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 4),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.12)
                            : null,
                        border: Border.all(
                          color: isActive
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '$page',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontWeight: isActive
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isActive
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                  ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => setState(() => _showControls = !_showControls),
        child: Stack(
          children: [
            // Main content
            Positioned.fill(
              child: _textMode ? _buildTextMode() : _buildPdfViewer(),
            ),

            // Sidebar (above content, below controls)
            if (_showSidebar) _buildSidebar(),

            // Header
            if (_showControls) _buildHeader(),

            // Bottom dock (only in PDF mode)
            if (_showControls && !_textMode) _buildDock(),
          ],
        ),
      ),
    );
  }
}
