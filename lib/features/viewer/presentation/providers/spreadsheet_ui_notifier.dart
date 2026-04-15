import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State for SpreadsheetTable UI controls
class SpreadsheetUIState {
  final double zoomLevel;
  final int? selectedRow;
  final int? selectedColumn;
  final ScrollController? horizontalScrollController;
  final ScrollController? verticalScrollController;

  const SpreadsheetUIState({
    this.zoomLevel = 1.0,
    this.selectedRow,
    this.selectedColumn,
    this.horizontalScrollController,
    this.verticalScrollController,
  });

  SpreadsheetUIState copyWith({
    double? zoomLevel,
    int? selectedRow,
    int? selectedColumn,
    ScrollController? horizontalScrollController,
    ScrollController? verticalScrollController,
  }) {
    return SpreadsheetUIState(
      zoomLevel: zoomLevel ?? this.zoomLevel,
      selectedRow: selectedRow,
      selectedColumn: selectedColumn,
      horizontalScrollController:
          horizontalScrollController ?? this.horizontalScrollController,
      verticalScrollController:
          verticalScrollController ?? this.verticalScrollController,
    );
  }
}

/// ViewModel for spreadsheet UI state using modern Notifier pattern
class SpreadsheetUINotifier extends Notifier<SpreadsheetUIState> {
  @override
  SpreadsheetUIState build() {
    return const SpreadsheetUIState();
  }

  void setZoomLevel(double zoom) {
    state = state.copyWith(zoomLevel: zoom.clamp(0.3, 3.0));
  }

  void zoomIn() {
    setZoomLevel(state.zoomLevel * 1.2);
  }

  void zoomOut() {
    setZoomLevel(state.zoomLevel / 1.2);
  }

  void resetZoom() {
    setZoomLevel(1.0);
  }

  void selectRow(int rowIndex) {
    state = state.copyWith(selectedRow: rowIndex);
  }

  void selectColumn(int colIndex) {
    state = state.copyWith(selectedColumn: colIndex);
  }

  void clearSelection() {
    state = state.copyWith(selectedRow: null, selectedColumn: null);
  }

  void setScrollControllers(
    ScrollController? horizontal,
    ScrollController? vertical,
  ) {
    state = state.copyWith(
      horizontalScrollController: horizontal,
      verticalScrollController: vertical,
    );
  }
}

/// Provider for spreadsheet UI state
final spreadsheetUIProvider = NotifierProvider<SpreadsheetUINotifier, SpreadsheetUIState>(
    SpreadsheetUINotifier.new);
