import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fadocx/features/viewer/domain/entities/sheet_entity.dart';

/// Professional Spreadsheet Viewer — virtualized for 50k+ rows.
///
/// Architecture:
/// - Row headers + data share vertical scroll (synced controllers)
/// - Column headers + data share horizontal scroll (single controller)
/// - ListView.builder for vertical virtualization (only visible rows render)
/// - No SizedBox with total height (avoids overflow & lag)
/// - setState for selection (only ~20 visible items rebuild = instant)
class ProfessionalSheetViewer extends StatefulWidget {
  final SheetEntity sheet;

  const ProfessionalSheetViewer({required this.sheet, super.key});

  @override
  State<ProfessionalSheetViewer> createState() =>
      _ProfessionalSheetViewerState();
}

class _ProfessionalSheetViewerState extends State<ProfessionalSheetViewer>
    with TickerProviderStateMixin {
  late ScrollController _hController; // horizontal: shared by headers + data
  late ScrollController _vDataController; // vertical: data rows
  late ScrollController _vRowController; // vertical: row numbers (synced)

  bool _syncingV = false;

  double _zoom = 1.0;
  static const _minZoom = 0.5;
  static const _maxZoom = 3.0;
  late AnimationController _zoomAnim;

  // Selection
  int? _selRow; // whole row
  int? _selCol; // whole column
  int? _selCellRow; // single cell
  int? _selCellCol;

  late List<List<String>> _rows;
  late List<String> _headers;

  static const _baseCellH = 40.0;
  static const _baseCellW = 96.0;
  static const _baseRowHdrW = 52.0;
  static const _baseColHdrH = 40.0;

  @override
  void initState() {
    super.initState();
    _hController = ScrollController();
    _vDataController = ScrollController();
    _vRowController = ScrollController();
    _zoomAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );

    _vRowController.addListener(_syncRowToData);
    _vDataController.addListener(_syncDataToRow);
    _prepareData();
  }

  void _prepareData() {
    _headers = _colLabels(widget.sheet.colCount);
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

  // ── Zoom ──────────────────────────────────────────────
  void _zoomIn() => _animateZoom((_zoom * 1.25).clamp(_minZoom, _maxZoom));
  void _zoomOut() => _animateZoom((_zoom / 1.25).clamp(_minZoom, _maxZoom));
  void _resetZoom() => _animateZoom(1.0);

  void _animateZoom(double target) {
    final anim = Tween(begin: _zoom, end: target).animate(
      CurvedAnimation(parent: _zoomAnim, curve: Curves.easeOutCubic),
    );
    anim.addListener(() => setState(() => _zoom = anim.value));
    _zoomAnim
      ..reset()
      ..forward();
  }

  // ── Selection ──────────────────────────────────────────
  void _toggleRow(int r) => setState(() {
        if (_selRow == r) {
          _selRow = null;
        } else {
          _selRow = r;
          _selCol = null;
          _selCellRow = null;
          _selCellCol = null;
        }
      });

  void _toggleCol(int c) => setState(() {
        if (_selCol == c) {
          _selCol = null;
        } else {
          _selCol = c;
          _selRow = null;
          _selCellRow = null;
          _selCellCol = null;
        }
      });

  void _toggleCell(int r, int c) => setState(() {
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

  void _clearSelection() => setState(() {
        _selRow = null;
        _selCol = null;
        _selCellRow = null;
        _selCellCol = null;
      });

  String? get _selectedText {
    if (_selCellRow != null && _selCellCol != null) {
      return _rows[_selCellRow!][_selCellCol!];
    }
    if (_selRow != null) {
      return _rows[_selRow!].where((c) => c.isNotEmpty).join('\t');
    }
    if (_selCol != null) {
      return _rows
          .map((r) => r[_selCol!])
          .where((c) => c.isNotEmpty)
          .join('\n');
    }
    return null;
  }

  String? get _selectedLabel {
    if (_selCellRow != null && _selCellCol != null) {
      return '${_headers[_selCellCol!]}${_selCellRow! + 1}';
    }
    if (_selRow != null) return 'Row ${_selRow! + 1}';
    if (_selCol != null) return 'Col ${_headers[_selCol!]}';
    return null;
  }

  Future<void> _copySelection() async {
    final text = _selectedText;
    if (text == null || text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied ${_selectedLabel ?? ""} to clipboard'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 60, left: 16, right: 16),
      ),
    );
  }

  @override
  void dispose() {
    _vRowController.removeListener(_syncRowToData);
    _vDataController.removeListener(_syncDataToRow);
    _hController.dispose();
    _vDataController.dispose();
    _vRowController.dispose();
    _zoomAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_rows.isEmpty) {
      return Center(child: Text('No data in ${widget.sheet.name}'));
    }

    final colors = _ThemeColors.of(context);
    final cw = _baseCellW * _zoom;
    final ch = _baseCellH * _zoom;
    final rhw = _baseRowHdrW * _zoom;
    final chh = _baseColHdrH * _zoom;
    final totalW = _headers.length * cw;

    return Column(
      children: [
        _toolbar(colors),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Fixed left column: corner + row numbers ──
              Column(
                children: [
                  _cornerCell(rhw, chh, colors),
                  Expanded(
                    child: SizedBox(
                      width: rhw,
                      child: ListView.builder(
                        controller: _vRowController,
                        physics: const ClampingScrollPhysics(),
                        itemExtent: ch,
                        itemCount: _rows.length,
                        cacheExtent: 600,
                        itemBuilder: (ctx, i) => _RowHdrCell(
                          label: '${i + 1}',
                          h: ch,
                          colors: colors,
                          odd: i.isOdd,
                          sel: _selRow == i,
                          onTap: () => _toggleRow(i),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // ── Scrollable right: headers + data ──
              Expanded(
                child: SingleChildScrollView(
                  controller: _hController,
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  child: SizedBox(
                    width: totalW,
                    child: Column(
                      children: [
                        // Column headers
                        _colHeadersRow(cw, chh, colors),
                        // Data grid (virtualized)
                        Expanded(
                          child: ListView.builder(
                            controller: _vDataController,
                            physics: const ClampingScrollPhysics(),
                            itemExtent: ch,
                            itemCount: _rows.length,
                            cacheExtent: 600,
                            itemBuilder: (ctx, ri) => _DataRow(
                              row: _rows[ri],
                              ri: ri,
                              cw: cw,
                              ch: ch,
                              colors: colors,
                              odd: ri.isOdd,
                              selRow: _selRow,
                              selCol: _selCol,
                              selCellR: _selCellRow,
                              selCellC: _selCellCol,
                              onCellTap: _toggleCell,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        _statusBar(colors),
      ],
    );
  }

  // ── Toolbar ────────────────────────────────────────────
  Widget _toolbar(_ThemeColors c) => Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: c.toolbar,
          border: Border(bottom: BorderSide(color: c.border, width: 0.5)),
        ),
        child: Row(
          children: [
            _zoomBtn(Icons.remove, _zoomOut, c),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                '${(_zoom * 100).round()}%',
                style: TextStyle(
                    color: c.toolbarText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ),
            _zoomBtn(Icons.add, _zoomIn, c),
            const SizedBox(width: 8),
            _zoomBtn(Icons.restart_alt, _resetZoom, c),
            const Spacer(),
            Text(
              '${widget.sheet.name}  •  ${_rows.length}R × ${_headers.length}C',
              style: TextStyle(color: c.secondaryText, fontSize: 11),
            ),
          ],
        ),
      );

  Widget _zoomBtn(IconData icon, VoidCallback cb, _ThemeColors c) => Tooltip(
        message: icon == Icons.add
            ? 'Zoom in'
            : icon == Icons.remove
                ? 'Zoom out'
                : 'Reset zoom',
        child: SizedBox(
          width: 32,
          height: 32,
          child: IconButton(
            onPressed: cb,
            icon: Icon(icon, size: 18, color: c.toolbarIcon),
            padding: EdgeInsets.zero,
            style: IconButton.styleFrom(
              backgroundColor: c.toolbarBtnBg,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
            ),
          ),
        ),
      );

  // ── Corner cell ────────────────────────────────────────
  Widget _cornerCell(double w, double h, _ThemeColors c) => GestureDetector(
        onTap: _clearSelection,
        child: Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: c.header,
            border: Border(
              right: BorderSide(color: c.border, width: 0.5),
              bottom: BorderSide(color: c.border, width: 0.5),
            ),
          ),
          alignment: Alignment.center,
          child: Transform.rotate(
            angle: math.pi / 4,
            child: Icon(Icons.arrow_forward, size: 12, color: c.headerText),
          ),
        ),
      );

  // ── Column headers ────────────────────────────────────
  Widget _colHeadersRow(double cw, double ch, _ThemeColors c) => SizedBox(
        height: ch,
        child: Row(
          children: List.generate(
              _headers.length,
              (i) => _ColHdrCell(
                    label: _headers[i],
                    w: cw,
                    h: ch,
                    colors: c,
                    sel: _selCol == i,
                    onTap: () => _toggleCol(i),
                  )),
        ),
      );

  // ── Status bar ─────────────────────────────────────────
  Widget _statusBar(_ThemeColors c) {
    final hasSel = _selRow != null || _selCol != null || _selCellRow != null;
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: c.statusBar,
        border: Border(top: BorderSide(color: c.border, width: 0.5)),
      ),
      child: Row(
        children: [
          if (hasSel) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: c.selCellBg,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                _selectedLabel ?? '',
                style: TextStyle(
                  color: c.selCellFg,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _selectedText?.substring(
                        0, math.min(120, _selectedText?.length ?? 0)) ??
                    '',
                style: TextStyle(color: c.secondaryText, fontSize: 11),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            IconButton(
              onPressed: _copySelection,
              icon: Icon(Icons.copy, size: 14, color: c.toolbarIcon),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              tooltip: 'Copy',
            ),
          ] else ...[
            Expanded(
              child: Text(
                'Ready',
                style: TextStyle(color: c.secondaryText, fontSize: 11),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Row header cell ──────────────────────────────────────
class _RowHdrCell extends StatelessWidget {
  final String label;
  final double h;
  final _ThemeColors colors;
  final bool odd;
  final bool sel;
  final VoidCallback onTap;

  const _RowHdrCell({
    required this.label,
    required this.h,
    required this.colors,
    required this.odd,
    required this.sel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext _) => GestureDetector(
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
          child: Text(
            label,
            style: TextStyle(
              color: sel ? colors.selCellFg : colors.headerText,
              fontWeight: sel ? FontWeight.w700 : FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
      );
}

// ── Column header cell ──────────────────────────────────
class _ColHdrCell extends StatelessWidget {
  final String label;
  final double w;
  final double h;
  final _ThemeColors colors;
  final bool sel;
  final VoidCallback onTap;

  const _ColHdrCell({
    required this.label,
    required this.w,
    required this.h,
    required this.colors,
    required this.sel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext _) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: w,
          height: h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: sel ? colors.selRowBg : colors.header,
            border: Border(
              right: BorderSide(color: colors.border, width: 0.5),
              bottom: BorderSide(color: colors.border, width: 0.5),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: sel ? colors.selCellFg : colors.headerText,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ),
      );
}

// ── Data row ─────────────────────────────────────────────
class _DataRow extends StatelessWidget {
  final List<String> row;
  final int ri;
  final double cw;
  final double ch;
  final _ThemeColors colors;
  final bool odd;
  final int? selRow;
  final int? selCol;
  final int? selCellR;
  final int? selCellC;
  final void Function(int r, int c) onCellTap;

  const _DataRow({
    required this.row,
    required this.ri,
    required this.cw,
    required this.ch,
    required this.colors,
    required this.odd,
    required this.selRow,
    required this.selCol,
    required this.selCellR,
    required this.selCellC,
    required this.onCellTap,
  });

  @override
  Widget build(BuildContext _) => Row(
        children: List.generate(row.length, (ci) {
          final isRowSel = selRow == ri;
          final isColSel = selCol == ci;
          final isCellSel = selCellR == ri && selCellC == ci;
          final highlighted = isRowSel || isColSel || isCellSel;

          return GestureDetector(
            onTap: () => onCellTap(ri, ci),
            child: Container(
              width: cw,
              height: ch,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: isCellSel
                    ? colors.selCellBg
                    : highlighted
                        ? colors.selRowBg
                        : (odd ? colors.oddRow : colors.evenRow),
                border: Border(
                  right: BorderSide(color: colors.border, width: 0.5),
                  bottom: BorderSide(color: colors.border, width: 0.5),
                ),
              ),
              child: isCellSel
                  ? Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: colors.selCellFg, width: 1.5),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Text(
                        row[ci],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.selCellFg,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : Text(
                      row[ci],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: highlighted
                            ? colors.highlightText
                            : colors.primaryText,
                        fontSize: 12,
                        fontWeight:
                            highlighted ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
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
        header: Color(0xFF4A4A4A),
        headerText: Color(0xFFD0D0D0),
        evenRow: Color(0xFF1E1E1E),
        oddRow: Color(0xFF282828),
        primaryText: Color(0xFFD0D0D0),
        secondaryText: Color(0xFF888888),
        border: Color(0xFF3E3E3E),
        statusBar: Color(0xFF181818),
        toolbar: Color(0xFF222222),
        toolbarText: Color(0xFFC0C0C0),
        toolbarIcon: Color(0xFFA0A0A0),
        toolbarBtnBg: Color(0xFF363636),
        selCellBg: Color(0xFF5C5C5C), // distinct cell bg
        selCellFg: Color(0xFFFFFFFF), // white text + border
        selRowBg: Color(0xFF404040), // subtle row/col highlight
        highlightText: Color(0xFFF0F0F0),
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
      statusBar: Color(0xFFEBEBEB),
      toolbar: Color(0xFFF2F2F2),
      toolbarText: Color(0xFF444444),
      toolbarIcon: Color(0xFF666666),
      toolbarBtnBg: Color(0xFFE0E0E0),
      selCellBg: Color(0xFFC8C8C8), // distinct cell bg
      selCellFg: Color(0xFF111111), // dark text + border
      selRowBg: Color(0xFFE0E0E0), // subtle row/col highlight
      highlightText: Color(0xFF111111),
    );
  }
}
