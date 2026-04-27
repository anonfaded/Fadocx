import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:fadocx/config/routing/app_router.dart';

/// Floating overlay scaffold that places app bar and bottom dock as transparent
/// overlays, allowing content to scroll behind them like iOS/macOS style.
class FloatingDockScaffold extends StatefulWidget {
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
  State<FloatingDockScaffold> createState() => _FloatingDockScaffoldState();
}

class _FloatingDockScaffoldState extends State<FloatingDockScaffold> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topSafePadding = mediaQuery.padding.top;
    final bottomSafePadding = mediaQuery.padding.bottom;
    final appBarHeight = widget.appBarContent != null
        ? 40.0
        : 0.0; // Reduced from 56 to 40 for compact
    final dockHeight = widget.showBottomDock ? 72.0 : 0.0;

    // Determine status bar style based on current theme
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusBarStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light, // For iOS
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: statusBarStyle,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Stack(
          children: [
            // Main scrollable content - FULL SCREEN, scrolls behind overlays
            Positioned.fill(
              child: widget.body,
            ),

            // Floating top bar with blur (overlay on top)
            if (widget.appBarContent != null)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: appBarHeight + topSafePadding,
                child: _FloatingAppBar(
                  content: widget.appBarContent!,
                  topPadding: topSafePadding,
                ),
              ),

            // Floating bottom dock with blur (overlay on bottom) - FIXED in place, no animation
            if (widget.showBottomDock)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: RepaintBoundary(
                  child: _FloatingDock(
                    bottomPadding: bottomSafePadding,
                    currentRoute: widget.currentRoute,
                  ),
                ),
              ),

            // Floating action button - above the dock
            if (widget.floatingActionButton != null && widget.showBottomDock)
              Positioned(
                right: 16,
                bottom: dockHeight + bottomSafePadding + 8,
                child: widget.floatingActionButton!,
              ),
          ],
        ),
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
        // Main app bar with rounded bottom corners - FULL WIDTH
        ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Theme.of(context)
                        .colorScheme
                        .surface
                        .withValues(alpha: 0.95)
                    : Theme.of(context)
                        .colorScheme
                        .surface
                        .withValues(alpha: 0.92),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 40, // Compact height for content area
                  child: Center(child: content),
                ),
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
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        child: Stack(
          clipBehavior: Clip.none, // Allow shadows to extend outside
          children: [
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
                    child: SizedBox(
                      height: 48,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                        Expanded(
                          child: _DockItem(
                            icon: Icons.home,
                            label: 'Home',
                            isActive: currentRoute == RouteNames.home,
                            onTap: () {
                              if (currentRoute != RouteNames.home) {
                                context.go(RouteNames.home);
                              }
                            },
                          ),
                        ),
                        Expanded(
                          child: _DockItem(
                            icon: Icons.auto_stories,
                            label: 'Library',
                            isActive: currentRoute == RouteNames.documents,
                            onTap: () {
                              if (currentRoute != RouteNames.documents) {
                                context.go(RouteNames.documents);
                              }
                            },
                          ),
                        ),
                        Expanded(
                          child: _DockItem(
                            icon: Icons.settings,
                            label: 'Settings',
                            isActive: currentRoute == RouteNames.settings,
                            onTap: () {
                              if (currentRoute != RouteNames.settings) {
                                context.go(RouteNames.settings);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
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
}

/// Stateful dock item that manages its own animation state
class _DockItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _DockItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_DockItem> createState() => _DockItemState();
}

class _DockItemState extends State<_DockItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
      value: widget.isActive ? 1.0 : 0.0,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void didUpdateWidget(_DockItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive) {
        _controller.forward(from: 0.0);
      } else {
        _controller.reverse(from: 1.0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 300),
            alignment: Alignment.topCenter,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon - always visible with opacity animation
                SizedBox(
                  width: 18,
                  height: 18,
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: widget.isActive ? 1.0 : 0.55,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        widget.icon,
                        size: 18,
                        color: widget.isActive
                            ? Theme.of(context).colorScheme.secondary
                            : Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                // Label - only rendered when active, fades in/out
                if (widget.isActive) ...[
                  const SizedBox(height: 2),
                  SizedBox(
                    height: 16,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.visible,
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(
                              fontSize: 9,
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                ],
              ],
            ),

          ),
        ),
      ),
    );
  }
}
