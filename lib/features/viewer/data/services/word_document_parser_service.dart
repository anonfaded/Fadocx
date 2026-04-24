import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

import 'package:fadocx/features/viewer/domain/entities/parsed_document_entity.dart';

class StructuredDocumentParseResult {
  final String plainTextContent;
  final List<DocumentBlock> documentBlocks;
  final List<String> parseWarnings;
  final DocumentFidelityLevel fidelityLevel;

  const StructuredDocumentParseResult({
    required this.plainTextContent,
    required this.documentBlocks,
    this.parseWarnings = const [],
    this.fidelityLevel = DocumentFidelityLevel.partial,
  });
}

class WordDocumentParserService {
  static Future<StructuredDocumentParseResult> parseOdt(
    String filePath,
  ) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    final contentFile = archive.findFile('content.xml');
    if (contentFile == null) {
      throw Exception('content.xml not found in ODT file');
    }

    final content = utf8.decode(contentFile.content as List<int>);
    final document = XmlDocument.parse(content);
    final blocks = <DocumentBlock>[];

    for (final paragraph in document.descendants.whereType<XmlElement>()) {
      if (paragraph.name.local != 'p') continue;
      final text = paragraph.innerText.replaceAll('\r', '').trimRight();
      if (text.isEmpty) continue;
      blocks.add(
        DocumentParagraphBlock(
          inlines: [DocumentInline(type: DocumentInlineType.text, text: text)],
        ),
      );
    }

