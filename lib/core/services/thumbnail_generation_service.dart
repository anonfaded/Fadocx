import 'dart:io';
import 'package:flutter/material.dart' show Icons, IconData;
import 'dart:ui' as ui;

import 'package:fadocx/features/viewer/data/services/document_parser_service.dart';
import 'package:fadocx/features/viewer/domain/entities/parsed_document_entity.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:highlight/highlight_core.dart';
import 'package:highlight/languages/java.dart';
import 'package:highlight/languages/python.dart';
import 'package:highlight/languages/bash.dart';
import 'package:highlight/languages/xml.dart';
import 'package:highlight/languages/markdown.dart';
import 'package:highlight/languages/json.dart' as hl_json_lang;

class ThumbnailGenerationService {
  static bool _hlRegistered = false;

  static void _ensureHighlightLanguages() {
    if (_hlRegistered) return;
    _hlRegistered = true;
    highlight.registerLanguage('java', java);
    highlight.registerLanguage('python', python);
    highlight.registerLanguage('bash', bash);
    highlight.registerLanguage('xml', xml);
    highlight.registerLanguage('markdown', markdown);
    highlight.registerLanguage('json', hl_json_lang.json);
  }

  static String? _languageForThumbnailType(String type) {
    switch (type) {
      case 'java': return 'java';
      case 'py': return 'python';
      case 'sh': return 'bash';
      case 'html': return 'xml';
      case 'xml': return 'xml';
      case 'md': return 'markdown';
      case 'json': return 'json';
      case 'fadrec': return 'json';
      default: return null;
    }
  }

  static const Map<String, ui.Color> _syntaxColors = {
    'keyword': ui.Color(0xFFC678DD),
    'selector-tag': ui.Color(0xFFE06C75),
    'addition': ui.Color(0xFF98C379),
    'built_in': ui.Color(0xFF56B6C2),
    'type': ui.Color(0xFF56B6C2),
    'title': ui.Color(0xFF61AFEF),
    'section': ui.Color(0xFF61AFEF),
    'attr': ui.Color(0xFFD19A66),
    'attribute': ui.Color(0xFFD19A66),
    'string': ui.Color(0xFF98C379),
    'regexp': ui.Color(0xFF98C379),
    'symbol': ui.Color(0xFF56B6C2),
    'variable': ui.Color(0xFFE06C75),
    'template-variable': ui.Color(0xFFE06C75),
    'link': ui.Color(0xFF56B6C2),
    'meta': ui.Color(0xFF7F848E),
    'comment': ui.Color(0xFF7F848E),
    'deletion': ui.Color(0xFFE06C75),
    'number': ui.Color(0xFFD19A66),
    'literal': ui.Color(0xFFD19A66),
    'params': ui.Color(0xFFABB2BF),
    'subst': ui.Color(0xFFE06C75),
    'tag': ui.Color(0xFFE06C75),
    'name': ui.Color(0xFFE06C75),
    'selector-id': ui.Color(0xFF61AFEF),
    'selector-class': ui.Color(0xFFD19A66),
    'selector-attr': ui.Color(0xFFD19A66),
    'selector-pseudo': ui.Color(0xFFD19A66),
    'property': ui.Color(0xFFE06C75),
    'operator': ui.Color(0xFF56B6C2),
    'punctuation': ui.Color(0xFFABB2BF),
    'bullet': ui.Color(0xFFD19A66),
    'code': ui.Color(0xFF98C379),
    'emphasis': ui.Color(0xFFC678DD),
    'strong': ui.Color(0xFFD19A66),
    'formula': ui.Color(0xFF56B6C2),
  };
  static const MethodChannel pdfChannel = MethodChannel(
    'com.fadseclab.fadocx/pdf',
  );
  static const MethodChannel docChannel = MethodChannel(
    'com.fadseclab.fadocx/document_parser',
  );

  static const int _thumbnailWidth = 400;
  static const int _thumbnailHeight = 560;
  static const int _sheetPreviewRows = 12;
  static const int _sheetPreviewCols = 5;
  static const int _sheetPreviewSheets = 1;
  static const int _maxPreviewTextLength = 1800;
  static const int _readingWordsPerMinute = 200;
  static const double _compactHeaderHeight = 56.0;

  static const ui.Color _lightPageBg = ui.Color(0xFFF8F6F1);
  static const ui.Color _darkPageBg = ui.Color(0xFF1E1E2E);
  static const ui.Color _lightText = ui.Color(0xFF2B2B2B);
  static const ui.Color _darkText = ui.Color(0xFFCDD6F4);
  static const ui.Color _lightCardBg = ui.Color(0xFFFBFCFA);
  static const ui.Color _darkCardBg = ui.Color(0xFF181825);
  static const ui.Color _lightGridLine = ui.Color(0xFFD6DDD2);
  static const ui.Color _darkGridLine = ui.Color(0xFF45475A);
  static const ui.Color _lightCellText = ui.Color(0xFF2C332F);
  static const ui.Color _darkCellText = ui.Color(0xFFCDD6F4);
  static const ui.Color _lightPlaceholderBg = ui.Color(0xFFF9FAF8);
  static const ui.Color _darkPlaceholderBg = ui.Color(0xFF181825);
  static const ui.Color _lightCaptionText = ui.Color(0xFF5D635F);
  static const ui.Color _darkCaptionText = ui.Color(0xFFA6ADC8);

