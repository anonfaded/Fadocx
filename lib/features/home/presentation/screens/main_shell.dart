import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fadocx/core/presentation/widgets/floating_dock_scaffold.dart';
import 'package:fadocx/features/home/presentation/screens/home_screen.dart';
import 'package:fadocx/features/home/presentation/screens/documents_screen.dart';
import 'package:fadocx/features/settings/presentation/screens/settings_screen.dart';
import 'package:fadocx/features/home/presentation/widgets/home_drawer.dart';
import 'package:fadocx/features/home/presentation/providers/update_check_provider.dart';
import 'package:fadocx/config/routing/app_router.dart';
import 'package:fadocx/l10n/app_localizations.dart';

/// Main tab shell with fragment-style tab switching (like FadCam).
/// Uses AnimatedSwitcher + FadeTransition instead of PageView sliding.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with TickerProviderStateMixin {
  int _currentPage = 0;

  // Sidebar state
  bool _sidebarOpen = false;
  late AnimationController _sidebarController;
  late AnimationController _patreonShimmerController;
  double _sidebarDragOffset = 0.0;

  DateTime? _lastBackPress;
  static const Duration _backPressExitDuration = Duration(seconds: 2);

  static const double _kSidebarTopOffset = 87;
  static const double _kSidebarBottomOffset = 88;
  static const double _kSidebarRadius = 24.0;
  static const double _kDragCloseThreshold = 100.0;

  @override
  void initState() {
    super.initState();
    _sidebarController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _patreonShimmerController = AnimationController(
      duration: const Duration(milliseconds: 2800),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _sidebarController.dispose();
    _patreonShimmerController.dispose();
    super.dispose();
  }

  void _switchToPage(int page) {
    if (page == _currentPage || page < 0 || page > 2) return;
    setState(() => _currentPage = page);
  }

  void _toggleSidebar() {
    setState(() => _sidebarOpen = !_sidebarOpen);
    if (_sidebarOpen) {
      _sidebarController.forward();
    } else {
      _sidebarController.reverse();
    }
  }

  void _closeSidebar() {
    setState(() => _sidebarOpen = false);
    _sidebarController.reverse();
  }

  void _handleSidebarDragUpdate(DragUpdateDetails details) {
    setState(() {
      final isRTL = Directionality.of(context) == TextDirection.rtl;
      final delta = isRTL ? -details.delta.dx : details.delta.dx;
      _sidebarDragOffset += delta;
      _sidebarDragOffset = _sidebarDragOffset.clamp(-500.0, 0.0);
    });
  }

  void _handleSidebarDragEnd(DragEndDetails details) {
    if (_sidebarDragOffset < -_kDragCloseThreshold) {
      setState(() => _sidebarOpen = false);
      _sidebarController.reverse();
      Future.delayed(const Duration(milliseconds: 260), () {
        if (mounted && !_sidebarOpen) {
          setState(() => _sidebarDragOffset = 0.0);
        }
      });
    } else {
      setState(() => _sidebarDragOffset = 0.0);
    }
  }

  void _showPatreonSheet(BuildContext context) {
    const patreonUrl = 'https://patreon.com/c/fadedx';
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Icon(SimpleIcons.patreon, size: 48, color: Color(0xFFF86754)),
            const SizedBox(height: 12),
            Text(
              l10n.visitPatreon,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.patreonDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => launchUrl(Uri.parse(patreonUrl)),
                icon: const Icon(SimpleIcons.patreon),
                label: Text(l10n.visitPatreon),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── App Bar builders ──

  Widget _buildHomeAppBar(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Consumer(
              builder: (context, ref, _) {
                final updateState = ref.watch(autoUpdateCheckProvider);
                final hasUpdate = updateState is UpdateCheckAvailable;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedHamburgerIcon(
                      onPressed: _toggleSidebar,
                      isOpen: _sidebarOpen,
                    ),
                    if (hasUpdate)
                      Positioned(
                        top: -2,
                        right: -4,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.surface,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(width: 12),
            Image.asset(
              'assets/fadocx_header_landscape_png.png',
              height: 32,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 6),
            Text(
              AppLocalizations.of(context)!.homeTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const Spacer(),
            AnimatedBuilder(
              animation: _patreonShimmerController,
              builder: (context, child) {
                return GestureDetector(
                  onTap: () => _showPatreonSheet(context),
                  child: ShaderMask(
                    shaderCallback: (bounds) {
                      const cycle = 56.0;
                      final offset =
                          (_patreonShimmerController.value * cycle) % cycle;
                      return const LinearGradient(
                        tileMode: TileMode.repeated,
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Color(0xFFC9A214),
                          Color(0xFFFFE873),
                          Color(0xFFC9A214),
                        ],
                        stops: [0.0, 0.5, 1.0],
                      ).createShader(Rect.fromLTWH(
                        bounds.left - offset,
                        bounds.top,
                        cycle,
                        bounds.height,
                      ));
                    },
                    blendMode: BlendMode.srcIn,
                    child: const Icon(
                      SimpleIcons.patreon,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLibraryAppBar(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Text(
              AppLocalizations.of(context)!.navLibrary,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsAppBar(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Text(
              AppLocalizations.of(context)!.settingsTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBarForPage(int page) {
    switch (page) {
      case 0:
        return KeyedSubtree(
            key: const ValueKey(0), child: _buildHomeAppBar(context));
      case 1:
        return KeyedSubtree(
            key: const ValueKey(1), child: _buildLibraryAppBar(context));
      case 2:
        return KeyedSubtree(
            key: const ValueKey(2), child: _buildSettingsAppBar(context));
      default:
        return KeyedSubtree(
            key: const ValueKey(0), child: _buildHomeAppBar(context));
    }
  }

  // ── Tab content with swipe + fragment-style switching ──

  Widget _buildTabBody() {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity == null) return;
        final velocity = details.primaryVelocity!;
        if (velocity < -500) {
          // Swipe left → next tab
          if (_currentPage < 2) _switchToPage(_currentPage + 1);
        } else if (velocity > 500) {
          // Swipe right → previous tab, or drawer on Home
          if (_currentPage > 0) {
            _switchToPage(_currentPage - 1);
          } else {
            _toggleSidebar();
          }
        }
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: switch (_currentPage) {
          0 => HomeScreen(key: const ValueKey(0), tabMode: true),
          1 => DocumentsScreen(key: const ValueKey(1), tabMode: true),
          _ => SettingsScreen(key: const ValueKey(2), tabMode: true),
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          if (_lastBackPress == null ||
              DateTime.now().difference(_lastBackPress!) >
                  _backPressExitDuration) {
            _lastBackPress = DateTime.now();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text(AppLocalizations.of(context)!.homePressBackExit),
                duration: _backPressExitDuration,
              ),
            );
          } else {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            FloatingDockScaffold(
              currentRoute: RouteNames.home,
              activeTabIndex: _currentPage,
              onTabChanged: _switchToPage,
              appBarContent: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _buildAppBarForPage(_currentPage),
              ),
              body: _buildTabBody(),
            ),
            // Scrim overlay
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !_sidebarOpen,
                child: AnimatedBuilder(
                  animation: _sidebarController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _sidebarController.value,
                      child: GestureDetector(
                        onTap: _closeSidebar,
                        onHorizontalDragUpdate: (details) =>
                            _handleSidebarDragUpdate(details),
                        onHorizontalDragEnd: _handleSidebarDragEnd,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.45),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            // Sidebar
            AnimatedBuilder(
              animation: _sidebarController,
              builder: (context, child) {
                final isRTL =
                    Directionality.of(context) == TextDirection.rtl;
                return Positioned(
                  top: _kSidebarTopOffset - _kSidebarRadius,
                  bottom: _kSidebarBottomOffset - _kSidebarRadius,
                  left: isRTL ? null : 0,
                  right: isRTL ? 0 : null,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: isRTL
                          ? const Offset(1.0, 0.0)
                          : const Offset(-1.0, 0.0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _sidebarController,
                      curve: Curves.easeOutCubic,
                    )),
                    child: IgnorePointer(
                      ignoring: !_sidebarOpen,
                      child: _buildSidebarDrawer(context, isDark),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Sidebar drawer ──

  Widget _buildSidebarDrawer(BuildContext context, bool isDark) {
    final maxWidth = MediaQuery.of(context).size.width * 0.8;
    final width = maxWidth < 280 ? maxWidth : 280.0;
    final theme = Theme.of(context);
    final bgColor = isDark
        ? theme.colorScheme.surface.withValues(alpha: 0.95)
        : theme.colorScheme.surface.withValues(alpha: 0.93);
    final borderColor = theme.colorScheme.outline.withValues(alpha: 0.2);
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    return GestureDetector(
      onTap: () {},
      behavior: HitTestBehavior.opaque,
      onHorizontalDragUpdate: (details) =>
          _handleSidebarDragUpdate(details),
      onHorizontalDragEnd: _handleSidebarDragEnd,
      child: Transform.translate(
        offset:
            Offset(isRTL ? -_sidebarDragOffset : _sidebarDragOffset, 0),
        child: SizedBox(
          width: width + 20,
          child: ClipPath(
            clipper: _SidebarClipper(
              sidebarWidth: width,
              radius: _kSidebarRadius,
              isRTL: isRTL,
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _InvertedCornerSidebarPainter(
                        color: bgColor,
                        borderColor: borderColor,
                        radius: _kSidebarRadius,
                        sidebarWidth: width,
                        isRTL: isRTL,
                      ),
                    ),
                  ),
                  Positioned(
                    left: isRTL ? null : 0,
                    right: isRTL ? 0 : null,
                    top: _kSidebarRadius,
                    bottom: _kSidebarRadius,
                    width: width,
                    child: ClipRRect(
                      borderRadius: isRTL
                          ? const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              bottomLeft: Radius.circular(16),
                            )
                          : const BorderRadius.only(
                              topRight: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                      child: Material(
                        color: Colors.transparent,
                        child: HomeDrawer(
                          onClose: _closeSidebar,
                        ),
                      ),
                    ),
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

// ── Sidebar helper classes ──

class _SidebarClipper extends CustomClipper<Path> {
  final double sidebarWidth;
  final double radius;
  final bool isRTL;

  _SidebarClipper({
    required this.sidebarWidth,
    required this.radius,
    this.isRTL = false,
  });

  double _x(double x, Size size) => isRTL ? size.width - x : x;

  @override
  Path getClip(Size size) {
    final path = Path();

    path.moveTo(_x(0, size), 0);
    path.cubicTo(
      _x(0, size), radius * 0.4,
      _x(radius * 0.1, size), radius,
      _x(radius, size), radius,
    );
    path.lineTo(_x(sidebarWidth - 16, size), radius);
    path.arcToPoint(
      Offset(_x(sidebarWidth, size), radius + 16),
      radius: const Radius.circular(16),
      clockwise: !isRTL,
    );
    path.lineTo(_x(sidebarWidth, size), size.height - radius - 16);
    path.arcToPoint(
      Offset(_x(sidebarWidth - 16, size), size.height - radius),
      radius: const Radius.circular(16),
      clockwise: !isRTL,
    );
    path.lineTo(_x(radius, size), size.height - radius);
    path.cubicTo(
      _x(radius * 0.1, size), size.height - radius,
      _x(0, size), size.height - radius * 0.4,
      _x(0, size), size.height,
    );
    path.lineTo(_x(0, size), 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _SidebarClipper oldClipper) =>
      oldClipper.sidebarWidth != sidebarWidth || oldClipper.isRTL != isRTL;
}

class _InvertedCornerSidebarPainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  final double radius;
  final double sidebarWidth;
  final bool isRTL;

  _InvertedCornerSidebarPainter({
    required this.color,
    required this.borderColor,
    required this.radius,
    required this.sidebarWidth,
    this.isRTL = false,
  });

  double _x(double x, Size size) => isRTL ? size.width - x : x;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    Path buildPath(Size size) {
      final path = Path();

      path.moveTo(_x(0, size), 0);
      path.cubicTo(
        _x(0, size), radius * 0.4,
        _x(radius * 0.1, size), radius,
        _x(radius, size), radius,
      );
      path.lineTo(_x(sidebarWidth - 16, size), radius);
      path.arcToPoint(
        Offset(_x(sidebarWidth, size), radius + 16),
        radius: const Radius.circular(16),
        clockwise: !isRTL,
      );
      path.lineTo(_x(sidebarWidth, size), size.height - radius - 16);
      path.arcToPoint(
        Offset(_x(sidebarWidth - 16, size), size.height - radius),
        radius: const Radius.circular(16),
        clockwise: !isRTL,
      );
      path.lineTo(_x(radius, size), size.height - radius);
      path.cubicTo(
        _x(radius * 0.1, size), size.height - radius,
        _x(0, size), size.height - radius * 0.4,
        _x(0, size), size.height,
      );
      path.lineTo(_x(0, size), 0);
      path.close();
      return path;
    }

    final path = buildPath(size);

    canvas.drawShadow(path, Colors.black, 10, false);
    canvas.drawPath(path, paint);

    final borderPath = buildPath(size);
    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _InvertedCornerSidebarPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.borderColor != borderColor ||
      oldDelegate.isRTL != isRTL;
}
