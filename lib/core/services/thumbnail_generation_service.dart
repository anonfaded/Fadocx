import 'package:image/image.dart' as img;
import 'package:logger/logger.dart';
import 'dart:io';
import 'package:flutter/services.dart';

final log = Logger();

/// Service for generating file thumbnails with REAL document previews
/// Calls native rendering from main thread (MethodChannels don't work in isolates!)
class ThumbnailGenerationService {
  static const pdfChannel = MethodChannel('com.fadseclab.fadocx/pdf');
  static const docChannel = MethodChannel('com.fadseclab.fadocx/document_parser');

  /// Generate thumbnail on main thread (required for MethodChannel calls)
  static Future<Uint8List?> generateThumbnail(
    String filePath,
    String fileName,
    String fileType,
  ) async {
    try {
      log.d('🎨 [Thumbnail] Starting generation for: $fileName ($fileType)');
      log.d('🎨 [Thumbnail] File path: $filePath');
      
      // Check if file exists
      final file = File(filePath);
      if (!file.existsSync()) {
        log.e('🎨 [Thumbnail] ERROR: File does not exist at $filePath');
        return null;
      }
      
      final fileSizeKb = file.lengthSync() / 1024;
      log.d('🎨 [Thumbnail] File exists: ${fileSizeKb.toStringAsFixed(1)} KB');

      // Generate appropriate thumbnail based on type
      final normalizedType = fileType.toLowerCase();
      
      return switch (normalizedType) {
        'pdf' => await _generatePdfThumbnail(filePath, fileName),
        'doc' || 'docx' => await _generateDocThumbnail(filePath, fileName),
        'xls' || 'xlsx' => await _generateExcelThumbnail(filePath, fileName),
        'ppt' || 'pptx' => _generatePptThumbnail(fileName),
        'txt' || 'rtf' || 'odt' => _generateTextThumbnail(fileName),
        'csv' || 'ods' => _generateSheetThumbnail(fileName),
        _ => _createColoredPlaceholder(fileType, 'FILE', Colors.gray),
      };
    } catch (e, st) {
      log.e('🎨 [Thumbnail] ERROR: $e');
      log.e('🎨 [Thumbnail] Stack: $st');
      return null;
    }
  }

  /// Generate PDF thumbnail using native PDF renderer
  static Future<Uint8List?> _generatePdfThumbnail(String filePath, String fileName) async {
    try {
      log.d('🎨 [PDF] Calling native PDF renderPage...');
      
      final result = await pdfChannel.invokeMethod<Map<dynamic, dynamic>>(
        'renderPage',
        <String, dynamic>{
          'filePath': filePath,
          'pageNumber': 0,
          'width': 140, // Small width for thumbnail
        },
      );

      if (result != null && result.containsKey('bytes')) {
        final bytes = result['bytes'];
        if (bytes is Uint8List && bytes.isNotEmpty) {
          log.d('🎨 [PDF] ✓ Native PDF render successful: ${bytes.length} bytes');
          return bytes;
        }
      }
      
      log.w('🎨 [PDF] ⚠️  Native render failed or returned empty');
    } on PlatformException catch (e) {
      log.e('🎨 [PDF] Platform error: ${e.code} - ${e.message}');
    } catch (e) {
      log.e('🎨 [PDF] Error calling native PDF renderer: $e');
    }

    // Fallback to colored placeholder
    log.d('🎨 [PDF] Falling back to colored placeholder');
    return _createColoredPlaceholder('pdf', '📄 PDF', Colors.pdfRed);
  }