    final plainText = _flattenBlocks(blocks);
    return StructuredDocumentParseResult(
      plainTextContent: plainText,
      documentBlocks: blocks,
      parseWarnings: const [
        'ODT currently renders paragraph text without full style/layout fidelity.'
      ],
      fidelityLevel: blocks.isEmpty
          ? DocumentFidelityLevel.plainText
          : DocumentFidelityLevel.partial,
    );
  }

  static Future<StructuredDocumentParseResult> parseDocx(
    String filePath,
  ) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    final documentFile = archive.findFile('word/document.xml');
    if (documentFile == null) {
      throw Exception('word/document.xml not found in DOCX file');
    }

    final rels = _parseDocxRelationships(archive);
    final numbering = _parseDocxNumbering(archive);
    final xmlContent = utf8.decode(documentFile.content as List<int>);
    final document = XmlDocument.parse(xmlContent);
    final body = document.rootElement.descendants
        .whereType<XmlElement>()
        .firstWhere((element) => element.name.local == 'body');

    final blocks = <DocumentBlock>[];
    final warnings = <String>[];

    for (final child in body.children.whereType<XmlElement>()) {
      switch (child.name.local) {
        case 'p':
          final paragraph = _parseDocxParagraph(
            child,
            relationships: rels,
            numberingFormats: numbering,
          );
          if (paragraph != null) {
            blocks.add(paragraph);
          }
          break;
        case 'tbl':
          blocks.add(_parseDocxTable(
            child,
            relationships: rels,
            numberingFormats: numbering,
          ));
          break;
        default:
          break;
      }
    }

    final plainText = _flattenBlocks(blocks);
    if (blocks.isEmpty && plainText.isEmpty) {
      warnings.add('No readable DOCX body content was extracted.');
    }

    return StructuredDocumentParseResult(
      plainTextContent: plainText,
      documentBlocks: blocks,
      parseWarnings: warnings,
      fidelityLevel: warnings.isEmpty
          ? DocumentFidelityLevel.rich
          : DocumentFidelityLevel.partial,
    );
  }

  static Future<StructuredDocumentParseResult> parseRtf(
    String filePath,
  ) async {
    final content = await File(filePath).readAsString();
    final parser = _RtfParser(content);
    return parser.parse();
  }

  static String flattenBlocks(List<DocumentBlock> blocks) =>
      _flattenBlocks(blocks);

  static Map<String, String> _parseDocxRelationships(Archive archive) {
    final relsFile = archive.findFile('word/_rels/document.xml.rels');
    if (relsFile == null) return const {};

    final relsDoc = XmlDocument.parse(
      utf8.decode(relsFile.content as List<int>),
    );
    final result = <String, String>{};
    for (final rel in relsDoc.findAllElements('Relationship')) {
      final id = rel.getAttribute('Id');
      final target = rel.getAttribute('Target');
      final type = rel.getAttribute('Type') ?? '';
      if (id != null && target != null && type.contains('hyperlink')) {
        result[id] = target;
      }
    }
    return result;
  }

  static Map<String, String> _parseDocxNumbering(Archive archive) {
    final numberingFile = archive.findFile('word/numbering.xml');
    if (numberingFile == null) return const {};

    final numberingDoc = XmlDocument.parse(
      utf8.decode(numberingFile.content as List<int>),
    );
    final abstractFormats = <String, String>{};
    for (final abstractNum in numberingDoc.findAllElements('abstractNum')) {
      final abstractId = abstractNum.getAttribute('abstractNumId');
      if (abstractId == null) continue;
      final numFmt = abstractNum
          .findAllElements('numFmt')
          .map((element) => element.getAttribute('val') ?? '')
          .firstWhere((value) => value.isNotEmpty, orElse: () => '');
      if (numFmt.isNotEmpty) {
        abstractFormats[abstractId] = numFmt;
      }
    }

    final numberingFormats = <String, String>{};
    for (final num in numberingDoc.findAllElements('num')) {
      final numId = num.getAttribute('numId');
      final abstractNumId = num.findAllElements('abstractNumId')
          .map((element) => element.getAttribute('val') ?? '')
          .firstWhere((value) => value.isNotEmpty, orElse: () => '');
      if (numId != null && abstractNumId.isNotEmpty) {
        numberingFormats[numId] = abstractFormats[abstractNumId] ?? 'bullet';
      }
    }
    return numberingFormats;
  }

  static DocumentParagraphBlock? _parseDocxParagraph(
    XmlElement paragraph, {
    required Map<String, String> relationships,
    required Map<String, String> numberingFormats,
  }) {
    final pPr = _firstChild(paragraph, 'pPr');
    final inlines = <DocumentInline>[];

    for (final child in paragraph.children.whereType<XmlElement>()) {
      if (child.name.local == 'r') {
        inlines.addAll(_parseDocxRun(child));
      } else if (child.name.local == 'hyperlink') {
        final relId = _getAttributeAny(child, const ['id', 'r:id']);
        final anchor = _getAttributeAny(child, const ['anchor', 'w:anchor']);
        final href = relId == null ? anchor : relationships[relId] ?? anchor;
        for (final run in child.children.whereType<XmlElement>()) {
          if (run.name.local != 'r') continue;
          final runInlines = _parseDocxRun(run, hyperlink: href);
          inlines.addAll(runInlines);
        }
      }
    }

    if (inlines.isEmpty) {
      final rawText = paragraph.innerText;
      if (rawText.trim().isEmpty) {
        return null;
      }
      inlines.add(DocumentInline(text: rawText, type: DocumentInlineType.text));
    }

    final alignment =
        _getAttributeAny(_firstDescendant(pPr, 'jc'), const ['val', 'w:val']);
    final spacing = _firstDescendant(pPr, 'spacing');
    final indentation = _firstDescendant(pPr, 'ind');
    final numPr = _firstDescendant(pPr, 'numPr');
    final numId = _getAttributeAny(
        _firstDescendant(numPr, 'numId'), const ['val', 'w:val']);
    final ilvl = _getAttributeAny(
        _firstDescendant(numPr, 'ilvl'), const ['val', 'w:val']);

    return DocumentParagraphBlock(
      inlines: inlines,
      alignment: alignment,
      spacingBefore: _twipsToLogical(
          _getAttributeAny(spacing, const ['before', 'w:before'])),
      spacingAfter: _twipsToLogical(
          _getAttributeAny(spacing, const ['after', 'w:after'])),
      firstLineIndent: _twipsToLogical(
          _getAttributeAny(indentation, const ['firstLine', 'w:firstLine'])),
      leftIndent: _twipsToLogical(
          _getAttributeAny(indentation, const ['left', 'w:left'])),
      rightIndent: _twipsToLogical(
          _getAttributeAny(indentation, const ['right', 'w:right'])),
      listLevel: int.tryParse(ilvl ?? ''),
      listKind: numId == null ? null : numberingFormats[numId],
    );
  }

  static List<DocumentInline> _parseDocxRun(
    XmlElement run, {
    String? hyperlink,
  }) {
    final runProperties = _firstChild(run, 'rPr');
    final underline = _firstDescendant(runProperties, 'u');
    final fonts = _firstDescendant(runProperties, 'rFonts');
    final size = _firstDescendant(runProperties, 'sz');
    final color = _firstDescendant(runProperties, 'color');
    final highlight = _firstDescendant(runProperties, 'highlight');
    final style = DocumentTextStyleData(
      bold: _hasDescendant(runProperties, 'b'),
      italic: _hasDescendant(runProperties, 'i'),
      underline: underline != null &&
          _getAttributeAny(underline, const ['val', 'w:val']) != 'none',
      strike: _hasDescendant(runProperties, 'strike'),
      fontFamily: _getAttributeAny(
          fonts, const ['ascii', 'w:ascii', 'hAnsi', 'w:hAnsi']),
      fontSize: ((num.tryParse(
                      _getAttributeAny(size, const ['val', 'w:val']) ?? '') ??
                  0) /
              2)
          .clamp(0, 200)
          .toDouble(),
      colorHex: _getAttributeAny(color, const ['val', 'w:val']),
      backgroundHex: _getAttributeAny(highlight, const ['val', 'w:val']),
    );

    final inlines = <DocumentInline>[];
    for (final child in run.children.whereType<XmlElement>()) {
      switch (child.name.local) {
        case 't':
          final text = child.innerText;
          if (text.isNotEmpty) {
            inlines.add(DocumentInline(
              type: hyperlink == null
                  ? DocumentInlineType.text
                  : DocumentInlineType.hyperlink,
              text: text,
              href: hyperlink,
              style: style,
            ));
          }
          break;
        case 'tab':
          inlines
              .add(DocumentInline(type: DocumentInlineType.tab, style: style));
          break;
        case 'br':
        case 'cr':
          inlines.add(
            DocumentInline(type: DocumentInlineType.lineBreak, style: style),
          );
          break;
        default:
          break;
      }
    }

    if (inlines.isEmpty) {
      final text = run.innerText;
      if (text.isNotEmpty) {
        inlines.add(DocumentInline(
          type: hyperlink == null
              ? DocumentInlineType.text
              : DocumentInlineType.hyperlink,
          text: text,
          href: hyperlink,
          style: style,
        ));
      }
    }

    return inlines;
  }

  static DocumentTableBlock _parseDocxTable(
    XmlElement table, {
    required Map<String, String> relationships,
    required Map<String, String> numberingFormats,
  }) {
    final rows = <DocumentTableRow>[];
    for (final row in table.children.whereType<XmlElement>()) {
      if (row.name.local != 'tr') continue;
      final cells = <DocumentTableCell>[];
      for (final cell in row.children.whereType<XmlElement>()) {
        if (cell.name.local != 'tc') continue;
        final blocks = <DocumentBlock>[];
        for (final cellChild in cell.children.whereType<XmlElement>()) {
          if (cellChild.name.local == 'p') {
            final paragraph = _parseDocxParagraph(
              cellChild,
              relationships: relationships,
              numberingFormats: numberingFormats,
            );
            if (paragraph != null) {
              blocks.add(paragraph);
            }
          } else if (cellChild.name.local == 'tbl') {
            blocks.add(_parseDocxTable(
              cellChild,
              relationships: relationships,
              numberingFormats: numberingFormats,
            ));
          }
        }
        cells.add(DocumentTableCell(blocks: blocks));
      }
      rows.add(DocumentTableRow(cells: cells));
    }
    return DocumentTableBlock(rows: rows);
  }

  static double? _twipsToLogical(String? raw) {
    final value = num.tryParse(raw ?? '');
    if (value == null) return null;
    return value / 20;
  }

  static String _flattenBlocks(List<DocumentBlock> blocks) {
    return blocks
        .map((block) => block.plainText)
        .where((text) => text.trim().isNotEmpty)
        .join('\n')
        .trim();
  }

  static XmlElement? _firstChild(XmlElement? parent, String localName) {
    if (parent == null) return null;
    for (final child in parent.children.whereType<XmlElement>()) {
      if (child.name.local == localName) {
        return child;
      }
    }
    return null;
  }

  static XmlElement? _firstDescendant(XmlElement? parent, String localName) {
    if (parent == null) return null;
    for (final child in parent.descendants.whereType<XmlElement>()) {
      if (child.name.local == localName) {
        return child;
      }
    }
    return null;
  }

  static bool _hasDescendant(XmlElement? parent, String localName) {
    return _firstDescendant(parent, localName) != null;
  }

  static String? _getAttributeAny(XmlElement? element, List<String> names) {
    if (element == null) return null;
    for (final name in names) {
      final exact = element.getAttribute(name);
      if (exact != null) return exact;
      final local = name.contains(':') ? name.split(':').last : name;
      for (final attribute in element.attributes) {
        if (attribute.name.local == local && attribute.value.isNotEmpty) {
          return attribute.value;
        }
      }
    }
    return null;
  }
}

