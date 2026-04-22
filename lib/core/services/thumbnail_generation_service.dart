import 'dart:io';
import 'dart:ui' as ui;

import 'package:fadocx/features/viewer/data/services/document_parser_service.dart';
import 'package:flutter/painting.dart';
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

  static final Logger _log = Logger();

  static Future<Uint8List?> generateThumbnail(
    String filePath,
    String fileName,
    String fileType,
  ) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        _log.w('Thumbnail skipped, file missing: $filePath');
        return null;
      }

      final normalizedType = fileType.toLowerCase();

      return switch (normalizedType) {
        'pdf' => _generatePdfThumbnail(filePath),
        'doc' || 'docx' || 'txt' || 'rtf' || 'odt' =>
          _generateTextThumbnail(filePath, normalizedType),
        'xls' || 'xlsx' || 'csv' || 'ods' =>
          _generateSpreadsheetThumbnail(filePath, normalizedType),
        'ppt' || 'pptx' || 'odp' => _createPlaceholderThumbnail(
          label: 'SLIDES',
          accent: ThumbnailColors.pptOrange,
          caption: 'Preview coming soon',
        ),
        _ => _createPlaceholderThumbnail(
          label: normalizedType.toUpperCase(),
          accent: ThumbnailColors.gray,
          caption: fileName,
        ),
      };
    } catch (e, st) {
      _log.e('Thumbnail generation failed for $fileName', error: e, stackTrace: st);
      return null;
    }
  }

  static Future<Uint8List?> _generatePdfThumbnail(String filePath) async {
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

      return _createPdfPreview(pageBytes: bytes, pageCount: pageCount);
    } on PlatformException catch (e, st) {
      _log.e('PDF thumbnail render failed: ${e.code}', error: e, stackTrace: st);
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
        canvas.drawRRect(cardRect, ui.Paint()..color = const ui.Color(0xFFFBFCFA));

        final headerHeight = 68.0;
        final headerRect = ui.RRect.fromRectAndCorners(
          ui.Rect.fromLTWH(18, 18, size.width - 36, headerHeight),
          topLeft: const ui.Radius.circular(22),
          topRight: const ui.Radius.circular(22),
        );
        canvas.drawRRect(headerRect, ui.Paint()..color = _uiColor(ThumbnailColors.pdfRed));

        final pageLabel = pageCount == 1 ? 'page' : 'pages';
        _paintCenteredText(
          canvas,
          text: 'PDF \u2022 $pageCount $pageLabel',
          top: 37,
          maxWidth: size.width - 72,
          style: const TextStyle(
            color: ui.Color(0xFFFDFDFD),
            fontSize: 21,
            fontWeight: FontWeight.w600,
            fontFamily: 'Ubuntu',
          ),
        );

        final imageTop = 18.0 + headerHeight;
        final imageAreaHeight = size.height - 36 - headerHeight;
        final imageAreaWidth = size.width - 36;

        final scaleX = imageAreaWidth / pageImage.width;
        final scaleY = imageAreaHeight / pageImage.height;
        final scale = scaleX < scaleY ? scaleX : scaleY;

        final drawWidth = pageImage.width * scale;
        final drawHeight = pageImage.height * scale;
        final drawLeft = 18 + (imageAreaWidth - drawWidth) / 2;
        final drawTop = imageTop + (imageAreaHeight - drawHeight) / 2;

        canvas.drawImageRect(
          pageImage,
          ui.Rect.fromLTWH(0, 0, pageImage.width.toDouble(), pageImage.height.toDouble()),
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
    String normalizedType,
  ) async {
    try {
      final text = await _extractTextPreview(filePath, normalizedType);
      if (text == null || text.trim().isEmpty) {
        _log.w('Text thumbnail fallback for $filePath');
        return _createPlaceholderThumbnail(
          label: normalizedType.toUpperCase(),
          accent: _accentForType(normalizedType),
          caption: 'No readable text found',
        );
      }

      return _createTextDocumentPreview(
        text: text,
        accent: _accentForType(normalizedType),
        label: normalizedType.toUpperCase(),
      );
    } catch (e, st) {
      _log.e('Text thumbnail parse failed for $filePath', error: e, stackTrace: st);
      return _createPlaceholderThumbnail(
        label: normalizedType.toUpperCase(),
        accent: _accentForType(normalizedType),
        caption: 'Preview unavailable',
      );
    }
  }

  static Future<Uint8List?> _generateSpreadsheetThumbnail(
    String filePath,
    String normalizedType,
  ) async {
    try {
      final sheets = await _extractSheetPreview(filePath, normalizedType);
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
      _log.e('Spreadsheet thumbnail parse failed for $filePath', error: e, stackTrace: st);
      return _createPlaceholderThumbnail(
        label: normalizedType.toUpperCase(),
        accent: _accentForType(normalizedType),
        caption: 'Preview unavailable',
      );
    }
  }

  static Future<String?> _extractTextPreview(
    String filePath,
    String normalizedType,
  ) async {
    switch (normalizedType) {
      case 'doc':
        final result = await docChannel.invokeMethod<Map<dynamic, dynamic>>(
          'parseDocument',
          <String, dynamic>{'filePath': filePath, 'format': 'DOC'},
        );
        return _trimPreviewText(result?['textContent'] as String?);
      case 'docx':
        return _trimPreviewText(await DocumentParserService.parseDOCX(filePath));
      case 'txt':
        return _trimPreviewText(await DocumentParserService.parseTXT(filePath));
      case 'rtf':
        return _trimPreviewText(await DocumentParserService.parseRTF(filePath));
      case 'odt':
        return _trimPreviewText(await DocumentParserService.parseODT(filePath));
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

    final normalized = value.replaceAll(RegExp(r'\s+'), ' ').trim();
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
    required ColorRgb accent,
    required String label,
  }) {
    return _renderCanvas((canvas, size) {
      _paintShadowBackground(canvas, size, accent);

      final pageRect = ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(20, 20, size.width - 40, size.height - 40),
        const ui.Radius.circular(22),
      );
      canvas.drawRRect(pageRect, ui.Paint()..color = const ui.Color(0xFFF8F6F1));

      final headerHeight = 78.0;
      final headerRect = ui.RRect.fromRectAndCorners(
        ui.Rect.fromLTWH(20, 20, size.width - 40, headerHeight),
        topLeft: const ui.Radius.circular(22),
        topRight: const ui.Radius.circular(22),
      );
      canvas.drawRRect(headerRect, ui.Paint()..color = _uiColor(accent));

      final stats = _buildReadingStats(text);
      _paintCenteredText(
        canvas,
        text: stats,
        top: 42,
        maxWidth: size.width - 80,
        style: const TextStyle(
          color: ui.Color(0xFFFDFDFD),
          fontSize: 22,
          fontWeight: FontWeight.w600,
          fontFamily: 'Ubuntu',
        ),
      );

      _paintText(
        canvas,
        text: label,
        left: 44,
        top: 112,
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
        top: 146,
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
      canvas.drawRRect(cardRect, ui.Paint()..color = const ui.Color(0xFFFBFCFA));

      final topBandRect = ui.RRect.fromRectAndCorners(
        ui.Rect.fromLTWH(18, 18, size.width - 36, 68),
        topLeft: const ui.Radius.circular(22),
        topRight: const ui.Radius.circular(22),
      );
      canvas.drawRRect(topBandRect, ui.Paint()..color = _uiColor(accent));

      final firstSheet = sheets.first;
      final sheetName =
          (firstSheet is Map ? firstSheet['name'] : null)?.toString() ?? 'Sheet1';
      final rows = _extractSheetRows(firstSheet);
      final visibleRows = rows.take(_sheetPreviewRows).toList();
      final visibleColCount = visibleRows.fold<int>(
        0,
        (current, row) => row.length > current ? row.length : current,
      ).clamp(1, _sheetPreviewCols);
      final dataRowCount = visibleRows.isEmpty ? 6 : visibleRows.length;

      _paintCenteredText(
        canvas,
        text: '$label \u2022 $sheetName \u2022 $dataRowCount rows',
        top: 37,
        maxWidth: size.width - 72,
        style: const TextStyle(
          color: ui.Color(0xFFFDFDFD),
          fontSize: 19,
          fontWeight: FontWeight.w600,
          fontFamily: 'Ubuntu',
        ),
      );

      final gridLeft = 18.0;
      final gridTop = 92.0;
      final gridWidth = size.width - 36;
      final gridHeight = size.height - 116;
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
      canvas.drawRRect(cardRect, ui.Paint()..color = const ui.Color(0xFFF9FAF8));

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
    final minutes = words == 0 ? 0 : (words / 220).ceil();
    final minuteLabel = minutes == 1 ? 'min' : 'mins';
    return '$words words \u2022 ${minutes == 0 ? '<1' : minutes} $minuteLabel read';
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
