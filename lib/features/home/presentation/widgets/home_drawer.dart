import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fadocx/config/routing/app_router.dart';
import 'package:fadocx/features/settings/presentation/providers/settings_providers.dart';

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
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    const lineSpacing = 6.5;
    const yOffset = 2.0;

    canvas.drawLine(
      Offset(0, yOffset),
      Offset(size.width * 0.7, yOffset),
      paint,
    );

    canvas.drawLine(
      Offset(0, lineSpacing + yOffset),
      Offset(size.width * bottomLineFactor, lineSpacing + yOffset),
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
  const HomeDrawer({super.key});

  @override
  ConsumerState<HomeDrawer> createState() => _HomeDrawerState();
}

class _HomeDrawerState extends ConsumerState<HomeDrawer> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Drawer(
        child: Column(
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
                  ListTile(
                    leading: const Icon(Icons.auto_awesome),
                    title: const Text("What's New"),
                    trailing: Icon(
                      Icons.arrow_forward,
                      size: 18,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      context.push(RouteNames.whatsNew);
                    },
                  ),
                  const SizedBox(height: 8),

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
        ),
      ),
    );
  }

  Widget _buildRecentFilesToggle(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.surfaceContainerLow,
      ),
      child: Consumer(
        builder: (context, ref, _) {
          final showRecentFiles = ref.watch(showRecentFilesProvider);

          return ListTile(
            leading: Icon(
              showRecentFiles ? Icons.visibility : Icons.visibility_off,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Recent Files'),
            subtitle: Text(
              showRecentFiles ? 'Visible' : 'Hidden',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            trailing: Switch(
              value: showRecentFiles,
              onChanged: (value) {
                ref.read(showRecentFilesProvider.notifier).setShowRecentFiles(value);
              },
            ),
            onTap: () {
              ref.read(showRecentFilesProvider.notifier).toggle();
            },
          );
        },
      ),
    );
  }
}
