import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fadocx/features/viewer/data/repositories/document_parsing_repository_impl.dart';
import 'package:fadocx/features/viewer/data/services/cache_service.dart';
import 'package:fadocx/features/viewer/data/services/platform_channel_service.dart';
import 'package:fadocx/features/viewer/domain/repositories/document_parsing_repository.dart';

/// Initialize cache service
final cacheServiceProvider = Provider<HiveCacheService>((ref) {
  return HiveCacheService();
});

/// Platform channel service singleton
final platformChannelServiceProvider = Provider<PlatformChannelService>((ref) {
  return MethodChannelService();
});

/// Document parsing repository with all dependencies injected
/// This is the main service for document parsing operations
final documentParsingRepositoryProvider = Provider<DocumentParsingRepository>((ref) {
  final cache = ref.watch(cacheServiceProvider);
  final platformChannel = ref.watch(platformChannelServiceProvider);

  return DocumentParsingRepositoryImpl(
    platformChannel: platformChannel,
    cache: cache,
  );
});
