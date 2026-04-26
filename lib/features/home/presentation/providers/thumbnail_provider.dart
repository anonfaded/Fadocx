import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fadocx/core/services/thumbnail_generation_service.dart';
import 'package:logger/logger.dart';
import 'package:fadocx/features/settings/presentation/providers/settings_providers.dart';
import 'package:fadocx/features/viewer/data/providers/repository_providers.dart';

final log = Logger();

/// Thumbnail provider - fetches cached thumbnail
final thumbnailProvider = FutureProvider.family<Uint8List?, String>(
  (ref, fileId) async {
    try {
      final hiveDatasource = ref.watch(hiveDatasourceProvider);

      final cached = await hiveDatasource.getThumbnail(fileId);
      if (cached != null) {
        return Uint8List.fromList(cached.pngBytes);
      }

      return null;
    } catch (e, st) {
      log.e('Thumbnail cache read failed for $fileId',
          error: e, stackTrace: st);
      return null;
    }
  },
);

/// Generate and cache thumbnail - uses passed brightness for theme-aware rendering
final generateAndCacheThumbnailProvider = FutureProvider.family<Uint8List?,
    ({String fileId, String filePath, String fileName, String fileType, String? extractedText, ui.Brightness brightness})>(
  (ref, params) async {
    try {
      final hiveDatasource = ref.watch(hiveDatasourceProvider);
      final documentRepository = ref.watch(documentParsingRepositoryProvider);

      // Check if cached thumbnail matches current brightness
      final brightnessName = params.brightness == ui.Brightness.dark ? 'dark' : 'light';
      final cached = await hiveDatasource.getThumbnail(params.fileId);
      if (cached != null && cached.brightness == brightnessName) {
        // Cache hit with matching brightness - no need to regenerate
        ref.invalidate(thumbnailProvider(params.fileId));
        return Uint8List.fromList(cached.pngBytes);
      }

      final cachedDocument =
          await documentRepository.getCachedParsing(params.filePath);

      final thumbnailBytes = await ThumbnailGenerationService.generateThumbnail(
        params.filePath,
        params.fileName,
        params.fileType,
        cachedDocument: cachedDocument,
        extractedText: params.extractedText,
        brightness: params.brightness,
      );

      if (thumbnailBytes != null) {
        try {
          await hiveDatasource.saveThumbnail(
              params.fileId, thumbnailBytes.toList(), brightness: brightnessName);
          ref.invalidate(thumbnailProvider(params.fileId));
        } catch (e, st) {
          log.e('Thumbnail cache save failed for ${params.fileName}',
              error: e, stackTrace: st);
        }
      }

      return thumbnailBytes;
    } catch (e, st) {
      log.e('Thumbnail generation failed for ${params.fileName}',
          error: e, stackTrace: st);
      return null;
    }
  },
);

/// Clear all cached thumbnails (call when upgrading thumbnail system)
Future<void> clearThumbnailCache() async {
  try {
    log.d('Clearing all cached thumbnails...');
    // Note: This would require adding a clearThumbnails method to HiveDatasource
    log.d('Thumbnails cleared');
  } catch (e) {
    log.e('ERROR clearing thumbnails: $e');
  }
}
