import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:fadocx/core/utils/logger.dart';

/// Service for generating file thumbnails offline
/// Creates colored placeholders with visual distinction by file type
class ThumbnailGenerationService {
  static const int _thumbnailWidth = 200;
  static const int _thumbnailHeight = 280;

  /// Generate thumbnail for any file type
  /// Returns PNG bytes or null if generation fails
  static Future<Uint8List?> generateThumbnail(
    String filePath,
    String fileName,
    String fileType,
  ) async {
    try {
      log.d('Generating thumbnail for: $fileName ($fileType)');

      // Create a colored background based on file type
      final bgColor = _getColorForFileType(fileType);

      // Create image with solid color
      final image = img.Image(
        width: _thumbnailWidth,
        height: _thumbnailHeight,
        numChannels: 4,
      );

      // Fill with background color
      img.fillRect(
        image,
        x1: 0,
        y1: 0,
        x2: _thumbnailWidth,
        y2: _thumbnailHeight,
        color: bgColor,
      );

      // Add subtle border
      img.drawRect(
        image,
        x1: 0,
        y1: 0,
        x2: _thumbnailWidth - 1,
        y2: _thumbnailHeight - 1,
        color: img.ColorRgba8(255, 255, 255, 80),
      );

      // Convert to PNG
      final pngBytes = img.encodePng(image);
      log.d('Thumbnail generated: ${pngBytes.length} bytes for $fileName');

      return pngBytes;
    } catch (e) {
      log.e('Error generating thumbnail for $fileName: $e');
      return null;
    }
  }

  /// Get color for file type background
  static img.ColorRgba8 _getColorForFileType(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        // PDF red
        return img.ColorRgba8(220, 53, 69, 255);
      case 'doc':
      case 'docx':
      case 'odt':
      case 'rtf':
      case 'txt':
        // Word blue
        return img.ColorRgba8(41, 128, 185, 255);
      case 'xlsx':
      case 'xls':
      case 'ods':
      case 'csv':
        // Excel green
        return img.ColorRgba8(39, 174, 96, 255);
      case 'ppt':
      case 'pptx':
      case 'odp':
        // PowerPoint orange
        return img.ColorRgba8(230, 126, 34, 255);
      default:
        // Default gray
        return img.ColorRgba8(149, 165, 166, 255);
    }
  }
}
