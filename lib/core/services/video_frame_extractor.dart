import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

/// Service for extracting video frames for thumbnail generation
/// Uses Android MediaMetadataRetriever via method channel
class VideoFrameExtractor {
  static const _platform = MethodChannel('com.fadseclab.fadocx/video');
  static final _log = Logger();

  /// Extract first frame (or frame at specified time) from video file
  /// Returns PNG-encoded image bytes, or null if extraction fails
  /// 
  /// [filePath]: Path to video file
  /// [timeUs]: Time in microseconds (default 0 = first frame)
  static Future<Uint8List?> extractFrame(String filePath, {int timeUs = 0}) async {
    try {
      final result = await _platform.invokeMethod<Uint8List>(
        'extractVideoFrame',
        {
          'filePath': filePath,
          'timeUs': timeUs,
        },
      );
      return result;
    } on PlatformException catch (e) {
      _log.e('Failed to extract video frame from $filePath: ${e.message}');
      return null;
    } catch (e) {
      _log.e('Unexpected error extracting video frame: $e');
      return null;
    }
  }

  /// Decode PNG bytes into ui.Image for rendering
  /// This is cached by the caller via Riverpod providers
  static Future<ui.Image?> decodeFrameImage(Uint8List pngBytes) async {
    try {
      final codec = await ui.instantiateImageCodec(pngBytes);
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (e) {
      _log.e('Failed to decode video frame image: $e');
      return null;
    }
  }
}
