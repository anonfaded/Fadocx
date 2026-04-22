import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

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
    this.useMonoFont = true,
    super.key,
  });

  @override
  State<TextDocumentViewer> createState() => _TextDocumentViewerState();
}

class _TextDocumentViewerState extends State<TextDocumentViewer> {
  late List<String> _lines;
  DateTime? _tapStartTime;
  Offset? _tapStartPosition;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeContent();
  }

  void _initializeContent() {
    final content = widget.textContent ?? '';
    if (content.isEmpty) {
      _lines = [];
    } else {
      // Split into lines for virtualization - more efficient than loading entire text
      _lines = content.split('\n');
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_lines.isEmpty) {
      return _buildEmptyView(context);
    }

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
        child: ListView.builder(
          controller: _scrollController,
          // Padding at top allows content to scroll past but shows space initially
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: _lines.length + 1, // +1 for top spacer
          itemBuilder: (context, index) {
            // First item is padding spacer that can scroll up
            if (index == 0) {
              return SizedBox(height: 64); // Match appbar height + buffer
            }
            final line = _lines[index - 1];
            return _buildTextLine(context, line, index - 1);
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

  Widget _buildTextLine(BuildContext context, String line, int index) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final lineNumberColor = Theme.of(context).colorScheme.onSurfaceVariant;
    final fontFamily = widget.useMonoFont ? 'Courier' : 'Ubuntu'; // Mono or Ubuntu font
    final fontSize = widget.fontSize;

    // Calculate line number width dynamically (max line number width)
    final lineNumberWidth = (_lines.length.toString().length * 8 + 12).clamp(40, 60).toDouble();

    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 12, top: 1, bottom: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Line number (compact, right-aligned)
          SizedBox(
            width: lineNumberWidth,
            child: Text(
              (index + 1).toString().padLeft(5),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: fontSize * 0.9,
                color: lineNumberColor.withValues(alpha: 0.4),
                fontFamily: fontFamily,
                height: 1.5,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(width: 12), // Small gap between line number and content
          // Line content - non-selectable when wrap is off to prevent individual scrolling
          Expanded(
            child: widget.wordWrap
                ? SelectableText(
                    line.isEmpty ? ' ' : line,
                    style: TextStyle(
                      fontSize: fontSize,
                      color: textColor,
                      fontFamily: fontFamily,
                      height: 1.5,
                      letterSpacing: -0.3,
                    ),
                  )
                : Text(
                    line.isEmpty ? ' ' : line,
                    style: TextStyle(
                      fontSize: fontSize,
                      color: textColor,
                      fontFamily: fontFamily,
                      height: 1.5,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
        ],
      ),
    );
  }
}
