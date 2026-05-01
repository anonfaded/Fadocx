import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fadocx/features/home/presentation/providers/update_check_provider.dart';
import 'package:fadocx/core/presentation/widgets/update_available_sheet.dart';
import 'package:fadocx/l10n/app_localizations.dart';

/// Animated drawer cards shown when updates are available.
/// Renders separate cards for stable and/or beta updates.
class DrawerUpdateBanner extends ConsumerWidget {
  const DrawerUpdateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateState = ref.watch(autoUpdateCheckProvider);

    if (updateState is! UpdateCheckAvailable) return const SizedBox.shrink();

    final hasStable = updateState.hasStableUpdate;
    final hasBeta = updateState.hasBetaUpdate;
    if (!hasStable && !hasBeta) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasStable)
          _DrawerCard(
            key: const ValueKey('stable_update'),
            label: AppLocalizations.of(context)!.updateBannerStable,
            icon: Icons.verified_rounded,
            accentColor: const Color(0xFF2E7D32),
            version: 'v${updateState.stableVersion}',
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
          if (hasStable) const SizedBox(height: 6),
          _DrawerCard(
            key: const ValueKey('beta_update'),
            label: AppLocalizations.of(context)!.updateBannerBeta,
            icon: Icons.science_rounded,
            accentColor: const Color(0xFF7C4DFF),
            version: 'v${updateState.betaVersion}',
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
    );
  }
}

class _DrawerCard extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final String version;
  final VoidCallback onTap;

  const _DrawerCard({
    super.key,
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.version,
    required this.onTap,
  });

  @override
  State<_DrawerCard> createState() => _DrawerCardState();
}

class _DrawerCardState extends State<_DrawerCard>
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
    return FadeTransition(
      opacity: _fadeSlide,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(_fadeSlide),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: widget.accentColor.withValues(alpha: 0.08),
                  border: Border.all(
                    color: widget.accentColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: widget.accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(widget.icon, size: 16, color: widget.accentColor),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.label,
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: widget.accentColor,
                                ),
                          ),
                          Text(
                            widget.version,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
