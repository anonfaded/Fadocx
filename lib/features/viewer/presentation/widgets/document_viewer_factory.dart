import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:fadocx/core/utils/logger.dart';
import 'package:fadocx/features/viewer/domain/entities/parsed_document_entity.dart';
import 'package:fadocx/features/viewer/domain/entities/sheet_entity.dart';
import 'professional_sheet_viewer.dart';

/// Returns embedded viewer content only.
/// The owning screen provides the outer Scaffold/AppBar.
class DocumentViewerFactory {
  static Widget createViewer({
    required ParsedDocumentEntity document,
    required String filePath,
  }) {
    return switch (document.format.toUpperCase()) {
      'JSON' || 'FADREC' => _buildJsonViewer(document),
      'XML' => _buildXmlViewer(document),
      'XLSX' || 'XLS' || 'CSV' || 'ODS' => _buildSpreadsheetViewer(document),
      'PDF' => _buildPdfViewer(filePath),
      'DOCX' || 'DOC' => _buildDocxViewer(document),
      _ => _buildUnsupportedViewer(document.format),
    };
  }

  static Widget _buildJsonViewer(ParsedDocumentEntity document) {
    return _JsonDocumentView(jsonString: document.textContent ?? '{}');
  }

  static Widget _buildXmlViewer(ParsedDocumentEntity document) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: SelectableText(
              document.textContent ?? 'No content',
              style: const TextStyle(
                fontFamily: 'Courier',
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        );
      },
    );
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
            tabs: document.sheets
                .map((sheet) => Tab(text: sheet.name))
                .toList(),
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

  static Widget _buildPdfViewer(String filePath) {
    return _PdfDocumentViewer(filePath: filePath);
  }

  static Widget _buildDocxViewer(ParsedDocumentEntity document) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SelectableText(
        document.textContent ?? 'No content',
        style: const TextStyle(fontSize: 14, height: 1.6),
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

class _PdfDocumentViewer extends StatefulWidget {
  final String filePath;

  const _PdfDocumentViewer({required this.filePath});

  @override
  State<_PdfDocumentViewer> createState() => _PdfDocumentViewerState();
}

class _PdfDocumentViewerState extends State<_PdfDocumentViewer> {
  late final PdfControllerPinch _controller;
  late final ValueNotifier<int> _currentPageNotifier;
  late final ValueNotifier<int> _totalPagesNotifier;

  @override
  void initState() {
    super.initState();
    _currentPageNotifier = ValueNotifier<int>(1);
    _totalPagesNotifier = ValueNotifier<int>(0);
    _controller = PdfControllerPinch(
      document: PdfDocument.openFile(widget.filePath),
    );
  }

  @override
  void dispose() {
    _currentPageNotifier.dispose();
    _totalPagesNotifier.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PdfViewPinch(
            controller: _controller,
            builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
              options: const DefaultBuilderOptions(),
              documentLoaderBuilder: (_) =>
                  const Center(child: CircularProgressIndicator()),
              pageLoaderBuilder: (_) => const Center(
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorBuilder: (_, error) {
                log.e('pdfx failed to load PDF: ${widget.filePath}', error);
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Failed to load PDF',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          error.toString(),
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            onDocumentLoaded: (doc) =>
                _totalPagesNotifier.value = doc.pagesCount,
            onPageChanged: (page) => _currentPageNotifier.value = page,
          ),
        ),
        _PdfControlBar(
          currentPageNotifier: _currentPageNotifier,
          totalPagesNotifier: _totalPagesNotifier,
          onPreviousPage: () => _controller.previousPage(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
          ),
          onNextPage: () => _controller.nextPage(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
          ),
        ),
      ],
    );
  }
}

class _PdfControlBar extends StatelessWidget {
  final ValueNotifier<int> currentPageNotifier;
  final ValueNotifier<int> totalPagesNotifier;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;

  const _PdfControlBar({
    required this.currentPageNotifier,
    required this.totalPagesNotifier,
    required this.onPreviousPage,
    required this.onNextPage,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: ValueListenableBuilder<int>(
          valueListenable: currentPageNotifier,
          builder: (context, currentPage, _) {
            return ValueListenableBuilder<int>(
              valueListenable: totalPagesNotifier,
              builder: (context, totalPages, _) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: currentPage > 1 ? onPreviousPage : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Page $currentPage / ${totalPages == 0 ? '-' : totalPages}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                    IconButton(
                      onPressed: totalPages > 0 && currentPage < totalPages
                          ? onNextPage
                          : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