  static final Logger _log = Logger();
  static const TextStyle _previewHeaderMetaStyle = TextStyle(
    color: ui.Color(0xFFFDFDFD),
    fontSize: 16,
    fontWeight: FontWeight.w600,
    fontFamily: 'Ubuntu',
  );

  static Future<Uint8List?> generateThumbnail(
      String filePath, String fileName, String fileType,
      {ParsedDocumentEntity? cachedDocument,
      ui.Brightness brightness = ui.Brightness.light}) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        _log.w('Thumbnail skipped, file missing: $filePath');
        return null;
      }

      final normalizedType = fileType.toLowerCase();

      return switch (normalizedType) {
        'pdf' => _generatePdfThumbnail(
            filePath,
            cachedDocument: cachedDocument,
            brightness: ui.Brightness.light,
          ),
        'doc' || 'docx' || 'txt' || 'rtf' || 'odt' || 'java' || 'py' || 'sh' || 'html' || 'md' || 'log' || 'json' || 'xml' || 'ott' || 'fadrec' => _generateTextThumbnail(
            filePath,
            normalizedType,
            cachedDocument: cachedDocument,
            brightness: brightness,
          ),
        'xls' || 'xlsx' || 'csv' || 'ods' => _generateSpreadsheetThumbnail(
            filePath,
            normalizedType,
            cachedDocument: cachedDocument,
            brightness: brightness,
          ),
        'ppt' || 'pptx' || 'odp' || 'epub' || 'ods' => _generatePresentationThumbnail(
            filePath,
            normalizedType,
            brightness: brightness,
          ),
        _ => _createPlaceholderThumbnail(
            label: normalizedType.toUpperCase(),
            accent: ThumbnailColors.gray,
            caption: fileName,
            brightness: brightness,
          ),
      };
    } catch (e, st) {
      _log.e('Thumbnail generation failed for $fileName',
          error: e, stackTrace: st);
      return null;
    }
  }

  static Future<Uint8List?> _generatePresentationThumbnail(
    String filePath,
    String fileType, {
    ParsedDocumentEntity? cachedDocument,
    ui.Brightness brightness = ui.Brightness.light,
  }) async {
    try {
      final accent = ThumbnailColors.pptOrange;
      final formatLabel = fileType.toUpperCase();
      String metaText = formatLabel;
      if (cachedDocument != null) {
        final slides = cachedDocument.slides.length;
        if (slides > 0) {
          metaText = '$formatLabel - $slides ${slides == 1 ? 'slide' : 'slides'}';
        }
        final wc = cachedDocument.wordCount ?? 0;
        if (wc > 0) metaText += ' - ${wc}w';
      }
      return _createSlideThumbnailCard(accent: accent, label: formatLabel, meta: metaText, brightness: brightness);
    } catch (e) {
      return _createPlaceholderThumbnail(label: fileType.toUpperCase(), accent: ThumbnailColors.pptOrange, caption: fileType.toUpperCase(), brightness: brightness);
    }
  }

  static Future<Uint8List?> _createSlideThumbnailCard({
    required ColorRgb accent,
    required String label,
    required String meta,
    ui.Brightness brightness = ui.Brightness.light,
  }) async {
    return _renderCanvas((canvas, size) {
      _paintShadowBackground(canvas, size, accent);

      final cardRect = ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(18, 18, size.width - 36, size.height - 36),
        const ui.Radius.circular(22),
      );
      final cardBg = brightness == ui.Brightness.dark ? _darkCardBg : _lightCardBg;
      canvas.drawRRect(cardRect, ui.Paint()..color = cardBg);

      final headerHeight = _compactHeaderHeight;
      final headerRect = ui.Rect.fromLTWH(18, 18, size.width - 36, headerHeight);
      _paintPreviewHeader(
        canvas,
        rect: headerRect,
        color: _uiColor(accent),
        text: meta,
      );

      final contentTop = 18.0 + headerHeight;
      final contentHeight = size.height - 36 - headerHeight;
      final contentWidth = size.width - 36;
      final centerX = 18.0 + contentWidth / 2;
      final centerY = contentTop + contentHeight / 2;

      canvas.drawCircle(
        Offset(centerX, centerY),
        40,
        ui.Paint()..color = _uiColor(accent, alpha: 30),
      );

      _paintCenteredText(
        canvas,
        text: String.fromCharCode(Icons.slideshow.codePoint),
        top: centerY - 18,
        maxWidth: 72,
        left: centerX - 36,
        style: TextStyle(
          fontSize: 36,
          fontFamily: Icons.slideshow.fontFamily,
          package: Icons.slideshow.fontPackage,
          color: _uiColor(accent, alpha: 180),
        ),
      );

      _paintCenteredText(
        canvas,
        text: label,
        top: centerY + 30,
        maxWidth: contentWidth,
        left: 18,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          fontFamily: 'Ubuntu',
          color: _uiColor(accent, alpha: 150),
        ),
      );
    });
  }

  static Future<Uint8List?> _generatePdfThumbnail(
    String filePath, {
    ParsedDocumentEntity? cachedDocument,
    ui.Brightness brightness = ui.Brightness.light,
  }) async {
    try {
      final result = await pdfChannel.invokeMethod<Map<dynamic, dynamic>>(
        'renderPage',
        <String, dynamic>{
          'filePath': filePath,
          'pageNumber': 0,
          'width': _thumbnailWidth,
          'height': _thumbnailHeight - 100,
        },
      );

      final bytes = result?['bytes'];
      if (bytes is! Uint8List || bytes.isEmpty) {
        _log.w('PDF thumbnail fell back to placeholder for $filePath');
        return _createPlaceholderThumbnail(
          label: 'PDF',
          accent: ThumbnailColors.pdfRed,
          caption: 'Unable to render preview',
          brightness: brightness,
        );
      }

      int pageCount = 0;
      try {
        pageCount = await pdfChannel.invokeMethod<int>('getPageCount', {
              'filePath': filePath,
            }) ??
            0;
      } catch (_) {}

      return _createPdfPreview(
        pageBytes: bytes,
        pageCount: pageCount,
        wordCount: cachedDocument?.wordCount,
        lineCount: cachedDocument?.lineCount,
        brightness: brightness,
      );
    } on PlatformException catch (e, st) {
      _log.e('PDF thumbnail render failed: \${e.code}',
          error: e, stackTrace: st);
      final msg = (e.message ?? '').toLowerCase();
      if (msg.contains('password') || msg.contains('encrypted') || e.code.toLowerCase().contains('password')) {
        return _createPlaceholderThumbnail(
          label: 'PDF',
          accent: ThumbnailColors.pdfRed,
          caption: 'Password protected',
          brightness: ui.Brightness.light,
          icon: Icons.lock_outline,
        );
      }
    } catch (e, st) {
      _log.e('PDF thumbnail render failed', error: e, stackTrace: st);
      if (e.toString().toLowerCase().contains('password') || e.toString().toLowerCase().contains('encrypted')) {
        return _createPlaceholderThumbnail(
          label: 'PDF',
          accent: ThumbnailColors.pdfRed,
          caption: 'Password protected',
          brightness: ui.Brightness.light,
          icon: Icons.lock_outline,
        );
      }
    }

    return _createPlaceholderThumbnail(
      label: 'PDF',
      accent: ThumbnailColors.pdfRed,
      caption: 'Unable to render preview',
      brightness: ui.Brightness.light,
    );
  }

  static Future<Uint8List> _createPdfPreview({
    required Uint8List pageBytes,
    required int pageCount,
    int? wordCount,
    int? lineCount,
    ui.Brightness brightness = ui.Brightness.light,
  }) async {
    final codec = await ui.instantiateImageCodec(pageBytes);
    final frame = await codec.getNextFrame();
    final pageImage = frame.image;

    try {
      return _renderCanvas((canvas, size) {
        _paintShadowBackground(canvas, size, ThumbnailColors.pdfRed);

        final cardRect = ui.RRect.fromRectAndRadius(
          ui.Rect.fromLTWH(18, 18, size.width - 36, size.height - 36),
          const ui.Radius.circular(22),
        );
        final pdfCardBg = brightness == ui.Brightness.dark ? _darkCardBg : _lightCardBg;
        canvas.drawRRect(
            cardRect, ui.Paint()..color = pdfCardBg);

        final headerHeight = _compactHeaderHeight;
        final headerRect = ui.RRect.fromRectAndRadius(
          ui.Rect.fromLTWH(18, 18, size.width - 36, headerHeight),
          const ui.Radius.circular(22),
        );
        _paintPreviewHeader(
          canvas,
          rect: headerRect.outerRect,
          color: _uiColor(ThumbnailColors.pdfRed),
          text: _buildPdfPreviewStats(
            pageCount,
            wordCount: wordCount,
            lineCount: lineCount,
          ),
        );

        final imageTop = 18.0 + headerHeight;
        final imageAreaHeight = size.height - 36 - headerHeight;
        final imageAreaWidth = size.width - 36;

        final scale = imageAreaWidth / pageImage.width;
        final visibleSourceHeight =
            (imageAreaHeight / scale).clamp(1.0, pageImage.height.toDouble());
        final sourceRect = ui.Rect.fromLTWH(
          0,
          0,
          pageImage.width.toDouble(),
          visibleSourceHeight,
        );
        final drawWidth = imageAreaWidth;
        final drawHeight = imageAreaHeight;
        final drawLeft = 18.0;
        final drawTop = imageTop;

        canvas.drawImageRect(
          pageImage,
          sourceRect,
          ui.Rect.fromLTWH(drawLeft, drawTop, drawWidth, drawHeight),
          ui.Paint()..filterQuality = FilterQuality.high,
        );
      });
    } finally {
      pageImage.dispose();
    }
  }

  static Future<Uint8List?> _generateTextThumbnail(
    String filePath,
    String normalizedType, {
    ParsedDocumentEntity? cachedDocument,
    ui.Brightness brightness = ui.Brightness.light,
  }) async {
    try {
      final fullText = cachedDocument?.searchableText.isNotEmpty == true
          ? cachedDocument!.searchableText
          : await _extractTextContent(filePath, normalizedType);
      if (cachedDocument?.searchableText.isNotEmpty == true) {
        _log.d('Using cached parsed text for thumbnail: $filePath');
      }
      if (fullText == null || fullText.trim().isEmpty) {
        _log.w('Text thumbnail fallback for $filePath');
        return _createPlaceholderThumbnail(
          label: normalizedType.toUpperCase(),
          accent: _accentForType(normalizedType),
          caption: 'No readable text found',
          brightness: brightness,
        );
      }

      final previewText = _trimPreviewText(fullText);
      if (previewText == null || previewText.isEmpty) {
        _log.w('Text thumbnail preview text empty for $filePath');
        return _createPlaceholderThumbnail(
          label: normalizedType.toUpperCase(),
          accent: _accentForType(normalizedType),
          caption: 'No readable text found',
          brightness: brightness,
        );
      }

      final language = _languageForThumbnailType(normalizedType);
      return _createTextDocumentPreview(
        text: previewText,
        fullText: fullText,
        accent: _accentForType(normalizedType),
        label: normalizedType.toUpperCase(),
        language: language,
        brightness: brightness,
      );
    } catch (e, st) {
      _log.e('Text thumbnail parse failed for $filePath',
          error: e, stackTrace: st);
      return _createPlaceholderThumbnail(
        label: normalizedType.toUpperCase(),
        accent: _accentForType(normalizedType),
        caption: 'Preview unavailable',
        brightness: brightness,
      );
    }
  }

  static Future<Uint8List?> _generateSpreadsheetThumbnail(
    String filePath,
    String normalizedType, {
    ParsedDocumentEntity? cachedDocument,
    ui.Brightness brightness = ui.Brightness.light,
  }) async {
    try {
      final sheets = cachedDocument != null && cachedDocument.sheets.isNotEmpty
          ? cachedDocument.sheets
              .map((sheet) => {
                    'name': sheet.name,
                    'rows': sheet.rows,
                    'rowCount': sheet.rowCount,
                    'colCount': sheet.colCount,
                  })
              .toList()
          : await _extractSheetPreview(filePath, normalizedType);
      if (cachedDocument != null && cachedDocument.sheets.isNotEmpty) {
        _log.d('Using cached parsed sheets for thumbnail: $filePath');
      }
      if (sheets == null || sheets.isEmpty) {
        _log.w('Spreadsheet thumbnail fallback for $filePath');
        return _createPlaceholderThumbnail(
          label: normalizedType.toUpperCase(),
          accent: _accentForType(normalizedType),
          caption: 'No cells available',
          brightness: brightness,
        );
      }

      return _createSpreadsheetPreview(
        sheets: sheets,
        accent: _accentForType(normalizedType),
        label: normalizedType.toUpperCase(),
        brightness: brightness,
      );
    } catch (e, st) {
      _log.e('Spreadsheet thumbnail parse failed for $filePath',
          error: e, stackTrace: st);
      return _createPlaceholderThumbnail(
        label: normalizedType.toUpperCase(),
        accent: _accentForType(normalizedType),
        caption: 'Preview unavailable',
        brightness: brightness,
      );
    }
  }

  static Future<String?> _extractTextContent(
    String filePath,
    String normalizedType,
  ) async {
    switch (normalizedType) {
      case 'doc':
        final result = await docChannel.invokeMethod<Map<dynamic, dynamic>>(
          'parseDocument',
          <String, dynamic>{'filePath': filePath, 'format': 'DOC'},
        );
        return result?['textContent'] as String?;
      case 'docx':
        return await DocumentParserService.parseDOCX(filePath);
      case 'rtf':
        return await DocumentParserService.parseRTF(filePath);
      case 'odt':
        return await DocumentParserService.parseODT(filePath);
      case 'json':
        return await DocumentParserService.parseJSON(filePath).then((r) => r['textContent'] as String? ?? '');
      case 'xml':
        return await DocumentParserService.parseXML(filePath).then((r) => r['textContent'] as String? ?? '');
      case 'ott':
        return await DocumentParserService.parseODT(filePath);
      default:
        try {
          return await DocumentParserService.parseTXT(filePath);
        } catch (_) {
          return File(filePath).readAsString();
        }
    }
  }

  static Future<List<dynamic>?> _extractSheetPreview(
    String filePath,
    String normalizedType,
  ) async {
    switch (normalizedType) {
      case 'xlsx':
      case 'xls':
        final result = await docChannel.invokeMethod<Map<dynamic, dynamic>>(
          'parseDocument',
          <String, dynamic>{
            'filePath': filePath,
            'format': normalizedType.toUpperCase(),
            'maxRows': _sheetPreviewRows,
            'maxCols': _sheetPreviewCols,
            'maxSheets': _sheetPreviewSheets,
          },
        );
        return result?['sheets'] as List<dynamic>?;
      case 'csv':
        final result = await DocumentParserService.parseCSV(filePath);
        return result['sheets'] as List<dynamic>?;
      case 'ods':
        final result = await DocumentParserService.parseODS(
          filePath,
          maxRowsPerSheet: _sheetPreviewRows,
          maxCols: _sheetPreviewCols,
          maxSheets: _sheetPreviewSheets,
        );
        return result['sheets'] as List<dynamic>?;
      default:
        return null;
    }
  }

  static String? _trimPreviewText(String? value) {
    if (value == null) {
      return null;
    }

    final normalized = value
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n')
        .map((line) => line.replaceAll(RegExp(r'[ \t]+'), ' ').trimRight())
        .join('\n')
        .trim();
    if (normalized.isEmpty) {
      return null;
    }

    if (normalized.length <= _maxPreviewTextLength) {
      return normalized;
    }

    return '${normalized.substring(0, _maxPreviewTextLength).trimRight()}...';
  }

  static Future<Uint8List> _createTextDocumentPreview({
    required String text,
    required String fullText,
    required ColorRgb accent,
    required String label,
    String? language,
    ui.Brightness brightness = ui.Brightness.light,
  }) {
    return _renderCanvas((canvas, size) {
      _paintShadowBackground(canvas, size, accent);

      final pageRect = ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(20, 20, size.width - 40, size.height - 40),
        const ui.Radius.circular(22),
      );
      final pageBg = brightness == ui.Brightness.dark ? _darkPageBg : _lightPageBg;
      canvas.drawRRect(
          pageRect, ui.Paint()..color = pageBg);

      final headerHeight = _compactHeaderHeight;
      final headerRect = ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(20, 20, size.width - 40, headerHeight),
        const ui.Radius.circular(22),
      );
      _paintPreviewHeader(
        canvas,
        rect: headerRect.outerRect,
        color: _uiColor(accent),
        text: _buildReadingStats(fullText, language: language),
      );

      _paintText(
        canvas,
        text: label,
        left: 44,
        top: 100,
        maxWidth: size.width - 88,
        style: TextStyle(
          color: _uiColor(accent),
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          fontFamily: 'Ubuntu',
        ),
      );

      if (language != null) {
        _paintSyntaxText(
          canvas,
          text: text,
          language: language,
          left: 44,
          top: 134,
          maxWidth: size.width - 88,
          maxLines: 16,
          baseStyle: TextStyle(
            color: brightness == ui.Brightness.dark ? _darkText : _lightText,
            fontSize: 19,
            height: 1.28,
            fontWeight: FontWeight.w400,
            fontFamily: 'Ubuntu',
          ),
        );
      } else {
        _paintText(
          canvas,
          text: text,
          left: 44,
          top: 134,
          maxWidth: size.width - 88,
          maxLines: 16,
          style: TextStyle(
            color: brightness == ui.Brightness.dark ? _darkText : _lightText,
            fontSize: 19,
            height: 1.28,
            fontWeight: FontWeight.w400,
            fontFamily: 'Ubuntu',
          ),
        );
      }
    });
  }

  static void _paintSyntaxText(
    ui.Canvas canvas, {
    required String text,
    required String language,
    required double left,
    required double top,
    required double maxWidth,
    required TextStyle baseStyle,
    int? maxLines,
  }) {
    _ensureHighlightLanguages();
    final result = highlight.parse(text, language: language);
    final spans = <TextSpan>[];
    _flattenNodes(result.nodes, null, spans, baseStyle);

    final painter = TextPainter(
      text: TextSpan(children: spans, style: baseStyle),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
      maxLines: maxLines,
      ellipsis: maxLines == null ? null : '\u2026',
    )..layout(maxWidth: maxWidth);

    painter.paint(canvas, ui.Offset(left, top));
  }

  static void _flattenNodes(
    List<Node>? nodes,
    String? parentClass,
    List<TextSpan> spans,
    TextStyle baseStyle,
  ) {
    if (nodes == null) return;
    for (final node in nodes) {
      if (node.value != null) {
        const defaultColor = ui.Color(0xFFABB2BF);
        final color = parentClass != null ? (_syntaxColors[parentClass] ?? defaultColor) : defaultColor;
        spans.add(TextSpan(
          text: node.value,
          style: TextStyle(color: color, fontSize: baseStyle.fontSize, fontWeight: baseStyle.fontWeight, fontFamily: baseStyle.fontFamily, height: baseStyle.height),
        ));
      } else if (node.children != null) {
        final effectiveClass = node.className ?? parentClass;
        _flattenNodes(node.children, effectiveClass, spans, baseStyle);
      }
    }
  }

  static Future<Uint8List> _createSpreadsheetPreview({
    required List<dynamic> sheets,
    required ColorRgb accent,
    required String label,
    ui.Brightness brightness = ui.Brightness.light,
  }) {
    return _renderCanvas((canvas, size) {
      _paintShadowBackground(canvas, size, accent);

      final cardRect = ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(18, 18, size.width - 36, size.height - 36),
        const ui.Radius.circular(22),
      );
      final sheetCardBg = brightness == ui.Brightness.dark ? _darkCardBg : _lightCardBg;
      canvas.drawRRect(
          cardRect, ui.Paint()..color = sheetCardBg);

      final topBandRect = ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(18, 18, size.width - 36, _compactHeaderHeight),
        const ui.Radius.circular(22),
      );

      final firstSheet = sheets.first;
      final sheetName =
          (firstSheet is Map ? firstSheet['name'] : null)?.toString() ??
              'Sheet1';
      final rows = _extractSheetRows(firstSheet);
      final visibleRows = rows.take(_sheetPreviewRows).toList();
      final visibleColCount = visibleRows
          .fold<int>(
            0,
            (current, row) => row.length > current ? row.length : current,
          )
          .clamp(1, _sheetPreviewCols);
      final dataRowCount = visibleRows.isEmpty ? 6 : visibleRows.length;

      _paintPreviewHeader(
        canvas,
        rect: topBandRect.outerRect,
        color: _uiColor(accent),
        text: '$label • $sheetName • $dataRowCount rows',
      );

      final gridLeft = 18.0;
      final gridTop = 80.0;
      final gridWidth = size.width - 36;
      final gridHeight = size.height - 104;
      final serialColWidth = 30.0;
      final dataGridWidth = gridWidth - serialColWidth;
      final dataColWidth = dataGridWidth / visibleColCount;
      final totalRows = visibleRows.isEmpty ? 6 : visibleRows.length + 1;
      final rowHeight = gridHeight / totalRows;

      final gridLineColor = brightness == ui.Brightness.dark ? _darkGridLine : _lightGridLine;
      final borderPaint = ui.Paint()
        ..color = gridLineColor
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1.0;

      final headerFill = ui.Paint()..color = _uiColor(accent, alpha: brightness == ui.Brightness.dark ? 20 : 36);
      canvas.drawRect(
        ui.Rect.fromLTWH(gridLeft, gridTop, gridWidth, rowHeight),
        headerFill,
      );
      canvas.drawRect(
        ui.Rect.fromLTWH(gridLeft, gridTop, serialColWidth, gridHeight),
        headerFill,
      );

      for (int rowIndex = 0; rowIndex <= totalRows; rowIndex++) {
        final y = gridTop + (rowIndex * rowHeight);
        canvas.drawLine(
          ui.Offset(gridLeft, y),
          ui.Offset(gridLeft + gridWidth, y),
          borderPaint,
        );
      }

      canvas.drawLine(
        ui.Offset(gridLeft + serialColWidth, gridTop),
        ui.Offset(gridLeft + serialColWidth, gridTop + gridHeight),
        borderPaint,
      );

      for (int colIndex = 0; colIndex <= visibleColCount; colIndex++) {
        final x = gridLeft + serialColWidth + (colIndex * dataColWidth);
        canvas.drawLine(
          ui.Offset(x, gridTop),
          ui.Offset(x, gridTop + gridHeight),
          borderPaint,
        );
      }

      for (int colIndex = 0; colIndex < visibleColCount; colIndex++) {
        _paintCenteredText(
          canvas,
          text: _columnName(colIndex),
          top: gridTop + 10,
          left: gridLeft + serialColWidth + (colIndex * dataColWidth),
          maxWidth: dataColWidth,
          style: TextStyle(
            color: _uiColor(accent),
            fontSize: 13,
            fontWeight: FontWeight.w700,
            fontFamily: 'Ubuntu',
          ),
        );
      }

      for (int rowIndex = 0; rowIndex < visibleRows.length; rowIndex++) {
        final top = gridTop + ((rowIndex + 1) * rowHeight) + 7;

        _paintCenteredText(
          canvas,
          text: '${rowIndex + 1}',
          top: top,
          left: gridLeft,
          maxWidth: serialColWidth,
          style: TextStyle(
            color: _uiColor(accent),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            fontFamily: 'Ubuntu',
          ),
        );

        final row = visibleRows[rowIndex];
        for (int colIndex = 0;
            colIndex < row.length && colIndex < visibleColCount;
            colIndex++) {
          _paintText(
            canvas,
            text: row[colIndex],
            left: gridLeft + serialColWidth + (colIndex * dataColWidth) + 6,
            top: top,
            maxWidth: dataColWidth - 10,
            maxLines: 1,
            style: TextStyle(
              color: brightness == ui.Brightness.dark ? _darkCellText : _lightCellText,
              fontSize: 14,
              height: 1.15,
              fontWeight: FontWeight.w400,
              fontFamily: 'Ubuntu',
            ),
          );
        }
      }
    });
  }

  static Future<Uint8List> _createPlaceholderThumbnail({
    required String label,
    required ColorRgb accent,
    required String caption,
    ui.Brightness brightness = ui.Brightness.light,
    IconData? icon,
  }) {
    return _renderCanvas((canvas, size) {
      _paintShadowBackground(canvas, size, accent);

      final cardRect = ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(26, 32, size.width - 52, size.height - 64),
        const ui.Radius.circular(26),
      );
      final placeholderBg = brightness == ui.Brightness.dark ? _darkPlaceholderBg : _lightPlaceholderBg;
      canvas.drawRRect(
          cardRect, ui.Paint()..color = placeholderBg);

      final accentPaint = ui.Paint()..color = _uiColor(accent);
      canvas.drawCircle(ui.Offset(size.width / 2, 178), 52, accentPaint);

      if (icon == Icons.lock_outline) {
        final lockPaint = ui.Paint()
          ..color = const ui.Color(0xFFFFFFFF)
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 3.0
          ..strokeCap = ui.StrokeCap.round;
        final lockFill = ui.Paint()
          ..color = const ui.Color(0xFFFFFFFF)
          ..style = ui.PaintingStyle.fill;
        final cx = size.width / 2;
        final cy = 178.0;
        final body = ui.Rect.fromCenter(center: ui.Offset(cx, cy + 8), width: 28, height: 22);
        canvas.drawRRect(ui.RRect.fromRectAndRadius(body, const ui.Radius.circular(4)), lockFill);
        final arcRect = ui.Rect.fromCenter(center: ui.Offset(cx, cy - 4), width: 18, height: 20);
        canvas.drawArc(arcRect, 3.14, 3.14, false, lockPaint);
      } else {
        final tp = TextPainter(
          text: TextSpan(text: label, style: const TextStyle(color: ui.Color(0xFFFFFFFF), fontSize: 22, fontWeight: FontWeight.w700, fontFamily: 'Ubuntu')),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, ui.Offset(size.width / 2 - tp.width / 2, 178 - tp.height / 2));
      }

      _paintCenteredText(
        canvas,
        text: icon == Icons.lock_outline ? 'Password Protected' : label,
        top: icon == Icons.lock_outline ? 250 : 250,
        maxWidth: size.width - 80,
        style: TextStyle(
          color: icon == Icons.lock_outline ? _uiColor(accent) : _uiColor(accent),
          fontSize: 26,
          fontWeight: FontWeight.w700,
          fontFamily: 'Ubuntu',
        ),
      );

      _paintCenteredText(
        canvas,
        text: caption,
        top: 294,
        maxWidth: size.width - 100,
        style: TextStyle(
          color: brightness == ui.Brightness.dark ? _darkCaptionText : _lightCaptionText,
          fontSize: 18,
          fontWeight: FontWeight.w500,
          fontFamily: 'Ubuntu',
        ),
      );
    });
  }

  static Future<Uint8List> _renderCanvas(
    void Function(ui.Canvas canvas, ui.Size size) painter,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final size = ui.Size(
      _thumbnailWidth.toDouble(),
      _thumbnailHeight.toDouble(),
    );

    painter(canvas, size);

    final picture = recorder.endRecording();
    final image = await picture.toImage(_thumbnailWidth, _thumbnailHeight);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('Unable to encode thumbnail image');
    }

    return byteData.buffer.asUint8List();
  }

  static void _paintShadowBackground(
    ui.Canvas canvas,
    ui.Size size,
    ColorRgb accent,
  ) {
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, size.width, size.height),
      ui.Paint()..color = _uiColor(accent, alpha: 18),
    );

    final shadowRect = ui.RRect.fromRectAndRadius(
      ui.Rect.fromLTWH(22, 26, size.width - 44, size.height - 52),
      const ui.Radius.circular(26),
    );
    canvas.drawRRect(
      shadowRect,
      ui.Paint()..color = const ui.Color(0x1A000000),
    );
  }

  static void _paintText(
    ui.Canvas canvas, {
    required String text,
    required double left,
    required double top,
    required double maxWidth,
    required TextStyle style,
    int? maxLines,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
      maxLines: maxLines,
      ellipsis: maxLines == null ? null : '\u2026',
    )..layout(maxWidth: maxWidth);

    painter.paint(canvas, ui.Offset(left, top));
  }

  static void _paintCenteredText(
    ui.Canvas canvas, {
    required String text,
    required double top,
    required double maxWidth,
    required TextStyle style,
    double left = 0,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 1,
      ellipsis: '\u2026',
    )..layout(maxWidth: maxWidth);

    final x = left + ((maxWidth - painter.width) / 2).clamp(0, maxWidth);
    painter.paint(canvas, ui.Offset(x, top));
  }

  static List<List<String>> _extractSheetRows(dynamic sheet) {
    if (sheet is! Map) {
      return const <List<String>>[];
    }

    final rows = sheet['rows'];
    if (rows is! List) {
      return const <List<String>>[];
    }

    final extracted = <List<String>>[];
    for (final row in rows) {
      if (row is List) {
        final values = row
            .take(_sheetPreviewCols)
            .map((cell) => cell?.toString().trim() ?? '')
            .toList();
        extracted.add(values);
        continue;
      }

      if (row is Map) {
        final cells = row['cells'];
        if (cells is List) {
          extracted.add(
            cells
                .take(_sheetPreviewCols)
                .map((cell) => cell?.toString().trim() ?? '')
                .toList(),
          );
        }
      }
    }

    return extracted;
  }

  static String _buildReadingStats(String text, {String? language}) {
    final words = RegExp(r'\S+').allMatches(text).length;
    final lines = text.split(RegExp(r'\r\n|\r|\n')).length;
    if (language == 'markdown') {
      final minutes = words == 0 ? 0 : (words / _readingWordsPerMinute).ceil();
      return '${minutes == 0 ? '<1' : minutes} min read • $words words • $lines lines';
    }
    if (language == 'json') {
      final objectCount = '{'.allMatches(text).length;
      final arrayCount = '['.allMatches(text).length;
      final parts = <String>['$lines lines'];
      if (objectCount > 0) parts.add('$objectCount ${objectCount == 1 ? 'object' : 'objects'}');
      if (arrayCount > 0) parts.add('$arrayCount ${arrayCount == 1 ? 'array' : 'arrays'}');
      return parts.join(' • ');
    }
    if (language != null) {
      final classCount = RegExp(r'\b(class|interface|enum)\s+\w+').allMatches(text).length;
      final funcCount = RegExp(r'\b(function|def|void|int|String|bool|var|let|const|public|private|static|async)\s+\w+\s*[(<]').allMatches(text).length;
      final parts = <String>['$lines lines'];
      if (classCount > 0) parts.add('$classCount ${classCount == 1 ? 'class' : 'classes'}');
      if (funcCount > 0) parts.add('$funcCount ${funcCount == 1 ? 'function' : 'functions'}');
      return parts.join(' • ');
    }
    final minutes = words == 0 ? 0 : (words / _readingWordsPerMinute).ceil();
    final minuteLabel = minutes == 1 ? 'minute' : 'minutes';
    return '${minutes == 0 ? '<1' : minutes} $minuteLabel read • $words words • $lines lines';
  }

  static String _buildPdfPreviewStats(
    int pageCount, {
    int? wordCount,
    int? lineCount,
  }) {
    final parts = <String>['PDF'];

    if (pageCount > 0) {
      parts.add('${_formatCompactCount(pageCount)}p');
    }

    if ((wordCount ?? 0) > 0) {
      final minutes =
          (wordCount! / _readingWordsPerMinute).ceil().clamp(1, 999);
      parts.add('${_formatCompactCount(minutes)}m');
      parts.add('${_formatCompactCount(wordCount)}W');
    }

    if ((lineCount ?? 0) > 0) {
      parts.add('${_formatCompactCount(lineCount!)}L');
    }

    return parts.join(' • ');
  }

  static String _formatCompactCount(int value) {
    if (value < 1000) return value.toString();
    if (value < 1000000) {
      final compact = value / 1000;
      final formatted = compact >= 10
          ? compact.round().toString()
          : compact.toStringAsFixed(1);
      return '${formatted.replaceAll('.0', '')}k';
    }

    final compact = value / 1000000;
    final formatted =
        compact >= 10 ? compact.round().toString() : compact.toStringAsFixed(1);
    return '${formatted.replaceAll('.0', '')}m';
  }

  static void _paintPreviewHeader(
    ui.Canvas canvas, {
    required ui.Rect rect,
    required ui.Color color,
    required String text,
  }) {
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        rect,
        const ui.Radius.circular(22),
      ),
      ui.Paint()..color = color,
    );

    _paintPreviewHeaderMeta(
      canvas,
      text: text,
      rect: rect,
    );
  }

  static void _paintAutoFitCenteredText(
    ui.Canvas canvas, {
    required String text,
    required ui.Rect rect,
    required TextStyle baseStyle,
    required double minFontSize,
    int maxLines = 1,
  }) {
    var fontSize = baseStyle.fontSize ?? minFontSize;
    TextPainter painter;

    while (true) {
      final style = baseStyle.copyWith(fontSize: fontSize);
      painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        maxLines: maxLines,
        ellipsis: maxLines == 1 ? '' : null,
      )..layout(maxWidth: rect.width);

      final maxHeight = fontSize * (maxLines == 1 ? 1.3 : 2.4);
      if ((painter.width <= rect.width && painter.height <= maxHeight) ||
          fontSize <= minFontSize) {
        break;
      }
      fontSize -= 1;
    }

    final x =
        rect.left + ((rect.width - painter.width) / 2).clamp(0, rect.width);
    final y = rect.top + ((rect.height - painter.height) / 2);
    painter.paint(canvas, ui.Offset(x, y));
  }

  static void _paintPreviewHeaderMeta(
    ui.Canvas canvas, {
    required String text,
    required ui.Rect rect,
  }) {
    _paintAutoFitCenteredText(
      canvas,
      text: text,
      rect: rect,
      baseStyle: _previewHeaderMetaStyle,
      minFontSize: 12,
      maxLines: 1,
    );
  }

  static String _columnName(int index) {
    var current = index;
    final buffer = StringBuffer();
    do {
      buffer.writeCharCode(65 + (current % 26));
      current = (current ~/ 26) - 1;
    } while (current >= 0);
    return buffer.toString().split('').reversed.join();
  }

  static ui.Color _uiColor(ColorRgb color, {int alpha = 255}) {
    return ui.Color.fromARGB(alpha, color.r, color.g, color.b);
  }

  static ColorRgb _accentForType(String normalizedType) {
    return switch (normalizedType) {
      'pdf' => ThumbnailColors.pdfRed,
      'doc' || 'docx' || 'odt' || 'rtf' || 'txt' => ThumbnailColors.docBlue,
      'xls' || 'xlsx' || 'csv' || 'ods' => ThumbnailColors.sheetGreen,
      'ppt' || 'pptx' || 'odp' || 'epub' || 'ods' => ThumbnailColors.pptOrange,
      _ => ThumbnailColors.gray,
    };
  }
}

class ColorRgb {
  const ColorRgb(this.r, this.g, this.b);

  final int r;
  final int g;
  final int b;
}

class ThumbnailColors {
  static const pdfRed = ColorRgb(209, 63, 58);
  static const docBlue = ColorRgb(44, 104, 184);
  static const sheetGreen = ColorRgb(43, 142, 92);
  static const pptOrange = ColorRgb(208, 117, 43);
  static const gray = ColorRgb(116, 124, 130);
}
