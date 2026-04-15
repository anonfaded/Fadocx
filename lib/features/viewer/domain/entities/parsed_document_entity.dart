import 'sheet_entity.dart';

/// Represents a complete parsed document
class ParsedDocumentEntity {
  final String format; // 'XLSX', 'CSV', 'DOCX', 'PDF', etc.
  final List<SheetEntity> sheets;
  final String? textContent; // For text/doc formats
  final int sheetCount;
  final DateTime parsedAt;
  final String sourceFilePath;

  ParsedDocumentEntity({
    required this.format,
    required this.sheets,
    this.textContent,
    required this.sheetCount,
    required this.parsedAt,
    required this.sourceFilePath,
  });

  /// Check if this is a spreadsheet format
  bool get isSpreadsheet => ['XLSX', 'CSV', 'XLS'].contains(format);

  /// Check if this is a text format
  bool get isText => ['DOCX', 'DOC', 'TXT'].contains(format);

  /// Create a copy with optional changes
  ParsedDocumentEntity copyWith({
    String? format,
    List<SheetEntity>? sheets,
    String? textContent,
    int? sheetCount,
    DateTime? parsedAt,
    String? sourceFilePath,
  }) {
    return ParsedDocumentEntity(
      format: format ?? this.format,
      sheets: sheets ?? this.sheets,
      textContent: textContent ?? this.textContent,
      sheetCount: sheetCount ?? this.sheetCount,
      parsedAt: parsedAt ?? this.parsedAt,
      sourceFilePath: sourceFilePath ?? this.sourceFilePath,
    );
  }
}
