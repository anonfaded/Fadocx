import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fadocx/core/utils/logger.dart';
import 'package:fadocx/features/settings/data/datasources/hive_datasource.dart';
import 'package:fadocx/features/settings/data/repositories/repositories_impl.dart';
import 'package:fadocx/features/settings/domain/entities/app_settings.dart';
import 'package:fadocx/features/settings/domain/repositories/repositories.dart';

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

  // Get initial settings
  final result = await repository.getSettings();
  yield await result.fold(
    (failure) async => null,
    (settings) async => settings,
  );

  // Watch for changes
  await for (final result in repository.watchSettings()) {
    yield await result.fold(
      (failure) async => null,
      (settings) async => settings,
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

  // Get initial list
  final result = await repository.getRecentFiles();
  yield await result.fold(
    (failure) async => [],
    (files) async => files,
  );

  // Watch for changes
  await for (final result in repository.watchRecentFiles()) {
    yield await result.fold(
      (failure) async => [],
      (files) async => files,
    );
  }
});

// ============================================================================
// RECENT FILES MUTATION PROVIDER
// ============================================================================

/// Recent files mutator for modifying recent files
final recentFilesMutatorProvider = Provider((ref) {
  final repository = ref.watch(recentFilesRepositoryProvider);
  return RecentFilesMutator(repository);
});

class RecentFilesMutator {
  final RecentFilesRepository _repository;

  RecentFilesMutator(this._repository);

  Future<void> addRecentFile(RecentFile file) async {
    log.i('Adding recent file: ${file.fileName}');
    final result = await _repository.addRecentFile(file);
    result.fold(
      (failure) => log.e('Failed to add recent file: ${failure.message}'),
      (success) => log.i('Recent file added successfully'),
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

  Future<void> removeRecentFile(String fileId) async {
    log.i('Removing recent file: $fileId');
    final result = await _repository.removeRecentFile(fileId);
    result.fold(
      (failure) => log.e('Failed to remove file: ${failure.message}'),
      (success) => log.i('File removed successfully'),
    );
  }

  Future<void> clearAllRecentFiles() async {
    log.i('Clearing all recent files');
    final result = await _repository.clearRecentFiles();
    result.fold(
      (failure) => log.e('Failed to clear recent files: ${failure.message}'),
      (success) => log.i('All recent files cleared'),
    );
  }
}
