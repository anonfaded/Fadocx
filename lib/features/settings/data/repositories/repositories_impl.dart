import 'package:flutter/foundation.dart';
import 'package:fadocx/core/errors/failures.dart';
import 'package:fadocx/core/utils/logger.dart';
import 'package:fadocx/features/settings/data/datasources/hive_datasource.dart';
import 'package:fadocx/features/settings/data/models/hive_models.dart';
import 'package:fadocx/features/settings/data/repositories/settings_mapper.dart';
import 'package:fadocx/features/settings/domain/entities/app_settings.dart';
import 'package:fadocx/features/settings/domain/repositories/repositories.dart';

/// Implementation of AppSettingsRepository using Hive
class AppSettingsRepositoryImpl implements AppSettingsRepository {
  final HiveDatasource _datasource;

  AppSettingsRepositoryImpl(this._datasource);

  /// Get current app settings or create default
  @override
  Future<Result<AppSettings>> getSettings() async {
    try {
      var settings = await _datasource.getSettings();

      // Create default settings if none exist
      if (settings == null) {
        settings = HiveAppSettings();
        await _datasource.saveSettings(settings);
        log.i('Created default app settings');
      }

      final domainSettings = SettingsMapper.fromHiveAppSettings(settings);
      return ResultSuccess(domainSettings);
    } catch (e, st) {
      log.e('Failed to get settings', e, st);
      return ResultFailure(UnknownFailure(message: 'Failed to get settings: $e'));
    }
  }

  @override
  Future<Result<void>> updateTheme(String theme) async {
    try {
      var settings = await _datasource.getSettings();
      settings ??= HiveAppSettings();

      final updated = settings.copyWith(
        theme: theme,
        syncStatus: 'pending',
        updatedAt: DateTime.now(),
      );

      await _datasource.saveSettings(updated);
      log.i('Updated theme to: $theme');
      return const ResultSuccess(null);
    } catch (e, st) {
      log.e('Failed to update theme', e, st);
      return ResultFailure(UnknownFailure(message: 'Failed to update theme'));
    }
  }

  @override
  Future<Result<void>> updateLanguage(String language) async {
    try {
      var settings = await _datasource.getSettings();
      settings ??= HiveAppSettings();

      final updated = settings.copyWith(
        language: language,
        syncStatus: 'pending',
        updatedAt: DateTime.now(),
      );

      await _datasource.saveSettings(updated);
      log.i('Updated language to: $language');
      return const ResultSuccess(null);
    } catch (e, st) {
      log.e('Failed to update language', e, st);
      return ResultFailure(UnknownFailure(message: 'Failed to update language'));
    }
  }

  @override
  Future<Result<void>> updateNotifications(bool enabled) async {
    try {
      var settings = await _datasource.getSettings();
      settings ??= HiveAppSettings();

      final updated = settings.copyWith(
        enableNotifications: enabled,
        syncStatus: 'pending',
        updatedAt: DateTime.now(),
      );

      await _datasource.saveSettings(updated);
      log.i('Updated notifications to: $enabled');
      return const ResultSuccess(null);
    } catch (e, st) {
      log.e('Failed to update notifications', e, st);
      return ResultFailure(UnknownFailure(message: 'Failed to update notifications'));
    }
  }

  @override
  Stream<Result<AppSettings>> watchSettings() async* {
    try {
      // Try to load from Hive, but yield default first if slow
      final box = await _datasource.getSettingsBox();
      
      if (box.values.isNotEmpty) {
        yield ResultSuccess(SettingsMapper.fromHiveAppSettings(box.values.first));
      } else {
        // No settings yet - yield default
        final now = DateTime.now();
        yield ResultSuccess(AppSettings(
          id: 'default',
          theme: 'system',
          language: 'en',
          enableNotifications: true,
          createdAt: now,
          updatedAt: now,
          syncStatus: 'local',
        ));
      }

      final stream = await _datasource.watchSettings();
      await for (final settings in stream) {
        if (settings != null) {
          yield ResultSuccess(SettingsMapper.fromHiveAppSettings(settings));
        }
      }
    } catch (e, st) {
      log.e('Error watching settings', e, st);
      // Yield defaults on error
      final now = DateTime.now();
      yield ResultSuccess(AppSettings(
        id: 'default',
        theme: 'system',
        language: 'en',
        enableNotifications: true,
        createdAt: now,
        updatedAt: now,
        syncStatus: 'local',
      ));
    }
  }

  @override
  Future<Result<void>> clearSettings() async {
    try {
      final defaultSettings = HiveAppSettings();
      await _datasource.saveSettings(defaultSettings);
      log.i('Settings cleared and reset to defaults');
      return const ResultSuccess(null);
    } catch (e, st) {
      log.e('Failed to clear settings', e, st);
      return ResultFailure(UnknownFailure(message: 'Failed to clear settings'));
    }
  }

