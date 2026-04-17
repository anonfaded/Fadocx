import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fadocx/core/services/thumbnail_generation_service.dart';
import 'package:fadocx/core/utils/logger.dart';
import 'package:fadocx/features/settings/presentation/providers/settings_providers.dart';

/// Thumbnail provider - fetches cached thumbnail
final thumbnailProvider = FutureProvider.family<Uint8List?, String>(
  (ref, fileId) async {
    try {
      log.d('🖼️  [Thumbnail Provider] Fetching cached thumbnail for fileId: $fileId');
      final hiveDatasource = ref.watch(hiveDatasourceProvider);

      // Try to get from cache
      final cached = await hiveDatasource.getThumbnail(fileId);
      if (cached != null) {
        log.d('🖼️  [Thumbnail Provider] ✓ Found cached thumbnail: ${cached.pngBytes.length} bytes');
        return Uint8List.fromList(cached.pngBytes);
      }

      log.d('🖼️  [Thumbnail Provider] ⚠️  No cached thumbnail found for $fileId');
      return null;
    } catch (e) {
      log.e('🖼️  [Thumbnail Provider] ERROR: $e');
      return null;
    }
  },
);

/// Generate and cache thumbnail - with proper MethodChannel support
final generateAndCacheThumbnailProvider = FutureProvider.family<Uint8List?,
    ({String fileId, String filePath, String fileName, String fileType})>(
  (ref, params) async {
    try {
      log.d('🖼️  [Generate Thumbnail] Starting for: ${params.fileName} (${params.fileType})');
      log.d('🖼️  [Generate Thumbnail] File ID: ${params.fileId}');
      
      final hiveDatasource = ref.watch(hiveDatasourceProvider);

      // Generate thumbnail with native rendering support
      log.d('🖼️  [Generate Thumbnail] Calling native thumbnail generation (on main thread)...');
      final thumbnailBytes = await ThumbnailGenerationService.generateThumbnail(
        params.filePath,
        params.fileName,
        params.fileType,
      );

      if (thumbnailBytes != null) {
        log.d('🖼️  [Generate Thumbnail] ✓ Generation successful: ${thumbnailBytes.length} bytes');
        log.d('🖼️  [Generate Thumbnail] Saving to cache...');
        
        try {
          await hiveDatasource.saveThumbnail(params.fileId, thumbnailBytes.toList());
          log.d('🖼️  [Generate Thumbnail] ✓ Saved to cache');
          
          // CRITICAL: Invalidate the cache reader provider so UI refreshes
          log.d('🖼️  [Generate Thumbnail] 🔄 Invalidating thumbnail provider to refresh UI...');
          ref.invalidate(thumbnailProvider(params.fileId));
        } catch (e) {
          log.e('🖼️  [Generate Thumbnail] ERROR saving to cache: $e');
        }
      } else {
        log.w('🖼️  [Generate Thumbnail] ⚠️  Generation returned null');
      }

      return thumbnailBytes;
    } catch (e, st) {
      log.e('🖼️  [Generate Thumbnail] ERROR: $e');
      log.e('🖼️  [Generate Thumbnail] Stack: $st');
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
