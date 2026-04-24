import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:fadocx/features/home/presentation/screens/home_screen.dart';
import 'package:fadocx/features/home/presentation/screens/documents_screen.dart';
import 'package:fadocx/features/home/presentation/screens/browse_screen.dart';
import 'package:fadocx/features/home/presentation/screens/trash_screen.dart';
import 'package:fadocx/features/home/presentation/screens/whats_new_screen.dart';
import 'package:fadocx/features/settings/presentation/screens/settings_screen.dart';
import 'package:fadocx/features/viewer/presentation/screens/viewer_screen.dart';
import 'package:fadocx/features/scanner/presentation/screens/scanner_screen.dart';
import 'package:fadocx/features/viewer/presentation/screens/lokit_test_screen.dart';

final log = Logger();

/// Route names constant
class RouteNames {
  static const String home = '/';
  static const String documents = '/documents';
  static const String browse = '/browse';
  static const String trash = '/trash';
  static const String viewer = '/viewer';
  static const String settings = '/settings';
  static const String scanner = '/scanner';
  static const String whatsNew = '/whats-new';
  static const String lokitTest = '/lokit-test';
}

/// Global router instance - singleton to prevent navigation reset on rebuild
GoRouter? _routerInstance;

/// Current route location preserved across rebuilds
String _currentLocation = RouteNames.home;

/// Helper to create a fade transition page
Page<dynamic> _fadeTransitionPage(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<dynamic>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}

/// GoRouter configuration provider
GoRouter createGoRouter() {
  // Return existing instance if available to prevent navigation reset
  if (_routerInstance != null) {
    log.d('Reusing existing GoRouter instance at: $_currentLocation');
    return _routerInstance!;
  }

  log.i('Creating GoRouter...');

  _routerInstance = GoRouter(
    initialLocation: _currentLocation,
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
        pageBuilder: (context, state) {
          log.d('Navigating to home');
          return _fadeTransitionPage(context, state, const HomeScreen());
        },
      ),

      // Documents screen
      GoRoute(
        path: RouteNames.documents,
        name: 'documents',
        pageBuilder: (context, state) {
          log.d('Navigating to documents');
          return _fadeTransitionPage(context, state, const DocumentsScreen());
        },
      ),

      // Browse screen
      GoRoute(
        path: RouteNames.browse,
        name: 'browse',
        pageBuilder: (context, state) {
          log.d('Navigating to browse');
          return _fadeTransitionPage(context, state, const BrowseScreen());
        },
      ),

      // Trash screen
      GoRoute(
        path: RouteNames.trash,
        name: 'trash',
        pageBuilder: (context, state) {
          log.d('Navigating to trash');
          return _fadeTransitionPage(context, state, const TrashScreen());
        },
      ),

      // Document viewer screen
      GoRoute(
        path: RouteNames.viewer,
        name: 'viewer',
        pageBuilder: (context, state) {
          final filePath = state.uri.queryParameters['path'];
          final fileName = state.uri.queryParameters['name'];

          if (filePath == null || filePath.isEmpty) {
            log.w('Document path is empty, redirecting to home');
            final errorWidget = Scaffold(
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
            return _fadeTransitionPage(context, state, errorWidget);
          }

          log.d('Navigating to viewer: $filePath');
          final displayName = fileName ?? (filePath.split('/').last);

          return _fadeTransitionPage(
            context,
            state,
            ViewerScreen(
              filePath: filePath,
              fileName: displayName,
            ),
          );
        },
      ),

      // Settings screen
      GoRoute(
        path: RouteNames.settings,
        name: 'settings',
        pageBuilder: (context, state) {
          log.d('Navigating to settings');
          return _fadeTransitionPage(context, state, const SettingsScreen());
        },
      ),


       // LOKit test screen
       GoRoute(
          path: RouteNames.lokitTest,
          name: 'lokit_test',
          pageBuilder: (context, state) {
            return _fadeTransitionPage(context, state, const LOKitTestScreen());
          },
        ),

       // Scanner screen
       GoRoute(
         path: RouteNames.scanner,
         name: 'scanner',
         pageBuilder: (context, state) {
           log.d('Navigating to scanner');
           return _fadeTransitionPage(context, state, const ScannerScreen());
         },
       ),

       // What's New screen
       GoRoute(
         path: RouteNames.whatsNew,
         name: 'whats_new',
         pageBuilder: (context, state) {
           log.d('Navigating to what\'s new');
           return _fadeTransitionPage(context, state, const WhatsNewScreen());
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

  // Update current location when route changes
  _routerInstance!.routerDelegate.addListener(() {
    // ignore: unnecessary_non_null_assertion
    _currentLocation = _routerInstance!.state!.uri.toString();
  });

  return _routerInstance!;
}
