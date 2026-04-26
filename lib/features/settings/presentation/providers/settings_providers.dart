import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:logger/logger.dart';
import 'package:fadocx/features/settings/data/datasources/hive_datasource.dart';
import 'package:fadocx/features/settings/data/repositories/repositories_impl.dart';
import 'package:fadocx/features/settings/domain/entities/app_settings.dart';
import 'package:fadocx/features/settings/domain/repositories/repositories.dart';
import 'package:fadocx/core/services/storage_service.dart';

final log = Logger();


final packageInfoProvider = FutureProvider<PackageInfo>((ref) async {
  return await PackageInfo.fromPlatform();
});

// ============================================================================
// DATASOURCE PROVIDER
// ============================================================================

/// Global Hive datasource provider
final hiveDatasourceProvider = Provider((ref) {
  log.d('Creating HiveDatasource provider');
  return HiveDatasource();
});

// ============================================================================
// REPOSITORY PROVIDERS
// ============================================================================

/// AppSettings repository provider
final appSettingsRepositoryProvider = Provider<AppSettingsRepository>((ref) {
  final datasource = ref.watch(hiveDatasourceProvider);
  log.d('Creating AppSettingsRepository provider');
  return AppSettingsRepositoryImpl(datasource);
});

/// Recent files repository provider
final recentFilesRepositoryProvider = Provider<RecentFilesRepository>((ref) {
  final datasource = ref.watch(hiveDatasourceProvider);
  log.d('Creating RecentFilesRepository provider');
  return RecentFilesRepositoryImpl(datasource);
});

// ============================================================================
// SETTINGS STATE PROVIDERS
// ============================================================================

/// Watch app settings with reactive updates
final appSettingsProvider = StreamProvider<AppSettings?>((ref) async* {
  final repository = ref.watch(appSettingsRepositoryProvider);
  log.d('Watching app settings stream...');

  await for (final result in repository.watchSettings()) {
    yield result.fold(
      (failure) => null,
      (settings) => settings,
    );
  }
});

// ============================================================================
// SETTINGS MUTATION PROVIDERS (State Notifiers)
// ============================================================================

/// Settings mutator for updating settings
final settingsMutatorProvider = Provider((ref) {
  final repository = ref.watch(appSettingsRepositoryProvider);
  return SettingsMutator(repository);
});

class SettingsMutator {
  final AppSettingsRepository _repository;

  SettingsMutator(this._repository);

  Future<void> updateTheme(String theme) async {
    log.i('Updating theme to: $theme');
    final result = await _repository.updateTheme(theme);
    result.fold(
      (failure) => log.e('Failed to update theme: ${failure.message}'),
      (success) => log.i('Theme updated successfully'),
    );
  }

  Future<void> updateLanguage(String language) async {
    log.i('Updating language to: $language');
    final result = await _repository.updateLanguage(language);
    result.fold(
      (failure) => log.e('Failed to update language: ${failure.message}'),
      (success) => log.i('Language updated successfully'),
    );
  }

  Future<void> updateNotifications(bool enabled) async {
    log.i('Updating notifications to: $enabled');
    final result = await _repository.updateNotifications(enabled);
    result.fold(
      (failure) => log.e('Failed to update notifications: ${failure.message}'),
      (success) => log.i('Notifications updated successfully'),
    );
  }

  Future<void> updateHasImportedSampleFiles(bool hasImported) async {
    log.i('Updating hasImportedSampleFiles to: $hasImported');
    final result = await _repository.updateHasImportedSampleFiles(hasImported);
    result.fold(
      (failure) => log.e('Failed to update hasImportedSampleFiles: ${failure.message}'),
      (success) => log.i('hasImportedSampleFiles updated successfully'),
    );
  }

  Future<void> updateHasDismissedWelcome(bool hasDismissed) async {
    log.i('Updating hasDismissedWelcome to: $hasDismissed');
    final result = await _repository.updateHasDismissedWelcome(hasDismissed);
    result.fold(
      (failure) => log.e('Failed to update hasDismissedWelcome: ${failure.message}'),
      (success) => log.i('hasDismissedWelcome updated successfully'),
    );
  }

