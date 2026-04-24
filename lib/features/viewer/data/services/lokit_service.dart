import 'package:flutter/services.dart';

class LOKitService {
  static const _channel = MethodChannel('com.fadseclab.fadocx/lokit');

  static bool _initialized = false;

  static Future<bool> init() async {
    if (_initialized) return true;
    final result = await _channel.invokeMethod<bool>('init');
    _initialized = result ?? false;
    return _initialized;
  }

  static Future<Map<String, dynamic>?> loadDocument(String filePath) async {
    final result = await _channel.invokeMethod<Map>('loadDocument', {
      'filePath': filePath,
    });
    return result?.cast<String, dynamic>();
  }

  static Future<Uint8List?> renderPage({
    int part = 0,
    int width = 800,
    int height = 1200,
  }) async {
    final result = await _channel.invokeMethod<Map>('renderPage', {
      'part': part,
      'width': width,
      'height': height,
    });
    if (result == null) return null;
    return result['bytes'] as Uint8List;
  }

  static Future<Uint8List?> renderPageFit({
    int part = 0,
    int maxWidth = 1080,
    int maxHeight = 1920,
  }) async {
    final result = await _channel.invokeMethod<Map>('renderPageFit', {
      'part': part,
      'maxWidth': maxWidth,
      'maxHeight': maxHeight,
    });
    if (result == null) return null;
    return result['bytes'] as Uint8List;
  }

  static Future<Map<String, dynamic>?> getDocumentInfo() async {
    final result = await _channel.invokeMethod<Map>('getDocumentInfo');
    return result?.cast<String, dynamic>();
  }

  static Future<Uint8List?> renderPageHighQuality({
    int part = 0,
    int maxWidth = 1080,
    int maxHeight = 1920,
    double scale = 2.0,
  }) async {
    try {
      final result = await _channel.invokeMethod<Map>(
        'renderPageHighQuality',
        {
          'part': part,
          'maxWidth': maxWidth,
          'maxHeight': maxHeight,
          'scale': scale,
        },
      );
      if (result == null) return null;
      return result['bytes'] as Uint8List;
    } on PlatformException {
      return null;
    }
  }


  static Future<String> extractText() async {
    try {
      final result = await _channel.invokeMethod<String>('extractText');
      return result ?? '';
    } on PlatformException {
      return '';
    }
  }

  static Future<String> extractPartText({int part = 0}) async {
    try {
      final result = await _channel.invokeMethod<String>('extractPartText', {
        'part': part,
      });
      return result ?? '';
    } on PlatformException {
      return '';
    }
  }

  static Future<int> getPageCount() async {
    try {
      final result = await _channel.invokeMethod<int>('getPageCount');
      return result ?? 0;
    } on PlatformException {
      return 0;
    }
  }

  static Future<Uint8List?> renderTextPage({
    int page = 0,
    int maxWidth = 1080,
    int maxHeight = 1920,
    double scale = 2.0,
  }) async {
    try {
      final result = await _channel.invokeMethod<Map>(
        'renderTextPage',
        {'page': page, 'maxWidth': maxWidth, 'maxHeight': maxHeight, 'scale': scale},
      );
      if (result == null) return null;
      return result['bytes'] as Uint8List;
    } on PlatformException {
      return null;
    }
  }

  static Future<Uint8List?> renderThumbnail({
    required String filePath,
    int part = 0,
    int width = 400,
    int height = 460,
  }) async {
    try {
      final loadResult = await loadDocument(filePath);
      if (loadResult == null) return null;
      final pngBytes = await renderPageFit(part: part, maxWidth: width, maxHeight: height);
      await closeDocument();
      return pngBytes;
    } on PlatformException {
      return null;
    }
  }
  static Future<bool> closeDocument() async {
    final result = await _channel.invokeMethod<bool>('closeDocument');
    return result ?? false;
  }

  static Future<bool> destroy() async {
    _initialized = false;
    final result = await _channel.invokeMethod<bool>('destroy');
    return result ?? false;
  }

  static String getDocTypeName(int type) {
    switch (type) {
      case 0:
        return 'Text Document';
      case 1:
        return 'Spreadsheet';
      case 2:
        return 'Presentation';
      case 3:
        return 'Drawing';
      default:
        return 'Other';
    }
  }
}
