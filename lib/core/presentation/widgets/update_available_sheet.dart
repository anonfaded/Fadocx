import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Reusable bottom sheet showing available app updates.
/// Renders separate cards for stable and/or beta updates,
/// each with its own "Visit GitHub" button.
class UpdateAvailableSheet extends StatelessWidget {
  final String currentVersion;
  final String? stableVersion;
  final String? stableUrl;
  final String? betaVersion;
  final String? betaUrl;
  final bool hasStableUpdate;
  final bool hasBetaUpdate;

  const UpdateAvailableSheet({
    super.key,
    required this.currentVersion,
    this.stableVersion,
    this.stableUrl,
    this.betaVersion,
    this.betaUrl,
    this.hasStableUpdate = false,
    this.hasBetaUpdate = false,
  });

  static void show(
    BuildContext context, {
    required String currentVersion,
    String? stableVersion,
    String? stableUrl,
    String? betaVersion,
    String? betaUrl,
    bool hasStableUpdate = false,
    bool hasBetaUpdate = false,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => UpdateAvailableSheet(
        currentVersion: currentVersion,
        stableVersion: stableVersion,
        stableUrl: stableUrl,
        betaVersion: betaVersion,
        betaUrl: betaUrl,
        hasStableUpdate: hasStableUpdate,
        hasBetaUpdate: hasBetaUpdate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle ──
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // ── Header icon ──
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                        Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.15),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.system_update_rounded,
                    size: 34,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // ── Title ──
          Text(
            'Update Available',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'A new version is ready to download',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),

          // ── Stable card ──
          if (hasStableUpdate)
            _UpdateCard(
              label: 'Stable Release',
              subtitle: 'Recommended for most users',
              currentVersion: currentVersion,
              newVersion: stableVersion!,
              releaseUrl: stableUrl,
              accentColor: const Color(0xFF2E7D32),
              gradientColors: const [Color(0xFF2E7D32), Color(0xFF43A047)],
              icon: Icons.verified_rounded,
            ),

          if (hasStableUpdate && hasBetaUpdate) const SizedBox(height: 14),

          // ── Beta card ──
          if (hasBetaUpdate)
            _UpdateCard(
              label: 'Beta Release',
              subtitle: 'Latest features — may be unstable',
              currentVersion: currentVersion,
              newVersion: betaVersion!,
              releaseUrl: betaUrl,
              accentColor: const Color(0xFF7C4DFF),
              gradientColors: const [Color(0xFF7C4DFF), Color(0xFFB388FF)],
              icon: Icons.science_rounded,
              isBeta: true,
            ),

          const SizedBox(height: 20),

          // ── Maybe Later ──
          SizedBox(
            width: double.infinity,
            height: 44,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Maybe Later',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single update card: version chips + Visit GitHub button.
class _UpdateCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final String currentVersion;
  final String newVersion;
  final String? releaseUrl;
  final Color accentColor;
  final List<Color> gradientColors;
  final IconData icon;
  final bool isBeta;

  const _UpdateCard({
    required this.label,
    required this.subtitle,
    required this.currentVersion,
    required this.newVersion,
    this.releaseUrl,
    required this.accentColor,
    required this.gradientColors,
    required this.icon,
    this.isBeta = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? accentColor.withValues(alpha: 0.06) : accentColor.withValues(alpha: 0.04),
        border: Border.all(
          color: accentColor.withValues(alpha: isDark ? 0.2 : 0.15),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors.map((c) => c.withValues(alpha: 0.2)).toList(),
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: accentColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: accentColor,
                            ),
                      ),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Version comparison
            Row(
              children: [
                // Current
                _versionChip(
                  context,
                  label: 'Current',
                  version: currentVersion,
                  color: Theme.of(context).colorScheme.error,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ),
                // New
                _versionChip(
                  context,
                  label: 'New',
                  version: newVersion,
                  color: accentColor,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Visit GitHub button
            SizedBox(
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      accentColor.withValues(alpha: 0.12),
                      accentColor.withValues(alpha: 0.06),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _openUrl(context, releaseUrl),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.open_in_new_rounded, size: 16, color: accentColor),
                          const SizedBox(width: 8),
                          Text(
                            'Visit GitHub',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Beta standalone info
            if (isBeta) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.12),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 14, color: accentColor.withValues(alpha: 0.7)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This is a standalone APK that can be installed alongside the stable version. It has isolated storage — your existing data won\'t be affected.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 11,
                              height: 1.4,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _versionChip(
    BuildContext context, {
    required String label,
    required String version,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: color.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Text(
              'v$version',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _openUrl(BuildContext context, String? url) async {
  if (url == null) return;
  try {
    await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
  } catch (e) {
    await Clipboard.setData(ClipboardData(text: url));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('URL copied to clipboard: $url')),
      );
    }
  }
}
