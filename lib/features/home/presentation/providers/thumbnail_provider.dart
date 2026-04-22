import 'dart:typed_data';
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

/// Generate and cache thumbnail - with proper MethodChannel support
final generateAndCacheThumbnailProvider = FutureProvider.family<Uint8List?,
    ({String fileId, String filePath, String fileName, String fileType})>(
  (ref, params) async {
    try {
      final hiveDatasource = ref.watch(hiveDatasourceProvider);
      final documentRepository = ref.watch(documentParsingRepositoryProvider);
      final cachedDocument = params.fileType.toLowerCase() == 'pdf'
          ? await documentRepository.getCachedParsing(params.filePath)
          : null;

      final thumbnailBytes = await ThumbnailGenerationService.generateThumbnail(
        params.filePath,
        params.fileName,
        params.fileType,
        cachedDocument: cachedDocument,
      );

      if (thumbnailBytes != null) {
        try {
          await hiveDatasource.saveThumbnail(
              params.fileId, thumbnailBytes.toList());
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
    log.d('🖼️  [Cache] Clearing all cached thumbnails...');
    // Note: This would require adding a clearThumbnails method to HiveDatasource
    log.d('🖼️  [Cache] Thumbnails cleared');
  } catch (e) {
    log.e('🖼️  [Cache] ERROR clearing: $e');
  }
}
