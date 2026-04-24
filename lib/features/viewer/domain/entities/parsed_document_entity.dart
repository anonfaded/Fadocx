import 'sheet_entity.dart';

enum DocumentFidelityLevel {
  plainText,
  partial,
  rich,
}

enum DocumentBlockType {
  paragraph,
  table,
  spacer,
}

enum DocumentInlineType {
  text,
  hyperlink,
  tab,
  lineBreak,
}

class DocumentTextStyleData {
  final bool bold;
  final bool italic;
  final bool underline;
  final bool strike;
  final String? fontFamily;
  final double? fontSize;
  final String? colorHex;
  final String? backgroundHex;

  const DocumentTextStyleData({
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strike = false,
    this.fontFamily,
    this.fontSize,
    this.colorHex,
    this.backgroundHex,
  });

  bool get hasFormatting =>
      bold ||
      italic ||
      underline ||
      strike ||
      fontFamily != null ||
      fontSize != null ||
      colorHex != null ||
      backgroundHex != null;

  Map<String, dynamic> toJson() => {
        'bold': bold,
        'italic': italic,
        'underline': underline,
        'strike': strike,
        'fontFamily': fontFamily,
        'fontSize': fontSize,
        'colorHex': colorHex,
        'backgroundHex': backgroundHex,
      };

  factory DocumentTextStyleData.fromJson(Map<String, dynamic> json) {
    return DocumentTextStyleData(
      bold: json['bold'] == true,
      italic: json['italic'] == true,
      underline: json['underline'] == true,
      strike: json['strike'] == true,
      fontFamily: json['fontFamily'] as String?,
      fontSize: (json['fontSize'] as num?)?.toDouble(),
      colorHex: json['colorHex'] as String?,
      backgroundHex: json['backgroundHex'] as String?,
    );
  }
}

class DocumentInline {
  final DocumentInlineType type;
  final String text;
  final String? href;
  final DocumentTextStyleData style;

  const DocumentInline({
    required this.type,
    this.text = '',
    this.href,
    this.style = const DocumentTextStyleData(),
  });

  String get plainText {
    return switch (type) {
      DocumentInlineType.tab => '\t',
      DocumentInlineType.lineBreak => '\n',
      _ => text,
    };
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'text': text,
        'href': href,
        'style': style.toJson(),
      };

  factory DocumentInline.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String? ?? DocumentInlineType.text.name;
    return DocumentInline(
      type: DocumentInlineType.values.firstWhere(
        (value) => value.name == typeName,
        orElse: () => DocumentInlineType.text,
      ),
      text: json['text'] as String? ?? '',
      href: json['href'] as String?,
      style: DocumentTextStyleData.fromJson(
        (json['style'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
    );
  }
}

abstract class DocumentBlock {
  final DocumentBlockType type;

  const DocumentBlock(this.type);

  String get plainText;

  Map<String, dynamic> toJson();

  factory DocumentBlock.fromJson(Map<String, dynamic> json) {
    final typeName =
        json['type'] as String? ?? DocumentBlockType.paragraph.name;
    final type = DocumentBlockType.values.firstWhere(
      (value) => value.name == typeName,
      orElse: () => DocumentBlockType.paragraph,
    );

    return switch (type) {
      DocumentBlockType.paragraph => DocumentParagraphBlock.fromJson(json),
      DocumentBlockType.table => DocumentTableBlock.fromJson(json),
      DocumentBlockType.spacer => DocumentSpacerBlock.fromJson(json),
    };
  }
}

class DocumentParagraphBlock extends DocumentBlock {
  final List<DocumentInline> inlines;
  final String? alignment;
  final double? spacingBefore;
  final double? spacingAfter;
  final double? firstLineIndent;
  final double? leftIndent;
  final double? rightIndent;
  final int? listLevel;
  final String? listKind;

  const DocumentParagraphBlock({
    this.inlines = const [],
    this.alignment,
    this.spacingBefore,
    this.spacingAfter,
    this.firstLineIndent,
    this.leftIndent,
    this.rightIndent,
    this.listLevel,
    this.listKind,
  }) : super(DocumentBlockType.paragraph);

  @override
  String get plainText => inlines.map((inline) => inline.plainText).join();

  @override
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'inlines': inlines.map((inline) => inline.toJson()).toList(),
        'alignment': alignment,
        'spacingBefore': spacingBefore,
        'spacingAfter': spacingAfter,
        'firstLineIndent': firstLineIndent,
        'leftIndent': leftIndent,
        'rightIndent': rightIndent,
        'listLevel': listLevel,
        'listKind': listKind,
      };

  factory DocumentParagraphBlock.fromJson(Map<String, dynamic> json) {
    return DocumentParagraphBlock(
      inlines: ((json['inlines'] as List?) ?? const [])
          .map((inline) =>
              DocumentInline.fromJson((inline as Map).cast<String, dynamic>()))
          .toList(),
      alignment: json['alignment'] as String?,
      spacingBefore: (json['spacingBefore'] as num?)?.toDouble(),
      spacingAfter: (json['spacingAfter'] as num?)?.toDouble(),
      firstLineIndent: (json['firstLineIndent'] as num?)?.toDouble(),
      leftIndent: (json['leftIndent'] as num?)?.toDouble(),
      rightIndent: (json['rightIndent'] as num?)?.toDouble(),
      listLevel: json['listLevel'] as int?,
      listKind: json['listKind'] as String?,
    );
  }
}

class DocumentTableCell {
  final List<DocumentBlock> blocks;

