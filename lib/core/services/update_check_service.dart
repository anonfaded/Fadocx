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

  /// Compare two semver strings.
  /// Handles stable (1.0.0), beta with number (1.0.0-beta2, 1.0.0-beta3),
  /// and beta without number (1.0.0-beta treated as -beta1).
  /// - Beta users should upgrade to the same stable release.
  /// - Stable users should NOT be offered beta upgrades.
  static bool isNewerThan(String current, String latest) {
    // Parse "major.minor.patch[-betaN]" into components
    (int major, int minor, int patch, int? betaNum) parse(String v) {
      final betaNumMatch =
          RegExp(r'^(\d+)\.(\d+)\.(\d+)-beta(\d+)$').firstMatch(v);
      if (betaNumMatch != null) {
        return (
          int.parse(betaNumMatch.group(1)!),
          int.parse(betaNumMatch.group(2)!),
          int.parse(betaNumMatch.group(3)!),
          int.parse(betaNumMatch.group(4)!),
        );
      }
      // -beta without number (treat as -beta1)
      final betaPlain =
          RegExp(r'^(\d+)\.(\d+)\.(\d+)-beta$', caseSensitive: false)
              .firstMatch(v);
      if (betaPlain != null) {
        return (
          int.parse(betaPlain.group(1)!),
          int.parse(betaPlain.group(2)!),
          int.parse(betaPlain.group(3)!),
          1,
        );
      }
      // Stable (no beta suffix)
      final stable = RegExp(r'^(\d+)\.(\d+)\.(\d+)').firstMatch(v);
      if (stable != null) {
        return (
          int.parse(stable.group(1)!),
          int.parse(stable.group(2)!),
          int.parse(stable.group(3)!),
          null,
        );
      }
      return (0, 0, 0, null);
    }

    final (curMajor, curMinor, curPatch, curBeta) = parse(current);
    final (latMajor, latMinor, latPatch, latBeta) = parse(latest);

    // Compare major.minor.patch
    if (latMajor != curMajor) return latMajor > curMajor;
    if (latMinor != curMinor) return latMinor > curMinor;
    if (latPatch != curPatch) return latPatch > curPatch;

    // Same major.minor.patch — compare beta status
    final currentIsBeta = curBeta != null;
    final latestIsBeta = latBeta != null;

    if (currentIsBeta && !latestIsBeta) return true; // beta user → stable upgrade
    if (!currentIsBeta && latestIsBeta) return false; // stable user → no beta offer
    if (currentIsBeta && latestIsBeta) return latBeta > curBeta; // newer beta

    return false; // identical stable or same beta version
  }
}
