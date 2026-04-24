import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import 'package:fadocx/features/viewer/domain/entities/parsed_document_entity.dart';
import 'package:fadocx/features/viewer/presentation/widgets/rich_document_search_drawer.dart';

final _richLog = Logger();

class RichDocumentViewer extends StatefulWidget {
  final List<DocumentBlock> documentBlocks;
  final String? plainTextContent;
  final List<String> parseWarnings;
  final DocumentFidelityLevel fidelityLevel;
  final VoidCallback? onTap;
  final VoidCallback? onSearchHighlight;
  final double fontSize;
  final bool wordWrap;
  final bool useMonoFont;

  const RichDocumentViewer({
    super.key,
    required this.documentBlocks,
    this.plainTextContent,
    this.parseWarnings = const [],
    this.fidelityLevel = DocumentFidelityLevel.partial,
    this.onTap,
    this.onSearchHighlight,
    this.fontSize = 14,
    this.wordWrap = true,
    this.useMonoFont = false,
  });

  @override
  State<RichDocumentViewer> createState() => _RichDocumentViewerState();
}

class _RichDocumentViewerState extends State<RichDocumentViewer>
    with SingleTickerProviderStateMixin {
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<int> _drawerVersion = ValueNotifier<int>(0);
  final Map<String, GlobalKey> _targetKeys = {};
  final GlobalKey _viewportKey = GlobalKey();
  late final AnimationController _highlightController;

  List<_SearchTarget> _targets = const [];
  List<RichDocumentSearchResult> _searchResults = const [];
  int _activeResultIndex = -1;
  bool _isSearching = false;
  String? _activeTargetId;
  int? _activeTargetMatchStart;
  int? _activeTargetMatchLength;
  int? _highlightedResultIndex;
  Timer? _highlightReverseTimer;
  DateTime? _tapStartTime;
  Offset? _tapStartPosition;

  @override
  void initState() {
    super.initState();
    _highlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _rebuildTargets();
    _richLog.i(
      'Rich document viewer initialized with ${widget.documentBlocks.length} blocks, '
      'fidelity=${widget.fidelityLevel.name}, warnings=${widget.parseWarnings.length}',
    );
  }

  @override
  void didUpdateWidget(covariant RichDocumentViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.documentBlocks != widget.documentBlocks ||
        oldWidget.plainTextContent != widget.plainTextContent) {
      _rebuildTargets();
      _performSearch(_searchController.text);
      _richLog.d(
        'Rich document content updated: blocks=${widget.documentBlocks.length}, '
        'fidelity=${widget.fidelityLevel.name}',
      );
    }
  }

  @override
  void dispose() {
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    _searchController.dispose();
    _highlightReverseTimer?.cancel();
    _highlightController.dispose();
    _drawerVersion.dispose();
    super.dispose();
  }

  Widget buildDrawerContent(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _drawerVersion,
      builder: (context, _, __) {
        return RichDocumentSearchDrawer(
          searchController: _searchController,
          results: _searchResults,
          activeResultIndex: _activeResultIndex,
          isSearching: _isSearching,
          onQueryChanged: _performSearch,
          onResultTap: _goToSearchResult,
          onNextResult: _goToNextResult,
          onPreviousResult: _goToPreviousResult,
        );
      },
    );
  }

  void _rebuildTargets() {
    _targetKeys.clear();
    _targets = _collectTargets(widget.documentBlocks);
    for (final target in _targets) {
      _targetKeys[target.id] = GlobalKey();
    }
    _richLog.d('Rich document targets rebuilt: ${_targets.length}');
  }

  void _performSearch(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      setState(() {
        _searchResults = const [];
        _activeResultIndex = -1;
        _activeTargetId = null;
        _activeTargetMatchStart = null;
        _activeTargetMatchLength = null;
        _isSearching = false;
      });
      _drawerVersion.value++;
      return;
    }

    setState(() => _isSearching = true);
    final results = <RichDocumentSearchResult>[];

    for (final target in _targets) {
      final lower = target.text.toLowerCase();
      var start = 0;
      while (start < lower.length) {
        final foundAt = lower.indexOf(normalized, start);
        if (foundAt == -1) break;
        results.add(
          RichDocumentSearchResult(
            targetId: target.id,
            label: target.label,
            snippet: _snippet(target.text, foundAt, normalized.length),
            matchStart: foundAt,
            matchLength: normalized.length,
          ),
        );
        start = foundAt + normalized.length;
      }
    }

    setState(() {
      _searchResults = results;
      _activeResultIndex = results.isEmpty ? -1 : 0;
      _isSearching = false;
    });
    _drawerVersion.value++;

    if (results.isNotEmpty) {
      _goToSearchResult(0);
    }
  }

  Future<void> _goToSearchResult(int index) async {
    if (index < 0 || index >= _searchResults.length) return;
    final result = _searchResults[index];
    setState(() {
      _activeResultIndex = index;
      _activeTargetId = result.targetId;
      _activeTargetMatchStart = result.matchStart;
      _activeTargetMatchLength = result.matchLength;
    });
    _drawerVersion.value++;
    widget.onSearchHighlight?.call();
    _richLog.d(
      'Rich search result selected: index=$index target=${result.targetId}',
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final targetContext = _targetKeys[result.targetId]?.currentContext;
      if (targetContext != null) {
        Scrollable.ensureVisible(
          targetContext,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          alignment: 0.24,
        );
      }
      _triggerHighlight(index);
    });
  }

  void _goToNextResult() {
    if (_searchResults.isEmpty) return;
    final next = (_activeResultIndex + 1) % _searchResults.length;
    _goToSearchResult(next).ignore();
  }

  void _goToPreviousResult() {
    if (_searchResults.isEmpty) return;
    final next = (_activeResultIndex - 1 + _searchResults.length) %
        _searchResults.length;
    _goToSearchResult(next).ignore();
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

  List<Rect> _buildHighlightRectsForResult(RichDocumentSearchResult result) {
    final targetContext = _targetKeys[result.targetId]?.currentContext;
    final viewportContext = _viewportKey.currentContext;
    if (targetContext == null || viewportContext == null) {
      return const [];
    }

    final renderObject = targetContext.findRenderObject();
    final viewportBox = viewportContext.findRenderObject();
    if (renderObject is! RenderBox || viewportBox is! RenderBox) {
      return const [];
    }

    final topLeft =
        renderObject.localToGlobal(Offset.zero, ancestor: viewportBox);
    return [
      Rect.fromLTWH(
        topLeft.dx,
        topLeft.dy,
        renderObject.size.width,
        renderObject.size.height,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.parseWarnings.isNotEmpty ||
              widget.fidelityLevel != DocumentFidelityLevel.rich)
            _buildNotice(theme),
          ..._buildBlocks(widget.documentBlocks),
        ],
      ),
    );

    final scrollContent = widget.wordWrap
        ? body
        : SingleChildScrollView(
            controller: _horizontalScrollController,
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 900),
              child: body,
            ),
          );

    return Listener(
      onPointerDown: (event) {
        _tapStartPosition = event.position;
        _tapStartTime = DateTime.now();
      },
      onPointerUp: (event) {
        if (_tapStartPosition != null && _tapStartTime != null) {
          final duration = DateTime.now().difference(_tapStartTime!);
          final distance = (_tapStartPosition! - event.position).distance;
          if (duration.inMilliseconds < 200 && distance < 10) {
            _richLog.d('Tap detected on rich viewer');
            widget.onTap?.call();
          }
        }
        _tapStartPosition = null;
        _tapStartTime = null;
      },
      child: Container(
        color: theme.colorScheme.surface,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              key: _viewportKey,
              children: [
                SelectionArea(
                  child: SingleChildScrollView(
                    controller: _verticalScrollController,
                    padding: const EdgeInsets.only(top: 16),
                    child: scrollContent,
                  ),
                ),
                if (_highlightedResultIndex != null)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: Listenable.merge([
                          _highlightController,
                          _verticalScrollController,
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
                          return _RichSpotlightOverlay(
                            rects: rects,
                            progress: _highlightController.value,
                            dimOpacity: 0.55,
                            strokeColor: theme.colorScheme.primary
                                .withValues(alpha: 0.72),
                            glowColor: theme.colorScheme.primary
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

  Widget _buildNotice(ThemeData theme) {
    final fidelityLabel = switch (widget.fidelityLevel) {
      DocumentFidelityLevel.rich => 'Rich fidelity',
      DocumentFidelityLevel.partial => 'Partial fidelity',
      DocumentFidelityLevel.plainText => 'Plain text fidelity',
    };

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fidelityLabel,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
          if (widget.parseWarnings.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              widget.parseWarnings.join('\n'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildBlocks(List<DocumentBlock> blocks) {
    return [
      for (var index = 0; index < blocks.length; index++)
        _buildBlock(blocks[index], 'b.$index'),
    ];
  }

  Widget _buildBlock(DocumentBlock block, String targetId) {
    if (block is DocumentParagraphBlock) {
      return _buildParagraph(block, targetId);
    }
    if (block is DocumentTableBlock) {
      return _buildTable(block, targetId);
    }
    if (block is DocumentSpacerBlock) {
      return SizedBox(
        height: block.isPageBreak ? block.height * 2 : block.height,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildParagraph(DocumentParagraphBlock paragraph, String targetId) {
    final key = _targetKeys[targetId] ?? GlobalKey();
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
          height: 1.5,
          fontSize: widget.fontSize,
          fontFamily: widget.useMonoFont ? 'Courier' : 'Ubuntu',
        );
    final text = paragraph.plainText;
    final matchStart =
        _activeTargetId == targetId ? _activeTargetMatchStart : null;
    final matchLength =
        _activeTargetId == targetId ? _activeTargetMatchLength : null;

    return Container(
      key: key,
      width: double.infinity,
      margin: EdgeInsets.only(
        bottom: (paragraph.spacingAfter ?? widget.fontSize * 0.8).clamp(8, 32),
        top: (paragraph.spacingBefore ?? 0).clamp(0, 24),
      ),
      child: RichText(
        softWrap: widget.wordWrap,
        textAlign: _textAlignFor(paragraph.alignment),
        text: TextSpan(
          style: style,
          children: _inlineSpansForParagraph(
            paragraph,
            paragraphText: text,
            matchStart: matchStart,
            matchLength: matchLength,
          ),
        ),
      ),
    );
  }

  Widget _buildTable(DocumentTableBlock table, String targetId) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Table(
        border: TableBorder.symmetric(
          inside:
              BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        defaultVerticalAlignment: TableCellVerticalAlignment.top,
        children: [
          for (var rowIndex = 0; rowIndex < table.rows.length; rowIndex++)
            TableRow(
              children: [
                for (var cellIndex = 0;
                    cellIndex < table.rows[rowIndex].cells.length;
                    cellIndex++)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var blockIndex = 0;
                            blockIndex <
                                table.rows[rowIndex].cells[cellIndex].blocks
                                    .length;
                            blockIndex++)
                          _buildBlock(
                            table.rows[rowIndex].cells[cellIndex]
                                .blocks[blockIndex],
                            '$targetId.$rowIndex.$cellIndex.$blockIndex',
                          ),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  List<InlineSpan> _inlineSpansForParagraph(
    DocumentParagraphBlock paragraph, {
    required String paragraphText,
    required int? matchStart,
    required int? matchLength,
  }) {
    final spans = <InlineSpan>[];
    var offset = 0;

    for (final inline in paragraph.inlines) {
      final rawText = inline.plainText;
      if (rawText.isEmpty) continue;
      final baseStyle = TextStyle(
        fontWeight: inline.style.bold ? FontWeight.w700 : FontWeight.w400,
        fontStyle: inline.style.italic ? FontStyle.italic : FontStyle.normal,
        decoration: TextDecoration.combine([
          if (inline.style.underline) TextDecoration.underline,
          if (inline.style.strike) TextDecoration.lineThrough,
        ]),
        fontFamily: widget.useMonoFont
            ? 'Courier'
            : (inline.style.fontFamily?.isNotEmpty == true
                ? inline.style.fontFamily
                : 'Ubuntu'),
        fontSize: inline.style.fontSize ?? widget.fontSize,
        color: _parseColor(inline.style.colorHex) ??
            (inline.type == DocumentInlineType.hyperlink
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface),
        backgroundColor: _parseColor(inline.style.backgroundHex),
      );

      final segments = _highlightSegments(
        rawText,
        startOffset: offset,
        matchStart: matchStart,
        matchLength: matchLength,
      );
      for (final segment in segments) {
        spans.add(
          TextSpan(
            text: segment.text,
            style: baseStyle.copyWith(
              backgroundColor: segment.isHighlight
                  ? Theme.of(context)
                      .colorScheme
                      .tertiaryContainer
                      .withValues(alpha: 0.9)
                  : baseStyle.backgroundColor,
            ),
          ),
        );
      }
      offset += rawText.length;
    }

    if (spans.isEmpty && paragraphText.isNotEmpty) {
      spans.add(TextSpan(text: paragraphText));
    }

    return spans;
  }

  List<_HighlightedSegment> _highlightSegments(
    String text, {
    required int startOffset,
    required int? matchStart,
    required int? matchLength,
  }) {
    if (matchStart == null || matchLength == null) {
      return [_HighlightedSegment(text: text, isHighlight: false)];
    }

    final matchEnd = matchStart + matchLength;
    final localStart = startOffset;
    final localEnd = startOffset + text.length;
    if (matchEnd <= localStart || matchStart >= localEnd) {
      return [_HighlightedSegment(text: text, isHighlight: false)];
    }

    final highlightStart = (matchStart - localStart).clamp(0, text.length);
    final highlightEnd = (matchEnd - localStart).clamp(0, text.length);
    final segments = <_HighlightedSegment>[];
    if (highlightStart > 0) {
      segments.add(
        _HighlightedSegment(
          text: text.substring(0, highlightStart),
          isHighlight: false,
        ),
      );
    }
    if (highlightEnd > highlightStart) {
      segments.add(
        _HighlightedSegment(
          text: text.substring(highlightStart, highlightEnd),
          isHighlight: true,
        ),
      );
    }
    if (highlightEnd < text.length) {
      segments.add(
        _HighlightedSegment(
          text: text.substring(highlightEnd),
          isHighlight: false,
        ),
      );
    }
    return segments;
  }

  List<_SearchTarget> _collectTargets(List<DocumentBlock> blocks,
      [String prefix = 'b']) {
    final targets = <_SearchTarget>[];
    for (var i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      final id = '$prefix.$i';
      if (block is DocumentParagraphBlock) {
        final text = block.plainText.trim();
        if (text.isNotEmpty) {
          targets.add(
            _SearchTarget(
              id: id,
              text: text,
              label: 'Paragraph ${targets.length + 1}',
            ),
          );
        }
      } else if (block is DocumentTableBlock) {
        for (var rowIndex = 0; rowIndex < block.rows.length; rowIndex++) {
          for (var cellIndex = 0;
              cellIndex < block.rows[rowIndex].cells.length;
              cellIndex++) {
            final cell = block.rows[rowIndex].cells[cellIndex];
            final nestedTargets = _collectTargets(
              cell.blocks,
              '$id.$rowIndex.$cellIndex',
            );
            targets.addAll(
              nestedTargets.map(
                (target) => target.copyWith(
                  label: 'Table ${rowIndex + 1}:${cellIndex + 1}',
                  isNested: true,
                ),
              ),
            );
          }
        }
      }
    }
    return targets;
  }

  TextAlign _textAlignFor(String? alignment) {
    return switch (alignment?.toLowerCase()) {
      'center' => TextAlign.center,
      'right' => TextAlign.right,
      'both' || 'justify' => TextAlign.justify,
      _ => TextAlign.left,
    };
  }

  Color? _parseColor(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final normalized = raw.replaceAll('#', '').trim();
    if (normalized.length != 6) return null;
    final value = int.tryParse(normalized, radix: 16);
    if (value == null) return null;
    return Color(0xFF000000 | value);
  }

  String _snippet(String text, int start, int length) {
    final left = (start - 36).clamp(0, text.length);
    final right = (start + length + 36).clamp(0, text.length);
    return text.substring(left, right).replaceAll('\n', ' ').trim();
  }
}

class _SearchTarget {
  final String id;
  final String text;
  final String label;
  final bool isNested;

  const _SearchTarget({
    required this.id,
    required this.text,
    required this.label,
    this.isNested = false,
  });

  _SearchTarget copyWith({
    String? id,
    String? text,
    String? label,
    bool? isNested,
  }) {
    return _SearchTarget(
      id: id ?? this.id,
      text: text ?? this.text,
      label: label ?? this.label,
      isNested: isNested ?? this.isNested,
    );
  }
}

class _HighlightedSegment {
  final String text;
  final bool isHighlight;

  const _HighlightedSegment({
    required this.text,
    required this.isHighlight,
  });
}

class _RichSpotlightOverlay extends StatelessWidget {
  final List<Rect> rects;
  final double progress;
  final double dimOpacity;
  final Color strokeColor;
  final Color glowColor;

  const _RichSpotlightOverlay({
    required this.rects,
    required this.progress,
    required this.dimOpacity,
    required this.strokeColor,
    required this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RichSpotlightPainter(
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

class _RichSpotlightPainter extends CustomPainter {
  final List<Rect> rects;
  final double progress;
  final double dimOpacity;
  final Color strokeColor;
  final Color glowColor;

  const _RichSpotlightPainter({
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

    canvas.saveLayer(viewportRect, Paint());
    canvas.drawRect(
      viewportRect,
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
  bool shouldRepaint(_RichSpotlightPainter oldDelegate) {
    return rects != oldDelegate.rects ||
        progress != oldDelegate.progress ||
        dimOpacity != oldDelegate.dimOpacity ||
        strokeColor != oldDelegate.strokeColor ||
        glowColor != oldDelegate.glowColor;
  }
}
