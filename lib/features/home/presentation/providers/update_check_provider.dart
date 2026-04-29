import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:logger/logger.dart';
import 'package:fadocx/core/services/update_check_service.dart';
import 'package:fadocx/features/settings/presentation/providers/settings_providers.dart';

final log = Logger();

/// State for the auto-update check flow.
sealed class UpdateCheckState {
  const UpdateCheckState();
}

class UpdateCheckIdle extends UpdateCheckState {
  const UpdateCheckIdle();
}

class UpdateCheckLoading extends UpdateCheckState {
  const UpdateCheckLoading();
}

/// An update is available (stable, beta, or both).
class UpdateCheckAvailable extends UpdateCheckState {
  final String currentVersion;
  final String? stableVersion;
  final String? stableUrl;
  final String? betaVersion;
  final String? betaUrl;
  final bool hasStableUpdate;
  final bool hasBetaUpdate;

  const UpdateCheckAvailable({
    required this.currentVersion,
    this.stableVersion,
    this.stableUrl,
    this.betaVersion,
    this.betaUrl,
    this.hasStableUpdate = false,
    this.hasBetaUpdate = false,
  });
}

class UpdateCheckUpToDate extends UpdateCheckState {
  final String currentVersion;
  const UpdateCheckUpToDate({required this.currentVersion});
}

class UpdateCheckError extends UpdateCheckState {
  final String message;
  const UpdateCheckError({required this.message});
}

class AutoUpdateCheckNotifier extends Notifier<UpdateCheckState> {
  @override
  UpdateCheckState build() {
    return const UpdateCheckIdle();
  }

  Future<void> checkForUpdate() async {
    // Only run once per session — state persists beyond this
    if (state is! UpdateCheckIdle) return;
    state = const UpdateCheckLoading();

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = '${packageInfo.version}+${packageInfo.buildNumber}';

      final result = await UpdateCheckService.checkForUpdate(
        currentVersion: currentVersion,
      );

      if (result.errorOccurred) {
        state = UpdateCheckError(message: 'Failed to check for updates. Check your connection.');
        return;
      }

      if (result.isUpdateAvailable) {
        state = UpdateCheckAvailable(
          currentVersion: currentVersion,
          stableVersion: result.stableVersion,
          stableUrl: result.stableUrl,
          betaVersion: result.betaVersion,
          betaUrl: result.betaUrl,
          hasStableUpdate: result.hasStableUpdate,
          hasBetaUpdate: result.hasBetaUpdate,
        );
      } else {
        state = UpdateCheckUpToDate(currentVersion: currentVersion);
      }
    } catch (e) {
      log.e('Auto-update check failed: $e');
      state = UpdateCheckError(message: 'Failed to check for updates.');
    }
  }
}

final autoUpdateCheckProvider =
    NotifierProvider<AutoUpdateCheckNotifier, UpdateCheckState>(
  AutoUpdateCheckNotifier.new,
);

final autoUpdateCheckEnabledProvider = Provider<bool>((ref) {
  final settings = ref.watch(appSettingsProvider);
  return settings.when(
    data: (settings) => settings?.autoUpdateCheck ?? true,
    loading: () => true,
    error: (_, __) => true,
  );
});
