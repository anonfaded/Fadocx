import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fadocx/config/theme/theme_provider.dart';
import 'package:fadocx/features/settings/data/datasources/hive_datasource.dart';
import 'package:fadocx/features/settings/data/models/hive_models.dart';
import 'package:fadocx/features/viewer/presentation/widgets/document_viewer_factory.dart';
import 'package:fadocx/features/viewer/presentation/providers/document_viewer_notifier.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ViewerScreen extends ConsumerStatefulWidget {
  final String filePath;
  final String fileName;

  const ViewerScreen({
    required this.filePath,
    required this.fileName,
    super.key,
  });

  @override
  ConsumerState<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends ConsumerState<ViewerScreen> {
  bool _invertColors = false;
  bool _textMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final docState = ref.read(documentViewerProvider);
      if (!docState.isLoading &&
          docState.document == null &&
          !docState.hasError) {
        ref
            .read(documentViewerProvider.notifier)
            .initializeAndLoad(widget.filePath, widget.fileName);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final docState = ref.watch(documentViewerProvider);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.zero,
        child: Container(),
      ),
      body: Stack(
        children: [
          // Main content
          docState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : docState.hasError
                  ? _buildErrorState(context, ref, docState)
                  : docState.document != null
                      ? DocumentViewerFactory.createViewer(
                          document: docState.document!,
                          filePath: widget.filePath,
                          invertColors: _invertColors,
                          textMode: _textMode,
                          onInvertToggle: () {
                            setState(() => _invertColors = !_invertColors);
                          },
                          onTextModeToggle: () {
                            setState(() => _textMode = !_textMode);
                          },
                        )
                      : const Center(child: Text('No content')),

          // Top floating dock
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: _buildTopDock(context, ref),
          ),

          // Right floating dock
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: _buildControlDock(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTopDock(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => context.pop(),
            tooltip: 'Back',
            iconSize: 22,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                widget.fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            tooltip: 'Theme',
            onPressed: () async {
              final notifier = ref.read(themeModeProvider.notifier);
              notifier.toggleThemeMode();
              final mode = ref.read(themeModeProvider);
              final box =
                  Hive.box<HiveAppSettings>(HiveDatasource.settingsBoxName);
              final settings = box.values.firstOrNull ?? HiveAppSettings();
              await box.put(0, settings.copyWith(theme: mode.value));
            },
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildControlDock(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              _invertColors ? Icons.brightness_high : Icons.brightness_low,
            ),
            tooltip: 'Invert colors',
            onPressed: () {
              setState(() => _invertColors = !_invertColors);
            },
            iconSize: 20,
          ),
          IconButton(
            icon: Icon(
              _textMode ? Icons.picture_as_pdf : Icons.text_snippet,
            ),
            tooltip: _textMode ? 'PDF mode' : 'Text mode',
            onPressed: () {
              setState(() => _textMode = !_textMode);
            },
            iconSize: 20,
          ),
        ],
      ),
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
                  .initializeAndLoad(widget.filePath, widget.fileName);
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
