import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:fadocx/config/routing/app_router.dart';
import 'package:fadocx/config/theme/app_theme.dart';
import 'package:fadocx/config/theme/theme_provider.dart';
import 'package:logger/logger.dart';
import 'package:fadocx/features/settings/data/datasources/hive_datasource.dart';
import 'package:fadocx/features/settings/presentation/providers/locale_provider.dart';
import 'package:fadocx/services/file_intent_service.dart';
import 'package:fadocx/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'dart:async';

final log = Logger();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive FIRST - pre-opens boxes
  await HiveDatasource.initialize();

  // Load theme from Hive to set correct system UI overlay style
  String savedTheme = 'dark'; // Default fallback
  try {
    final settings = await HiveDatasource().getSettings();
    if (settings?.theme != null) {
      savedTheme = settings!.theme;
      log.i('📱 Theme loaded from Hive: $savedTheme');
    }
  } catch (e) {
    log.w('⚠️ Could not load theme from Hive, using default: $e');
  }

  // Set system UI overlay style to match saved theme
  // IMPORTANT: Use statusBarIconBrightness (not deprecated statusBarBrightness)
  final isDarkTheme = savedTheme.toLowerCase() == 'dark';
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDarkTheme ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  log.d('✅ System UI overlay style set for $savedTheme theme');

  // Clear old thumbnail cache to regenerate with new system
  try {
    await HiveDatasource().clearThumbnailCache();
    log.i('✅ Thumbnail cache cleared on startup - will regenerate with new system');
  } catch (e) {
    log.e('Error clearing thumbnail cache on startup', error: e);
  }

  runApp(
    ProviderScope(
      overrides: [
        initialThemeProvider.overrideWithValue(savedTheme),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  StreamSubscription<String>? _fileIntentSub;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // Create router ONCE - prevents navigation reset on theme change
    _router = createGoRouter();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fileIntentSub = FileIntentService.fileIntentStream.listen((filePath) {
        if (!mounted) return;
        final encodedPath = Uri.encodeComponent(filePath);
        // Use the same router instance
        _router
            .push('/viewer?path=$encodedPath&name=${filePath.split('/').last}');
      }, onError: (e) => log.e('File intent error: $e'));
    });
  }

  @override
  void dispose() {
    _fileIntentSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Fadocx',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      // Use the pre-created router - never changes on rebuild
      routerConfig: _router,
    );
  }
}
