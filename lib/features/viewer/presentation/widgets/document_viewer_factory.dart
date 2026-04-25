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
      'XLSX' || 'XLS' || 'CSV' || 'ODS' => _buildSpreadsheetViewer(document),
      'PDF' => _buildPdfViewer(filePath, fileName, invertColors, textMode,
          onInvertToggle, onTextModeToggle, onTap, onPageChanged),
      'TXT' => _buildTextViewer(document, onTap: onTap),
      _ => _buildUnsupportedViewer(document.format),
    };
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