class _RtfState {
  final bool bold;
  final bool italic;
  final bool underline;
  final bool strike;
  final double? fontSize;
  final String? hyperlink;
  final bool skipText;

  const _RtfState({
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strike = false,
    this.fontSize,
    this.hyperlink,
    this.skipText = false,
  });

  _RtfState copyWith({
    bool? bold,
    bool? italic,
    bool? underline,
    bool? strike,
    double? fontSize,
    String? hyperlink,
    bool clearHyperlink = false,
    bool? skipText,
  }) {
    return _RtfState(
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      underline: underline ?? this.underline,
      strike: strike ?? this.strike,
      fontSize: fontSize ?? this.fontSize,
      hyperlink: clearHyperlink ? null : (hyperlink ?? this.hyperlink),
      skipText: skipText ?? this.skipText,
    );
  }
}

class _RtfParser {
  final String source;
  final List<DocumentBlock> _blocks = [];
  final List<String> _warnings = [];
  final List<_RtfState> _stack = [const _RtfState()];
  final StringBuffer _text = StringBuffer();
  final List<DocumentInline> _currentInlines = [];
  final List<DocumentTableRow> _currentTableRows = [];
  final List<DocumentTableCell> _currentRowCells = [];
  final List<DocumentBlock> _currentCellBlocks = [];
  final StringBuffer _fldInstBuffer = StringBuffer();
  final StringBuffer _fldRsltBuffer = StringBuffer();
  int _index = 0;
  int _unicodeSkipCount = 1;
  int _pendingUnicodeFallbackSkips = 0;
  bool _expectIgnorableDestination = false;
  bool _inFontTable = false;
  bool _inColorTable = false;
  bool _inField = false;
  bool _inFieldInstruction = false;
  bool _inFieldResult = false;
  bool _inTableRow = false;