  const DocumentTableCell({
    this.blocks = const [],
  });

  String get plainText =>
      blocks.map((block) => block.plainText).join('\n').trim();

  Map<String, dynamic> toJson() => {
        'blocks': blocks.map((block) => block.toJson()).toList(),
      };

  factory DocumentTableCell.fromJson(Map<String, dynamic> json) {
    return DocumentTableCell(
      blocks: ((json['blocks'] as List?) ?? const [])
          .map((block) =>
              DocumentBlock.fromJson((block as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}

class DocumentTableRow {
  final List<DocumentTableCell> cells;

  const DocumentTableRow({
    this.cells = const [],
  });

  String get plainText => cells.map((cell) => cell.plainText).join('\t');

  Map<String, dynamic> toJson() => {
        'cells': cells.map((cell) => cell.toJson()).toList(),
      };

  factory DocumentTableRow.fromJson(Map<String, dynamic> json) {
    return DocumentTableRow(
      cells: ((json['cells'] as List?) ?? const [])
          .map((cell) =>
              DocumentTableCell.fromJson((cell as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}

class DocumentTableBlock extends DocumentBlock {
  final List<DocumentTableRow> rows;

  const DocumentTableBlock({
    this.rows = const [],
  }) : super(DocumentBlockType.table);

  @override
  String get plainText => rows.map((row) => row.plainText).join('\n');

  @override
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'rows': rows.map((row) => row.toJson()).toList(),
      };

  factory DocumentTableBlock.fromJson(Map<String, dynamic> json) {
    return DocumentTableBlock(
      rows: ((json['rows'] as List?) ?? const [])
          .map((row) =>
              DocumentTableRow.fromJson((row as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}

class DocumentSpacerBlock extends DocumentBlock {
  final double height;
  final bool isPageBreak;

  const DocumentSpacerBlock({
    this.height = 16,
    this.isPageBreak = false,
  }) : super(DocumentBlockType.spacer);

  @override
  String get plainText => isPageBreak ? '\n\n' : '\n';

  @override
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'height': height,
        'isPageBreak': isPageBreak,
      };

  factory DocumentSpacerBlock.fromJson(Map<String, dynamic> json) {
    return DocumentSpacerBlock(
      height: (json['height'] as num?)?.toDouble() ?? 16,
      isPageBreak: json['isPageBreak'] == true,
    );
  }
}

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
  final String? plainTextContent;
  final List<DocumentBlock> documentBlocks;
  final List<String> parseWarnings;
  final DocumentFidelityLevel fidelityLevel;
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
    this.plainTextContent,
    this.documentBlocks = const [],
    this.parseWarnings = const [],
    this.fidelityLevel = DocumentFidelityLevel.plainText,
    this.slides = const [],
    this.sheetCount = 0,
    this.slideCount = 0,
    this.wordCount,
    this.lineCount,
    required this.parsedAt,
    required this.sourceFilePath,
  });

  /// Compatibility alias for existing callers while the app migrates to `plainTextContent`.
  String? get textContent => plainTextContent;

  String get searchableText {
    if ((plainTextContent ?? '').isNotEmpty) {
      return plainTextContent!;
    }
    if (documentBlocks.isEmpty) return '';
    return _flattenBlocks(documentBlocks);
  }

  bool get hasRichDocument => documentBlocks.isNotEmpty;

  /// Check if this is a spreadsheet format
  bool get isSpreadsheet => ['XLSX', 'XLS', 'CSV', 'ODS'].contains(format);

  /// Check if this is a text/doc format
  bool get isText => ['DOCX', 'DOC', 'TXT', 'RTF', 'ODT'].contains(format);

  /// Check if this is a data format (JSON, XML, FADREC)
  bool get isData => ['JSON', 'XML', 'FADREC'].contains(format);

  /// Check if this is a presentation format
  bool get isPresentation => ['PPT', 'PPTX', 'ODP'].contains(format);

  /// Create a copy with optional changes
  ParsedDocumentEntity copyWith({
    String? format,
    List<SheetEntity>? sheets,
    String? plainTextContent,
    String? textContent,
    List<DocumentBlock>? documentBlocks,
    List<String>? parseWarnings,
    DocumentFidelityLevel? fidelityLevel,
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
      plainTextContent:
          plainTextContent ?? textContent ?? this.plainTextContent,
      documentBlocks: documentBlocks ?? this.documentBlocks,
      parseWarnings: parseWarnings ?? this.parseWarnings,
      fidelityLevel: fidelityLevel ?? this.fidelityLevel,
      slides: slides ?? this.slides,
      sheetCount: sheetCount ?? this.sheetCount,
      slideCount: slideCount ?? this.slideCount,
      wordCount: wordCount ?? this.wordCount,
      lineCount: lineCount ?? this.lineCount,
      parsedAt: parsedAt ?? this.parsedAt,
      sourceFilePath: sourceFilePath ?? this.sourceFilePath,
    );
  }

  static String _flattenBlocks(List<DocumentBlock> blocks) {
    return blocks
        .map((block) => block.plainText)
        .where((text) => text.isNotEmpty)
        .join('\n')
        .trim();
  }
}
