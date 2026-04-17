import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fadocx/core/services/thumbnail_generation_service.dart';
import 'package:fadocx/core/utils/logger.dart';
import 'package:fadocx/features/settings/presentation/providers/settings_providers.dart';

/// Thumbnail provider for a specific file
/// Fetches from cache or generates on demand
final thumbnailProvider = FutureProvider.family<Uint8List?, String>(
  (ref, fileId) async {
    try {
      final hiveDatasource = ref.watch(hiveDatasourceProvider);

      // Try to get from cache first
      final cached = await hiveDatasource.getThumbnail(fileId);
      if (cached != null) {
        log.d('Thumbnail cache hit for: $fileId');
        return Uint8List.fromList(cached.pngBytes);
      }

      // Cache miss - will be handled by screen to generate on demand
      log.d('Thumbnail cache miss for: $fileId');
      return null;
    } catch (e) {
      log.e('Error fetching thumbnail: $e');
      return null;
    }
  },
);

/// Family provider for generating and caching thumbnails
final generateThumbnailProvider =
    FutureProvider.family<Uint8List?, Map<String, String>>(
  (ref, params) async {
    try {
      final fileId = params['fileId']!;
      final filePath = params['filePath']!;
      final fileName = params['fileName']!;
      final fileType = params['fileType']!;

      // Generate thumbnail
      final thumbnailBytes = await ThumbnailGenerationService.generateThumbnail(
        filePath,
        fileName,
        fileType,
      );

      if (thumbnailBytes != null) {
        // Cache it
        final hiveDatasource = ref.watch(hiveDatasourceProvider);
        await hiveDatasource.saveThumbnail(fileId, thumbnailBytes.toList());
        log.i('Thumbnail generated and cached for: $fileId');
      }

      return thumbnailBytes;
    } catch (e) {
      log.e('Error generating thumbnail: $e');
      return null;
    }
  },
);