  _RtfParser(this.source);

  StructuredDocumentParseResult parse() {
    while (_index < source.length) {
      final char = source[_index];
      if (_pendingUnicodeFallbackSkips > 0) {
        _pendingUnicodeFallbackSkips--;
        _index++;
        continue;
      }

      switch (char) {
        case '{':
          _pushState();
          _index++;
          break;
        case '}':
          _popState();
          _index++;
          break;
        case '\\':
          _handleControl();
          break;
        default:
          _appendText(char);
          _index++;
          break;
      }
    }

    _flushCurrentParagraph();
    _flushTableRowIfNeeded();

    final plainText = WordDocumentParserService.flattenBlocks(_blocks);
    return StructuredDocumentParseResult(
      plainTextContent: plainText,
      documentBlocks: List.unmodifiable(_blocks),
      parseWarnings: List.unmodifiable(_warnings),
      fidelityLevel: _warnings.isEmpty
          ? DocumentFidelityLevel.rich
          : DocumentFidelityLevel.partial,
    );
  }

  _RtfState get _state => _stack.last;

  void _pushState() {
    _stack.add(_state);
  }

  void _popState() {
    if (_stack.length > 1) {
      final popped = _stack.removeLast();
      if (popped.skipText && !_state.skipText) {
        _inFontTable = false;
        _inColorTable = false;
      }
    }

    if (_inFieldResult && _stack.length == 1) {
      _commitHyperlinkField();
    }
  }

