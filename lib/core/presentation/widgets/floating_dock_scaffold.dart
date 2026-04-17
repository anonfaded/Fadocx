import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fadocx/features/home/presentation/widgets/bottom_nav_dock.dart';

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

    return Stack(
      children: [
        // Shadow above the bottom dock
        Positioned(
          top: -8,
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
                  offset: const Offset(0, -4),
                ),
              ],
            ),
          ),
        ),
        // Main dock
        ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surface
                    .withValues(alpha: 0.8),
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BottomNavDock(currentRoute: currentRoute),
                  SizedBox(height: bottomPadding),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
