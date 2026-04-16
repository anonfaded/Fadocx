import 'dart:async';
import 'package:flutter/services.dart';

/// Platform channel service for PDF operations using Android's native PdfRenderer
/// Much more stable and performant than pdfx package
class PdfPlatformService {
  static const MethodChannel _channel = MethodChannel(
    'com.fadseclab.fadocx/pdf',
  );

  /// Open a PDF file for rendering
  static Future<Map<String, dynamic>> openPdf(String filePath) async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'openPdf',
        {'filePath': filePath},
      );
      return {
        'pageCount': result?['pageCount'] ?? 0,
        'filePath': result?['filePath'] ?? filePath,
      };
    } catch (e) {
      throw Exception('Failed to open PDF: $e');
    }
  }

  /// Close a PDF file and free resources
  static Future<void> closePdf(String filePath) async {
    try {
      await _channel.invokeMethod('closePdf', {'filePath': filePath});
    } catch (e) {
      // Ignore close errors
    }
  }

  /// Get total page count of PDF file
  static Future<int> getPageCount(String filePath) async {
    try {
      final result = await _channel.invokeMethod<int>('getPageCount', {
        'filePath': filePath,
      });
      return result ?? 0;
    } catch (e) {
      throw Exception('Failed to get PDF page count: $e');
    }
  }

  /// Get page size in points (1/72 inch)
  static Future<Size> getPageSize(String filePath, int pageNumber) async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getPageSize',
        {
          'filePath': filePath,
          'pageNumber': pageNumber,
        },
      );
      return Size(
        (result?['width'] ?? 612).toDouble(),
        (result?['height'] ?? 792).toDouble(),
      );
    } catch (e) {
      // Return default US Letter size
      return const Size(612, 792);
    }
  }

  /// Render a specific page to PNG bytes at specified width
  /// Height is calculated automatically to maintain aspect ratio
  static Future<PdfPageRender> renderPage(
    String filePath,
    int pageNumber, {
    int width = 800,
  }) async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'renderPage',
        {
          'filePath': filePath,
          'pageNumber': pageNumber,
          'width': width,
        },
      );

      final bytes = result?['bytes'] as Uint8List?;
      if (bytes == null || bytes.isEmpty) {
        throw Exception('Failed to render page: no image data');
      }

      return PdfPageRender(
        bytes: bytes,
        width: (result?['width'] ?? width).toDouble(),
        height: (result?['height'] ?? 1000).toDouble(),
        pageNumber: (result?['pageNumber'] ?? pageNumber) as int,
      );
    } catch (e) {
      throw Exception('Failed to render page $pageNumber: $e');
    }
  }

  /// Extract text from a specific page (1-indexed)
  static Future<String> extractPageText(String filePath, int pageNumber) async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'extractPageText',
        {
          'filePath': filePath,
          'pageNumber': pageNumber,
        },
      );
      return result?['text'] ?? '';
    } catch (e) {
      throw Exception('Failed to extract page $pageNumber text: $e');
    }
  }

  /// Extract text with character positions for text selection overlay
  static Future<TextExtractionResult> extractTextWithPositions(
    String filePath,
    int pageNumber,
  ) async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'extractTextWithPositions',
        {
          'filePath': filePath,
          'pageNumber': pageNumber,
        },
      );

      final characters = (result?['characters'] as List<dynamic>?)?.map((c) {
            return PdfCharacter(
              text: c['text'] as String? ?? '',
              x: (c['x'] as num?)?.toDouble() ?? 0.0,
              y: (c['y'] as num?)?.toDouble() ?? 0.0,
              width: (c['width'] as num?)?.toDouble() ?? 0.0,
              height: (c['height'] as num?)?.toDouble() ?? 0.0,
              fontSize: (c['fontSize'] as num?)?.toDouble() ?? 12.0,
            );
          }).toList() ??
          [];

      return TextExtractionResult(
        text: result?['text'] as String? ?? '',
        characters: characters,
        pageNumber: pageNumber,
      );
    } catch (e) {
      throw Exception('Failed to extract text positions: $e');
    }
  }
}

/// Size in points
class Size {
  final double width;
  final double height;

  const Size(this.width, this.height);

  double get aspectRatio => width / height;
}

/// Rendered PDF page result
class PdfPageRender {
  final Uint8List bytes;
  final double width;
  final double height;
  final int pageNumber;

  PdfPageRender({
    required this.bytes,
    required this.width,
    required this.height,
    required this.pageNumber,
  });
}

/// Extracted text with positions
class TextExtractionResult {
  final String text;
  final List<PdfCharacter> characters;
  final int pageNumber;

  TextExtractionResult({
    required this.text,
    required this.characters,
    required this.pageNumber,
  });
}

/// Single character with PDF position (in PDF points)
class PdfCharacter {
  final String text;
  final double x;
  final double y;
  final double width;
  final double height;
  final double fontSize;

  PdfCharacter({
    required this.text,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.fontSize,
  });

  /// Convert PDF coordinates (bottom-left origin) to Flutter coordinates (top-left origin)
  /// given the page height in points
  PdfCharacter toFlutterCoordinates(double pageHeight) {
    return PdfCharacter(
      text: text,
      x: x,
      y: pageHeight - y - height, // Flip Y coordinate
      width: width,
      height: height,
      fontSize: fontSize,
    );
  }
}

/// Cache for rendered PDF page images
class PdfImageCache {
  final Map<String, Map<int, PdfPageRender>> _cache = {};
  static const int _maxCacheSize = 5; // Keep last 5 pages per PDF

  String _key(String filePath) => filePath;

  PdfPageRender? get(String filePath, int pageNumber) {
    return _cache[_key(filePath)]?[pageNumber];
  }

  void put(String filePath, int pageNumber, PdfPageRender render) {
    final key = _key(filePath);
    _cache[key] ??= {};

    final pdfCache = _cache[key]!;

    // Evict oldest if needed
    if (pdfCache.length >= _maxCacheSize && !pdfCache.containsKey(pageNumber)) {
      final oldest = pdfCache.keys.first;
      pdfCache.remove(oldest);
    }

    pdfCache[pageNumber] = render;
  }

  void clear(String filePath) {
    _cache.remove(_key(filePath));
  }

  void clearAll() => _cache.clear();
}
