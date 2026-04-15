import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fadocx/l10n/app_localizations.dart';
import 'package:fadocx/features/viewer/presentation/widgets/spreadsheet_table.dart';
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

    // Load document on first build
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
              ? _buildErrorState(context, docState)
              : docState.document != null
                  ? _buildDocumentContent(context, ref, docState, uiState)
                  : const Center(child: Text('No content')),
    );
  }

  /// Loading state with optional parsing status
  Widget _buildLoadingState(BuildContext context, ParsedDocumentState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          if (state.parsingStatus != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                state.parsingStatus!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
        ],
      ),
    );
  }

  /// Error state with retry option
  Widget _buildErrorState(BuildContext context, ParsedDocumentState state) {
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
          ElevatedButton(
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

    if (doc.isSpreadsheet) {
      return _buildSpreadsheetViewer(context, ref, docState, uiState);
    } else if (doc.isText) {
      return _buildTextViewer(context, doc);
    } else {
      return Center(
        child: Text('Format ${doc.format} not yet supported for preview'),
      );
    }
  }

  /// Spreadsheet viewer with professional UI
  Widget _buildSpreadsheetViewer(
    BuildContext context,
    WidgetRef ref,
    ParsedDocumentState docState,
    SpreadsheetUIState uiState,
  ) {
    final sheets = docState.document!.sheets;

    if (sheets.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context)?.tableNoContent ?? 'No sheets'),
      );
    }

    // Single sheet view
    if (sheets.length == 1) {
      final sheet = sheets.first;
      return GestureDetector(
        onScaleUpdate: (details) {
          ref.read(spreadsheetUIProvider.notifier).setZoomLevel(
                uiState.zoomLevel * details.scale,
              );
        },
        child: SpreadsheetTable(
          rows: sheet.rows,
          sheetName: sheet.name,
          zoomLevel: uiState.zoomLevel,
          selectedRow: uiState.selectedRow,
          selectedColumn: uiState.selectedColumn,
          onRowSelected: (rowIndex) {
            ref.read(spreadsheetUIProvider.notifier).selectRow(rowIndex);
          },
          onColumnSelected: (colIndex) {
            ref.read(spreadsheetUIProvider.notifier).selectColumn(colIndex);
          },
          onZoomChanged: (zoom) {
            ref.read(spreadsheetUIProvider.notifier).setZoomLevel(zoom);
          },
        ),
      );
    }

    // Multiple sheets: tabbed view
    return DefaultTabController(
      length: sheets.length,
      child: Column(
        children: [
          TabBar(
            tabs: sheets
                .map((sheet) => Tab(text: sheet.name))
                .toList(),
          ),
          Expanded(
            child: TabBarView(
              children: sheets
                  .map((sheet) =>
                      GestureDetector(
                        onScaleUpdate: (details) {
                          ref.read(spreadsheetUIProvider.notifier).setZoomLevel(
                            uiState.zoomLevel * details.scale,
                          );
                        },
                        child: SpreadsheetTable(
                          rows: sheet.rows,
                          sheetName: sheet.name,
                          zoomLevel: uiState.zoomLevel,
                          selectedRow: uiState.selectedRow,
                          selectedColumn: uiState.selectedColumn,
                          onRowSelected: (rowIndex) {
                            ref.read(spreadsheetUIProvider.notifier).selectRow(rowIndex);
                          },
                          onColumnSelected: (colIndex) {
                            ref.read(spreadsheetUIProvider.notifier).selectColumn(colIndex);
                          },
                          onZoomChanged: (zoom) {
                            ref.read(spreadsheetUIProvider.notifier).setZoomLevel(zoom);
                          },
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Text document viewer with lazy loading
  Widget _buildTextViewer(BuildContext context, document) {
    final text = document.textContent ?? '';
    final lines = text.split('\n');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lines.length,
      itemExtent: 22.0,
      itemBuilder: (context, index) {
        return Text(
          lines[index],
          style: Theme.of(context).textTheme.bodyMedium,
        );
      },
    );
  }
}


