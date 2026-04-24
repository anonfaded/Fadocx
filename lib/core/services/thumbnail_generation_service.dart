import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:fadocx/features/viewer/data/services/document_parser_service.dart';
import 'package:fadocx/features/viewer/domain/entities/parsed_document_entity.dart';
import 'package:flutter/painting.dart';
import 'package:fadocx/features/viewer/data/services/lokit_service.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

class ThumbnailGenerationService {
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

  static final Logger _log = Logger();
  static const TextStyle _previewHeaderMetaStyle = TextStyle(
    color: ui.Color(0xFFFDFDFD),
    fontSize: 16,
    fontWeight: FontWeight.w600,
    fontFamily: 'Ubuntu',
  );

  static Future<Uint8List?> generateThumbnail(
      String filePath, String fileName, String fileType,
      {ParsedDocumentEntity? cachedDocument}) async {
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
          ),
        'doc' || 'docx' || 'txt' || 'rtf' || 'odt' => _generateTextThumbnail(
            filePath,
            normalizedType,
            cachedDocument: cachedDocument,
          ),
        'xls' || 'xlsx' || 'csv' || 'ods' => _generateSpreadsheetThumbnail(
            filePath,
            normalizedType,
            cachedDocument: cachedDocument,
          ),
        'ppt' || 'pptx' || 'odp' => _generatePresentationThumbnail(
            filePath,
            normalizedType,
          ),
        _ => _createPlaceholderThumbnail(
            label: normalizedType.toUpperCase(),
            accent: ThumbnailColors.gray,
            caption: fileName,
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
    String fileType,
  ) async {
    try {
      final pngBytes = await LOKitService.renderThumbnail(
        filePath: filePath,
        part: 0,
        width: _thumbnailWidth,
        height: _thumbnailHeight - 100,
      );
      if (pngBytes == null || pngBytes.isEmpty) {
        return _createPlaceholderThumbnail(
          label: 'SLIDES',
          accent: ThumbnailColors.pptOrange,
          caption: fileType.toUpperCase(),
        );
      }
      return _buildPresentationCard(pngBytes, fileType);
    } catch (e) {
      _log.w('Presentation thumbnail fell back to placeholder for $filePath', error: e);
      return _createPlaceholderThumbnail(
        label: 'SLIDES',
        accent: ThumbnailColors.pptOrange,
        caption: fileType.toUpperCase(),
      );
    }
  }

