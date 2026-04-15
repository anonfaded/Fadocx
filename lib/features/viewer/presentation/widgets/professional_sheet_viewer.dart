import 'package:flutter/material.dart';
import 'package:fadocx/features/viewer/domain/entities/sheet_entity.dart';

/// Spreadsheet viewer optimized for large row counts.
///
/// Design goals:
/// - Sticky top row with Excel-style column labels.
/// - Sticky left column with row numbers.
/// - Vertical row virtualization via ListView.builder.
/// - Synchronized horizontal header/data scrolling.
/// - Theme-aware colors that follow app light/dark mode.
class ProfessionalSheetViewer extends StatefulWidget {
  final SheetEntity sheet;

  const ProfessionalSheetViewer({
    required this.sheet,
    super.key,
  });

  @override
  State<ProfessionalSheetViewer> createState() =>
      _ProfessionalSheetViewerState();
}

class _ProfessionalSheetViewerState extends State<ProfessionalSheetViewer> {
  late final ScrollController _horizontalController;
  late final ScrollController _rowNumbersController;
  late final ScrollController _dataRowsController;

  late final List<List<String>> _dataRows;
  late final List<String> _columnHeaders;

  bool _syncingVerticalOffset = false;

  static const double _cellHeight = 40;
  static const double _cellWidth = 96;
  static const double _rowHeaderWidth = 52;
  static const double _headerHeight = 40;

  @override
  void initState() {
    super.initState();
    _horizontalController = ScrollController();
    _rowNumbersController = ScrollController();
    _dataRowsController = ScrollController();
    _rowNumbersController.addListener(_syncRowNumbersToData);
    _dataRowsController.addListener(_syncDataToRowNumbers);
    _prepareData();
  }

  void _prepareData() {
    _columnHeaders = _generateColumnHeaders(widget.sheet.colCount);
    _dataRows = widget.sheet.rows.map((row) {
      final normalized = List<String>.from(row);
      if (normalized.length < widget.sheet.colCount) {
        normalized.addAll(
          List<String>.filled(widget.sheet.colCount - normalized.length, ''),
        );
      } else if (normalized.length > widget.sheet.colCount) {
        normalized.length = widget.sheet.colCount;
      }
      return normalized;
    }).toList();
  }

  List<String> _generateColumnHeaders(int count) {
    final headers = <String>[];
    for (int index = 0; index < count; index++) {
      var value = index;
      var label = '';
      do {
        label = String.fromCharCode(65 + (value % 26)) + label;
        value = (value ~/ 26) - 1;
      } while (value >= 0);
      headers.add(label);
    }
    return headers;
  }

  void _syncRowNumbersToData() {
    if (_syncingVerticalOffset || !_dataRowsController.hasClients) {
      return;
    }
    _syncingVerticalOffset = true;
    _dataRowsController.jumpTo(_rowNumbersController.offset);
    _syncingVerticalOffset = false;
  }

  void _syncDataToRowNumbers() {
    if (_syncingVerticalOffset || !_rowNumbersController.hasClients) {
      return;
    }
    _syncingVerticalOffset = true;
    _rowNumbersController.jumpTo(_dataRowsController.offset);
    _syncingVerticalOffset = false;
  }

  @override
  void dispose() {
    _rowNumbersController.removeListener(_syncRowNumbersToData);
    _dataRowsController.removeListener(_syncDataToRowNumbers);
    _horizontalController.dispose();
    _rowNumbersController.dispose();
    _dataRowsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_dataRows.isEmpty || _columnHeaders.isEmpty) {
      return Center(
        child: Text('No data in ${widget.sheet.name}'),
      );
    }

    final colors = _ThemeColors.of(context);
    final totalWidth = _columnHeaders.length * _cellWidth;

