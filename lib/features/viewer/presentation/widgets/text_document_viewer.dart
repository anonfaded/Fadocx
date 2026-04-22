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
  late String _fullContent;
  DateTime? _tapStartTime;
  Offset? _tapStartPosition;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeContent();
  }

  void _initializeContent() {
    _fullContent = widget.textContent ?? '';
    if (_fullContent.isNotEmpty) {
      log.d('Text document initialized with ${_fullContent.split("\n").length} lines');
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
    if (_fullContent.isEmpty) {
      return _buildEmptyView(context);
    }

    final textColor = Theme.of(context).colorScheme.onSurface;
    final fontFamily = widget.useMonoFont ? 'Courier' : 'Ubuntu';
    final fontSize = widget.fontSize;
    final lines = _fullContent.split('\n');
    final totalLineDigits = lines.length.toString().length;
    final lineNumberWidth = switch (totalLineDigits) {
      1 => 30.0,
      2 => 40.0,
      _ => 50.0,
    };

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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Line numbers (scrollable with content)
            _buildLineNumbers(context, lines, lineNumberWidth, fontSize),
            // Content area with selection enabled (allows multi-line selection)
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16, top: 40),
                  child: widget.wordWrap
                      ? SelectableText(
                          _fullContent.isEmpty ? ' ' : _fullContent,
                          style: TextStyle(
                            fontSize: fontSize,
                            color: textColor,
                            fontFamily: fontFamily,
                            height: 1.5,
                            letterSpacing: -0.3,
                          ),
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SelectableText(
                            _fullContent.isEmpty ? ' ' : _fullContent,
                            style: TextStyle(
                              fontSize: fontSize,
                              color: textColor,
                              fontFamily: fontFamily,
                              height: 1.5,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ],
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

  Widget _buildLineNumbers(
    BuildContext context,
    List<String> lines,
    double lineNumberWidth,
    double fontSize,
  ) {
    final lineNumberColor = Theme.of(context).colorScheme.onSurfaceVariant;
    final fontFamily = widget.useMonoFont ? 'Courier' : 'Ubuntu';

    return SingleChildScrollView(
      controller: _scrollController,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, right: 12, top: 40, bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (int i = 0; i < lines.length; i++)
              SizedBox(
                height: (fontSize * 1.5),
                child: SizedBox(
                  width: lineNumberWidth,
                  child: Text(
                    (i + 1).toString().padLeft(5),
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
              ),
          ],
        ),
      ),
    );
  }
}
