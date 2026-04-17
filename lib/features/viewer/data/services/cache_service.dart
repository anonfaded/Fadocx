import 'dart:io';
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fadocx/core/utils/logger.dart';

/// Cache model stored in Hive
class CachedParsedSheet {
  static const String boxName = 'parsedSheets';

  final String filePath;
  final int fileModTimeMs;
  final String parsedDataJson;
  final DateTime cachedAt;

  CachedParsedSheet({
    required this.filePath,
    required this.fileModTimeMs,
    required this.parsedDataJson,
    required this.cachedAt,
  });

  /// Convert to JSON string for storage
  String toJson() {
    return '$fileModTimeMs|||$parsedDataJson|||${cachedAt.toIso8601String()}';
  }

  /// Parse from stored JSON string
  static CachedParsedSheet? fromJson(String filePath, String jsonString) {
    try {
      final parts = jsonString.split('|||');
      if (parts.length < 3) return null;

      return CachedParsedSheet(
        filePath: filePath,
        fileModTimeMs: int.parse(parts[0]),
        parsedDataJson: parts[1],
        cachedAt: DateTime.parse(parts[2]),
      );
    } catch (e) {
      log.w('Failed to parse cached sheet: $e');
      return null;
    }
  }
}

/// Service for managing cached parsed documents
/// Handles Hive box lifecycle and validation
abstract class CacheService {
  /// Get cached parsing if available and file unchanged
  Future<Map<String, dynamic>?> getCachedParsing(String filePath);

  /// Store parsing in cache
  Future<void> cacheParsing(
    String filePath,
    Map<String, dynamic> parsedData,
  );

  /// Clear all cached data
  Future<void> clearCache();

  /// Check if cached file is still valid
  Future<bool> isCacheValid(String filePath, DateTime lastParsed);
}

/// Concrete Hive-based cache implementation
class HiveCacheService implements CacheService {
  late Box<String> _cacheBox;
  bool _isInitialized = false;

  /// Initialize Hive box - called lazily on first access
  Future<void> _initialize() async {
    if (_isInitialized) return;
    
    try {
      if (!Hive.isBoxOpen(CachedParsedSheet.boxName)) {
        log.d('Lazy opening cache box: ${CachedParsedSheet.boxName}');
        _cacheBox = await Hive.openBox<String>(CachedParsedSheet.boxName);
      } else {
        _cacheBox = Hive.box<String>(CachedParsedSheet.boxName);
      }
      _isInitialized = true;
      log.i('HiveCacheService initialized lazily');
    } catch (e) {
      log.e('Failed to initialize Hive cache: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> getCachedParsing(String filePath) async {
    try {
      await _initialize();

      final cachedJson = _cacheBox.get(filePath);
      if (cachedJson == null) {
        log.d('No cache found for: $filePath');
        return null;
      }

      final cached = CachedParsedSheet.fromJson(filePath, cachedJson);
      if (cached == null) {
        log.w('Failed to parse cached data for: $filePath');
        return null;
      }

      // Check if file has been modified
      final file = File(filePath);
      if (!await file.exists()) {
        log.w('Cached file no longer exists: $filePath');
        await _cacheBox.delete(filePath);
        return null;
      }

      final stat = await file.stat();
      final currentModTimeMs = stat.modified.millisecondsSinceEpoch;

      if (currentModTimeMs != cached.fileModTimeMs) {
        log.i('Cache invalid - file was modified: $filePath');
        await _cacheBox.delete(filePath);
        return null;
      }

      log.i('Cache hit for: $filePath (cached ${DateTime.now().difference(cached.cachedAt).inSeconds}s ago)');
      
      // Return parsed data from stored JSON
      try {
        return _jsonToParsedData(cached.parsedDataJson);
      } catch (e) {
        log.e('Failed to deserialize cached data: $e');
        await _cacheBox.delete(filePath);
        return null;
      }
    } catch (e) {
      log.e('Error retrieving cache: $e');
      return null;
    }
  }

  @override
  Future<void> cacheParsing(
    String filePath,
    Map<String, dynamic> parsedData,
  ) async {
    try {
      await _initialize();

      final file = File(filePath);
      if (!await file.exists()) {
        log.w('Cannot cache - file does not exist: $filePath');
        return;
      }

      final stat = await file.stat();
      final modTimeMs = stat.modified.millisecondsSinceEpoch;

      final cached = CachedParsedSheet(
        filePath: filePath,
        fileModTimeMs: modTimeMs,
        parsedDataJson: _parsedDataToJson(parsedData),
        cachedAt: DateTime.now(),
      );

      await _cacheBox.put(filePath, cached.toJson());
      log.i('Cached parsing for: $filePath');
    } catch (e) {
      log.e('Error caching parsing: $e');
      // Don't rethrow - caching failures shouldn't stop the app
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await _initialize();
      await _cacheBox.clear();
      log.i('Cleared all cached parsings');
    } catch (e) {
      log.e('Error clearing cache: $e');
    }
  }

  @override
  Future<bool> isCacheValid(String filePath, DateTime lastParsed) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return false;

      final stat = await file.stat();
      return stat.modified.isBefore(lastParsed);
    } catch (e) {
      log.w('Error checking cache validity: $e');
      return false;
    }
  }

  /// Convert parsed data map to JSON string for storage
  String _parsedDataToJson(Map<String, dynamic> data) {
    return jsonEncode(data);
  }

  /// Convert JSON string back to parsed data map
  Map<String, dynamic> _jsonToParsedData(String json) {
    final decoded = jsonDecode(json);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    // Fallback for unexpected types
    log.w('Unexpected cached data type: ${decoded.runtimeType}');
    return {};
  }
}