  /// Generate Word document thumbnail using document parser
  static Future<Uint8List?> _generateDocThumbnail(String filePath, String fileName) async {
    try {
      log.d('🎨 [Word] Parsing document: $fileName');
      
      final result = await docChannel.invokeMethod<Map<dynamic, dynamic>>(
        'parseDocument',
        <String, dynamic>{
          'filePath': filePath,
          'format': 'DOC',
        },
      );

      if (result != null && result.containsKey('textContent')) {
        final text = result['textContent'] as String?;
        if (text != null && text.isNotEmpty) {
          log.d('🎨 [Word] ✓ Document parsed: ${text.length} characters');
          return _createDocumentPreview(text, Colors.docBlue, '📝');
        }
      }
    } on PlatformException catch (e) {
      log.e('🎨 [Word] Platform error: ${e.code}');
    } catch (e) {
      log.e('🎨 [Word] Error parsing: $e');
    }

    log.d('🎨 [Word] Falling back to colored placeholder');
    return _createColoredPlaceholder('docx', '📝 WORD', Colors.docBlue);
  }

  /// Generate Excel spreadsheet thumbnail
  static Future<Uint8List?> _generateExcelThumbnail(String filePath, String fileName) async {
    try {
      log.d('🎨 [Excel] Parsing spreadsheet: $fileName');
      
      final result = await docChannel.invokeMethod<Map<dynamic, dynamic>>(
        'parseDocument',
        <String, dynamic>{
          'filePath': filePath,
          'format': 'XLSX',
        },
      );

      if (result != null && result.containsKey('sheets')) {
        final sheets = result['sheets'] as List?;
        if (sheets != null && sheets.isNotEmpty) {
          log.d('🎨 [Excel] ✓ Spreadsheet parsed: ${sheets.length} sheets');
          return _createSpreadsheetPreview(sheets, Colors.excelGreen);
        }
      }
    } on PlatformException catch (e) {
      log.e('🎨 [Excel] Platform error: ${e.code}');
    } catch (e) {
      log.e('🎨 [Excel] Error parsing: $e');
    }

    log.d('🎨 [Excel] Falling back to colored placeholder');
    return _createColoredPlaceholder('xlsx', '📊 EXCEL', Colors.excelGreen);
  }

  /// Generate PowerPoint thumbnail
  static Uint8List _generatePptThumbnail(String fileName) {
    log.d('🎨 [PowerPoint] Creating placeholder (PPT rendering not yet supported)');
    return _createColoredPlaceholder('pptx', '🎬 SLIDES', Colors.pptOrange);
  }

  /// Generate text document thumbnail
  static Uint8List _generateTextThumbnail(String fileName) {
    log.d('🎨 [Text] Creating text document placeholder');
    return _createColoredPlaceholder('txt', '📄 TEXT', Colors.textBlue);
  }

  /// Generate spreadsheet thumbnail
  static Uint8List _generateSheetThumbnail(String fileName) {
    log.d('🎨 [Sheet] Creating sheet placeholder');
    return _createColoredPlaceholder('csv', '📑 SHEET', Colors.sheetGreen);
  }

  /// Create colored placeholder for unsupported formats
  static Uint8List _createColoredPlaceholder(
    String type,
    String label,
    ColorRgb color,
  ) {
    try {
      final image = img.Image(width: 200, height: 280, numChannels: 4);

      // Fill with base color
      img.fillRect(
        image,
        x1: 0,
        y1: 0,
        x2: 200,
        y2: 280,
        color: img.ColorRgba8(color.r, color.g, color.b, 255),
      );

      // Add gradient darkening at bottom
      for (int y = 140; y < 280; y++) {
        final intensity = ((y - 140) / 140.0).clamp(0, 1);
        final factor = 0.7 + (intensity * 0.3);
        
        for (int x = 0; x < 200; x++) {
          final r = (color.r * factor).toInt().clamp(0, 255);
          final g = (color.g * factor).toInt().clamp(0, 255);
          final b = (color.b * factor).toInt().clamp(0, 255);
          image.setPixelRgba(x, y, r, g, b, 255);
        }
      }

      // Border
      img.drawRect(
        image,
        x1: 0,
        y1: 0,
        x2: 199,
        y2: 279,
        color: img.ColorRgba8(255, 255, 255, 100),
      );

      final bytes = img.encodePng(image);
      log.d('🎨 [Placeholder] Created: ${bytes.length} bytes');
      return bytes;
    } catch (e) {
      log.e('🎨 [Placeholder] Error: $e');
      return _createMinimalPlaceholder(color);
    }
  }

