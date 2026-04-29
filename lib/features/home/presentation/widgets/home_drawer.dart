import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fadocx/config/routing/app_router.dart';
import 'package:fadocx/features/settings/presentation/providers/settings_providers.dart';
import 'package:fadocx/core/presentation/widgets/drawer_update_banner.dart';
import 'package:fadocx/core/presentation/constants.dart';

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

    // Top line
    canvas.drawLine(
      Offset(0, yOffset),
      Offset(size.width * 0.75, yOffset),
      paint,
    );

    // Bottom line
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

              // Donation card with gold shimmer
              const SizedBox(height: 8),
              _buildDonateCard(context),
            ],
          ),
        ),

        // Footer with copyright + Discord
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: InkWell(
            onTap: () => _openUrl('https://fadseclab.com'),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: '\u00a9 ',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.redAccent,
                            ),
                        children: [
                          TextSpan(
                            text: 'fadseclab.com',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.redAccent,
                                ),
                          ),
                          TextSpan(
                            text: ' 2024 \u2013 2026',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.redAccent,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Discord icon
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _openUrl('https://discord.gg/kvAZvdkuuN'),
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          SimpleIcons.discord,
                          size: 18,
                          color: const Color(0xFF5865F2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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

  Widget _buildDonateCard(BuildContext context) {
    const goldColor = Color(0xFFD4A017);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ShimmerWidget(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showPatreonSheet(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: goldColor.withValues(alpha: isDark ? 0.1 : 0.07),
                border: Border.all(
                  color: goldColor.withValues(alpha: isDark ? 0.25 : 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: goldColor.withValues(alpha: isDark ? 0.18 : 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      SimpleIcons.patreon,
                      size: 16,
                      color: goldColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Support Development',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: goldColor,
                              ),
                        ),
                        Text(
                          'Unlock exclusive benefits',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: goldColor.withValues(alpha: 0.7),
                              ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: goldColor.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showPatreonSheet(BuildContext context) {
    const patreonUrl = 'https://patreon.com/c/fadedx';
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: brightness == Brightness.dark
              ? const Color(0xFF1C1C1E)
              : const Color(0xFFF2F2F7),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        ),
        padding: EdgeInsets.only(
          top: 6,
          bottom: MediaQuery.of(context).padding.bottom + 6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 36,
              height: 5,
              margin: const EdgeInsets.only(top: 4, bottom: 12),
              decoration: BoxDecoration(
                color: brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            // Patreon icon + title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
              child: Column(
                children: [
                  const Icon(SimpleIcons.patreon, size: 40, color: Color(0xFFD4A017)),
                  const SizedBox(height: 12),
                  Text(
                    'Support Development',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Explanation
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                patreonDescription,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            // Visit Patreon
            _sheetActionButton(
              context,
              icon: SimpleIcons.patreon,
              label: 'Visit Patreon',
              onTap: () {
                Navigator.pop(ctx);
                _openUrl(patreonUrl);
              },
            ),
            const SizedBox(height: 8),
            // Copy link
            _sheetActionButton(
              context,
              icon: Icons.content_copy,
              label: 'Copy Link',
              onTap: () {
                Clipboard.setData(ClipboardData(text: patreonUrl));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _sheetActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final brightness = Theme.of(context).brightness;
    final bgColor = brightness == Brightness.dark
        ? const Color(0xFF2C2C2E)
        : Colors.white;
    final textColor = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          color: bgColor,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 20, color: textColor),
                    const SizedBox(width: 10),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w500,
                          ),
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

  void _openUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
}

/// Gold shimmer animation for the donation card
class ShimmerWidget extends StatefulWidget {
  final Widget child;
  const ShimmerWidget({super.key, required this.child});

  @override
  State<ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: const [
              Colors.transparent,
              Color(0x55FFD700),
              Colors.transparent,
            ],
            stops: [
              (_animation.value - 0.3).clamp(0.0, 1.0),
              _animation.value.clamp(0.0, 1.0),
              (_animation.value + 0.3).clamp(0.0, 1.0),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ).createShader(bounds),
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
