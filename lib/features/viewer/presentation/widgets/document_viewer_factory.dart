import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fadocx/features/viewer/domain/entities/parsed_document_entity.dart';
import 'package:fadocx/features/viewer/domain/entities/sheet_entity.dart';
import 'professional_sheet_viewer.dart';
import 'modern_pdf_viewer.dart';
import 'text_document_viewer.dart';

/// Returns embedded viewer content only.
/// The owning screen provides the outer Scaffold/AppBar.
class DocumentViewerFactory {
  static Widget createViewer({
    required ParsedDocumentEntity document,
    required String filePath,
    String? fileName,
    bool invertColors = false,
    bool textMode = false,
    VoidCallback? onInvertToggle,
    VoidCallback? onTextModeToggle,
    VoidCallback? onTap,
    Function(int currentPage, int totalPages)? onPageChanged,
  }) {
    return switch (document.format.toUpperCase()) {
      'FADREC' => _buildJsonViewer(document),
      'XLSX' || 'XLS' || 'CSV' || 'ODS' => _buildSpreadsheetViewer(document),
      'PDF' => _buildPdfViewer(filePath, fileName, invertColors, textMode,
          onInvertToggle, onTextModeToggle, onTap, onPageChanged),
      'TXT' => _buildTextViewer(document, onTap: onTap),
      _ => _buildUnsupportedViewer(document.format),
    };
  }

  static Widget _buildJsonViewer(ParsedDocumentEntity document) {
    return _JsonDocumentView(jsonString: document.textContent ?? '{}');
  }

  static Widget _buildSpreadsheetViewer(ParsedDocumentEntity document) {
    if (document.sheets.isEmpty) {
      return Center(
        child: Text('No sheets found in ${document.format}'),
      );
    }

    if (document.sheetCount == 1) {
      return _buildSheetTable(document.sheets.first);
    }

    return DefaultTabController(
      length: document.sheetCount,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabs:
                document.sheets.map((sheet) => Tab(text: sheet.name)).toList(),
          ),
          Expanded(
            child: TabBarView(
              children: document.sheets.map(_buildSheetTable).toList(),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildSheetTable(SheetEntity sheet) {
    if (sheet.rows.isEmpty) {
      return Center(
        child: Text('No data in ${sheet.name}'),
      );
    }

    return ProfessionalSheetViewer(sheet: sheet);
  }

  static Widget _buildPdfViewer(
    String filePath,
    String? fileName,
    bool invertColors,
    bool textMode,
    VoidCallback? onInvertToggle,
    VoidCallback? onTextModeToggle,
    VoidCallback? onTap,
    Function(int currentPage, int totalPages)? onPageChanged,
  ) {
    return ModernPdfViewer(
      filePath: filePath,
      fileName: fileName,
      invertColors: invertColors,
      textMode: textMode,
      onInvertToggle: onInvertToggle,
      onTextModeToggle: onTextModeToggle,
      onTap: onTap,
      onPageChanged: onPageChanged,
    );
  }

  static Widget _buildTextViewer(
    ParsedDocumentEntity document, {
    VoidCallback? onTap,
  }) {
    final textContent = document.searchableText;

    return GestureDetector(
      onTap: onTap,
      child: TextDocumentViewer(
        textContent: textContent,
        onTap: onTap,
      ),
    );
  }

  static Widget _buildUnsupportedViewer(String format) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Format not supported: $format',
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _JsonDocumentView extends StatelessWidget {
  final String jsonString;

  const _JsonDocumentView({required this.jsonString});

  @override
  Widget build(BuildContext context) {
    String prettyJson;

    try {
      final decoded = jsonDecode(jsonString);
      prettyJson = const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (_) {
      prettyJson = jsonString;
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Pretty'),
              Tab(text: 'Raw'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(
                    prettyJson,
                    style: const TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(
                    jsonString,
                    style: const TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Professional presentation slide viewer with PageView carousel
class _PresentationViewer extends StatefulWidget {
  final List<SlideEntity> slides;

  const _PresentationViewer({required this.slides});

  @override
  State<_PresentationViewer> createState() => _PresentationViewerState();
}

class _PresentationViewerState extends State<_PresentationViewer> {
  late final PageController _pageController;
  late final ValueNotifier<int> _currentSlideNotifier;

  @override
  void initState() {
    super.initState();
    _currentSlideNotifier = ValueNotifier<int>(1);
    _pageController = PageController();
  }

  @override
  void dispose() {
    _currentSlideNotifier.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _goToPreviousSlide() {
    if (_currentSlideNotifier.value > 1) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToNextSlide() {
    if (_currentSlideNotifier.value < widget.slides.length) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.slides.isEmpty) {
      return const Center(
        child: Text('No slides in presentation'),
      );
    }

    return Column(
      children: [
        // Slide counter and navigation header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outlineVariant,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.slideshow,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Presentation',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              ValueListenableBuilder<int>(
                valueListenable: _currentSlideNotifier,
                builder: (context, currentSlide, _) {
                  return Text(
                    '$currentSlide / ${widget.slides.length}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        // Main slide carousel
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              _currentSlideNotifier.value = index + 1;
            },
            itemCount: widget.slides.length,
            itemBuilder: (context, index) {
              final slide = widget.slides[index];
              return _SlideView(
                slide: slide,
                totalSlides: widget.slides.length,
              );
            },
          ),
        ),
        // Bottom control bar
        _PresentationControlBar(
          currentSlideNotifier: _currentSlideNotifier,
          totalSlides: widget.slides.length,
          onPreviousSlide: _goToPreviousSlide,
          onNextSlide: _goToNextSlide,
        ),
      ],
    );
  }
}

/// Individual slide view with professional styling
class _SlideView extends StatelessWidget {
  final SlideEntity slide;
  final int totalSlides;

  const _SlideView({
    required this.slide,
    required this.totalSlides,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          children: [
            // Slide header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Slide ${slide.slideNumber}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.present_to_all,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
            // Slide content
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                child: slide.text.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.hide_image,
                              size: 64,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Slide ${slide.slideNumber}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No text content',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        child: SelectableText(
                          slide.text,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            height: 1.6,
                            fontSize: 16,
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
}

/// Bottom control bar for presentation navigation
class _PresentationControlBar extends StatelessWidget {
  final ValueNotifier<int> currentSlideNotifier;
  final int totalSlides;
  final VoidCallback onPreviousSlide;
  final VoidCallback onNextSlide;

  const _PresentationControlBar({
    required this.currentSlideNotifier,
    required this.totalSlides,
    required this.onPreviousSlide,
    required this.onNextSlide,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outlineVariant,
            ),
          ),
        ),
        child: SafeArea(
          child: ValueListenableBuilder<int>(
            valueListenable: currentSlideNotifier,
            builder: (context, currentSlide, _) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Previous button
                  Material(
                    color: currentSlide > 1
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: currentSlide > 1 ? onPreviousSlide : null,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          Icons.chevron_left,
                          color: currentSlide > 1
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Slide indicator with dot
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.circle,
                          size: 8,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$currentSlide / $totalSlides',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Next button
                  Material(
                    color: currentSlide < totalSlides
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: currentSlide < totalSlides ? onNextSlide : null,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          Icons.chevron_right,
                          color: currentSlide < totalSlides
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
