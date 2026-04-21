import 'package:logger/logger.dart';
import 'package:fadocx/features/settings/data/models/hive_models.dart';
import 'package:hive_flutter/hive_flutter.dart';

final log = Logger();

/// Datasource for Hive database operations
/// Handles all direct Hive box access
class HiveDatasource {
  static const String settingsBoxName = 'fadocx_settings';
  static const String recentFilesBoxName = 'fadocx_recent_files';
  static const String deviceInfoBoxName = 'fadocx_device_info';
  static const String thumbnailCacheBoxName = 'fadocx_thumbnail_cache';

  /// Initialize Hive, register adapters, and pre-open essential boxes
  static Future<void> initialize() async {
    try {
      await Hive.initFlutter();
      Hive.registerAdapter(HiveRecentFileAdapter());
      Hive.registerAdapter(HiveAppSettingsAdapter());
      Hive.registerAdapter(HiveDeviceInfoAdapter());
      Hive.registerAdapter(HiveThumbnailAdapter());

      // Pre-open both settings and recent files boxes to avoid blocking UI during home screen render
      if (!Hive.isBoxOpen(settingsBoxName)) {
        await Hive.openBox<HiveAppSettings>(settingsBoxName);
      }
      if (!Hive.isBoxOpen(recentFilesBoxName)) {
        await Hive.openBox<HiveRecentFile>(recentFilesBoxName);
      }

      log.i(
          'Hive initialization complete (settings + recent files boxes opened)');
    } catch (e, st) {
      log.e('Error initializing Hive', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Open/get settings box
  Future<Box<HiveAppSettings>> getSettingsBox() async {
    try {
      if (Hive.isBoxOpen(settingsBoxName)) {
        return Hive.box<HiveAppSettings>(settingsBoxName);
      }
      return await Hive.openBox<HiveAppSettings>(settingsBoxName);
    } catch (e, st) {
      log.e('Error opening settings box', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Open/get recent files box (lazy load)
  Future<Box<HiveRecentFile>> getRecentFilesBox() async {
    try {
      if (Hive.isBoxOpen(recentFilesBoxName)) {
        return Hive.box<HiveRecentFile>(recentFilesBoxName);
      }
      log.d('Lazy opening recent files box...');
      return await Hive.openBox<HiveRecentFile>(recentFilesBoxName);
    } catch (e, st) {
      log.e('Error opening recent files box', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Open/get device info box (lazy load)
  Future<Box<HiveDeviceInfo>> getDeviceInfoBox() async {
    try {
      if (Hive.isBoxOpen(deviceInfoBoxName)) {
        return Hive.box<HiveDeviceInfo>(deviceInfoBoxName);
      }
      log.d('Lazy opening device info box...');
      return await Hive.openBox<HiveDeviceInfo>(deviceInfoBoxName);
    } catch (e, st) {
      log.e('Error opening device info box', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Get settings (or create defaults if not found)
  Future<HiveAppSettings?> getSettings() async {
    try {
      final box = await getSettingsBox();
      if (box.values.isEmpty) {
        log.d('No settings found, creating defaults');
        final defaults = HiveAppSettings();
        await box.put(0, defaults);
        log.i('Default settings created');
        return defaults;
      }
      final settings = box.values.first;
      log.d('Retrieved settings: ${settings.theme}');
      return settings;
    } catch (e, st) {
      log.e('Error getting settings', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Save settings
  Future<void> saveSettings(HiveAppSettings settings) async {
    try {
      final box = await getSettingsBox();
      // Store single settings object in box[0]
      await box.put(0, settings);
      log.i(
          'Settings saved: theme=${settings.theme}, language=${settings.language}');
    } catch (e, st) {
      log.e('Error saving settings', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Get all recent files
  Future<List<HiveRecentFile>> getRecentFiles() async {
    try {
      final box = await getRecentFilesBox();
      final files = box.values.toList();
      // Sort by dateOpened descending
      files.sort((a, b) => b.dateOpened.compareTo(a.dateOpened));
      log.d('Retrieved ${files.length} recent files');
      return files;
    } catch (e, st) {
      log.e('Error getting recent files', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Add recent file
  Future<void> addRecentFile(HiveRecentFile file) async {
    try {
      final box = await getRecentFilesBox();
      await box.put(file.id, file);
      log.i('Added recent file: ${file.fileName}');
    } catch (e, st) {
      log.e('Error adding recent file', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Update recent file
  Future<void> updateRecentFile(HiveRecentFile file) async {
    try {
      final box = await getRecentFilesBox();
      await box.put(file.id, file);
      log.d('Updated recent file: ${file.fileName}');
    } catch (e, st) {
      log.e('Error updating recent file', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Delete recent file
  Future<void> deleteRecentFile(String fileId) async {
    try {
      final box = await getRecentFilesBox();
      await box.delete(fileId);
      log.i('Deleted recent file: $fileId');
    } catch (e, st) {
      log.e('Error deleting recent file', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Clear all recent files
  Future<void> clearRecentFiles() async {
    try {
      final box = await getRecentFilesBox();
      await box.clear();
      log.i('Cleared all recent files');
    } catch (e, st) {
      log.e('Error clearing recent files', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Watch settings changes (reactive)
  Future<Stream<HiveAppSettings?>> watchSettings() async {
    try {
      final box = await getSettingsBox();
      log.d('Started watching settings');
      return box
          .watch()
          .map((_) => box.values.isNotEmpty ? box.values.first : null);
    } catch (e, st) {
      log.e('Error watching settings', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Watch recent files changes (reactive)
  Future<Stream<List<HiveRecentFile>>> watchRecentFiles() async {
    try {
      final box = await getRecentFilesBox();
      log.d('Started watching recent files');

      // Helper to get and sort current values
      List<HiveRecentFile> getSorted() {
        final files = box.values.toList();
        files.sort((a, b) => b.dateOpened.compareTo(a.dateOpened));
        return files;
      }

      // Combine initial values with stream of updates
      return box.watch().map((_) => getSorted()).asBroadcastStream(
        onListen: (sub) {
          // Note: Hive.watch doesn't emit initial value,
          // but Riverpod StreamProvider handles it by continuing from await for.
        },
      );
    } catch (e, st) {
      log.e('Error watching recent files', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Get single recent file by ID
  Future<HiveRecentFile?> getRecentFile(String fileId) async {
    try {
      final box = await getRecentFilesBox();
      return box.get(fileId);
    } catch (e, st) {
      log.e('Error getting recent file', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Open/get thumbnail cache box (lazy load)
  Future<Box<HiveThumbnail>> getThumbnailCacheBox() async {
    try {
      if (Hive.isBoxOpen(thumbnailCacheBoxName)) {
        return Hive.box<HiveThumbnail>(thumbnailCacheBoxName);
      }
      return await Hive.openBox<HiveThumbnail>(thumbnailCacheBoxName);
    } catch (e, st) {
      log.e('Error opening thumbnail cache box', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Save thumbnail for a file
  Future<void> saveThumbnail(String fileId, List<int> pngBytes) async {
    try {
      final box = await getThumbnailCacheBox();
      final thumbnail = HiveThumbnail(
        fileId: fileId,
        pngBytes: pngBytes,
        generatedAt: DateTime.now(),
      );
      await box.put(fileId, thumbnail);
      log.d('Thumbnail saved for file: $fileId');
    } catch (e, st) {
      log.e('Error saving thumbnail', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Get thumbnail for a file
  Future<HiveThumbnail?> getThumbnail(String fileId) async {
    try {
      final box = await getThumbnailCacheBox();
      return box.get(fileId);
    } catch (e, st) {
      log.e('Error getting thumbnail', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Remove thumbnail from cache
  Future<void> removeThumbnail(String fileId) async {
    try {
      final box = await getThumbnailCacheBox();
      await box.delete(fileId);
      log.d('Thumbnail removed for file: $fileId');
    } catch (e, st) {
      log.e('Error removing thumbnail', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Clear all thumbnails from cache
  Future<void> clearThumbnailCache() async {
    try {
      final box = await getThumbnailCacheBox();
      await box.clear();
      log.i('Thumbnail cache cleared');
    } catch (e, st) {
      log.e('Error clearing thumbnail cache', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Close all boxes (call on app exit)
  static Future<void> close() async {
    try {
      await Hive.close();
      log.i('Hive database closed');
    } catch (e, st) {
      log.e('Error closing Hive', error: e, stackTrace: st);
    }
  }
}