  Future<void> clearSettings() async {
    log.i('Clearing settings');
    final result = await _repository.clearSettings();
    result.fold(
      (failure) => log.e('Failed to clear settings: ${failure.message}'),
      (success) => log.i('Settings cleared successfully'),
    );
  }
}

// ============================================================================
// RECENT FILES PROVIDERS
// ============================================================================

/// Watch recent files with reactive updates
final recentFilesProvider = StreamProvider<List<RecentFile>>((ref) async* {
  final repository = ref.watch(recentFilesRepositoryProvider);
  log.d('Watching recent files stream...');

  // Start watching immediately - Hive watch() will trigger an initial event if configured,
  // or we get it through the map logic in datasource.
  // We remove the blocking initial getRecentFiles() to prevent main thread lag on startup.
  await for (final result in repository.watchRecentFiles()) {
    yield result.fold(
      (failure) => [],
      (files) => files,
    );
  }
});

/// Trash files provider - FutureProvider for trash files list
final trashFilesProvider = FutureProvider<List<RecentFile>>((ref) async {
  final repository = ref.watch(recentFilesRepositoryProvider);
  log.d('Fetching trash files...');

  final result = await repository.getTrashFiles();
  return result.fold(
    (failure) {
      log.e('Failed to fetch trash files: ${failure.message}');
      return [];
    },
    (files) => files,
  );
});

// ============================================================================
// RECENT FILES MUTATION PROVIDER
// ============================================================================

/// Recent files mutator for modifying recent files
final recentFilesMutatorProvider = Provider((ref) {
  final repository = ref.watch(recentFilesRepositoryProvider);
  return RecentFilesMutator(repository, ref);
});

class RecentFilesMutator {
  final RecentFilesRepository _repository;
  final Ref _ref;

  RecentFilesMutator(this._repository, this._ref);

  Future<void> addRecentFile(RecentFile file) async {
    log.i('Adding recent file: ${file.fileName}');
    final result = await _repository.addRecentFile(file);
    result.fold(
      (failure) => log.e('Failed to add recent file: ${failure.message}'),
      (success) {
        log.i('Recent file added successfully');
        _ref.invalidate(recentFilesProvider);
        _ref.invalidate(storageStatsProvider);
      },
    );
  }

  Future<void> updatePagePosition(String fileId, int pagePosition) async {
    log.d('Updating page position for $fileId to $pagePosition');
    final result = await _repository.updatePagePosition(fileId, pagePosition);
    result.fold(
      (failure) => log.e('Failed to update position: ${failure.message}'),
      (success) => log.d('Page position updated'),
    );
  }

  Future<void> updateDateOpened(String filePath) async {
    log.i('Updating date opened for: $filePath');
    final result = await _repository.updateDateOpened(filePath);
    result.fold(
      (failure) => log.e('Failed to update date opened: ${failure.message}'),
      (success) {
        log.i('Date opened updated');
        _ref.invalidate(recentFilesProvider);
      },
    );
  }

  Future<void> removeRecentFile(String fileId) async {
    log.i('Removing recent file: $fileId');
    final result = await _repository.removeRecentFile(fileId);
    result.fold(
      (failure) => log.e('Failed to remove file: ${failure.message}'),
      (success) {
        log.i('File removed successfully');
        _ref.invalidate(recentFilesProvider);
      },
    );
  }

  Future<void> clearAllRecentFiles() async {
    log.i('Clearing all recent files');
    final result = await _repository.clearRecentFiles();
    result.fold(
      (failure) => log.e('Failed to clear recent files: ${failure.message}'),
      (success) {
        log.i('All recent files cleared');
        _ref.invalidate(recentFilesProvider);
      },
    );
  }

  Future<void> softDeleteFile(String fileId) async {
    log.i('Soft deleting file: $fileId');
    final result = await _repository.softDeleteFile(fileId);
    result.fold(
      (failure) => log.e('Failed to delete file: ${failure.message}'),
      (success) {
        log.i('File moved to trash');
        _ref.invalidate(trashFilesProvider);
        _ref.invalidate(recentFilesProvider);
        _ref.invalidate(storageStatsProvider);
      },
    );
  }

