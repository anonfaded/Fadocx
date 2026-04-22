import 'sheet_entity.dart';

/// Represents a single slide in a presentation (PPT/PPTX)
class SlideEntity {
  final int slideNumber;
  final String text;

  const SlideEntity({
    required this.slideNumber,
    required this.text,
  });
}

/// Represents a complete parsed document
class ParsedDocumentEntity {
  final String format; // 'XLSX', 'CSV', 'DOCX', 'PDF', 'PPT', 'PPTX', etc.
  final List<SheetEntity> sheets;
  final String? textContent; // For text/doc formats
  final List<SlideEntity> slides; // For PPT/PPTX presentations
  final int sheetCount; // For spreadsheets
  final int slideCount; // For presentations
  final int? wordCount; // Exact extracted word count when available
  final int? lineCount; // Exact extracted line count when available
  final DateTime parsedAt;
  final String sourceFilePath;

  ParsedDocumentEntity({
    required this.format,
    required this.sheets,
    this.textContent,
    this.slides = const [],
    this.sheetCount = 0,
    this.slideCount = 0,
    this.wordCount,
    this.lineCount,
    required this.parsedAt,
    required this.sourceFilePath,
  });

  /// Check if this is a spreadsheet format
  bool get isSpreadsheet => ['XLSX', 'XLS', 'CSV', 'ODS'].contains(format);

  /// Check if this is a text/doc format
  bool get isText => ['DOCX', 'DOC', 'TXT', 'RTF'].contains(format);

  /// Check if this is a data format (JSON, XML, FADREC)
  bool get isData => ['JSON', 'XML', 'FADREC'].contains(format);

  /// Check if this is a presentation format
  bool get isPresentation => ['PPT', 'PPTX', 'ODP'].contains(format);

  /// Create a copy with optional changes
  ParsedDocumentEntity copyWith({
    String? format,
    List<SheetEntity>? sheets,
    String? textContent,
    List<SlideEntity>? slides,
    int? sheetCount,
    int? slideCount,
    int? wordCount,
    int? lineCount,
    DateTime? parsedAt,
    String? sourceFilePath,
  }) {
    return ParsedDocumentEntity(
      format: format ?? this.format,
      sheets: sheets ?? this.sheets,
      textContent: textContent ?? this.textContent,
      slides: slides ?? this.slides,
      sheetCount: sheetCount ?? this.sheetCount,
      slideCount: slideCount ?? this.slideCount,
      wordCount: wordCount ?? this.wordCount,
      lineCount: lineCount ?? this.lineCount,
      parsedAt: parsedAt ?? this.parsedAt,
      sourceFilePath: sourceFilePath ?? this.sourceFilePath,
    );
  }
}
