import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fadocx/features/viewer/data/services/word_document_parser_service.dart';
import 'package:fadocx/features/viewer/domain/entities/parsed_document_entity.dart';

void main() {
  group('WordDocumentParserService', () {
    test('parseDocx preserves paragraphs and tables', () async {
      final directory =
          await Directory.systemTemp.createTemp('fadocx_docx_test');
      final file = File('${directory.path}/sample.docx');
      final archive = Archive()
        ..addFile(
          ArchiveFile(
            'word/document.xml',
            0,
            utf8.encode('''
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    <w:p>
      <w:r><w:t>Hello </w:t></w:r>
      <w:r><w:rPr><w:b/></w:rPr><w:t>World</w:t></w:r>
    </w:p>
    <w:tbl>
      <w:tr>
        <w:tc><w:p><w:r><w:t>A1</w:t></w:r></w:p></w:tc>
        <w:tc><w:p><w:r><w:t>B1</w:t></w:r></w:p></w:tc>
      </w:tr>
    </w:tbl>
  </w:body>
</w:document>
'''),
          ),
        );
      final bytes = ZipEncoder().encode(archive);
      await file.writeAsBytes(bytes);

      addTearDown(() async {
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      });

      final parsed = await WordDocumentParserService.parseDocx(file.path);

      expect(parsed.documentBlocks.length, 2);
      expect(parsed.documentBlocks.first, isA<DocumentParagraphBlock>());
      expect(parsed.documentBlocks.last, isA<DocumentTableBlock>());
      expect(parsed.plainTextContent, contains('Hello World'));
      expect(parsed.plainTextContent, contains('A1\tB1'));
    });

    test('parseRtf preserves paragraphs and inline formatting', () async {
      final directory =
          await Directory.systemTemp.createTemp('fadocx_rtf_test');
      final file = File('${directory.path}/sample.rtf');
      await file.writeAsString(
        r'{\rtf1\ansi Plain \b Bold\b0\par Second\tabLine\par}',
      );

      addTearDown(() async {
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      });

      final parsed = await WordDocumentParserService.parseRtf(file.path);

      expect(parsed.documentBlocks.length, 2);
      final firstParagraph =
          parsed.documentBlocks.first as DocumentParagraphBlock;
      expect(firstParagraph.inlines.any((inline) => inline.style.bold), isTrue);
      expect(parsed.plainTextContent, contains('Plain Bold'));
      expect(parsed.plainTextContent, contains('Second\tLine'));
    });
  });
}