  Future<void> restoreFromTrash(String fileId) async {
    log.i('Restoring file from trash: $fileId');
    final result = await _repository.restoreFromTrash(fileId);
    result.fold(
      (failure) => log.e('Failed to restore file: ${failure.message}'),
      (success) {
        log.i('File restored from trash');
        _ref.invalidate(trashFilesProvider);
        _ref.invalidate(recentFilesProvider);
        _ref.invalidate(storageStatsProvider);
      },
    );
  }

  Future<void> markAsRead(String fileId) async {
    log.i('Marking file as read: $fileId');
    final result = await _repository.markAsRead(fileId);
    result.fold(
      (failure) => log.e('Failed to mark as read: ${failure.message}'),
      (success) => _ref.invalidate(recentFilesProvider),
    );
  }

  Future<void> startViewingSession(String filePath) async {
    log.d('Starting viewing session: $filePath');
    final result = await _repository.startViewingSession(filePath);
    result.fold(
      (failure) => log.e('Failed to start session: ${failure.message}'),
      (success) {
        log.d('Session started successfully');
        _ref.invalidate(recentFilesProvider);
      },
    );
  }

  Future<void> endViewingSession(String filePath) async {
    log.d('Ending viewing session: $filePath');
    final result = await _repository.endViewingSession(filePath);
    result.fold(
      (failure) => log.e('Failed to end session: ${failure.message}'),
      (success) {
        log.d('Session ended, time will be added');
        _ref.invalidate(recentFilesProvider);
      },
    );
  }

  Future<void> permanentlyDeleteFile(String fileId) async {
    log.i('Permanently deleting file: $fileId');
    final result = await _repository.permanentlyDeleteFile(fileId);
    result.fold(
      (failure) =>
          log.e('Failed to permanently delete file: ${failure.message}'),
      (success) {
        log.i('File permanently deleted');
        _ref.invalidate(trashFilesProvider);
        _ref.invalidate(recentFilesProvider);
        _ref.invalidate(storageStatsProvider);
      },
    );
  }

  Future<void> updateExtractedText(String filePath, String extractedText) async {
    log.i('Updating extracted text for: $filePath');
    final result = await _repository.updateExtractedText(filePath, extractedText);
    result.fold(
      (failure) => log.e('Failed to update extracted text: ${failure.message}'),
      (success) => log.i('Extracted text updated'),
    );
  }
}

// ============================================================================
// UI PREFERENCE PROVIDERS
// ============================================================================

/// Grid view preference - true for grid, false for list (stored in memory)
final gridViewPreferenceProvider = NotifierProvider<GridViewNotifier, bool>(
  GridViewNotifier.new,
);

/// Notifier for managing grid/list view preference
class GridViewNotifier extends Notifier<bool> {
  @override
  bool build() => true; // Default to grid view

  void toggleViewMode() {
    state = !state;
    log.i('Toggled view mode to: ${state ? 'grid' : 'list'}');
  }

  void setGridView(bool isGrid) {
    state = isGrid;
    log.i('Set view mode to: ${isGrid ? 'grid' : 'list'}');
  }
}

// ============================================================================
// RECENT FILES VISIBILITY PROVIDER
// ============================================================================

/// Show/Hide recent files section on home screen (stored in memory)
final showRecentFilesProvider = NotifierProvider<ShowRecentFilesNotifier, bool>(
  ShowRecentFilesNotifier.new,
);

/// Notifier for managing show/hide recent files
class ShowRecentFilesNotifier extends Notifier<bool> {
  @override
  bool build() {
    log.d('Creating showRecentFilesProvider with default value: true');
    return true; // Default to showing recent files
  }

  void toggle() {
    state = !state;
    log.i('Toggled recent files visibility to: ${state ? 'visible' : 'hidden'}');
  }

  void setShowRecentFiles(bool show) {
    state = show;
    log.i('Set recent files visibility to: ${show ? 'visible' : 'hidden'}');
  }
}

// ============================================================================
// STORAGE STATS PROVIDER
// ============================================================================

/// Storage stats provider - returns bytes and count for each category
/// Auto-invalidated when files are added/duplicated/restored
final storageStatsProvider =
    FutureProvider<Map<String, Map<String, int>>>((ref) async {
  log.i('Loading storage stats...');
  return await StorageService.getStorageStats();
});
