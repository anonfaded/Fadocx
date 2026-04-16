import 'package:flutter/services.dart';
import 'package:fadocx/core/services/image_processing_service.dart';

/// Wrapper for isolate message — only image processing (OpenCV).
/// OCR must run on the main isolate because flutter_tesseract_ocr
/// accesses ServicesBinding which requires the Flutter binding.
class IsolateMessage {
  final RootIsolateToken rootIsolateToken;
  final String imagePath;

  IsolateMessage({
    required this.rootIsolateToken,
    required this.imagePath,
  });
}

/// Run OpenCV image processing in a background isolate.
/// Returns the processed image path (String?) — null if processing failed
/// but caller should still fall back to the original path for OCR.
Future<String?> processImageInBackgroundIsolate(
  IsolateMessage message,
) async {
  BackgroundIsolateBinaryMessenger.ensureInitialized(
    message.rootIsolateToken,
  );
  // ImageProcessingService uses path_provider (platform channel) which is
  // safe here because BackgroundIsolateBinaryMessenger is initialized above.
  return await ImageProcessingService.processImageFile(message.imagePath);
}
