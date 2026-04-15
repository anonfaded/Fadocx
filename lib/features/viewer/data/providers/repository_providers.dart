import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fadocx/features/viewer/data/repositories/document_parsing_repository_impl.dart';
import 'package:fadocx/features/viewer/data/services/cache_service.dart';
import 'package:fadocx/features/viewer/data/services/platform_channel_service.dart';
import 'package:fadocx/features/viewer/domain/repositories/document_parsing_repository.dart';

/// Initialize cache service - should be called once at app startup
final cacheServiceProvider = FutureProvider<HiveCacheService>((ref) async {
  final cache = HiveCacheService();
  await cache.initialize();
  return cache;
});

/// Platform channel service singleton
final platformChannelServiceProvider = Provider<PlatformChannelService>((ref) {
  return MethodChannelService();
});

/// Document parsing repository with all dependencies injected
/// This is the main service for document parsing operations
final documentParsingRepositoryProvider = FutureProvider<DocumentParsingRepository>((ref) async {
  // Wait for cache to initialize
  final cache = await ref.watch(cacheServiceProvider.future);
  
  final platformChannel = ref.watch(platformChannelServiceProvider);

  return DocumentParsingRepositoryImpl(
    platformChannel: platformChannel,
    cache: cache,
  );
});
