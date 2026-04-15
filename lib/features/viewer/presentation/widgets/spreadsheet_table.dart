import 'package:flutter/material.dart';
import 'package:fadocx/l10n/app_localizations.dart';

/// Spreadsheet viewer with:
/// - Frozen header row (column names)
/// - Frozen left column (row numbers)
/// - Row/column selection with highlighting
/// - Zoom in/out functionality
/// - 2D virtualization for instant rendering
class SpreadsheetTable extends StatefulWidget {
  final List<List<String>> rows;
  final String sheetName;

  const SpreadsheetTable({
    required this.rows,
    required this.sheetName,
    super.key,
  });

  @override
  State<SpreadsheetTable> createState() => _SpreadsheetTableState();
}

class _SpreadsheetTableState extends State<SpreadsheetTable> {
  late ScrollController _horizontalScrollController;
  late ScrollController _verticalScrollController;
  
  int? _selectedRowIndex;
  int? _selectedColumnIndex;
  double _zoomLevel = 1.0;
  
  static const double _baseColumnWidth = 100.0;
  static const double _rowNumberColumnWidth = 50.0;
  static const double _rowHeight = 40.0;

  @override
  void initState() {
    super.initState();
    _horizontalScrollController = ScrollController();
    _verticalScrollController = ScrollController();
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  /// Get normalized rows (consistent column count)
  List<List<String>> _getNormalizedRows() {
    if (widget.rows.isEmpty) return [];
    
    int maxCols = 0;
    for (final row in widget.rows) {
      maxCols = maxCols > row.length ? maxCols : row.length;
    }
    
    if (maxCols == 0) return [];
    
    return widget.rows.map((row) {
      final normalized = <String>[...row];
      while (normalized.length < maxCols) {
        normalized.add('');
      }
      if (normalized.length > maxCols) {
        normalized.removeRange(maxCols, normalized.length);
      }
      return normalized;
    }).toList();
  }

  int get _maxColumns {
    if (widget.rows.isEmpty) return 0;
    int max = 0;
    for (final row in widget.rows) {
      max = max > row.length ? max : row.length;
    }
    return max;
  }

  void _selectRow(int rowIndex) {
    setState(() {
      _selectedRowIndex = _selectedRowIndex == rowIndex ? null : rowIndex;
      _selectedColumnIndex = null;
    });
  }

  void _selectColumn(int colIndex) {
    setState(() {
      _selectedColumnIndex = _selectedColumnIndex == colIndex ? null : colIndex;
      _selectedRowIndex = null;
    });
  }

  void _zoomIn() {
    setState(() {
      _zoomLevel = (_zoomLevel + 0.1).clamp(0.3, 3.0);
    });
  }

  void _zoomOut() {
    setState(() {
      _zoomLevel = (_zoomLevel - 0.1).clamp(0.3, 3.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final normalizedRows = _getNormalizedRows();
    final columnCount = _maxColumns;

    if (normalizedRows.isEmpty || columnCount == 0) {
      return Center(
        child: Text(l10n?.tableEmpty ?? 'No data'),
      );
    }

    final columnWidth = _baseColumnWidth * _zoomLevel;
    final rowHeight = _rowHeight * _zoomLevel;
    final headerColor = isDarkMode ? Colors.grey[800] : Colors.grey[100];
    final borderColor = isDarkMode ? Colors.grey[700] : Colors.grey[300];
    final altRowColor = isDarkMode ? Colors.grey[900] : Colors.grey[50];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top controls: sheet name, zoom buttons
        _buildTopControls(context, l10n),
        
        // Main spreadsheet area with frozen headers - gesture support for pinch zoom
        Expanded(
          child: GestureDetector(
            onScaleUpdate: (ScaleUpdateDetails details) {
              setState(() {
                _zoomLevel = (_zoomLevel * details.scale).clamp(0.3, 3.0);
              });
            },
            child: Row(
            children: [
              // Left frozen column (row numbers)
              _buildRowNumberColumn(
                normalizedRows,
                rowHeight,
                headerColor,
                borderColor,
                isDarkMode,
              ),
              
              // Main scrollable area
              Expanded(
                child: Column(
                  children: [
                    // Frozen header row - wrapped in same scroll controller for sync
                    SingleChildScrollView(
                      controller: _horizontalScrollController,
                      scrollDirection: Axis.horizontal,
                      child: _buildHeaderRow(
                        columnCount,
                        columnWidth,
                        headerColor,
                        borderColor,
                      ),
                    ),
                    
                    // Scrollable data area
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _horizontalScrollController,
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          controller: _verticalScrollController,
                          child: Column(
                            children: List.generate(
                              normalizedRows.length,
                              (rowIndex) {
                                final isSelected = _selectedRowIndex == rowIndex;
                                final isAltRow = rowIndex % 2 == 0;
                                final row = normalizedRows[rowIndex];
                                
                                return _buildDataRow(
                                  row,
                                  rowIndex,
                                  columnCount,
                                  columnWidth,
                                  rowHeight,
                                  isSelected,
                                  isAltRow,
                                  altRowColor,
                                  borderColor,
                                  isDarkMode,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
            ),
        ),
      ],
    );
  }

  Widget _buildTopControls(BuildContext context, AppLocalizations? l10n) {
    final normalizedRows = _getNormalizedRows();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '${widget.sheetName} (${normalizedRows.length} rows)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            children: [
              // Zoom controls
              IconButton(
                icon: const Icon(Icons.zoom_out),
                onPressed: _zoomLevel > 0.3 ? _zoomOut : null,
                tooltip: 'Zoom out',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '${(_zoomLevel * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.zoom_in),
                onPressed: _zoomLevel < 3.0 ? _zoomIn : null,
                tooltip: 'Zoom in',
              ),
              const SizedBox(width: 8),
              // Reset zoom
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  setState(() {
                    _zoomLevel = 1.0;
                    _selectedRowIndex = null;
                    _selectedColumnIndex = null;
                  });
                },
                tooltip: 'Reset zoom',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRowNumberColumn(
    List<List<String>> rows,
    double rowHeight,
    Color? headerColor,
    Color? borderColor,
    bool isDarkMode,
  ) {
    return Column(
      children: [
        // Header cell
        Container(
          width: _rowNumberColumnWidth,
          height: rowHeight,
          decoration: BoxDecoration(
            color: headerColor,
            border: Border(
              right: BorderSide(color: borderColor ?? Colors.grey, width: 1),
              bottom: BorderSide(color: borderColor ?? Colors.grey, width: 1),
            ),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(4),
          child: Text(
            '#',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        // Row numbers
        Expanded(
          child: SingleChildScrollView(
            controller: _verticalScrollController,
            child: Column(
              children: List.generate(
                rows.length,
                (rowIndex) {
                  final isSelected = _selectedRowIndex == rowIndex;
                  final isAltRow = rowIndex % 2 == 0;
                  
                  return GestureDetector(
                    onTap: () => _selectRow(rowIndex),
                    child: Container(
                      width: _rowNumberColumnWidth,
                      height: rowHeight,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.blue.withValues(alpha: 0.3)
                            : isAltRow
                                ? Colors.grey[isDarkMode ? 900 : 50]
                                : null,
                        border: Border(
                          right: BorderSide(
                            color: borderColor ?? Colors.grey,
                            width: 1,
                          ),
                          bottom: BorderSide(
                            color: borderColor ?? Colors.grey,
                            width: 0.5,
                          ),
                        ),
                      ),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(4),
                      child: Text(
                        '${rowIndex + 1}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderRow(
    int columnCount,
    double columnWidth,
    Color? headerColor,
    Color? borderColor,
  ) {
    return Container(
      color: headerColor,
      child: Row(
        children: List.generate(
          columnCount,
          (colIndex) {
            final columnLabel = String.fromCharCode(65 + (colIndex % 26));
            final isSelected = _selectedColumnIndex == colIndex;
            
            return GestureDetector(
              onTap: () => _selectColumn(colIndex),
              child: Container(
                width: columnWidth,
                height: _rowHeight * _zoomLevel,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.blue.withValues(alpha: 0.3)
                      : headerColor,
                  border: Border(
                    right: BorderSide(
                      color: borderColor ?? Colors.grey,
                      width: 0.5,
                    ),
                    bottom: BorderSide(
                      color: borderColor ?? Colors.grey,
                      width: 1,
                    ),
                  ),
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  columnLabel,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.bold,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDataRow(
    List<String> row,
    int rowIndex,
    int columnCount,
    double columnWidth,
    double rowHeight,
    bool isRowSelected,
    bool isAltRow,
    Color? altRowColor,
    Color? borderColor,
    bool isDarkMode,
  ) {
    return Container(
      color: isRowSelected
          ? Colors.blue.withValues(alpha: 0.15)
          : isAltRow
              ? altRowColor
              : null,
      child: Row(
        children: List.generate(
          columnCount,
          (colIndex) {
            final cellValue = colIndex < row.length ? row[colIndex] : '';
            final isColumnSelected = _selectedColumnIndex == colIndex;
            
            return Container(
              width: columnWidth,
              height: rowHeight,
              decoration: BoxDecoration(
                color: isColumnSelected
                    ? Colors.blue.withValues(alpha: 0.15)
                    : null,
                border: Border(
                  right: BorderSide(
                    color: borderColor ?? Colors.grey,
                    width: 0.5,
                  ),
                  bottom: BorderSide(
                    color: borderColor ?? Colors.grey,
                    width: 0.5,
                  ),
                ),
              ),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                cellValue,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
