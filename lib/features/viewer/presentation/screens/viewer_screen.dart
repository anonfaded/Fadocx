import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fadocx/features/viewer/presentation/widgets/document_viewer_factory.dart';
import 'package:fadocx/features/viewer/presentation/providers/document_viewer_notifier.dart';
import 'package:fadocx/features/viewer/presentation/providers/spreadsheet_ui_notifier.dart';

/// Clean separation of concerns:
/// - DocumentViewerNotifier handles all parsing logic via repository
/// - SpreadsheetUINotifier handles UI state (zoom, selection, etc.)
/// - This widget is purely presentational
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
    // Watch the document viewer state (handles parsing)
    final docState = ref.watch(documentViewerProvider);

    // Watch spreadsheet UI state (zoom, selection)
    final uiState = ref.watch(spreadsheetUIProvider);

    // Load document on first build (autoDispose provider ensures clean state per screen)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!docState.isLoading && docState.document == null && !docState.hasError) {
        ref
            .read(documentViewerProvider.notifier)
            .initializeAndLoad(filePath, fileName);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: docState.isLoading
          ? _buildLoadingState(context, docState)
          : docState.hasError
              ? _buildErrorState(context, ref, docState)
              : docState.document != null
                  ? _buildDocumentContent(context, ref, docState, uiState)
                  : const Center(child: Text('No content')),
    );
  }

  /// Loading state with animated progress indicator
  Widget _buildLoadingState(BuildContext context, ParsedDocumentState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Parsing document...',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          if (state.parsingStatus != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                state.parsingStatus!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'This may take a moment for large files...',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
              ),
            ),
        ],
      ),
    );
  }

  /// Error state with retry option
  Widget _buildErrorState(BuildContext context, WidgetRef ref, ParsedDocumentState state) {
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

  /// Route to appropriate viewer based on document format
  Widget _buildDocumentContent(
    BuildContext context,
    WidgetRef ref,
    ParsedDocumentState docState,
    SpreadsheetUIState uiState,
  ) {
    final doc = docState.document!;

    // Use DocumentViewerFactory for all format routing
    return DocumentViewerFactory.createViewer(
      document: doc,
      filePath: filePath,
    );
  }
}


