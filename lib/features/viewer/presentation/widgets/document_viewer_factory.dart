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
    void Function(String? cellRef, String value)? onSheetSelectionChanged,
    Key? sheetViewerKey,
    double sheetZoom = 1.0,
  }) {
    return switch (document.format.toUpperCase()) {
      'XLSX' || 'XLS' || 'CSV' || 'ODS' => _buildSpreadsheetViewer(document, onSheetSelectionChanged, sheetViewerKey, zoom: sheetZoom),
      'PDF' => _buildPdfViewer(filePath, fileName, invertColors, textMode,
          onInvertToggle, onTextModeToggle, onTap, onPageChanged),
      'TXT' => _buildTextViewer(document, onTap: onTap),
      _ => _buildUnsupportedViewer(document.format),
    };
  }

  static Widget _buildSpreadsheetViewer(ParsedDocumentEntity document, void Function(String?, String)? onSelectionChanged, Key? sheetViewerKey, {double zoom = 1.0}) {
    if (document.sheets.isEmpty) {
      return Center(
        child: Text('No sheets found in ${document.format}'),
      );
    }

    if (document.sheetCount == 1) {
      return _buildSheetTable(document.sheets.first, onSelectionChanged, sheetViewerKey, zoom: zoom);
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
              children: document.sheets.map((s) => _buildSheetTable(s, onSelectionChanged, sheetViewerKey, zoom: zoom)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildSheetTable(SheetEntity sheet, void Function(String?, String)? onSelectionChanged, Key? sheetViewerKey, {double zoom = 1.0}) {
    if (sheet.rows.isEmpty) {
      return Center(
        child: Text('No data in ${sheet.name}'),
      );
    }

    return ProfessionalSheetViewer(
      key: sheetViewerKey,
      sheet: sheet,
      onSelectionChanged: onSelectionChanged,
      initialZoom: zoom,
    );
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

