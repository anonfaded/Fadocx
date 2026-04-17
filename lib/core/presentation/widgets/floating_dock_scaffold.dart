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
          children: [
            // Strong shadows (top, bottom, sides)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    // Top shadow
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.6)
                          : Colors.black.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, -8),
                      spreadRadius: 4,
                    ),
                    // Bottom shadow
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.7)
                          : Colors.black.withValues(alpha: 0.5),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                      spreadRadius: 6,
                    ),
                  ],
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