  /// Create document preview from extracted text
  static Uint8List _createDocumentPreview(
    String text,
    ColorRgb color,
    String icon,
  ) {
    try {
      final image = img.Image(width: 200, height: 280, numChannels: 4);

      // Fill background
      img.fillRect(
        image,
        x1: 0,
        y1: 0,
        x2: 200,
        y2: 280,
        color: img.ColorRgba8(color.r, color.g, color.b, 255),
      );

      // Add text representation (visual indicator)
      img.drawRect(
        image,
        x1: 20,
        y1: 60,
        x2: 180,
        y2: 240,
        color: img.ColorRgba8(255, 255, 255, 30),
      );

      // Border
      img.drawRect(
        image,
        x1: 0,
        y1: 0,
        x2: 199,
        y2: 279,
        color: img.ColorRgba8(255, 255, 255, 120),
      );

      final bytes = img.encodePng(image);
      log.d('🎨 [DocPreview] Created: ${bytes.length} bytes');
      return bytes;
    } catch (e) {
      log.e('🎨 [DocPreview] Error: $e');
      return _createMinimalPlaceholder(color);
    }
  }

  /// Create spreadsheet preview
  static Uint8List _createSpreadsheetPreview(List<dynamic> sheets, ColorRgb color) {
    try {
      final image = img.Image(width: 200, height: 280, numChannels: 4);

      // Fill background
      img.fillRect(
        image,
        x1: 0,
        y1: 0,
        x2: 200,
        y2: 280,
        color: img.ColorRgba8(color.r, color.g, color.b, 255),
      );

      // Draw grid pattern to show it's a spreadsheet
      for (int i = 0; i < 6; i++) {
        final x = 30 + (i * 25);
        img.drawLine(
          image,
          x1: x,
          y1: 80,
          x2: x,
          y2: 230,
          color: img.ColorRgba8(255, 255, 255, 40),
        );
      }

      for (int i = 0; i < 6; i++) {
        final y = 80 + (i * 25);
        img.drawLine(
          image,
          x1: 30,
          y1: y,
          x2: 180,
          y2: y,
          color: img.ColorRgba8(255, 255, 255, 40),
        );
      }

      // Border
      img.drawRect(
        image,
        x1: 0,
        y1: 0,
        x2: 199,
        y2: 279,
        color: img.ColorRgba8(255, 255, 255, 120),
      );

      final bytes = img.encodePng(image);
      log.d('🎨 [SheetPreview] Created: ${bytes.length} bytes');
      return bytes;
    } catch (e) {
      log.e('🎨 [SheetPreview] Error: $e');
      return _createMinimalPlaceholder(color);
    }
  }

  /// Minimal fallback placeholder
  static Uint8List _createMinimalPlaceholder(ColorRgb color) {
    final image = img.Image(width: 200, height: 280, numChannels: 4);
    img.fillRect(
      image,
      x1: 0,
      y1: 0,
      x2: 200,
      y2: 280,
      color: img.ColorRgba8(color.r, color.g, color.b, 255),
    );
    return img.encodePng(image);
  }
}

/// Color definitions
class ColorRgb {
  final int r, g, b;
  ColorRgb(this.r, this.g, this.b);
}

class Colors {
  static final pdfRed = ColorRgb(220, 53, 69);
  static final docBlue = ColorRgb(41, 128, 185);
  static final excelGreen = ColorRgb(39, 174, 96);
  static final pptOrange = ColorRgb(230, 126, 34);
  static final textBlue = ColorRgb(52, 152, 219);
  static final sheetGreen = ColorRgb(46, 204, 113);
  static final gray = ColorRgb(149, 165, 166);
}
