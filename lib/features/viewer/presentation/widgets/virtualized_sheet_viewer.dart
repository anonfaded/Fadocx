import 'package:flutter/material.dart';
import 'package:fadocx/features/viewer/domain/entities/sheet_entity.dart';

/// Virtualized spreadsheet viewer for efficient rendering of large sheets
/// 
/// Uses ListView.builder to lazily render rows instead of creating all widgets at once.
/// This prevents UI freezes when opening sheets with 1000+ rows.
/// 
/// Features:
/// - Virtual scrolling (only visible rows rendered)
/// - Frozen header row
/// - Horizontal scrolling for wide sheets
/// - Efficient memory usage
class VirtualizedSheetViewer extends StatefulWidget {
  final SheetEntity sheet;

  const VirtualizedSheetViewer({
    required this.sheet,
    super.key,
  });

  @override
  State<VirtualizedSheetViewer> createState() => _VirtualizedSheetViewerState();
}

class _VirtualizedSheetViewerState extends State<VirtualizedSheetViewer> {
  late ScrollController _horizontalController;
  late List<List<String>> _normalizedRows;
  late List<String> _headers;

  @override
  void initState() {
    super.initState();
    _horizontalController = ScrollController();
    _prepareData();
  }

  /// Prepare and normalize data for rendering
  void _prepareData() {
    // First row is headers
    final firstRow = widget.sheet.rows.isNotEmpty ? widget.sheet.rows.first : [];
    _headers = firstRow is List<String> ? firstRow : firstRow.cast<String>();
    
    // Normalize header row
    if (_headers.length < widget.sheet.colCount) {
      _headers = List<String>.from(_headers)
        ..addAll(List<String>.filled(
          widget.sheet.colCount - _headers.length,
          '',
        ));
    } else if (_headers.length > widget.sheet.colCount) {
      _headers = _headers.sublist(0, widget.sheet.colCount);
    }

    // Get data rows (skip first row which is header)
    final allDataRows = widget.sheet.rows.length > 1 
      ? widget.sheet.rows.sublist(1).cast<List<String>>() 
      : <List<String>>[];

    // Normalize all data rows
    _normalizedRows = allDataRows.map((row) {
      if (row.length == widget.sheet.colCount) {
        return row;
      }
      final normalized = List<String>.from(row);
      if (normalized.length < widget.sheet.colCount) {
        normalized.addAll(List<String>.filled(
          widget.sheet.colCount - normalized.length,
          '',
        ));
      } else if (normalized.length > widget.sheet.colCount) {
        normalized.length = widget.sheet.colCount;
      }
      return normalized;
    }).toList();
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  /// Build a single cell widget
  Widget _buildCell(String text, {bool isHeader = false}) {
    return Container(
      constraints: const BoxConstraints(minWidth: 80),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey.shade300),
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
        color: isHeader ? Colors.grey.shade100 : Colors.white,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SelectableText(
          text,
          maxLines: 1,
          style: TextStyle(
            fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  /// Build a single row widget
  Widget _buildRow(List<String> cells, {bool isHeader = false}) {
    return Row(
      children: cells
          .map((cell) => _buildCell(cell, isHeader: isHeader))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_normalizedRows.isEmpty) {
      return Center(
        child: Text('No data in ${widget.sheet.name}'),
      );
    }

    return Column(
      children: [
        // Header row (frozen)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          controller: _horizontalController,
          child: _buildRow(_headers, isHeader: true),
        ),
        // Data rows (virtualized)
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: _horizontalController,
            child: SizedBox(
              width: widget.sheet.colCount * 100.0, // Approximate width
              child: ListView.builder(
                itemCount: _normalizedRows.length,
                itemBuilder: (context, index) {
                  return _buildRow(_normalizedRows[index]);
                },
              ),
            ),
          ),
        ),
        // Footer showing row count
        if (_normalizedRows.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              'Showing ${_normalizedRows.length} rows',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
      ],
    );
  }
}
