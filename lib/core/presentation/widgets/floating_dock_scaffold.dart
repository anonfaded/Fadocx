import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fadocx/config/routing/app_router.dart';

/// Floating overlay scaffold that places app bar and bottom dock as transparent
/// overlays, allowing content to scroll behind them like iOS/macOS style.
class FloatingDockScaffold extends StatelessWidget {
  final Widget body; // Should be a scrollable widget (ListView, Column, etc)
  final String currentRoute;
  final bool showBottomDock;
  final Widget? appBarContent; // Just the content, not PreferredSize
  final Widget? floatingActionButton;

  const FloatingDockScaffold({
    super.key,
    required this.body,
    required this.currentRoute,
    this.showBottomDock = true,
    this.appBarContent,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;
    final bottomPadding = mediaQuery.padding.bottom;
    final appBarHeight = appBarContent != null ? 56.0 : 0.0;
    final dockHeight = showBottomDock ? 72.0 : 0.0;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          // Main scrollable content - full screen, scrolls behind overlays
          Positioned.fill(
            child: body,
          ),

          // Floating top bar with blur (overlay on top)
          if (appBarContent != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: appBarHeight + topPadding,
              child: _FloatingAppBar(
                content: appBarContent!,
                topPadding: topPadding,
              ),
            ),

          // Floating bottom dock with blur (overlay on bottom)
          if (showBottomDock)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _FloatingDock(
                bottomPadding: bottomPadding,
                currentRoute: currentRoute,
              ),
            ),

          // Floating action button - above the dock
          if (floatingActionButton != null && showBottomDock)
            Positioned(
              right: 16,
              bottom: dockHeight + bottomPadding + 8,
              child: floatingActionButton!,
            ),
        ],
      ),
    );
  }
}

/// Floating app bar with blur background
class _FloatingAppBar extends StatelessWidget {
  final Widget content;
  final double topPadding;

  const _FloatingAppBar({
    required this.content,
    required this.topPadding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Shadow below the top bar
        Positioned(
          bottom: -8,
          left: 0,
          right: 0,
          height: 8,
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
        ),
        // Main app bar
        ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color:
                  Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
              child: Column(
                children: [
                  SizedBox(height: topPadding),
                  SizedBox(
                    height: 56,
                    child: content,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Floating bottom dock with blur background
class _FloatingDock extends StatelessWidget {
  final double bottomPadding;
  final String currentRoute;

  const _FloatingDock({
    required this.bottomPadding,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        child: Stack(
          clipBehavior: Clip.none, // Allow shadows to extend outside
          children: [
            // Shadow layer - positioned to extend beyond dock
            Positioned(
              bottom: -60, // Extend shadow further down
              left: -20, // Extend shadow to left
              right: -20, // Extend shadow to right
              height: 140, // Taller height to contain shadow blur
              child: CustomPaint(
                painter: _DockShadowPainter(
                  isDark: isDark,
                  borderRadius: 16,
                ),
              ),
            ),
            // Main dock with blur and buttons (compact)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surface
                        .withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        _buildDockItem(
                          context,
                          icon: Icons.home,
                          label: 'Home',
                          isActive: currentRoute == RouteNames.home,
                          onTap: () {
                            if (currentRoute != RouteNames.home) {
                              context.go(RouteNames.home);
                            }
                          },
                        ),
                        _buildDockItem(
                          context,
                          icon: Icons.history,
                          label: 'Recents',
                          isActive: false,
                          onTap: () {
                            if (currentRoute != RouteNames.home) {
                              context.go(RouteNames.home);
                            }
                          },
                        ),
                        _buildDockItem(
                          context,
                          icon: Icons.settings,
                          label: 'Settings',
                          isActive: currentRoute == RouteNames.settings,
                          onTap: () {
                            if (currentRoute != RouteNames.settings) {
                              context.go(RouteNames.settings);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDockItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      color: isActive
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter for dock shadow - only on bottom and sides, NOT on top
class _DockShadowPainter extends CustomPainter {
  final bool isDark;
  final double borderRadius;

  _DockShadowPainter({
    required this.isDark,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.80)
        : Colors.white.withValues(alpha: 0.89);

    // Draw bottom shadow with rectangle for uniform darkness
    final shadowPaint = Paint()
      ..color = shadowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);

    // Draw shadow twice for darker effect (not 3 times)
    for (int i = 0; i < 2; i++) {
      // Draw large bottom shadow as a stretched rectangle for even coverage
      canvas.drawRect(
        Rect.fromLTWH(
          -10, // Extend left beyond bounds
          50, // Start further down (below dock top, no shadow on top)
          size.width + 20, // Full width plus overflow for sides
          80, // Height to cover blur
        ),
        shadowPaint,
      );
    }

    // Draw left side shadow that extends down - optional, can comment out
    // to only have bottom shadow
    shadowPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
    canvas.drawRect(
      Rect.fromLTWH(
        -5,
        50, // Start further down
        25,
        size.height - 50,
      ),
      shadowPaint,
    );

    // Draw right side shadow that extends down - optional
    canvas.drawRect(
      Rect.fromLTWH(
        size.width - 20,
        50, // Start further down
        25,
        size.height - 50,
      ),
      shadowPaint,
    );
  }

  @override
  bool shouldRepaint(_DockShadowPainter oldDelegate) {
    return oldDelegate.isDark != isDark ||
        oldDelegate.borderRadius != borderRadius;
  }
}
