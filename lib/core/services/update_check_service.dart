import 'dart:io';
import 'package:logger/logger.dart';

final log = Logger();

/// Result from checking GitHub for updates.
class UpdateCheckResult {
  final String currentVersion;
  final String? stableVersion;
  final String? stableUrl;
  final String? betaVersion;
  final String? betaUrl;
  final bool isUpdateAvailable;
  final bool hasStableUpdate;
  final bool hasBetaUpdate;
  final bool errorOccurred;

  const UpdateCheckResult({
    required this.currentVersion,
    this.stableVersion,
    this.stableUrl,
    this.betaVersion,
    this.betaUrl,
    this.isUpdateAvailable = false,
    this.hasStableUpdate = false,
    this.hasBetaUpdate = false,
    this.errorOccurred = false,
  });
}

/// Checks for app updates using GitHub's Atom releases feed.
/// No API key needed — fetches /releases.atom, parses entries for
/// both stable (no -beta) and beta (contains -beta) releases.
class UpdateCheckService {
  static const String _repoOrg = 'anonfaded';
  static const String _repoName = 'Fadocx';
  static const String _feedUrl = 'https://github.com/$_repoOrg/$_repoName/releases.atom';

  static const Duration _timeout = Duration(seconds: 10);

  /// Check for both stable and beta updates.
  static Future<UpdateCheckResult> checkForUpdate({
    required String currentVersion,
  }) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = _timeout;

      final request = await client.getUrl(Uri.parse(_feedUrl));
      final response = await request.close();

      if (response.statusCode != 200) {
        log.w('Update check failed: HTTP ${response.statusCode}');
        client.close(force: true);
        return UpdateCheckResult(
          currentVersion: currentVersion,
          errorOccurred: true,
        );
      }

      // Read the full response body as bytes then decode
      final bodyBytes = await response.fold<List<int>>(
        [],
        (prev, chunk) => prev..addAll(chunk),
      );
      final xml = String.fromCharCodes(bodyBytes);
      client.close(force: true);

      // Parse entries from the Atom feed — extract tag from <id> field
      // <id>tag:github.com,2008:Repository/825005239/v3.1.0-beta</id>
      final tagRegexp = RegExp(r'<id>[^<]*/(v[^<]+)</id>');
      final matches = tagRegexp.allMatches(xml);

      String? latestStableVersion;
      String? latestStableUrl;
      String? latestBetaVersion;
      String? latestBetaUrl;

      for (final m in matches) {
        final tag = m.group(1)!.trim();

        // Build the release URL for this tag
        final releaseUrl = 'https://github.com/$_repoOrg/$_repoName/releases/tag/$tag';
        final version = tag.startsWith('v') ? tag.substring(1) : tag;

        if (version.contains('beta', 0)) {
          // Beta release
          if (latestBetaVersion == null) {
            latestBetaVersion = version;
            latestBetaUrl = releaseUrl;
          }
        } else {
          // Stable release
          if (latestStableVersion == null) {
            latestStableVersion = version;
            latestStableUrl = releaseUrl;
          }
        }

        // Stop once we have both
        if (latestStableVersion != null && latestBetaVersion != null) break;
      }

      if (latestStableVersion == null && latestBetaVersion == null) {
        log.w('Update check: no releases found in feed');
        return UpdateCheckResult(currentVersion: currentVersion, errorOccurred: true);
      }

      final hasStableUpdate = latestStableVersion != null &&
          isNewerThan(currentVersion, latestStableVersion);
      final hasBetaUpdate = latestBetaVersion != null &&
          isNewerThan(currentVersion, latestBetaVersion);
      final isAvailable = hasStableUpdate || hasBetaUpdate;

      log.i('Update check: current=$currentVersion, '
          'stable=$latestStableVersion${hasStableUpdate ? " ✅" : ""}, '
          'beta=$latestBetaVersion${hasBetaUpdate ? " ✅" : ""}');

      return UpdateCheckResult(
        currentVersion: currentVersion,
        stableVersion: latestStableVersion,
        stableUrl: latestStableUrl,
        betaVersion: latestBetaVersion,
        betaUrl: latestBetaUrl,
        isUpdateAvailable: isAvailable,
        hasStableUpdate: hasStableUpdate,
        hasBetaUpdate: hasBetaUpdate,
      );
    } catch (e) {
      log.e('Update check failed (network/error): $e');
      return UpdateCheckResult(
        currentVersion: currentVersion,
        errorOccurred: true,
      );
    }
  }

  /// Compare two semver strings. Matches FadCam logic:
  /// - Strips `-beta` from [current] only.
  /// - If all parts equal and current was beta → update available
  ///   (beta users should upgrade to the same stable release).
  /// Public so UI can use it to check if a beta is newer than current.
  static bool isNewerThan(String current, String latest) {
    final currentIsBeta = current.toLowerCase().contains('beta');
    final currentClean = current.replaceAll(RegExp(r'-beta', caseSensitive: false), '');
    // latest from GitHub tag is already clean

    final currentParts = currentClean.split('.');
    final latestParts = latest.split('.');

    for (int i = 0; i < currentParts.length && i < latestParts.length; i++) {
      final currentNum = int.tryParse(currentParts[i]) ?? 0;
      final latestNum = int.tryParse(latestParts[i]) ?? 0;

      if (latestNum > currentNum) return true;
      if (latestNum < currentNum) return false;
    }

    if (latestParts.length > currentParts.length) return true;
    if (latestParts.length == currentParts.length && currentIsBeta) return true;

    return false;
  }
}
