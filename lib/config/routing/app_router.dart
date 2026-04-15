import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fadocx/core/utils/logger.dart';
import 'package:fadocx/features/home/presentation/screens/home_screen.dart';
import 'package:fadocx/features/settings/presentation/screens/settings_screen.dart';
import 'package:fadocx/features/viewer/presentation/screens/viewer_screen.dart';

/// Route names constant
class RouteNames {
  static const String home = '/';
  static const String viewer = '/viewer';
  static const String settings = '/settings';
}

/// GoRouter configuration provider
GoRouter createGoRouter() {
  log.i('Creating GoRouter...');

  return GoRouter(
    initialLocation: RouteNames.home,
    debugLogDiagnostics: false, // Set to true for debugging
    errorBuilder: (context, state) {
      log.e('Route error: ${state.error}');
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Route not found: ${state.uri.toString()}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go(RouteNames.home),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      );
    },
    routes: [
      // Home screen
      GoRoute(
        path: RouteNames.home,
        name: 'home',
        builder: (context, state) {
          log.d('Navigating to home');
          return const HomeScreen();
        },
      ),

      // Document viewer screen
      GoRoute(
        path: RouteNames.viewer,
        name: 'viewer',
        builder: (context, state) {
          final filePath = state.uri.queryParameters['path'];
          final fileName = state.uri.queryParameters['name'];
          
          if (filePath == null || filePath.isEmpty) {
            log.w('Document path is empty, redirecting to home');
            return Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.warning, size: 64),
                    const SizedBox(height: 16),
                    const Text('Invalid document path'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.go(RouteNames.home),
                      child: const Text('Go Home'),
                    ),
                  ],
                ),
              ),
            );
          }
          
          log.d('Navigating to viewer: $filePath');
          final displayName = fileName ?? (filePath.split('/').last);
          
          return ViewerScreen(
            filePath: filePath,
            fileName: displayName,
          );
        },
      ),

      // Settings screen
      GoRoute(
        path: RouteNames.settings,
        name: 'settings',
        builder: (context, state) {
          log.d('Navigating to settings');
          return const SettingsScreen();
        },
      ),
    ],

    // Handle redirects including file intents from other apps
    redirect: (context, state) {
      final uri = state.uri.toString();
      
      // Log route for debugging
      log.d('Route: $uri');
      
      // If URI is a content:// or file:// scheme (file intent from other app),
      // redirect to viewer with the URI as the file path
      if (uri.startsWith('content://') || uri.startsWith('file://')) {
        log.i('File intent detected: $uri');
        // Navigate to viewer with the content URI directly
        // The viewer will handle reading the file
        final encodedPath = Uri.encodeComponent(uri);
        return '/viewer?path=$encodedPath';
      }
      
      return null; // No redirects for standard routes
    },

    // Refresh listenable for reactive navigation (Phase 2+)
    refreshListenable: null,
  );
}