  static Future<Uint8List?> _buildPresentationCard(Uint8List slideImage, String fileType) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final w = _thumbnailWidth.toDouble();
    final h = _thumbnailHeight.toDouble();
    final accent = ThumbnailColors.pptOrange;

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = ui.Color.fromARGB(18, accent.r, accent.g, accent.b));
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(10, 10, w - 20, h - 20), Radius.circular(22)),
      Paint()..color = const ui.Color(0x1A000000),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(8, 8, w - 16, h - 16), Radius.circular(22)),
      Paint()..color = const ui.Color(0xFFFFFFFF),
    );

    final headerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(8, 8, w - 16, _compactHeaderHeight),
      Radius.circular(22),
    );
    canvas.drawRRect(headerRect, Paint()..color = ui.Color.fromARGB(255, accent.r, accent.g, accent.b));

    final headerPainter = TextPainter(
      text: TextSpan(
        text: fileType.toUpperCase(),
        style: _previewHeaderMetaStyle,
      ),
      textDirection: ui.TextDirection.ltr,
      maxLines: 1,
    );
    headerPainter.layout(minWidth: w - 48, maxWidth: w - 48);
    headerPainter.paint(canvas, Offset(24, 8 + (_compactHeaderHeight - headerPainter.height) / 2));

    final codec = await ui.instantiateImageCodec(slideImage);
    final frame = await codec.getNextFrame();
    final img = frame.image;

    final imgAreaTop = 8 + _compactHeaderHeight + 4;
    final imgAreaHeight = h - imgAreaTop - 12;
    final imgAreaWidth = w - 16;
    final imgScale = min<double>(imgAreaWidth / img.width, imgAreaHeight / img.height);
    final drawW = img.width * imgScale;
    final drawH = img.height * imgScale;
    final drawX = 8 + (imgAreaWidth - drawW) / 2;
    final drawY = imgAreaTop + (imgAreaHeight - drawH) / 2;

    canvas.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
      Rect.fromLTWH(drawX, drawY, drawW, drawH),
      Paint()..filterQuality = FilterQuality.high,
    );

    final picture = recorder.endRecording();
    final finalImage = await picture.toImage(_thumbnailWidth, _thumbnailHeight);
    final byteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  static Future<Uint8List?> _generatePdfThumbnail(
    String filePath, {
    ParsedDocumentEntity? cachedDocument,
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
      );
    } on PlatformException catch (e, st) {
      _log.e('PDF thumbnail render failed: ${e.code}',
          error: e, stackTrace: st);
    } catch (e, st) {
      _log.e('PDF thumbnail render failed', error: e, stackTrace: st);
    }

    return _createPlaceholderThumbnail(
      label: 'PDF',
      accent: ThumbnailColors.pdfRed,
      caption: 'Unable to render preview',
    );
  }

  static Future<Uint8List> _createPdfPreview({
    required Uint8List pageBytes,
    required int pageCount,
    int? wordCount,
    int? lineCount,
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
        canvas.drawRRect(
            cardRect, ui.Paint()..color = const ui.Color(0xFFFBFCFA));

        final headerHeight = _compactHeaderHeight;
        final headerRect = ui.RRect.fromRectAndCorners(
          ui.Rect.fromLTWH(18, 18, size.width - 36, headerHeight),
          topLeft: const ui.Radius.circular(22),
          topRight: const ui.Radius.circular(22),
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
        );
      }

      final previewText = _trimPreviewText(fullText);
      if (previewText == null || previewText.isEmpty) {
        _log.w('Text thumbnail preview text empty for $filePath');
        return _createPlaceholderThumbnail(
          label: normalizedType.toUpperCase(),
          accent: _accentForType(normalizedType),
          caption: 'No readable text found',
        );
      }

      return _createTextDocumentPreview(
        text: previewText,
        fullText: fullText,
        accent: _accentForType(normalizedType),
        label: normalizedType.toUpperCase(),
      );
    } catch (e, st) {
      _log.e('Text thumbnail parse failed for $filePath',
          error: e, stackTrace: st);
      return _createPlaceholderThumbnail(
        label: normalizedType.toUpperCase(),
        accent: _accentForType(normalizedType),
        caption: 'Preview unavailable',
      );
    }
  }

  static Future<Uint8List?> _generateSpreadsheetThumbnail(
    String filePath,
    String normalizedType, {
    ParsedDocumentEntity? cachedDocument,
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
        );
      }

      return _createSpreadsheetPreview(
        sheets: sheets,
        accent: _accentForType(normalizedType),
        label: normalizedType.toUpperCase(),
      );
    } catch (e, st) {
      _log.e('Spreadsheet thumbnail parse failed for $filePath',
          error: e, stackTrace: st);
      return _createPlaceholderThumbnail(
        label: normalizedType.toUpperCase(),
        accent: _accentForType(normalizedType),
        caption: 'Preview unavailable',
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
      case 'txt':
        return await DocumentParserService.parseTXT(filePath);
      case 'rtf':
        return await DocumentParserService.parseRTF(filePath);
      case 'odt':
        return await DocumentParserService.parseODT(filePath);
      default:
        return null;
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
  }) {
    return _renderCanvas((canvas, size) {
      _paintShadowBackground(canvas, size, accent);

      final pageRect = ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(20, 20, size.width - 40, size.height - 40),
        const ui.Radius.circular(22),
      );
      canvas.drawRRect(
          pageRect, ui.Paint()..color = const ui.Color(0xFFF8F6F1));

      final headerHeight = _compactHeaderHeight;
      final headerRect = ui.RRect.fromRectAndCorners(
        ui.Rect.fromLTWH(20, 20, size.width - 40, headerHeight),
        topLeft: const ui.Radius.circular(22),
        topRight: const ui.Radius.circular(22),
      );
      _paintPreviewHeader(
        canvas,
        rect: headerRect.outerRect,
        color: _uiColor(accent),
        text: _buildReadingStats(fullText),
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

      _paintText(
        canvas,
        text: text,
        left: 44,
        top: 134,
        maxWidth: size.width - 88,
        maxLines: 16,
        style: const TextStyle(
          color: ui.Color(0xFF2B2B2B),
          fontSize: 19,
          height: 1.28,
          fontWeight: FontWeight.w400,
          fontFamily: 'Ubuntu',
        ),
      );
    });
  }

  static Future<Uint8List> _createSpreadsheetPreview({
    required List<dynamic> sheets,
    required ColorRgb accent,
    required String label,
  }) {
    return _renderCanvas((canvas, size) {
      _paintShadowBackground(canvas, size, accent);

      final cardRect = ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(18, 18, size.width - 36, size.height - 36),
        const ui.Radius.circular(22),
      );
      canvas.drawRRect(
          cardRect, ui.Paint()..color = const ui.Color(0xFFFBFCFA));

      final topBandRect = ui.RRect.fromRectAndCorners(
        ui.Rect.fromLTWH(18, 18, size.width - 36, _compactHeaderHeight),
        topLeft: const ui.Radius.circular(22),
        topRight: const ui.Radius.circular(22),
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

      final borderPaint = ui.Paint()
        ..color = const ui.Color(0xFFD6DDD2)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1.0;

      final headerFill = ui.Paint()..color = _uiColor(accent, alpha: 36);
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
            style: const TextStyle(
              color: ui.Color(0xFF2C332F),
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
  }) {
    return _renderCanvas((canvas, size) {
      _paintShadowBackground(canvas, size, accent);

      final cardRect = ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(26, 32, size.width - 52, size.height - 64),
        const ui.Radius.circular(26),
      );
      canvas.drawRRect(
          cardRect, ui.Paint()..color = const ui.Color(0xFFF9FAF8));

      final accentPaint = ui.Paint()..color = _uiColor(accent);
      canvas.drawCircle(ui.Offset(size.width / 2, 178), 52, accentPaint);

      _paintCenteredText(
        canvas,
        text: label,
        top: 250,
        maxWidth: size.width - 80,
        style: TextStyle(
          color: _uiColor(accent),
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
        style: const TextStyle(
          color: ui.Color(0xFF5D635F),
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

  static String _buildReadingStats(String text) {
    final words = RegExp(r'\S+').allMatches(text).length;
    final lines = text.split(RegExp(r'\r\n|\r|\n')).length;
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
      ui.RRect.fromRectAndCorners(
        rect,
        topLeft: const ui.Radius.circular(22),
        topRight: const ui.Radius.circular(22),
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
      'ppt' || 'pptx' || 'odp' => ThumbnailColors.pptOrange,
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
