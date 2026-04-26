import 'package:flutter/material.dart';
import 'package:fadocx/features/viewer/domain/entities/sheet_entity.dart';

/// Professional Spreadsheet Viewer — virtualized for 50k+ rows.
class ProfessionalSheetViewer extends StatefulWidget {
  final SheetEntity sheet;
  final void Function(String?, String)? onSelectionChanged;
  final double initialZoom;

  const ProfessionalSheetViewer({
    required this.sheet,
    this.onSelectionChanged,
    this.initialZoom = 1.0,
    super.key,
  });

  @override
  State<ProfessionalSheetViewer> createState() => _ProfessionalSheetViewerState();
}

class _ProfessionalSheetViewerState extends State<ProfessionalSheetViewer> {
  late ScrollController _hController;
  late ScrollController _vDataController;
  late ScrollController _vRowController;

  bool _syncingV = false;

  double _zoom = 1.0;

  // Selection
  int? _selRow;
  int? _selCol;
  int? _selCellRow;
  int? _selCellCol;
  bool _selectAll = false;

  late List<List<String>> _rows;
  late List<String> _headers;

  // Per-column widths (resizable by user)
  late List<double> _colWidths;

  static const _baseCellH = 40.0;
  static const _baseCellW = 96.0;
  static const _baseRowHdrW = 52.0;
  static const _baseColHdrH = 40.0;

  // Drag state for column resize
  int? _resizingCol;
  double _resizeStartX = 0;
  double _resizeStartW = 0;

  @override
  void initState() {
    super.initState();
    _hController = ScrollController();
    _vDataController = ScrollController();
    _vRowController = ScrollController();
    _zoom = widget.initialZoom;

    _vRowController.addListener(_syncRowToData);
    _vDataController.addListener(_syncDataToRow);
    _prepareData();
  }

