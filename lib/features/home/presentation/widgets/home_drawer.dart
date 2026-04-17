import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fadocx/config/routing/app_router.dart';
import 'package:fadocx/features/settings/presentation/providers/settings_providers.dart';

/// Custom hamburger icon with 2 lines (bottom line shorter)
class CustomHamburgerIcon extends StatelessWidget {
  final VoidCallback onPressed;
  final Color? color;
  final bool sidebarOpen;

  const CustomHamburgerIcon({
    super.key,
    required this.onPressed,
    this.color,
    this.sidebarOpen = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? Theme.of(context).colorScheme.onSurface;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          width: 24,
          height: 28,
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: sidebarOpen ? 0.35 : 0.7,
                end: sidebarOpen ? 0.7 : 0.35,
              ),
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return CustomPaint(
                  size: const Size(14, 10),
                  painter: HamburgerPainter(
                    color: iconColor,
                    bottomLineFactor: value,
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

    // Top line - 70% width
    canvas.drawLine(
      Offset(0, yOffset),
      Offset(size.width * 0.7, yOffset),
      paint,
    );

    // Bottom line - animated width
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
