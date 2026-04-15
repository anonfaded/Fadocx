/// Represents a spreadsheet sheet/tab
class SheetEntity {
  final String name;
  final List<List<String>> rows;
  final int rowCount;
  final int colCount;

  SheetEntity({
    required this.name,
    required this.rows,
    required this.rowCount,
    required this.colCount,
  });

  /// Create a copy with optional changes
  SheetEntity copyWith({
    String? name,
    List<List<String>>? rows,
    int? rowCount,
    int? colCount,
  }) {
    return SheetEntity(
      name: name ?? this.name,
      rows: rows ?? this.rows,
      rowCount: rowCount ?? this.rowCount,
      colCount: colCount ?? this.colCount,
    );
  }
}
