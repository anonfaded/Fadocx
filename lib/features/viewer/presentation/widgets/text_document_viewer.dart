import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:logger/logger.dart';
import 'package:highlight/highlight_core.dart';
import 'package:highlight/languages/java.dart';
import 'package:highlight/languages/python.dart';
import 'package:highlight/languages/bash.dart';
import 'package:highlight/languages/xml.dart';
import 'package:highlight/languages/markdown.dart';
import 'package:highlight/languages/json.dart' as hl_json_lang;
import 'package:fadocx/features/viewer/presentation/widgets/text_document_search_drawer.dart';

final log = Logger();

/// High-performance text document viewer with lazy loading for large files
/// Supports tap-to-hide controls, font sizing, search, and virtualization
class TextDocumentViewer extends StatefulWidget {
  final String? textContent;
  final VoidCallback? onTap;
  final VoidCallback? onSearchHighlight;
  final double fontSize;
  final bool wordWrap;
  final bool useMonoFont;
  final String? language;

  const TextDocumentViewer({
    required this.textContent,
    this.onTap,
    this.onSearchHighlight,
    this.fontSize = 14,
    this.wordWrap = true,
    this.useMonoFont = false,
    this.language,
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
  List<List<_HighlightToken>> _highlightedLines = const [];
  DateTime? _tapStartTime;
  Offset? _tapStartPosition;
  final ScrollController _scrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _drawerScrollController = ScrollController();
  final ValueNotifier<int> _drawerVersion = ValueNotifier<int>(0);
  late final AnimationController _highlightController;
  final GlobalKey _viewportKey = GlobalKey();
  final Map<int, GlobalKey> _lineTextKeys = {};
  static bool _languagesRegistered = false;

  List<TextSearchResult> _searchResults = const [];
  int _activeSearchResultIndex = -1;
  bool _isSearching = false;
  int _searchLinesChecked = 0;
  int _searchCancellationToken = 0;
  int? _highlightedResultIndex;
  Timer? _highlightReverseTimer;

  @override
  void initState() {
    super.initState();
    _highlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _initializeContent();
  }

  static void _ensureLanguagesRegistered() {
    if (_languagesRegistered) return;
    _languagesRegistered = true;
    highlight.registerLanguage('java', java);
    highlight.registerLanguage('python', python);
    highlight.registerLanguage('bash', bash);
    highlight.registerLanguage('shell', bash);
    highlight.registerLanguage('xml', xml);
    highlight.registerLanguage('markdown', markdown);
    highlight.registerLanguage('json', hl_json_lang.json);
  }

  static const Color _defaultDarkSyntaxColor = Color(0xFFABB2BF);
  static const Color _defaultLightSyntaxColor = Color(0xFF383A42);

  static Map<String, Color> _getSyntaxColors(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return const {
        'keyword': Color(0xFFC678DD),
        'selector-tag': Color(0xFFE06C75),
        'addition': Color(0xFF98C379),
        'built_in': Color(0xFF56B6C2),
        'type': Color(0xFF56B6C2),
        'title': Color(0xFF61AFEF),
        'section': Color(0xFF61AFEF),
        'attr': Color(0xFFD19A66),
        'attribute': Color(0xFFD19A66),
        'string': Color(0xFF98C379),
        'regexp': Color(0xFF98C379),
        'symbol': Color(0xFF56B6C2),
        'variable': Color(0xFFE06C75),
        'template-variable': Color(0xFFE06C75),
        'link': Color(0xFF56B6C2),
        'meta': Color(0xFF7F848E),
        'comment': Color(0xFF7F848E),
        'deletion': Color(0xFFE06C75),
        'number': Color(0xFFD19A66),
        'literal': Color(0xFFD19A66),
        'params': Color(0xFFABB2BF),
        'subst': Color(0xFFE06C75),
        'tag': Color(0xFFE06C75),
        'name': Color(0xFFE06C75),
        'selector-id': Color(0xFF61AFEF),
        'selector-class': Color(0xFFD19A66),
        'selector-attr': Color(0xFFD19A66),
        'selector-pseudo': Color(0xFFD19A66),
        'property': Color(0xFFE06C75),
        'operator': Color(0xFF56B6C2),
        'punctuation': Color(0xFFABB2BF),
        'bullet': Color(0xFFD19A66),
        'code': Color(0xFF98C379),
        'emphasis': Color(0xFFC678DD),
        'strong': Color(0xFFD19A66),
        'formula': Color(0xFF56B6C2),
      };
    }
    return const {
      'keyword': Color(0xFFA626A4),
      'selector-tag': Color(0xFFE45649),
      'addition': Color(0xFF50A14F),
      'built_in': Color(0xFF0184BC),
      'type': Color(0xFF0184BC),
      'title': Color(0xFF4078F2),
      'section': Color(0xFF4078F2),
      'attr': Color(0xFF986801),
      'attribute': Color(0xFF986801),
      'string': Color(0xFF50A14F),
      'regexp': Color(0xFF50A14F),
      'symbol': Color(0xFF0184BC),
      'variable': Color(0xFFE45649),
      'template-variable': Color(0xFFE45649),
      'link': Color(0xFF0184BC),
      'meta': Color(0xFFA0A1A7),
      'comment': Color(0xFFA0A1A7),
      'deletion': Color(0xFFE45649),
      'number': Color(0xFF986801),
      'literal': Color(0xFF986801),
      'params': Color(0xFF383A42),
      'subst': Color(0xFFE45649),
      'tag': Color(0xFFE45649),
      'name': Color(0xFFE45649),
      'selector-id': Color(0xFF4078F2),
      'selector-class': Color(0xFF986801),
      'selector-attr': Color(0xFF986801),
      'selector-pseudo': Color(0xFF986801),
      'property': Color(0xFFE45649),
      'operator': Color(0xFF0184BC),
      'punctuation': Color(0xFF383A42),
      'bullet': Color(0xFF986801),
      'code': Color(0xFF50A14F),
      'emphasis': Color(0xFFA626A4),
      'strong': Color(0xFF986801),
      'formula': Color(0xFF0184BC),
    };
  }

  void _initializeContent() {
    _fullContent = widget.textContent ?? '';
    _lines = _fullContent.split(RegExp(r'\r\n|\r|\n'));
    _highlightedLines = const [];
    _lineTextKeys.clear();

    if (widget.language != null && _fullContent.isNotEmpty) {
      _ensureLanguagesRegistered();
      try {
        final result = highlight.parse(_fullContent, language: widget.language!);
        _highlightedLines = _tokenizeResult(result.nodes);
      } catch (e) {
        log.w('Syntax highlighting failed, falling back to plain text: $e');
        _highlightedLines = const [];
      }
    }

    _performSearch(_searchController.text);

    if (_fullContent.isNotEmpty) {
      log.d('Text document initialized with ${_lines.length} lines (lang: ${widget.language})');
    }
  }

  List<List<_HighlightToken>> _tokenizeResult(List<Node>? nodes) {
    final tokens = <_HighlightToken>[];
    _flattenNodes(nodes, null, tokens);

    final lines = <List<_HighlightToken>>[];
    var currentLine = <_HighlightToken>[];

    for (final token in tokens) {
      var text = token.text;
      final className = token.className;
      while (text.contains('\n')) {
        final idx = text.indexOf('\n');
        final before = text.substring(0, idx);
        final after = text.substring(idx + 1);
        if (before.isNotEmpty) {
          currentLine.add(_HighlightToken(before, className));
        }
        lines.add(currentLine);
        currentLine = <_HighlightToken>[];
        text = after;
      }
      if (text.isNotEmpty) {
        currentLine.add(_HighlightToken(text, className));
      }
    }
    lines.add(currentLine);

    while (lines.length < _lines.length) {
      lines.add(const []);
    }

    return lines;
  }

  void _flattenNodes(List<Node>? nodes, String? parentClass, List<_HighlightToken> tokens) {
    if (nodes == null) return;
    for (final node in nodes) {
      final effectiveClass = node.className ?? parentClass;
      if (node.value != null) {
        tokens.add(_HighlightToken(node.value!, effectiveClass));
      }
      if (node.children != null) {
        _flattenNodes(node.children, effectiveClass, tokens);
      }
    }
  }

  TextSpan _buildHighlightedSpan(int lineIndex, TextStyle baseStyle) {
    final tokens = lineIndex < _highlightedLines.length ? _highlightedLines[lineIndex] : const [];
    if (tokens.isEmpty) {
      return TextSpan(text: _lines[lineIndex], style: baseStyle);
    }
    final brightness = Theme.of(context).brightness;
    final colors = _getSyntaxColors(brightness);
    final defaultColor = brightness == Brightness.dark ? _defaultDarkSyntaxColor : _defaultLightSyntaxColor;
    return TextSpan(
      style: baseStyle,
      children: tokens.map((t) {
        final color = t.className != null ? (colors[t.className] ?? defaultColor) : defaultColor;
        return TextSpan(
          text: t.text,
          style: TextStyle(color: color),
        );
      }).toList(),
    );
  }

  @override
  void didUpdateWidget(TextDocumentViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.textContent != widget.textContent || oldWidget.language != widget.language) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _initializeContent();
      });
    }
  }

  void updateFontSize(double size) {
    // Parent widget handles state updates via fontSize parameter
  }

  void toggleWordWrap() {
    // Parent widget handles state updates via wordWrap parameter
  }

  void toggleFont() {
    // Parent widget handles state updates via useMonoFont parameter
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
    return ValueListenableBuilder<int>(
      valueListenable: _drawerVersion,
      builder: (context, _, __) {
        return TextDocumentSearchDrawer(
          searchController: _searchController,
          scrollController: _drawerScrollController,
          results: _searchResults,
          activeResultIndex: _activeSearchResultIndex,
          isSearching: _isSearching,
          linesChecked: _searchLinesChecked,
          totalLines: _lines.length,
          onQueryChanged: _performSearch,
          onResultTap: _goToSearchResult,
          onNextResult: _goToNextResult,
          onPreviousResult: _goToPreviousResult,
        );
      },
    );
  }

  void _performSearch(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    final searchToken = ++_searchCancellationToken;

    if (normalizedQuery.isEmpty) {
      if (mounted) {
        setState(() {
          _searchResults = const [];
          _activeSearchResultIndex = -1;
          _isSearching = false;
          _searchLinesChecked = 0;
        });
        _drawerVersion.value++;
      }
      return;
    }

    setState(() {
      _isSearching = true;
      _searchLinesChecked = 0;
      _searchResults = const [];
      _activeSearchResultIndex = -1;
    });
    _drawerVersion.value++;

    Future<void>(() async {
      final results = <TextSearchResult>[];
      final totalLines = _lines.length;

      for (int i = 0; i < totalLines; i++) {
        if (!mounted || searchToken != _searchCancellationToken) return;

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

        if ((i + 1) % 120 == 0 || i == totalLines - 1) {
          if (!mounted || searchToken != _searchCancellationToken) return;
          setState(() {
            _searchLinesChecked = i + 1;
            _searchResults = results;
          });
          _drawerVersion.value++;
          await Future<void>.delayed(Duration.zero);
        }
      }

      if (!mounted || searchToken != _searchCancellationToken) return;
      setState(() {
        _isSearching = false;
        _searchLinesChecked = totalLines;
        _searchResults = results;
        _activeSearchResultIndex = results.isNotEmpty ? 0 : -1;
      });
      _drawerVersion.value++;

      if (results.isNotEmpty) {
        _jumpToLine(results.first.lineNumber, animate: false);
      }
    });
  }

  Future<void> _goToSearchResult(int index) async {
    if (index < 0 || index >= _searchResults.length) return;
    final result = _searchResults[index];

    setState(() => _activeSearchResultIndex = index);
    _drawerVersion.value++;
    _scrollDrawerToResult(index);
    widget.onSearchHighlight?.call();
    _triggerHighlight(index);
    await _bringResultIntoView(result);
  }

  /// Scroll the search drawer's result list so the active card is visible.
  void _scrollDrawerToResult(int index) {
    if (!_drawerScrollController.hasClients) return;
    // Each card is ~76px tall (12+12 padding + 12 vertical + ~40 content)
    // plus 12px margin top+bottom = ~88px per item. Use estimate for instant jump.
    const estimatedItemHeight = 88.0;
    const padding = 8.0;
    final targetOffset =
        (index * estimatedItemHeight - padding).clamp(0.0, _drawerScrollController.position.maxScrollExtent);
    _drawerScrollController.jumpTo(targetOffset);
  }

  void _goToNextResult() {
    if (_searchResults.isEmpty) return;
    final nextIndex = (_activeSearchResultIndex + 1) % _searchResults.length;
    _goToSearchResult(nextIndex).ignore();
  }

  void _goToPreviousResult() {
    if (_searchResults.isEmpty) return;
    final prevIndex = (_activeSearchResultIndex - 1 + _searchResults.length) %
        _searchResults.length;
    _goToSearchResult(prevIndex).ignore();
  }

  Future<void> _jumpToLine(int lineNumber, {bool animate = true}) async {
    if (!_scrollController.hasClients) return;
    final lineOffset = _kTopPadding + ((lineNumber - 1) * _lineExtent);
    final viewportHeight = _scrollController.position.viewportDimension;
    final centeredOffset = lineOffset - (viewportHeight * 0.35);
    final target = centeredOffset.clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    if (animate) {
      await _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scrollController.jumpTo(target);
    }
  }

  Future<void> _bringResultIntoView(TextSearchResult result) async {
    if (!_scrollController.hasClients) return;

    final lineIndex = result.lineNumber - 1;
    final lineKey = _lineTextKeys[lineIndex];

    // Step 1: Jump immediately to approximate position
    if (lineKey?.currentContext == null) {
      final approxOffset = _kTopPadding + (lineIndex * _lineExtent);
      final viewportHeight = _scrollController.position.viewportDimension;
      final centered = approxOffset - (viewportHeight * 0.35);
      _scrollController.jumpTo(
        centered.clamp(0.0, _scrollController.position.maxScrollExtent),
      );
    }

    // Step 2: Wait one frame for the line to be built, then fine-tune
    await WidgetsBinding.instance.endOfFrame;

    final rects = _buildHighlightRectsForResult(result);
    if (rects.isEmpty) return;
    final bounds = _combineRects(rects);
    final viewportBox =
        _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (viewportBox == null) return;
    final viewportSize = viewportBox.size;

    final desiredTop = viewportSize.height * 0.3;
    final desiredBottom = viewportSize.height * 0.7;

    // Vertical adjustment — jump instantly for responsiveness
    double? verticalTarget;
    if (bounds.top < desiredTop) {
      verticalTarget =
          (_scrollController.offset + bounds.top - desiredTop).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
    } else if (bounds.bottom > desiredBottom) {
      verticalTarget =
          (_scrollController.offset + bounds.bottom - desiredBottom).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
    }

    // Horizontal adjustment for unwrapped mode
    double? horizontalTarget;
    if (!widget.wordWrap && _horizontalScrollController.hasClients) {
      final desiredLeft = viewportSize.width * 0.2;
      final desiredRight = viewportSize.width * 0.8;
      if (bounds.left < desiredLeft) {
        horizontalTarget =
            (_horizontalScrollController.offset + bounds.left - desiredLeft)
                .clamp(
          0.0,
          _horizontalScrollController.position.maxScrollExtent,
        );
      } else if (bounds.right > desiredRight) {
        horizontalTarget =
            (_horizontalScrollController.offset + bounds.right - desiredRight)
                .clamp(
          0.0,
          _horizontalScrollController.position.maxScrollExtent,
        );
      }
    }

    // Apply both adjustments instantly — no animation for immediate feel
    if (verticalTarget != null) _scrollController.jumpTo(verticalTarget);
    if (horizontalTarget != null) _horizontalScrollController.jumpTo(horizontalTarget);
  }

  void _triggerHighlight(int resultIndex) {
    _highlightReverseTimer?.cancel();
    _highlightController.stop();
    setState(() => _highlightedResultIndex = resultIndex);
    _highlightController.forward(from: 0);
    _highlightReverseTimer =
        Timer(const Duration(milliseconds: 1500), () async {
      if (!mounted) return;
      await _highlightController.reverse();
      if (!mounted) return;
      setState(() => _highlightedResultIndex = null);
    });
  }

  List<Rect> _buildHighlightRectsForResult(TextSearchResult result) {
    final lineIndex = result.lineNumber - 1;
    if (lineIndex < 0 || lineIndex >= _lines.length) return const [];
    final lineKey = _lineTextKeys[lineIndex];
    final lineContext = lineKey?.currentContext;
    final viewportContext = _viewportKey.currentContext;
    if (lineContext == null || viewportContext == null) {
      return const [];
    }

    final renderObject = lineContext.findRenderObject();
    final viewportBox = viewportContext.findRenderObject();
    if (renderObject is! RenderParagraph || viewportBox is! RenderBox) {
      return const [];
    }

    final lineText = _lines[lineIndex];
    final start = result.matchStart.clamp(0, lineText.length);
    final end =
        (result.matchStart + result.matchLength).clamp(start, lineText.length);
    final boxes = renderObject.getBoxesForSelection(
      TextSelection(baseOffset: start, extentOffset: end),
      boxHeightStyle: ui.BoxHeightStyle.tight,
      boxWidthStyle: ui.BoxWidthStyle.tight,
    );
    if (boxes.isEmpty) {
      return const [];
    }

    return boxes.map(
      (box) {
        final topLeft = renderObject.localToGlobal(
          Offset(box.left, box.top),
          ancestor: viewportBox,
        );
        return Rect.fromLTWH(
          topLeft.dx,
          topLeft.dy,
          box.right - box.left,
          box.bottom - box.top,
        );
      },
    ).toList();
  }

  Rect _combineRects(List<Rect> rects) {
    var bounds = rects.first;
    for (final rect in rects.skip(1)) {
      bounds = bounds.expandToInclude(rect);
    }
    return bounds;
  }

  double get _lineHeight => widget.fontSize * 1.5;
  double get _lineExtent => _lineHeight + 2;

  GlobalKey _lineTextKey(int index) {
    return _lineTextKeys.putIfAbsent(index, GlobalKey.new);
  }

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

  @override
  void dispose() {
    _scrollController.dispose();
    _horizontalScrollController.dispose();
    _searchController.dispose();
    _drawerScrollController.dispose();
    _highlightReverseTimer?.cancel();
    _highlightController.dispose();
    _drawerVersion.dispose();
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
            return Stack(
              key: _viewportKey,
              children: [
                if (widget.wordWrap)
                  SelectionArea(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(
                        left: 4,
                        right: 8,
                        top: _kTopPadding,
                        bottom: _kBottomPadding,
                      ),
                      itemCount: _lines.length,
                      cacheExtent: 800,
                      itemBuilder: (itemContext, index) {
                        return _buildWrappedLineRow(
                          context: context,
                          selectionContext: itemContext,
                          index: index,
                          lineNumberWidth: lineNumberWidth,
                          textStyle: textStyle,
                        );
                      },
                    ),
                  )
                else
                  // Virtualized unwrapped mode: horizontal SingleChildScrollView
                  // wrapping vertical ListView.builder — axes don't conflict.
                  SingleChildScrollView(
                    controller: _horizontalScrollController,
                    scrollDirection: Axis.horizontal,
                    child: SelectionArea(
                      child: Builder(
                        builder: (selectionContext) {
                          // Estimate max line width for horizontal scroll extent.
                          // Uses character count × approximate char width.
                          final maxLineLen = _lines.isEmpty
                              ? 0
                              : _lines
                                  .map((l) => l.length)
                                  .reduce((a, b) => a > b ? a : b);
                          final estimatedMaxLineWidth =
                              maxLineLen * fontSize * 0.602;
                          final contentWidth = max(
                            constraints.maxWidth,
                            estimatedMaxLineWidth +
                                lineNumberWidth +
                                20, // padding
                          );
                          return SizedBox(
                            width: contentWidth,
                            height: constraints.maxHeight,
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.only(
                                left: 4,
                                right: 8,
                                top: _kTopPadding,
                                bottom: _kBottomPadding,
                              ),
                              itemCount: _lines.length,
                              cacheExtent: 800,
                              itemBuilder: (itemContext, index) {
                                return _buildUnwrappedLineRow(
                                  context: context,
                                  selectionContext: selectionContext,
                                  index: index,
                                  lineNumberWidth: lineNumberWidth,
                                  textStyle: textStyle,
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                if (_highlightedResultIndex != null)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: Listenable.merge([
                          _highlightController,
                          _scrollController,
                          _horizontalScrollController,
                        ]),
                        builder: (context, child) {
                          if (_highlightController.value == 0 ||
                              _highlightedResultIndex == null ||
                              _highlightedResultIndex! >=
                                  _searchResults.length) {
                            return const SizedBox.shrink();
                          }
                          final rects = _buildHighlightRectsForResult(
                            _searchResults[_highlightedResultIndex!],
                          )
                              .where((rect) => rect
                                  .overlaps(Offset.zero & constraints.biggest))
                              .toList();
                          if (rects.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return _TextSpotlightOverlay(
                            rects: rects,
                            progress: _highlightController.value,
                            dimOpacity: 0.55,
                            strokeColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.72),
                            glowColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.22),
                          );
                        },
                      ),
                    ),
                  ),
              ],
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
    required int index,
    required double lineNumberWidth,
    required TextStyle lineNumberStyle,
  }) {
    return SelectionContainer.disabled(
      child: SizedBox(
        width: lineNumberWidth,
        child: Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Text(
              '${index + 1}',
              textAlign: TextAlign.right,
              style: lineNumberStyle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWrappedLineRow({
    required BuildContext context,
    required BuildContext selectionContext,
    required int index,
    required double lineNumberWidth,
    required TextStyle textStyle,
  }) {
    final lineNumberStyle = textStyle.copyWith(
      fontSize: widget.fontSize * 0.9,
      color: Theme.of(context)
          .colorScheme
          .onSurfaceVariant
          .withValues(alpha: 0.55),
      letterSpacing: -0.1,
    );
    final selectionRegistrar = SelectionContainer.maybeOf(selectionContext);
    final selectionColor =
        Theme.of(selectionContext).colorScheme.primary.withValues(alpha: 0.22);

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLineNumbers(
            context: context,
            index: index,
            lineNumberWidth: lineNumberWidth,
            lineNumberStyle: lineNumberStyle,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _lines[index].isEmpty
                ? SizedBox(height: _lineHeight)
                : RichText(
                    key: _lineTextKey(index),
                    text: _highlightedLines.isEmpty
                        ? TextSpan(text: _lines[index], style: textStyle)
                        : _buildHighlightedSpan(index, textStyle),
                    textAlign: TextAlign.left,
                    softWrap: true,
                    textDirection: Directionality.of(context),
                    textScaler: MediaQuery.textScalerOf(context),
                    selectionRegistrar: selectionRegistrar,
                    selectionColor: selectionColor,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnwrappedLineRow({
    required BuildContext context,
    required BuildContext selectionContext,
    required int index,
    required double lineNumberWidth,
    required TextStyle textStyle,
  }) {
    final lineNumberStyle = textStyle.copyWith(
      fontSize: widget.fontSize * 0.9,
      color: Theme.of(context)
          .colorScheme
          .onSurfaceVariant
          .withValues(alpha: 0.55),
      letterSpacing: -0.1,
    );
    final selectionRegistrar = SelectionContainer.maybeOf(selectionContext);
    final selectionColor =
        Theme.of(selectionContext).colorScheme.primary.withValues(alpha: 0.22);

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLineNumbers(
            context: context,
            index: index,
            lineNumberWidth: lineNumberWidth,
            lineNumberStyle: lineNumberStyle,
          ),
          const SizedBox(width: 12),
          _lines[index].isEmpty
              ? SizedBox(height: _lineHeight)
              : RichText(
                  key: _lineTextKey(index),
                  text: _highlightedLines.isEmpty
                      ? TextSpan(text: _lines[index], style: textStyle)
                      : _buildHighlightedSpan(index, textStyle),
                  textAlign: TextAlign.left,
                  softWrap: false,
                  textDirection: Directionality.of(context),
                  textScaler: MediaQuery.textScalerOf(context),
                  selectionRegistrar: selectionRegistrar,
                  selectionColor: selectionColor,
                ),
        ],
      ),
    );
  }


}

class _HighlightToken {
  final String text;
  final String? className;
  const _HighlightToken(this.text, this.className);
}

class _TextSpotlightOverlay extends StatelessWidget {
  final List<Rect> rects;
  final double progress;
  final double dimOpacity;
  final Color strokeColor;
  final Color glowColor;

  const _TextSpotlightOverlay({
    required this.rects,
    required this.progress,
    required this.dimOpacity,
    required this.strokeColor,
    required this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TextSpotlightPainter(
        rects: rects,
        progress: progress,
        dimOpacity: dimOpacity,
        strokeColor: strokeColor,
        glowColor: glowColor,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _TextSpotlightPainter extends CustomPainter {
  final List<Rect> rects;
  final double progress;
  final double dimOpacity;
  final Color strokeColor;
  final Color glowColor;

  const _TextSpotlightPainter({
    required this.rects,
    required this.progress,
    required this.dimOpacity,
    required this.strokeColor,
    required this.glowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || rects.isEmpty) return;

    final viewportRect = Offset.zero & size;
    final overlayBounds = viewportRect;
    final spotlightRects = rects
        .map((rect) => rect.intersect(viewportRect))
        .where((rect) => !rect.isEmpty)
        .map(
          (rect) => RRect.fromRectAndRadius(
            rect.inflate(3),
            const Radius.circular(8),
          ),
        )
        .toList();
    if (spotlightRects.isEmpty) return;

    canvas.saveLayer(overlayBounds, Paint());
    canvas.drawRect(
      overlayBounds,
      Paint()..color = Colors.black.withValues(alpha: dimOpacity * progress),
    );
    for (final spotlight in spotlightRects) {
      canvas.drawRRect(
        spotlight,
        Paint()..blendMode = BlendMode.clear,
      );
    }
    canvas.restore();

    final glowPaint = Paint()
      ..color = glowColor.withValues(alpha: glowColor.a * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    for (final spotlight in spotlightRects) {
      canvas.drawRRect(spotlight, glowPaint);
    }

    final strokePaint = Paint()
      ..color = strokeColor.withValues(alpha: strokeColor.a * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final spotlight in spotlightRects) {
      canvas.drawRRect(spotlight, strokePaint);
    }
  }

  @override
  bool shouldRepaint(_TextSpotlightPainter oldDelegate) {
    return rects != oldDelegate.rects ||
        progress != oldDelegate.progress ||
        dimOpacity != oldDelegate.dimOpacity ||
        strokeColor != oldDelegate.strokeColor ||
        glowColor != oldDelegate.glowColor;
  }
}
