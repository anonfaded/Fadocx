import 'package:fadocx/core/utils/logger.dart';
import 'package:fadocx/features/settings/data/models/hive_models.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Datasource for Hive database operations
/// Handles all direct Hive box access
class HiveDatasource {
  static const String settingsBoxName = 'fadocx_settings';
  static const String recentFilesBoxName = 'fadocx_recent_files';
  static const String deviceInfoBoxName = 'fadocx_device_info';

  /// Initialize Hive and register adapters
  static Future<void> initialize() async {
    try {
      log.i('Initializing Hive database...');

      // Initialize Hive with Flutter support (sets up storage path)
      await Hive.initFlutter();
      log.d('Hive Flutter initialized with storage path');

      // Register adapters for type-safe storage
      Hive.registerAdapter(HiveRecentFileAdapter());
      Hive.registerAdapter(HiveAppSettingsAdapter());
      Hive.registerAdapter(HiveDeviceInfoAdapter());

      log.d('Hive adapters registered successfully');
    } catch (e, st) {
      log.e('Error initializing Hive', e, st);
      rethrow;
    }
  }

  /// Open/get settings box
  static Future<Box<HiveAppSettings>> getSettingsBox() async {
    try {
      if (Hive.isBoxOpen(settingsBoxName)) {
        return Hive.box<HiveAppSettings>(settingsBoxName);
      }
      return await Hive.openBox<HiveAppSettings>(settingsBoxName);
    } catch (e, st) {
      log.e('Error opening settings box', e, st);
      rethrow;
    }
  }

  /// Open/get recent files box
  static Future<Box<HiveRecentFile>> getRecentFilesBox() async {
    try {
      if (Hive.isBoxOpen(recentFilesBoxName)) {
        return Hive.box<HiveRecentFile>(recentFilesBoxName);
      }
      return await Hive.openBox<HiveRecentFile>(recentFilesBoxName);
    } catch (e, st) {
      log.e('Error opening recent files box', e, st);
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
      log.e('Error getting settings', e, st);
      rethrow;
    }
  }

  /// Save settings
  Future<void> saveSettings(HiveAppSettings settings) async {
    try {
      final box = await getSettingsBox();
      // Store single settings object in box[0]
      await box.put(0, settings);
      log.i('Settings saved: theme=${settings.theme}, language=${settings.language}');
    } catch (e, st) {
      log.e('Error saving settings', e, st);
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
      log.e('Error getting recent files', e, st);
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
      log.e('Error adding recent file', e, st);
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
      log.e('Error updating recent file', e, st);
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
      log.e('Error deleting recent file', e, st);
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
      log.e('Error clearing recent files', e, st);
      rethrow;
    }
  }

  /// Watch settings changes (reactive) - creates defaults on first access
  Future<Stream<HiveAppSettings?>> watchSettings() async {
    try {
      final box = await getSettingsBox();
      // Ensure defaults exist before watching
      if (box.isEmpty) {
        log.d('Initializing defaults for watchSettings');
        await box.put(0, HiveAppSettings());
      }
      log.d('Started watching settings');
      return box.watch().map((_) => box.values.isNotEmpty ? box.values.first : null);
    } catch (e, st) {
      log.e('Error watching settings', e, st);
      rethrow;
    }
  }

  /// Watch recent files changes (reactive)
  Future<Stream<List<HiveRecentFile>>> watchRecentFiles() async {
    try {
      final box = await getRecentFilesBox();
      log.d('Started watching recent files');
      return box.watch().map((_) {
        final files = box.values.toList();
        files.sort((a, b) => b.dateOpened.compareTo(a.dateOpened));
        return files;
      });
    } catch (e, st) {
      log.e('Error watching recent files', e, st);
      rethrow;
    }
  }

  /// Get single recent file by ID
  Future<HiveRecentFile?> getRecentFile(String fileId) async {
    try {
      final box = await getRecentFilesBox();
      return box.get(fileId);
    } catch (e, st) {
      log.e('Error getting recent file', e, st);
      rethrow;
    }
  }

  /// Close all boxes (call on app exit)
  static Future<void> close() async {
    try {
      await Hive.close();
      log.i('Hive database closed');
    } catch (e, st) {
      log.e('Error closing Hive', e, st);
    }
  }
}
