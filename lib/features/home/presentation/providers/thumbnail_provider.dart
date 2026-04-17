import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fadocx/core/services/thumbnail_generation_service.dart';
import 'package:fadocx/core/utils/logger.dart';
import 'package:fadocx/features/settings/presentation/providers/settings_providers.dart';

/// Thumbnail provider - only calls once per file ID, caches result
final thumbnailProvider = FutureProvider.family<Uint8List?, String>(
  (ref, fileId) async {
    try {
      final hiveDatasource = ref.watch(hiveDatasourceProvider);

      // Try to get from cache first
      final cached = await hiveDatasource.getThumbnail(fileId);
      if (cached != null) {
        return Uint8List.fromList(cached.pngBytes);
      }

      // No cached thumbnail - return null and let UI show placeholder
      return null;
    } catch (e) {
      log.e('Error fetching thumbnail: $e');
      return null;
    }
  },
);

/// Generate and cache thumbnail - call ONCE from UI, then forget
final generateAndCacheThumbnailProvider = FutureProvider.family<Uint8List?,
    ({String fileId, String filePath, String fileName, String fileType})>(
  (ref, params) async {
    try {
      final hiveDatasource = ref.watch(hiveDatasourceProvider);

      // Generate thumbnail
      final thumbnailBytes = await ThumbnailGenerationService.generateThumbnail(
        params.filePath,
        params.fileName,
        params.fileType,
      );

      if (thumbnailBytes != null) {
        // Cache it
        await hiveDatasource.saveThumbnail(
            params.fileId, thumbnailBytes.toList());
      }

      return thumbnailBytes;
    } catch (e) {
      log.e('Error generating thumbnail: $e');
      return null;
    }
  },
);