  @override
  void didUpdateWidget(covariant ProfessionalSheetViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialZoom != widget.initialZoom) {
      setState(() => _zoom = widget.initialZoom);
    }
  }

  void _prepareData() {
    _headers = _colLabels(widget.sheet.colCount);
    _colWidths = List.filled(widget.sheet.colCount, _baseCellW);
    _rows = widget.sheet.rows.map((row) {
      final r = List<String>.from(row);
      if (r.length < widget.sheet.colCount) {
        r.addAll(List.filled(widget.sheet.colCount - r.length, ''));
      } else {
        r.length = widget.sheet.colCount;
      }
      return r;
    }).toList();
  }

  List<String> _colLabels(int count) {
    final h = <String>[];
    for (int i = 0; i < count; i++) {
      var v = i;
      var l = '';
      do {
        l = String.fromCharCode(65 + (v % 26)) + l;
        v = (v ~/ 26) - 1;
      } while (v >= 0);
      h.add(l);
    }
    return h;
  }

  void _syncRowToData() {
    if (_syncingV || !_vDataController.hasClients) return;
    _syncingV = true;
    _vDataController.jumpTo(_vRowController.offset);
    _syncingV = false;
  }

  void _syncDataToRow() {
    if (_syncingV || !_vRowController.hasClients) return;
    _syncingV = true;
    _vRowController.jumpTo(_vDataController.offset);
    _syncingV = false;
  }

  double _colW(int ci) => _colWidths[ci] * _zoom;
  double get _cellH => _baseCellH * _zoom;
  double get _rowHdrW => _baseRowHdrW * _zoom;
  double get _colHdrH => _baseColHdrH * _zoom;
  double get _totalW =>
      List.generate(_headers.length, _colW).fold(0.0, (a, b) => a + b);

  // ── Selection ──────────────────────────────────────────
  void _toggleRow(int r) {
    setState(() {
      _selectAll = false;
      if (_selRow == r) {
        _selRow = null;
      } else {
        _selRow = r;
        _selCol = null;
        _selCellRow = null;
        _selCellCol = null;
      }
    });
    _notifySelection();
  }

  void _toggleCol(int c) {
    setState(() {
      _selectAll = false;
      if (_selCol == c) {
        _selCol = null;
      } else {
        _selCol = c;
        _selRow = null;
        _selCellRow = null;
        _selCellCol = null;
      }
    });
    _notifySelection();
  }

  void _toggleCell(int r, int c) {
    setState(() {
      _selectAll = false;
      if (_selCellRow == r && _selCellCol == c) {
        _selCellRow = null;
        _selCellCol = null;
      } else {
        _selCellRow = r;
        _selCellCol = c;
        _selRow = null;
        _selCol = null;
      }
    });
    _notifySelection();
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectAll) {
        _selectAll = false;
        _selRow = null;
        _selCol = null;
        _selCellRow = null;
        _selCellCol = null;
      } else {
        _selectAll = true;
        _selRow = null;
        _selCol = null;
        _selCellRow = null;
        _selCellCol = null;
      }
    });
    _notifySelection();
  }

  void _clearSelection() => setState(() {
        _selectAll = false;
        _selRow = null;
        _selCol = null;
        _selCellRow = null;
        _selCellCol = null;
      });

  /// Public method to scroll to cell - called from viewer screen search
  void scrollToCell(int row, int col) {
    if (row < 0 || col < 0 || row >= _rows.length || col >= _headers.length) return;
    final targetY = row * _cellH;
    if (_vDataController.hasClients) {
      _vDataController.animateTo(targetY.clamp(0.0, _vDataController.position.maxScrollExtent), duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    }
    final targetX = col * _colW(col);
    if (_hController.hasClients) {
      _hController.animateTo(targetX.clamp(0.0, _hController.position.maxScrollExtent), duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    }
    setState(() { _selCellRow = row; _selCellCol = col; _selRow = null; _selCol = null; _selectAll = false; });
    WidgetsBinding.instance.addPostFrameCallback((_) => _notifySelection());
  }

  void _notifySelection() {
    if (widget.onSelectionChanged == null) return;
    if (_selectAll) {
      final allData = _rows.map((r) => r.join(',')).join('\n');
      widget.onSelectionChanged!('All (${_rows.length}×${_headers.length})', allData);
    } else if (_selCellRow != null && _selCellCol != null) {
      final cellRef = '${_headers[_selCellCol!]}${_selCellRow! + 1}';
      final value = _rows[_selCellRow!][_selCellCol!];
      widget.onSelectionChanged!(cellRef, value);
    } else if (_selRow != null) {
      final rowValues = _rows[_selRow!].join(', ');
      widget.onSelectionChanged!('Row ${_selRow! + 1}', rowValues);
    } else if (_selCol != null) {
      final colValues = _rows.map((r) => r[_selCol!]).join(', ');
      widget.onSelectionChanged!('Col ${_headers[_selCol!]}', colValues);
    } else {
      widget.onSelectionChanged!(null, '');
    }
  }

  bool _isHighlighted(int ri, int ci) {
    if (_selectAll) return true;
    if (_selRow == ri) return true;
    if (_selCol == ci) return true;
    if (_selCellRow == ri && _selCellCol == ci) return true;
    return false;
  }

  bool _isCellSelected(int ri, int ci) =>
      _selCellRow == ri && _selCellCol == ci;

  // ── Column resize ──────────────────────────────────────
  void _onColResizeStart(int ci, double startX) {
    setState(() {
      _resizingCol = ci;
      _resizeStartX = startX;
      _resizeStartW = _colWidths[ci];
    });
  }

  void _onColResizeUpdate(double globalX) {
    if (_resizingCol == null) return;
    final dx = (globalX - _resizeStartX) / _zoom;
    final newW =
        (_resizeStartW + dx).clamp(40.0, 800.0); // Max 800 for wide cols
    setState(() => _colWidths[_resizingCol!] = newW);
  }

  void _onColResizeEnd() {
    setState(() => _resizingCol = null);
  }


  @override
  void dispose() {
    _vRowController.removeListener(_syncRowToData);
    _vDataController.removeListener(_syncDataToRow);
    _hController.dispose();
    _vDataController.dispose();
    _vRowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_rows.isEmpty) {
      return Center(child: Text('No data in ${widget.sheet.name}'));
    }

    final colors = _ThemeColors.of(context);
    final ch = _cellH;
    final rhw = _rowHdrW;
    final chh = _colHdrH;
    final totalW = _totalW;

    // Font size scales with zoom
    final fontSize = (12.0 * _zoom).clamp(4.0, 24.0); // Min 4px at 10% zoom
    final hdrFontSize = (11.0 * _zoom).clamp(4.0, 20.0);

    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            // Global drag handler when resizing
            onHorizontalDragUpdate: _resizingCol != null
                ? (d) => _onColResizeUpdate(d.globalPosition.dx)
                : null,
            onHorizontalDragEnd:
                _resizingCol != null ? (_) => _onColResizeEnd() : null,
            onTap: _clearSelection,
            behavior: HitTestBehavior.translucent,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    _cornerCell(rhw, chh, colors, hdrFontSize),
                    Expanded(
                      child: SizedBox(
                        width: rhw,
                        child: ListView.builder(
                          controller: _vRowController,
                          physics: const ClampingScrollPhysics(),
                          itemExtent: ch,
                          itemCount: _rows.length,
                          cacheExtent: 800,
                          padding: EdgeInsets.zero,
                          itemBuilder: (ctx, i) => _RowHdrCell(
                            label: '${i + 1}',
                            h: ch,
                            colors: colors,
                            sel: _selRow == i || _selectAll,
                            fontSize: hdrFontSize,
                            onTap: () => _toggleRow(i),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (ctx, constraints) {
                      final availableHeight = constraints.maxHeight;
                      final dataHeight = availableHeight - chh;
                      return SingleChildScrollView(
                        controller: _hController,
                        scrollDirection: Axis.horizontal,
                        physics: const ClampingScrollPhysics(),
                        child: SizedBox(
                          width: totalW,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _colHeadersRow(colors, chh, hdrFontSize),
                              SizedBox(
                                height: dataHeight,
                                child: ListView.builder(
                                  controller: _vDataController,
                                  physics: const ClampingScrollPhysics(),
                                  itemExtent: ch,
                                  itemCount: _rows.length,
                                  cacheExtent: 800,
                                  padding: EdgeInsets.zero,
                                  itemBuilder: (ctx, ri) => _DataRow(
                                    row: _rows[ri],
                                    ri: ri,
                                    colWidths:
                                        List.generate(_headers.length, _colW),
                                    ch: ch,
                                    colors: colors,
                                    odd: ri.isOdd,
                                    isHighlighted: _isHighlighted,
                                    isCellSelected: _isCellSelected,
                                    onCellTap: _toggleCell,
                                    fontSize: fontSize,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _cornerCell(double w, double h, _ThemeColors c, double fontSize) =>
      GestureDetector(
        onTap: _toggleSelectAll,
        child: Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: _selectAll ? c.selCellBg : c.header,
            border: Border(
              right: BorderSide(color: c.border, width: 0.5),
              bottom: BorderSide(color: c.border, width: 0.5),
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            _selectAll ? Icons.deselect : Icons.select_all,
            size: fontSize + 2,
            color: _selectAll ? c.selCellFg : c.headerText,
          ),
        ),
      );

  Widget _colHeadersRow(_ThemeColors c, double ch, double fontSize) => SizedBox(
        height: ch,
        child: Row(
          children: List.generate(_headers.length, (i) {
            final cw = _colW(i);
            return _ColHdrCell(
              label: _headers[i],
              w: cw,
              h: ch,
              colors: c,
              sel: _selCol == i || _selectAll,
              fontSize: fontSize,
              onTap: () => _toggleCol(i),
              onResizeStart: (dx) => _onColResizeStart(i, dx),
              onResizeUpdate: _resizingCol == i ? _onColResizeUpdate : null,
              onResizeEnd: _resizingCol == i ? _onColResizeEnd : null,
              isResizing: _resizingCol == i,
            );
          }),
        ),
      );

}

// ── Row header cell ──────────────────────────────────────
class _RowHdrCell extends StatelessWidget {
  final String label;
  final double h;
  final _ThemeColors colors;
  final bool sel;
  final double fontSize;
  final VoidCallback onTap;

  const _RowHdrCell({
    required this.label,
    required this.h,
    required this.colors,
    required this.sel,
    required this.fontSize,
    required this.onTap,
  });

  @override
  Widget build(_) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: sel ? colors.selRowBg : colors.header,
            border: Border(
              right: BorderSide(color: colors.border, width: 0.5),
              bottom: BorderSide(color: colors.border, width: 0.5),
            ),
          ),
          child: Text(label,
              style: TextStyle(
                color: sel ? colors.selCellFg : colors.headerText,
                fontWeight: sel ? FontWeight.w700 : FontWeight.w600,
                fontSize: fontSize,
              )),
        ),
      );
}

// ── Column header cell with RESIZABLE and VISIBLE handle ────────────────
class _ColHdrCell extends StatefulWidget {
  final String label;
  final double w;
  final double h;
  final _ThemeColors colors;
  final bool sel;
  final double fontSize;
  final VoidCallback onTap;
  final void Function(double globalX) onResizeStart;
  final void Function(double globalX)? onResizeUpdate;
  final VoidCallback? onResizeEnd;
  final bool isResizing;

  const _ColHdrCell({
    required this.label,
    required this.w,
    required this.h,
    required this.colors,
    required this.sel,
    required this.fontSize,
    required this.onTap,
    required this.onResizeStart,
    required this.onResizeUpdate,
    required this.onResizeEnd,
    required this.isResizing,
  });

  @override
  State<_ColHdrCell> createState() => _ColHdrCellState();
}

class _ColHdrCellState extends State<_ColHdrCell> {
  bool _hovering = false;

  @override
  Widget build(_) => Stack(
        clipBehavior: Clip.none,
        children: [
          // Main cell - tap to select column
          GestureDetector(
            onTap: widget.onTap,
            child: Container(
              width: widget.w,
              height: widget.h,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color:
                    widget.sel ? widget.colors.selRowBg : widget.colors.header,
                border: Border(
                  right: BorderSide(color: widget.colors.border, width: 0.5),
                  bottom: BorderSide(color: widget.colors.border, width: 0.5),
                ),
              ),
              child: Text(widget.label,
                  style: TextStyle(
                    color: widget.sel
                        ? widget.colors.selCellFg
                        : widget.colors.headerText,
                    fontWeight: FontWeight.w700,
                    fontSize: widget.fontSize,
                  )),
            ),
          ),
          // PROMINENT resize handle on right edge - vertical line with hover effect
          Positioned(
            right: -8, // Extend beyond the cell for easier grabbing
            top: 0,
            bottom: 0,
            child: MouseRegion(
              onEnter: (_) => setState(() => _hovering = true),
              onExit: (_) => setState(() => _hovering = false),
              cursor: SystemMouseCursors.resizeColumn,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragStart: (d) =>
                    widget.onResizeStart(d.globalPosition.dx),
                onHorizontalDragUpdate: widget.onResizeUpdate != null
                    ? (d) => widget.onResizeUpdate!(d.globalPosition.dx)
                    : null,
                onHorizontalDragEnd: widget.onResizeEnd != null
                    ? (_) => widget.onResizeEnd!()
                    : null,
                child: Container(
                  width: 16, // Wider touch area (16px)
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: 4,
                    height: widget.h * 0.6,
                    decoration: BoxDecoration(
                      color: widget.isResizing
                          ? widget.colors.selCellFg
                          : (_hovering
                              ? widget.colors.selCellFg.withValues(alpha: 0.8)
                              : widget.colors.border.withValues(alpha: 0.5)),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
}

// ── Data row ─────────────────────────────────────────────
class _DataRow extends StatelessWidget {
  final List<String> row;
  final int ri;
  final List<double> colWidths;
  final double ch;
  final _ThemeColors colors;
  final bool odd;
  final bool Function(int ri, int ci) isHighlighted;
  final bool Function(int ri, int ci) isCellSelected;
  final void Function(int r, int c) onCellTap;
  final double fontSize;

  const _DataRow({
    required this.row,
    required this.ri,
    required this.colWidths,
    required this.ch,
    required this.colors,
    required this.odd,
    required this.isHighlighted,
    required this.isCellSelected,
    required this.onCellTap,
    required this.fontSize,
  });

  @override
  Widget build(_) => Row(
        children: List.generate(row.length, (ci) {
          final highlighted = isHighlighted(ri, ci);
          final cellSel = isCellSelected(ri, ci);

          return GestureDetector(
            onTap: () => onCellTap(ri, ci),
            child: Container(
              width: colWidths[ci],
              height: ch,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: cellSel
                    ? colors.selCellBg
                    : highlighted
                        ? colors.selRowBg
                        : (odd ? colors.oddRow : colors.evenRow),
                border: Border(
                  right: BorderSide(color: colors.border, width: 0.5),
                  bottom: BorderSide(color: colors.border, width: 0.5),
                ),
              ),
              child: cellSel
                  ? Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: colors.selCellFg, width: 1.5),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Text(row[ci],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.selCellFg,
                            fontSize: fontSize,
                            fontWeight: FontWeight.w600,
                          )),
                    )
                  : Text(row[ci],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: highlighted
                            ? colors.highlightText
                            : colors.primaryText,
                        fontSize: fontSize,
                        fontWeight:
                            highlighted ? FontWeight.w600 : FontWeight.normal,
                      )),
            ),
          );
        }),
      );
}

// ── Grayscale theme colors (no blue) ─────────────────────
class _ThemeColors {
  final Color header;
  final Color headerText;
  final Color evenRow;
  final Color oddRow;
  final Color primaryText;
  final Color secondaryText;
  final Color border;
  final Color statusBar;
  final Color toolbar;
  final Color toolbarText;
  final Color toolbarIcon;
  final Color toolbarBtnBg;
  final Color selCellBg;
  final Color selCellFg;
  final Color selRowBg;
  final Color highlightText;

  const _ThemeColors({
    required this.header,
    required this.headerText,
    required this.evenRow,
    required this.oddRow,
    required this.primaryText,
    required this.secondaryText,
    required this.border,
    required this.statusBar,
    required this.toolbar,
    required this.toolbarText,
    required this.toolbarIcon,
    required this.toolbarBtnBg,
    required this.selCellBg,
    required this.selCellFg,
    required this.selRowBg,
    required this.highlightText,
  });

  factory _ThemeColors.of(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    if (dark) {
      return const _ThemeColors(
        header: Color(0xFF2D2D2D),
        headerText: Color(0xFFE0E0E0),
        evenRow: Color(0xFF141414),
        oddRow: Color(0xFF1C1C1C),
        primaryText: Color(0xFFE0E0E0),
        secondaryText: Color(0xFF999999),
        border: Color(0xFF393939),
        statusBar: Color(0xFF242424),
        toolbar: Color(0xFF1A1A1A),
        toolbarText: Color(0xFFD0D0D0),
        toolbarIcon: Color(0xFFB0B0B0),
        toolbarBtnBg: Color(0xFF2D2D2D),
        selCellBg: Color(0xFF3D5A6A),
        selCellFg: Color(0xFFFFFFFF),
        selRowBg: Color(0xFF2D4A5A),
        highlightText: Color(0xFFF5F5F5),
      );
    }

    return const _ThemeColors(
      header: Color(0xFFD4D4D4),
      headerText: Color(0xFF333333),
      evenRow: Color(0xFFFFFFFF),
      oddRow: Color(0xFFF5F5F5),
      primaryText: Color(0xFF333333),
      secondaryText: Color(0xFF777777),
      border: Color(0xFFCCCCCC),
      statusBar: Color(0xFFF5F5F5),
      toolbar: Color(0xFFF2F2F2),
      toolbarText: Color(0xFF444444),
      toolbarIcon: Color(0xFF666666),
      toolbarBtnBg: Color(0xFFE0E0E0),
      selCellBg: Color(0xFFC8C8C8),
      selCellFg: Color(0xFF111111),
      selRowBg: Color(0xFFE0E0E0),
      highlightText: Color(0xFF111111),
    );
  }
}
