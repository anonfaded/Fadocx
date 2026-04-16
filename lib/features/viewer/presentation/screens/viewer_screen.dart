import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fadocx/config/theme/theme_provider.dart';
import 'package:fadocx/features/settings/data/datasources/hive_datasource.dart';
import 'package:fadocx/features/settings/data/models/hive_models.dart';
import 'package:fadocx/features/viewer/presentation/widgets/document_viewer_factory.dart';
import 'package:fadocx/features/viewer/presentation/providers/document_viewer_notifier.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ViewerScreen extends ConsumerWidget {
  final String filePath;
  final String fileName;

  const ViewerScreen({
    required this.filePath,
    required this.fileName,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docState = ref.watch(documentViewerProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!docState.isLoading &&
          docState.document == null &&
          !docState.hasError) {
        ref
            .read(documentViewerProvider.notifier)
            .initializeAndLoad(filePath, fileName);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          // Theme toggle - switch dark/light without leaving viewer
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            tooltip: Theme.of(context).brightness == Brightness.dark
                ? 'Switch to light'
                : 'Switch to dark',
            onPressed: () async {
              final notifier = ref.read(themeModeProvider.notifier);
              notifier.toggleThemeMode();
              // Persist to Hive
              final mode = ref.read(themeModeProvider);
              final box =
                  Hive.box<HiveAppSettings>(HiveDatasource.settingsBoxName);
              final settings = box.values.firstOrNull ?? HiveAppSettings();
              await box.put(0, settings.copyWith(theme: mode.value));
            },
          ),
        ],
      ),
      body: docState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : docState.hasError
              ? _buildErrorState(context, ref, docState)
              : docState.document != null
                  ? DocumentViewerFactory.createViewer(
                      document: docState.document!,
                      filePath: filePath,
                    )
                  : const Center(child: Text('No content')),
    );
  }

  Widget _buildErrorState(
      BuildContext context, WidgetRef ref, ParsedDocumentState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              state.error ?? 'Error loading document',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              ref
                  .read(documentViewerProvider.notifier)
                  .initializeAndLoad(filePath, fileName);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }
}
