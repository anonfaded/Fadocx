import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fadocx/config/routing/app_router.dart';
import 'package:fadocx/features/settings/presentation/providers/settings_providers.dart';

/// Custom hamburger icon with 2 lines (bottom line shorter)
class CustomHamburgerIcon extends StatelessWidget {
  final VoidCallback onPressed;
  final Color? color;

  const CustomHamburgerIcon({
    super.key,
    required this.onPressed,
    this.color,
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
          width: 36,
          height: 32,
          child: Center(
            child: CustomPaint(
              size: const Size(20, 14),
              painter: HamburgerPainter(color: iconColor),
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

  HamburgerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    const lineSpacing = 6.5; // Gap between lines

    // Top line - 70% width
    canvas.drawLine(
      const Offset(0, 0),
      Offset(size.width * 0.7, 0),
      paint,
    );

    // Bottom line - 35% width (much shorter, more from right)
    canvas.drawLine(
      const Offset(0, lineSpacing),
      Offset(size.width * 0.35, lineSpacing),
      paint,
    );
  }

  @override
  bool shouldRepaint(HamburgerPainter oldDelegate) => false;
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
    return Drawer(
      child: SafeArea(
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
