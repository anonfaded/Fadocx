import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:fadocx/features/viewer/presentation/widgets/text_document_search_drawer.dart';

final log = Logger();

/// High-performance text document viewer with lazy loading for large files
/// Supports tap-to-hide controls, font sizing, search, and virtualization
class TextDocumentViewer extends StatefulWidget {
  final String? textContent;
  final VoidCallback? onTap;
  final double fontSize;
  final bool wordWrap;
  final bool useMonoFont;

  const TextDocumentViewer({
    required this.textContent,
    this.onTap,
    this.fontSize = 14,
    this.wordWrap = true,
    this.useMonoFont = false,
    super.key,
  });

  @override
  State<TextDocumentViewer> createState() => _TextDocumentViewerState();
}

class _TextDocumentViewerState extends State<TextDocumentViewer>
    with SingleTickerProviderStateMixin {
  static const double _kTopPadding = 40;
  static const double _kBottomPadding = 16;
  static const double _kLineNumberColumnPadding = 8;

  late String _fullContent;
  List<String> _lines = const [];
  DateTime? _tapStartTime;
  Offset? _tapStartPosition;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  late final AnimationController _highlightController;

  List<TextSearchResult> _searchResults = const [];
  int _activeSearchResultIndex = -1;
  int? _highlightedLine;

  @override
  void initState() {
    super.initState();
    _highlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _initializeContent();
  }

  void _initializeContent() {
    _fullContent = widget.textContent ?? '';
    _lines = _fullContent.split('\n');
    _performSearch(_searchController.text);

    if (_fullContent.isNotEmpty) {
      log.d('Text document initialized with ${_lines.length} lines');
    }
  }

  @override
  void didUpdateWidget(TextDocumentViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.textContent != widget.textContent) {
      _initializeContent();
    }
  }

  void updateFontSize(double size) {
    // Parent widget handles state updates via fontSize parameter
  }

  void toggleWordWrap() {
    // Parent widget handles state updates via wordWrap parameter
  }

  void toggleFont() {
    // TODO: Implement font toggle (currently mono only)
  }

  void scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Widget buildDrawerContent(BuildContext context) {
    return TextDocumentSearchDrawer(
      searchController: _searchController,
      results: _searchResults,
      activeResultIndex: _activeSearchResultIndex,
      onQueryChanged: _performSearch,
      onResultTap: _goToSearchResult,
      onNextResult: _goToNextResult,
      onPreviousResult: _goToPreviousResult,
    );
  }

  void _performSearch(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      if (mounted) {
        setState(() {
          _searchResults = const [];
          _activeSearchResultIndex = -1;
        });
      }
      return;
    }

    final results = <TextSearchResult>[];
    for (int i = 0; i < _lines.length; i++) {
      final lineText = _lines[i];
      final lowerLine = lineText.toLowerCase();
      var start = 0;
      while (start < lowerLine.length) {
        final foundAt = lowerLine.indexOf(normalizedQuery, start);
        if (foundAt == -1) break;

        results.add(
          TextSearchResult(
            lineNumber: i + 1,
            lineText: lineText,
            matchStart: foundAt,
            matchLength: normalizedQuery.length,
          ),
        );
        start = foundAt + normalizedQuery.length;
      }
    }

    if (!mounted) return;
    setState(() {
      _searchResults = results;
      _activeSearchResultIndex = results.isNotEmpty ? 0 : -1;
    });

    if (results.isNotEmpty) {
      _jumpToLine(results.first.lineNumber, animate: false);
      _flashLineHighlight(results.first.lineNumber);
    }
  }

  void _goToSearchResult(int index) {
    if (index < 0 || index >= _searchResults.length) return;
    final result = _searchResults[index];

    setState(() => _activeSearchResultIndex = index);
    _jumpToLine(result.lineNumber);
    _flashLineHighlight(result.lineNumber);
  }

  void _goToNextResult() {
    if (_searchResults.isEmpty) return;
    final nextIndex = (_activeSearchResultIndex + 1) % _searchResults.length;
    _goToSearchResult(nextIndex);
  }

  void _goToPreviousResult() {
    if (_searchResults.isEmpty) return;
    final prevIndex = (_activeSearchResultIndex - 1 + _searchResults.length) %
        _searchResults.length;
    _goToSearchResult(prevIndex);
  }

  void _jumpToLine(int lineNumber, {bool animate = true}) {
    if (!_scrollController.hasClients) return;
    final lineOffset = _kTopPadding + ((lineNumber - 1) * _lineHeight);
    final target = lineOffset.clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    if (animate) {
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scrollController.jumpTo(target);
    }
  }

  void _flashLineHighlight(int lineNumber) {
    _highlightController.stop();
    setState(() => _highlightedLine = lineNumber);
    _highlightController.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() => _highlightedLine = null);
    });
  }

  double get _lineHeight => widget.fontSize * 1.5;

  double _lineNumberWidth(BuildContext context) {
    final lineNumberStyle = TextStyle(
      fontSize: widget.fontSize * 0.9,
      fontFamily: widget.useMonoFont ? 'Courier' : 'Ubuntu',
      height: 1.5,
      letterSpacing: -0.1,
    );
    final maxLineNumber = _lines.isEmpty ? '1' : _lines.length.toString();
    final painter = TextPainter(
      text: TextSpan(text: maxLineNumber, style: lineNumberStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();

    return painter.width + _kLineNumberColumnPadding;
  }

  String _buildLineNumbersText() {
    if (_lines.isEmpty) return '1';
    return List.generate(_lines.length, (index) => '${index + 1}').join('\n');
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _highlightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_fullContent.isEmpty) {
      return _buildEmptyView(context);
    }

    final textColor = Theme.of(context).colorScheme.onSurface;
    final fontFamily = widget.useMonoFont ? 'Courier' : 'Ubuntu';
    final fontSize = widget.fontSize;
    final lineNumberWidth = _lineNumberWidth(context);
    final textStyle = TextStyle(
      fontSize: fontSize,
      color: textColor,
      fontFamily: fontFamily,
      height: 1.5,
      letterSpacing: -0.3,
    );

    // Wrap entire content in Listener to detect taps (like PDF viewer)
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
            log.d('✓ TAP detected on text viewer');
            widget.onTap?.call();
          }
        }
        _tapStartPosition = null;
        _tapStartTime = null;
      },
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final minTextWidth = (constraints.maxWidth - lineNumberWidth - 24)
                .clamp(80.0, double.infinity);

            return SingleChildScrollView(
              controller: _scrollController,
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 4,
                  right: 8,
                  top: _kTopPadding,
                  bottom: _kBottomPadding,
                ),
                child: Stack(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLineNumbers(
                          context: context,
                          lineNumberWidth: lineNumberWidth,
                          lineNumberStyle: textStyle.copyWith(
                            fontSize: fontSize * 0.9,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: 0.55),
                            letterSpacing: -0.1,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: widget.wordWrap
                              ? ConstrainedBox(
                                  constraints:
                                      BoxConstraints(minWidth: minTextWidth),
                                  child: SelectableText(
                                    _fullContent.isEmpty ? ' ' : _fullContent,
                                    style: textStyle,
                                  ),
                                )
                              : SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: SelectableText(
                                    _fullContent.isEmpty ? ' ' : _fullContent,
                                    style: textStyle,
                                  ),
                                ),
                        ),
                      ],
                    ),
                    if (_highlightedLine != null)
                      Positioned(
                        left: lineNumberWidth + 12,
                        right: 0,
                        top: (_highlightedLine! - 1) * _lineHeight,
                        child: IgnorePointer(
                          child: AnimatedBuilder(
                            animation: _highlightController,
                            builder: (context, child) {
                              final t = 1 - _highlightController.value;
                              return Container(
                                height: _lineHeight,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.25 * t),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Empty file',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineNumbers({
    required BuildContext context,
    required double lineNumberWidth,
    required TextStyle lineNumberStyle,
  }) {
    return SizedBox(
      width: lineNumberWidth,
      child: Text(
        _buildLineNumbersText(),
        textAlign: TextAlign.right,
        style: lineNumberStyle,
      ),
    );
  }
}