  @override
  Future<Result<void>> syncSettings() async {
    // Phase 2 implementation
    log.i('Sync settings called (Phase 2+ feature)');
    return const ResultSuccess(null);
  }
}

/// Implementation of RecentFilesRepository using Hive
class RecentFilesRepositoryImpl implements RecentFilesRepository {
  final HiveDatasource _datasource;

  RecentFilesRepositoryImpl(this._datasource);

  @override
  Future<Result<List<RecentFile>>> getRecentFiles() async {
    try {
      final hiveFiles = await _datasource.getRecentFiles();
      // Offload to background isolate for production performance
      final domainFiles = await compute(_processRecentFiles, hiveFiles);
      log.d('Retrieved ${domainFiles.length} recent files');
      return ResultSuccess(domainFiles);
    } catch (e, st) {
      log.e('Failed to get recent files', e, st);
      return ResultFailure(UnknownFailure(message: 'Failed to get recent files'));
    }
  }

  @override
  Future<Result<void>> addRecentFile(RecentFile file) async {
    try {
      final hiveFile = SettingsMapper.toHiveRecentFile(file);
      await _datasource.addRecentFile(hiveFile);
      log.i('Added recent file: ${file.fileName}');
      return const ResultSuccess(null);
    } catch (e, st) {
      log.e('Failed to add recent file', e, st);
      return ResultFailure(UnknownFailure(message: 'Failed to add recent file'));
    }
  }

  @override
  Future<Result<void>> updatePagePosition(String fileId, int pagePosition) async {
    try {
      final existing = await _datasource.getRecentFile(fileId);
      if (existing != null) {
        final updated = existing.copyWith(pagePosition: pagePosition);
        await _datasource.updateRecentFile(updated);
        log.d('Updated page position for $fileId to $pagePosition');
      }
      return const ResultSuccess(null);
    } catch (e, st) {
      log.e('Failed to update page position', e, st);
      return ResultFailure(UnknownFailure(message: 'Failed to update page position'));
    }
  }

  @override
  Future<Result<void>> removeRecentFile(String fileId) async {
    try {
      await _datasource.deleteRecentFile(fileId);
      log.i('Removed recent file: $fileId');
      return const ResultSuccess(null);
    } catch (e, st) {
      log.e('Failed to remove recent file', e, st);
      return ResultFailure(UnknownFailure(message: 'Failed to remove recent file'));
    }
  }

  @override
  Future<Result<void>> clearRecentFiles() async {
    try {
      await _datasource.clearRecentFiles();
      log.i('Cleared all recent files');
      return const ResultSuccess(null);
    } catch (e, st) {
      log.e('Failed to clear recent files', e, st);
      return ResultFailure(UnknownFailure(message: 'Failed to clear recent files'));
    }
  }

  @override
  Stream<Result<List<RecentFile>>> watchRecentFiles() async* {
    try {
      // CRITICAL FIX: Yield empty list immediately, then load data in background
      // This prevents blocking the UI thread on Hive box opening (~1 second)
      log.d('watchRecentFiles: yielding empty list immediately');
      yield const ResultSuccess([]);
      
      // Now open box on background thread - doesn't block UI
      final box = await _datasource.getRecentFilesBox();
      
      // Yield initial values (processed in background)
      final hiveFiles = box.values.toList();
      final initialDomainFiles = await compute(_processRecentFiles, hiveFiles);
      log.d('watchRecentFiles: yielding ${initialDomainFiles.length} files');
      yield ResultSuccess(initialDomainFiles);

      final stream = await _datasource.watchRecentFiles();
      await for (final updatedHiveFiles in stream) {
        final domainFiles = await compute(_processRecentFiles, updatedHiveFiles);
        yield ResultSuccess(domainFiles);
      }
    } catch (e, st) {
      log.e('Error watching recent files', e, st);
      yield ResultFailure(UnknownFailure(message: 'Error watching recent files'));
    }
  }


  @override
  Future<Result<void>> syncRecentFiles() async {
    // Phase 2 implementation
    log.i('Sync recent files called (Phase 2+ feature)');
    return const ResultSuccess(null);
  }

  @override
  Future<Result<String>> getSyncStatus(String fileId) async {
    try {
      final file = await _datasource.getRecentFile(fileId);
      if (file != null) {
        return ResultSuccess(file.syncStatus);
      }
      return ResultFailure(FileNotFoundFailure(filePath: fileId));
    } catch (e, st) {
      log.e('Failed to get sync status', e, st);
      return ResultFailure(UnknownFailure(message: 'Failed to get sync status'));
    }
  }
}

/// TOP LEVEL FUNCTION for compute()
List<RecentFile> _processRecentFiles(List<HiveRecentFile> hiveFiles) {
  // 1. Sort by date opened (descending)
  final sorted = List<HiveRecentFile>.from(hiveFiles)
    ..sort((a, b) => b.dateOpened.compareTo(a.dateOpened));
  
  // 2. Map to domain entities
  return sorted.map(SettingsMapper.fromHiveRecentFile).toList();
}
