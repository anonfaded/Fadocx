import 'package:fadocx/features/settings/data/models/hive_models.dart';
import 'package:fadocx/features/settings/domain/entities/app_settings.dart';

/// Mapper to convert Hive models to Domain entities
class SettingsMapper {
  /// Convert HiveRecentFile → RecentFile (domain entity)
  static RecentFile fromHiveRecentFile(HiveRecentFile hive) {
    return RecentFile(
      id: hive.id,
      filePath: hive.filePath,
      fileName: hive.fileName,
      fileType: hive.fileType,
      fileSizeBytes: hive.fileSizeBytes,
      dateOpened: hive.dateOpened,
      dateModified: hive.dateModified,
      pagePosition: hive.pagePosition,
      syncedAt: hive.syncedAt,
      syncStatus: hive.syncStatus,
      isRead: hive.isRead,
    );
  }

  /// Convert RecentFile (domain) → HiveRecentFile
  static HiveRecentFile toHiveRecentFile(RecentFile domain) {
    return HiveRecentFile(
      id: domain.id,
      filePath: domain.filePath,
      fileName: domain.fileName,
      fileType: domain.fileType,
      fileSizeBytes: domain.fileSizeBytes,
      dateOpened: domain.dateOpened,
      dateModified: domain.dateModified,
      pagePosition: domain.pagePosition,
      syncedAt: domain.syncedAt,
      syncStatus: domain.syncStatus,
      isRead: domain.isRead,
    );
  }

  /// Convert HiveAppSettings → AppSettings (domain entity)
  static AppSettings fromHiveAppSettings(HiveAppSettings hive) {
    return AppSettings(
      id: hive.id,
      theme: hive.theme,
      language: hive.language,
      enableNotifications: hive.enableNotifications,
      hasImportedSampleFiles: hive.hasImportedSampleFiles,
      hasDismissedWelcome: hive.hasDismissedWelcome ?? false,
      createdAt: hive.createdAt,
      updatedAt: hive.updatedAt,
      syncStatus: hive.syncStatus,
      syncedAt: hive.syncedAt,
    );
  }

  /// Convert AppSettings (domain) → HiveAppSettings
  static HiveAppSettings toHiveAppSettings(AppSettings domain) {
    return HiveAppSettings(
      id: domain.id,
      theme: domain.theme,
      language: domain.language,
      enableNotifications: domain.enableNotifications,
      hasImportedSampleFiles: domain.hasImportedSampleFiles,
      hasDismissedWelcome: domain.hasDismissedWelcome,
      createdAt: domain.createdAt,
      updatedAt: domain.updatedAt,
      syncStatus: domain.syncStatus,
      syncedAt: domain.syncedAt,
    );
  }
}
