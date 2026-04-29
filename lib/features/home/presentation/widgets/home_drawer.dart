import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fadocx/config/routing/app_router.dart';
import 'package:fadocx/features/settings/presentation/providers/settings_providers.dart';
import 'package:fadocx/core/presentation/widgets/drawer_update_banner.dart';

/// Custom animated hamburger icon with bottom line that grows when sidebar opens
class AnimatedHamburgerIcon extends StatefulWidget {
  final VoidCallback onPressed;
  final Color? color;
  final bool isOpen;

  const AnimatedHamburgerIcon({
    super.key,
    required this.onPressed,
    this.color,
    this.isOpen = false,
  });

  @override
  State<AnimatedHamburgerIcon> createState() => _AnimatedHamburgerIconState();
}

class _AnimatedHamburgerIconState extends State<AnimatedHamburgerIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
      value: widget.isOpen ? 1.0 : 0.0,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didUpdateWidget(AnimatedHamburgerIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isOpen != widget.isOpen) {
      if (widget.isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
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
    final iconColor = widget.color ?? Theme.of(context).colorScheme.onSurface;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onPressed,
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          width: 24,
          height: 28,
          child: Center(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                final bottomLineFactor = 0.35 + (_animation.value * 0.35);
                return CustomPaint(
                  size: const Size(14, 10),
                  painter: HamburgerPainter(
                    color: iconColor,
                    bottomLineFactor: bottomLineFactor,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Painter for custom hamburger icon
class HamburgerPainter extends CustomPainter {
  final Color color;
  final double bottomLineFactor;

  HamburgerPainter({
    required this.color,
    this.bottomLineFactor = 0.35,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    const lineSpacing = 6.5;
    const yOffset = 2.0;

    // Top line - slightly increased width from 0.7 to 0.75
    canvas.drawLine(
      Offset(0, yOffset),
      Offset(size.width * 0.75, yOffset),
      paint,
    );

    // Bottom line - maintains same ratio (0.375 is 50% of 0.75)
    canvas.drawLine(
      Offset(0, lineSpacing + yOffset),
      Offset(size.width * (bottomLineFactor * 1.07), lineSpacing + yOffset),
      paint,
    );
  }

  @override
  bool shouldRepaint(HamburgerPainter oldDelegate) =>
      oldDelegate.bottomLineFactor != bottomLineFactor ||
      oldDelegate.color != color;
}

/// Side drawer widget
class HomeDrawer extends ConsumerStatefulWidget {
  final VoidCallback? onClose;
  
  const HomeDrawer({super.key, this.onClose});

  @override
  ConsumerState<HomeDrawer> createState() => _HomeDrawerState();
}

class _HomeDrawerState extends ConsumerState<HomeDrawer> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/fadocx_header_landscape_png.png',
                    height: 32,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Fadocx',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Document Management',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        const SizedBox(height: 8),

        // Menu items
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              // What's New
              _buildDrawerCard(
                context,
                icon: Icons.auto_awesome,
                title: "What's New",
                onTap: () {
                  widget.onClose?.call();
                  context.push(RouteNames.whatsNew);
                },
              ),

              // Update available banner (auto-hides when no update)
              const DrawerUpdateBanner(),
              const SizedBox(height: 12),

              // Recent Files visibility toggle
              _buildRecentFilesToggle(context),
            ],
          ),
        ),

        // Footer
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'v1.0.0',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildDrawerCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentFilesToggle(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final showRecentFiles = ref.watch(showRecentFilesProvider);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              ref.read(showRecentFilesProvider.notifier).toggle();
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      showRecentFiles ? Icons.visibility : Icons.visibility_off,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recent Files',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        Text(
                          showRecentFiles ? 'Visible' : 'Hidden',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    child: Switch(
                      value: showRecentFiles,
                      onChanged: (value) {
                        ref.read(showRecentFilesProvider.notifier).setShowRecentFiles(value);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