  void _handleControl() {
    _index++;
    if (_index >= source.length) return;

    final next = source[_index];
    if (next == '\\' || next == '{' || next == '}') {
      _appendText(next);
      _index++;
      return;
    }
    if (next == '\'') {
      final hex = source.substring(
        (_index + 1).clamp(0, source.length),
        (_index + 3).clamp(0, source.length),
      );
      if (hex.length == 2) {
        final code = int.tryParse(hex, radix: 16);
        if (code != null) {
          _appendText(String.fromCharCode(code));
          _index += 3;
          return;
        }
      }
    }
    if (next == '*') {
      _expectIgnorableDestination = true;
      _index++;
      return;
    }

    final wordStart = _index;
    while (_index < source.length &&
        RegExp(r'[A-Za-z]').hasMatch(source[_index])) {
      _index++;
    }
    final controlWord = source.substring(wordStart, _index);

    final numberStart = _index;
    if (_index < source.length &&
        (source[_index] == '-' || RegExp(r'\d').hasMatch(source[_index]))) {
      _index++;
      while (_index < source.length && RegExp(r'\d').hasMatch(source[_index])) {
        _index++;
      }
    }
    final parameter = numberStart == _index
        ? null
        : int.tryParse(source.substring(numberStart, _index));

    if (_index < source.length && source[_index] == ' ') {
      _index++;
    }

    _applyControlWord(controlWord, parameter);
  }

  void _applyControlWord(String word, int? parameter) {
    switch (word) {
      case 'par':
        _flushCurrentParagraph();
        break;
      case 'line':
        _flushPendingText();
        _commitInline(DocumentInline(
            type: DocumentInlineType.lineBreak, style: _style()));
        break;
      case 'tab':
        _flushPendingText();
        _commitInline(
            DocumentInline(type: DocumentInlineType.tab, style: _style()));
        break;
      case 'b':
        _replaceState(_state.copyWith(bold: parameter != 0));
        break;
      case 'i':
        _replaceState(_state.copyWith(italic: parameter != 0));
        break;
      case 'ul':
        _replaceState(_state.copyWith(underline: true));
        break;
      case 'ulnone':
        _replaceState(_state.copyWith(underline: false));
        break;
      case 'strike':
        _replaceState(_state.copyWith(strike: parameter != 0));
        break;
      case 'fs':
        _replaceState(_state.copyWith(
            fontSize: parameter == null ? null : parameter / 2));
        break;
      case 'u':
        if (parameter != null) {
          _appendText(String.fromCharCode(
              parameter < 0 ? 65536 + parameter : parameter));
          _pendingUnicodeFallbackSkips = _unicodeSkipCount;
        }
        break;
      case 'uc':
        if (parameter != null) {
          _unicodeSkipCount = parameter;
        }
        break;
      case 'fonttbl':
        _inFontTable = true;
        _replaceState(_state.copyWith(skipText: true));
        break;
      case 'colortbl':
        _inColorTable = true;
        _replaceState(_state.copyWith(skipText: true));
        break;
      case 'stylesheet':
      case 'info':
      case 'pict':
      case 'object':
        _replaceState(_state.copyWith(skipText: true));
        break;
      case 'field':
        _inField = true;
        _fldInstBuffer.clear();
        _fldRsltBuffer.clear();
        break;
      case 'fldinst':
        _inFieldInstruction = true;
        _inFieldResult = false;
        break;
      case 'fldrslt':
        _inFieldInstruction = false;
        _inFieldResult = true;
        break;
      case 'trowd':
        _inTableRow = true;
        _flushCurrentParagraph();
        _currentRowCells.clear();
        break;
      case 'cell':
        _flushCurrentParagraph();
        _currentRowCells.add(
          DocumentTableCell(
              blocks: List<DocumentBlock>.from(_currentCellBlocks)),
        );
        _currentCellBlocks.clear();
        break;
      case 'row':
        _flushCurrentParagraph();
        _flushTableRowIfNeeded();
        break;
      default:
        if (_expectIgnorableDestination) {
          _replaceState(_state.copyWith(skipText: true));
          _expectIgnorableDestination = false;
        }
        break;
    }
  }