    return Column(
      children: [
        _buildHeader(colors, totalWidth),
        Expanded(
          child: Row(
            children: [
              SizedBox(
                width: _rowHeaderWidth,
                child: ListView.builder(
                  controller: _rowNumbersController,
                  physics: const ClampingScrollPhysics(),
                  itemCount: _dataRows.length,
                  itemExtent: _cellHeight,
                  itemBuilder: (context, index) {
                    return _RowHeaderCell(
                      label: '${index + 1}',
                      height: _cellHeight,
                      colors: colors,
                      isOddRow: index.isOdd,
                    );
                  },
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: _horizontalController,
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  child: SizedBox(
                    width: totalWidth,
                    child: ListView.builder(
                      controller: _dataRowsController,
                      physics: const ClampingScrollPhysics(),
                      itemCount: _dataRows.length,
                      itemExtent: _cellHeight,
                      itemBuilder: (context, rowIndex) {
                        return _DataRowWidget(
                          row: _dataRows[rowIndex],
                          cellWidth: _cellWidth,
                          colors: colors,
                          isOddRow: rowIndex.isOdd,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: colors.statusBar,
            border: Border(top: BorderSide(color: colors.border, width: 0.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rows: ${_dataRows.length}',
                style: TextStyle(color: colors.secondaryText, fontSize: 11),
              ),
              Text(
                'Columns: ${_columnHeaders.length}',
                style: TextStyle(color: colors.secondaryText, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(_ThemeColors colors, double totalWidth) {
    return Row(
      children: [
        // Fixed row header cell (# symbol)
        Container(
          width: _rowHeaderWidth,
          height: _headerHeight,
          decoration: BoxDecoration(
            color: colors.header,
            border: Border(
              right: BorderSide(color: colors.border, width: 0.5),
              bottom: BorderSide(color: colors.border, width: 0.5),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '#',
            style: TextStyle(
              color: colors.headerText,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ),
        // Scrollable column headers - uses same controller as data area
        Expanded(
          child: SingleChildScrollView(
            controller: _horizontalController,
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: SizedBox(
              width: totalWidth,
              height: _headerHeight,
              child: Row(
                children: _columnHeaders.map((label) {
                  return _ColumnHeaderCell(
                    label: label,
                    width: _cellWidth,
                    colors: colors,
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DataRowWidget extends StatelessWidget {
  final List<String> row;
  final double cellWidth;
  final _ThemeColors colors;
  final bool isOddRow;

  const _DataRowWidget({
    required this.row,
    required this.cellWidth,
    required this.colors,
    required this.isOddRow,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: row.map((value) {
        return Container(
          width: cellWidth,
          height: _ProfessionalSheetViewerState._cellHeight,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: isOddRow ? colors.oddRow : colors.evenRow,
            border: Border(
              right: BorderSide(color: colors.border, width: 0.5),
              bottom: BorderSide(color: colors.border, width: 0.5),
            ),
          ),
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.primaryText, fontSize: 12),
          ),
        );
      }).toList(),
    );
  }
}

class _ColumnHeaderCell extends StatelessWidget {
  final String label;
  final double width;
  final _ThemeColors colors;

  const _ColumnHeaderCell({
    required this.label,
    required this.width,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: _ProfessionalSheetViewerState._headerHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.header,
        border: Border(
          right: BorderSide(color: colors.border, width: 0.5),
          bottom: BorderSide(color: colors.border, width: 0.5),
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: colors.headerText,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _RowHeaderCell extends StatelessWidget {
  final String label;
  final double height;
  final _ThemeColors colors;
  final bool isOddRow;

  const _RowHeaderCell({
    required this.label,
    required this.height,
    required this.colors,
    required this.isOddRow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isOddRow ? colors.rowHeaderOdd : colors.rowHeaderEven,
        border: Border(
          right: BorderSide(color: colors.border, width: 0.5),
          bottom: BorderSide(color: colors.border, width: 0.5),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colors.headerText,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _ThemeColors {
  final Color header;
  final Color headerText;
  final Color rowHeaderEven;
  final Color rowHeaderOdd;
  final Color evenRow;
  final Color oddRow;
  final Color primaryText;
  final Color secondaryText;
  final Color border;
  final Color statusBar;

  const _ThemeColors({
    required this.header,
    required this.headerText,
    required this.rowHeaderEven,
    required this.rowHeaderOdd,
    required this.evenRow,
    required this.oddRow,
    required this.primaryText,
    required this.secondaryText,
    required this.border,
    required this.statusBar,
  });

  factory _ThemeColors.of(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    
    // Debug logging
    // log.d('Sheet theme detection: brightness=$brightness, isDark=$isDark');
    
    if (isDark) {
      // Dark theme: grayscale colors (no blue)
      return const _ThemeColors(
        header: Color(0xFF334155),        // Slate-700: dark gray header
        headerText: Color(0xFFF8FAFC),    // Slate-50: light text
        rowHeaderEven: Color(0xFF334155), // Slate-700
        rowHeaderOdd: Color(0xFF334155),  // Slate-700
        evenRow: Color(0xFF111827),       // Slate-900: very dark row
        oddRow: Color(0xFF1F2937),        // Slate-800: dark row
        primaryText: Color(0xFFE5E7EB),   // Slate-200: light text
        secondaryText: Color(0xFFCBD5E1), // Slate-300: medium light text
        border: Color(0xFF475569),        // Slate-600: dark border
        statusBar: Color(0xFF0F172A),     // Slate-950: almost black
      );
    }

    // Light theme: light grayscale colors (no blue)
    return const _ThemeColors(
      header: Color(0xFFE2E8F0),         // Slate-200: light gray header
      headerText: Color(0xFF0F172A),     // Slate-950: dark text
      rowHeaderEven: Color(0xFFF1F5F9),  // Slate-100: very light even
      rowHeaderOdd: Color(0xFFE2E8F0),   // Slate-200: light odd
      evenRow: Color(0xFFFFFFFF),        // White: even rows
      oddRow: Color(0xFFF8FAFC),         // Slate-50: odd rows
      primaryText: Color(0xFF111827),    // Slate-900: dark text
      secondaryText: Color(0xFF475569),  // Slate-600: medium text
      border: Color(0xFFCBD5E1),         // Slate-300: light border
      statusBar: Color(0xFFF8FAFC),      // Slate-50: light status bar
    );
  }
}
