import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:fadocx/features/viewer/data/services/document_parser_service.dart';

void main() {
  group('DocumentParserService.parseCSV', () {
    test('parses quoted commas, escaped quotes, and multiline fields',
        () async {
      final directory =
          await Directory.systemTemp.createTemp('fadocx_csv_test');
      final file = File('${directory.path}/sample.csv');
      await file.writeAsString(
        'name,notes\n'
        '"Doe, Jane","Line 1\nLine 2"\n'
        '"Quote","He said ""hello"""',
      );

      addTearDown(() async {
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      });

      final parsed = await DocumentParserService.parseCSV(file.path);
      final rows = (parsed['sheets'] as List).first['rows'] as List;

      expect(rows[0], ['name', 'notes']);
      expect(rows[1], ['Doe, Jane', 'Line 1\nLine 2']);
      expect(rows[2], ['Quote', 'He said "hello"']);
    });
  });
}
