import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fadocx/core/presentation/widgets/update_available_sheet.dart';
import 'package:fadocx/features/home/presentation/providers/update_check_provider.dart';
import 'package:fadocx/l10n/app_localizations.dart';

/// Drawer section shown when updates are available.
/// Renders separate cards for stable and/or beta updates.
class DrawerUpdateBanner extends ConsumerWidget {
  const DrawerUpdateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateState = ref.watch(autoUpdateCheckProvider);

    if (updateState is! UpdateCheckAvailable) {
      return const SizedBox.shrink();
    }

    final hasStable = updateState.hasStableUpdate;
    final hasBeta = updateState.hasBetaUpdate;
    if (!hasStable && !hasBeta) return const SizedBox.shrink();
    final updateCount = (hasStable ? 1 : 0) + (hasBeta ? 1 : 0);

    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 8),
          child: Text(
            AppLocalizations.of(context)!.updatesAvailableTitle(updateCount),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        Material(
          color: colorScheme.surfaceContainerLow
              .withValues(alpha: isDark ? 0.94 : 0.88),
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              if (hasStable)
                _BannerRow(
                  key: const ValueKey('stable_update'),
                  label: AppLocalizations.of(context)!.updateBannerStable,
                  icon: Icons.verified_rounded,
                  accentColor: const Color(0xFF2E7D32),
                  currentVersion: updateState.currentVersion,
                  latestVersion: updateState.stableVersion!,
                  onTap: () {
                    UpdateAvailableSheet.show(
                      context,
                      currentVersion: updateState.currentVersion,
                      stableVersion: updateState.stableVersion,
                      stableUrl: updateState.stableUrl,
                      betaVersion: updateState.betaVersion,
                      betaUrl: updateState.betaUrl,
                      hasStableUpdate: updateState.hasStableUpdate,
                      hasBetaUpdate: updateState.hasBetaUpdate,
                    );
                  },
                ),
              if (hasBeta) ...[
                if (hasStable) _BannerDivider(colorScheme),
                _BannerRow(
                  key: const ValueKey('beta_update'),
                  label: AppLocalizations.of(context)!.updateBannerBeta,
                  icon: Icons.science_rounded,
                  accentColor: const Color(0xFF7C4DFF),
                  currentVersion: updateState.currentVersion,
                  latestVersion: updateState.betaVersion!,
                  onTap: () {
                    UpdateAvailableSheet.show(
                      context,
                      currentVersion: updateState.currentVersion,
                      stableVersion: updateState.stableVersion,
                      stableUrl: updateState.stableUrl,
                      betaVersion: updateState.betaVersion,
                      betaUrl: updateState.betaUrl,
                      hasStableUpdate: updateState.hasStableUpdate,
                      hasBetaUpdate: updateState.hasBetaUpdate,
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _BannerRow extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final String currentVersion;
  final String latestVersion;
  final VoidCallback onTap;

  const _BannerRow({
    super.key,
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.currentVersion,
    required this.latestVersion,
    required this.onTap,
  });

  @override
  State<_BannerRow> createState() => _BannerRowState();
}

class _BannerRowState extends State<_BannerRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    )..forward();
    _fadeSlide = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final colorScheme = Theme.of(context).colorScheme;

    return FadeTransition(
      opacity: _fadeSlide,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(_fadeSlide),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh
                          .withValues(alpha: _chipAlpha(brightness)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 18,
                      color: widget.accentColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.label,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.onSurface,
                                  ),
                          softWrap: true,
                          overflow: TextOverflow.visible,
                        ),
                        RichText(
                          text: TextSpan(
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      height: 1.2,
                                    ),
                            children: [
                              TextSpan(
                                text: widget.currentVersion,
                                style: TextStyle(
                                  color:
                                      Colors.redAccent.withValues(alpha: 0.9),
                                ),
                              ),
                              TextSpan(
                                text: '  >>  ',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              TextSpan(
                                text: widget.latestVersion,
                                style: TextStyle(
                                  color: Colors.green.withValues(alpha: 0.95),
                                ),
                              ),
                            ],
                          ),
                          softWrap: true,
                          overflow: TextOverflow.visible,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: widget.accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.newBadge,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: widget.accentColor,
                            letterSpacing: 0.5,
                          ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BannerDivider extends StatelessWidget {
  final ColorScheme colorScheme;

  const _BannerDivider(this.colorScheme);

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 56,
      color: colorScheme.outlineVariant.withValues(alpha: 0.42),
    );
  }
}

double _chipAlpha(Brightness brightness) =>
    brightness == Brightness.dark ? 0.9 : 0.98;