  void _replaceState(_RtfState newState) {
    _flushPendingText();
    _stack[_stack.length - 1] = newState;
  }

  void _appendText(String text) {
    if (_state.skipText || _inFontTable || _inColorTable) {
      return;
    }
    if (_inFieldInstruction) {
      _fldInstBuffer.write(text);
      return;
    }
    if (_inFieldResult) {
      _fldRsltBuffer.write(text);
    }
    _text.write(text);
  }

  void _flushCurrentParagraph() {
    _flushPendingText();

    if (_currentInlines.isEmpty) {
      return;
    }

    final paragraph = DocumentParagraphBlock(
        inlines: List<DocumentInline>.from(_currentInlines));
    if (_inTableRow) {
      _currentCellBlocks.add(paragraph);
    } else {
      _blocks.add(paragraph);
    }
    _currentInlines.clear();

    if (_inField) {
      _commitHyperlinkField();
    }
  }

  void _commitInline(DocumentInline inline) {
    _currentInlines.add(inline);
  }

  void _flushPendingText() {
    final pendingText = _text.toString();
    if (pendingText.isEmpty) return;
    _currentInlines.add(
      DocumentInline(
        type: _state.hyperlink == null
            ? DocumentInlineType.text
            : DocumentInlineType.hyperlink,
        text: pendingText,
        href: _state.hyperlink,
        style: _style(),
      ),
    );
    _text.clear();
  }

  DocumentTextStyleData _style() {
    return DocumentTextStyleData(
      bold: _state.bold,
      italic: _state.italic,
      underline: _state.underline,
      strike: _state.strike,
      fontSize: _state.fontSize,
    );
  }

  void _commitHyperlinkField() {
    if (!_inField) return;
    _inField = false;
    _inFieldInstruction = false;
    _inFieldResult = false;

    final instruction = _fldInstBuffer.toString();
    final resultText = _fldRsltBuffer.toString().trim();
    _fldInstBuffer.clear();
    _fldRsltBuffer.clear();

    final match = RegExp(r'HYPERLINK\s+"([^"]+)"', caseSensitive: false)
        .firstMatch(instruction);
    final href = match?.group(1);
    if (href == null || resultText.isEmpty) {
      return;
    }

    _currentInlines.removeWhere((inline) => inline.text.trim() == resultText);
    _currentInlines.add(
      DocumentInline(
        type: DocumentInlineType.hyperlink,
        text: resultText,
        href: href,
        style: _style(),
      ),
    );
  }

  void _flushTableRowIfNeeded() {
    if (!_inTableRow) {
      return;
    }
    if (_currentCellBlocks.isNotEmpty) {
      _currentRowCells.add(
        DocumentTableCell(blocks: List<DocumentBlock>.from(_currentCellBlocks)),
      );
      _currentCellBlocks.clear();
    }
    if (_currentRowCells.isNotEmpty) {
      _currentTableRows.add(
        DocumentTableRow(cells: List<DocumentTableCell>.from(_currentRowCells)),
      );
      _currentRowCells.clear();
    }
    if (_currentTableRows.isNotEmpty) {
      _blocks.add(DocumentTableBlock(
          rows: List<DocumentTableRow>.from(_currentTableRows)));
      _currentTableRows.clear();
    }
    _inTableRow = false;
  }
}
