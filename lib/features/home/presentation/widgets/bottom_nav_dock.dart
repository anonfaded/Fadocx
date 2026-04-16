import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fadocx/config/routing/app_router.dart';

/// Bottom navigation dock
class BottomNavDock extends StatelessWidget {
  final String currentRoute;

  const BottomNavDock({
    required this.currentRoute,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Container(
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(
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
              _buildNavItem(
                context,
                icon: Icons.history,
                label: 'Recents',
                isActive: false, // Recents is shown on home, not separate route
                onTap: () {
                  if (currentRoute != RouteNames.home) {
                    context.go(RouteNames.home);
                  }
                },
              ),
              _buildNavItem(
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
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isActive
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isActive
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
