import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:fadocx/config/routing/app_router.dart';
import 'package:fadocx/config/theme/app_theme.dart';
import 'package:fadocx/config/theme/theme_provider.dart';
import 'package:fadocx/core/utils/logger.dart';
import 'package:fadocx/features/settings/data/datasources/hive_datasource.dart';
import 'package:fadocx/features/settings/presentation/providers/locale_provider.dart';
import 'package:fadocx/l10n/app_localizations.dart';

void main() async {
  // Initialize Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();

  log.i('═══════════════════════════════════════════════════════════');
  log.i('🚀 Starting Fadocx Application');
  log.i('═══════════════════════════════════════════════════════════');

  try {
    // Initialize Hive database
    log.i('Initializing local database (Hive)...');
    await HiveDatasource.initialize();
    log.i('✅ Hive initialized successfully');
  } catch (e, st) {
    log.e('❌ Failed to initialize Hive', e, st);
  }

  log.i('🎨 Starting Fadocx UI...');
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch theme mode and locale
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    log.d('Building MyApp with theme: ${themeMode.name}, locale: ${locale.languageCode}');

    return MaterialApp.router(
      title: 'Fadocx',
      debugShowCheckedModeBanner: false,

      // Theme configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,

      // Localization (flutter_localizations + app_en.arb + app_ur.arb)
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,

      // Routing
      routerConfig: createGoRouter(),

      // App-wide builders
      builder: (context, child) {
        log.v('Building widget tree with themeMode: ${themeMode.name}');
        return child ?? const Placeholder();
      },
    );
  }
}
