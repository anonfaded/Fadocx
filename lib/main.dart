import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fadocx/config/routing/app_router.dart';
import 'package:fadocx/config/theme/app_theme.dart';
import 'package:fadocx/config/theme/theme_provider.dart';
import 'package:fadocx/core/utils/logger.dart';
import 'package:fadocx/features/settings/data/datasources/hive_datasource.dart';
import 'package:fadocx/features/settings/data/models/hive_models.dart';
import 'package:fadocx/features/settings/presentation/providers/locale_provider.dart';
import 'package:fadocx/features/viewer/data/services/cache_service.dart';
import 'package:fadocx/services/file_intent_service.dart';
import 'package:fadocx/l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await HiveDatasource.initialize();

    // Restore saved theme before runApp to avoid dark-mode flash
    final settingsBox =
        Hive.box<HiveAppSettings>(HiveDatasource.settingsBoxName);
    final savedTheme = settingsBox.values.firstOrNull?.theme ?? 'dark';

    final cacheService = HiveCacheService();
    await cacheService.initialize();
    await FileIntentService.initialize();

    runApp(ProviderScope(
      overrides: [initialThemeProvider.overrideWithValue(savedTheme)],
      child: const MyApp(),
    ));
  } catch (e, st) {
    log.e('Failed to initialize', e, st);
    runApp(const ProviderScope(child: MyApp()));
  }
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
