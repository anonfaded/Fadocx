import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fadocx/core/utils/logger.dart';
import 'package:xml/xml.dart';

class TesseractService {
  static const String _language = 'eng';
  static const String _tessdataAsset = 'assets/tessdata/eng.traineddata';

  /// Copy tessdata from Flutter assets to the app documents directory.
  /// Must be called on the **main isolate** before spawning any background
  /// isolate that runs OCR.
  static Future<String> ensureTessdataReady() async {
    final appDir = await getApplicationDocumentsDirectory();
    final tessdataDir = Directory('${appDir.path}/tessdata');
    if (!tessdataDir.existsSync()) {
      tessdataDir.createSync(recursive: true);
    }

    final destFile = File('${tessdataDir.path}/eng.traineddata');
    if (!destFile.existsSync()) {
      log.i('Copying tessdata to filesystem: ${destFile.path}');
      final data = await rootBundle.load(_tessdataAsset);
      final bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await destFile.writeAsBytes(bytes, flush: true);
      log.i('Tessdata copy complete (${bytes.length} bytes)');
    } else {
      log.i('Tessdata already on filesystem: ${destFile.path}');
    }

    return tessdataDir.path;
  }

  /// Extract text from an image file using hOCR for line boxes and confidence.
  ///
  /// This app is a document scanner, so the OCR flow is document-first:
  ///   PSM 1 = full page with automatic orientation/script detection
  ///   PSM 6 = single uniform text block fallback after page crop/warp
  static Future<OcrResult?> extractFromImage(
    String imagePath, {
    String? tessdataPath,
  }) async {
    try {
      if (!File(imagePath).existsSync()) {
        log.w('Image file not found: $imagePath');
        return null;
      }

      final baseArgs = <String, String>{
        'oem': '1', // LSTM engine only — most accurate
        'preserve_interword_spaces': '1',
        'user_defined_dpi': '300',
      };
      if (tessdataPath != null) {
        baseArgs['tessdata'] = tessdataPath;
      }

      final primaryResult = await _extractBestForPath(imagePath, baseArgs);
      if (primaryResult == null) {
        log.w('No text found in primary OCR pass');
        return null;
      }

      OcrResult bestOverall = primaryResult;
      String bestPath = imagePath;

      if (_needsRotationRetry(primaryResult)) {
        final candidatePaths = await _buildRotationCandidates(imagePath);
        for (final candidatePath in candidatePaths.skip(1)) {
          final candidateResult =
              await _extractBestForPath(candidatePath, baseArgs);
          if (candidateResult == null) continue;

          final score = _scoreResult(candidateResult);
          final bestScore = _scoreResult(bestOverall);
          if (score > bestScore) {
            bestOverall = candidateResult;
            bestPath = candidatePath;
          }
        }
      }

      if (bestPath != imagePath) {
        log.i('Using rotated OCR candidate: $bestPath');
      }

      log.i(
          'hOCR parsed: ${bestOverall.lines.length} lines, ${bestOverall.words.length} words, avg confidence: ${bestOverall.averageConfidence.toStringAsFixed(2)}');
      log.i('Extracted text: "${bestOverall.plainText}"');

      return bestOverall;
    } catch (e, st) {
      log.e('Error during hOCR extraction', e, st);
      return null;
    }
  }

  static Future<OcrResult?> _extractBestForPath(
    String imagePath,
    Map<String, String> baseArgs,
  ) async {
    try {
      log.i('Starting hOCR extraction for: $imagePath');

      final args1 = Map<String, String>.from(baseArgs)..['psm'] = '1';
      final hocr1 = await FlutterTesseractOcr.extractHocr(
        imagePath,
        language: _language,
        args: args1,
      );
      log.i('PSM 1 hOCR length: ${hocr1.length}');
      log.i(
          'hOCR raw (first 500): ${hocr1.substring(0, hocr1.length.clamp(0, 500))}');

      OcrResult? result1;
      if (hocr1.isNotEmpty) {
        result1 = _parseHocr(hocr1);
      }

      OcrResult? result6;
      final psm1LineCount = result1?.lines.length ?? 0;
      final psm1WordCount = result1?.words.length ?? 0;
      final psm1Conf = result1?.averageConfidence ?? 0.0;

      if (_needsPsm6Retry(result1)) {
        log.i(
            'PSM 1 weak ($psm1LineCount lines, $psm1WordCount words, conf=${psm1Conf.toStringAsFixed(2)}), trying PSM 6');
        final args6 = Map<String, String>.from(baseArgs)..['psm'] = '6';
        final hocr6 = await FlutterTesseractOcr.extractHocr(
          imagePath,
          language: _language,
          args: args6,
        );
        log.i('PSM 6 hOCR length: ${hocr6.length}');
        if (hocr6.isNotEmpty) {
          result6 = _parseHocr(hocr6);
        }
      }

      OcrResult? best;
      if (result1 != null && result6 != null) {
        final score1 = _scoreResult(result1);
        final score6 = _scoreResult(result6);
        best = score1 >= score6 ? result1 : result6;
        log.i(
            'PSM comparison: PSM1 score=${score1.toStringAsFixed(1)}, PSM6 score=${score6.toStringAsFixed(1)} -> using PSM${score1 >= score6 ? 1 : 6}');
      } else {
        best = result1 ?? result6;
      }

      return best;
    } catch (e, st) {
      log.e('Error during OCR candidate extraction', e, st);
      return null;
    }
  }

  static OcrResult _parseHocr(String hocr) {
    try {
      final document = XmlDocument.parse('<root>$hocr</root>');
      final pageNode = document
          .findAllElements('div')
          .firstWhere(_isOcrPage, orElse: () => XmlElement(XmlName('div')));
      final pageBox = _parseBbox(pageNode.getAttribute('title') ?? '');

      final words = <OcrWord>[];
      final lines = <TextBlock>[];

      for (final lineNode
          in document.findAllElements('span').where(_isOcrLine)) {
        final lineWords = <OcrWord>[];
        for (final wordNode
            in lineNode.findAllElements('span').where(_isOcrWord)) {
          final text = _cleanText(wordNode.innerText);
          if (text.isEmpty) continue;

          final title = wordNode.getAttribute('title') ?? '';
          final bbox = _parseBbox(title);
          final confidence = _parseConfidence(title);

          final word = OcrWord(
            text: text,
            confidence: confidence,
            x: bbox?.left,
            y: bbox?.top,
            width: bbox?.width,
            height: bbox?.height,
          );
          words.add(word);
          lineWords.add(word);
        }

        if (lineWords.isEmpty) continue;

        final lineTitle = lineNode.getAttribute('title') ?? '';
        final lineBox = _parseBbox(lineTitle) ?? _deriveBbox(lineWords);
        final lineConfidence = lineWords
                .map((word) => word.confidence)
                .fold<double>(0, (sum, value) => sum + value) /
            lineWords.length;
        final lineText = lineWords.map((word) => word.text).join(' ').trim();

        lines.add(TextBlock(
          text: lineText,
          confidence: lineConfidence,
          x: lineBox?.left,
          y: lineBox?.top,
          width: lineBox?.width,
          height: lineBox?.height,
        ));
      }

      final plainText = lines
          .where((line) => line.text.isNotEmpty)
          .map((line) => line.text)
          .join('\n')
          .trim();

      return OcrResult(
        words: words,
        lines: lines,
        plainText: plainText.isNotEmpty
            ? plainText
            : words.map((word) => word.text).join(' ').trim(),
        imageWidth: pageBox?.width,
        imageHeight: pageBox?.height,
      );
    } catch (e, st) {
      log.e('Failed to parse hOCR', e, st);
      return const OcrResult(words: [], lines: [], plainText: '');
    }
  }

  static bool _isOcrPage(XmlElement node) =>
      (node.getAttribute('class') ?? '').contains('ocr_page');

  static bool _isOcrLine(XmlElement node) =>
      (node.getAttribute('class') ?? '').contains('ocr_line');

  static bool _isOcrWord(XmlElement node) =>
      (node.getAttribute('class') ?? '').contains('ocrx_word');

  static String _cleanText(String text) =>
      text.replaceAll(RegExp(r'\s+'), ' ').trim();

  static double _parseConfidence(String title) {
    final confMatch = RegExp(r'x_wconf\s+(\d+)').firstMatch(title);
    if (confMatch == null) return 0.0;
    return int.parse(confMatch.group(1)!) / 100.0;
  }

  static _HocrBox? _parseBbox(String title) {
    final bboxMatch =
        RegExp(r'bbox\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)').firstMatch(title);
    if (bboxMatch == null) return null;

    final left = int.parse(bboxMatch.group(1)!);
    final top = int.parse(bboxMatch.group(2)!);
    final right = int.parse(bboxMatch.group(3)!);
    final bottom = int.parse(bboxMatch.group(4)!);
    return _HocrBox(
      left: left,
      top: top,
      width: right - left,
      height: bottom - top,
    );
  }

  static _HocrBox? _deriveBbox(List<OcrWord> words) {
    final boxedWords = words
        .where((word) =>
            word.x != null &&
            word.y != null &&
            word.width != null &&
            word.height != null)
        .toList();
    if (boxedWords.isEmpty) return null;

    final left =
        boxedWords.map((word) => word.x!).reduce((a, b) => a < b ? a : b);
    final top =
        boxedWords.map((word) => word.y!).reduce((a, b) => a < b ? a : b);
    final right = boxedWords
        .map((word) => word.x! + word.width!)
        .reduce((a, b) => a > b ? a : b);
    final bottom = boxedWords
        .map((word) => word.y! + word.height!)
        .reduce((a, b) => a > b ? a : b);

    return _HocrBox(
      left: left,
      top: top,
      width: right - left,
      height: bottom - top,
    );
  }

  static Future<List<String>> _buildRotationCandidates(String imagePath) async {
    final candidates = <String>[imagePath];

    try {
      final bytes = await File(imagePath).readAsBytes();
      final source = img.decodeImage(bytes);
      if (source == null) return candidates;

      final tempDir = await getTemporaryDirectory();
      final basename = DateTime.now().millisecondsSinceEpoch;
      final rotations = <({int degrees, img.Image image})>[
        (degrees: 90, image: img.copyRotate(source, angle: 90)),
        (degrees: 270, image: img.copyRotate(source, angle: 270)),
      ];

      for (final rotation in rotations) {
        final path = '${tempDir.path}/ocr_${basename}_${rotation.degrees}.png';
        await File(path)
            .writeAsBytes(img.encodePng(rotation.image), flush: true);
        candidates.add(path);
      }
    } catch (e) {
      log.w('Failed to prepare rotation candidates: $e');
    }

    return candidates;
  }

  static bool _needsRotationRetry(OcrResult result) {
    final horizontalBias = _horizontalBias(result.lines);
    return horizontalBias < 0.45 ||
        result.averageConfidence < 0.72 ||
        result.lines.length < 3;
  }

  static bool _needsPsm6Retry(OcrResult? result) {
    if (result == null) return true;
    final horizontalBias = _horizontalBias(result.lines);
    return result.averageConfidence < 0.7 ||
        result.lines.length < 3 ||
        horizontalBias < 0.55;
  }

  static double _scoreResult(OcrResult result) {
    final strongLines =
        result.lines.where((line) => line.confidence >= 0.6).length;
    final strongWords =
        result.words.where((word) => word.confidence >= 0.65).length;
    final horizontalBias = _horizontalBias(result.lines);
    return strongLines * 4 +
        strongWords +
        (result.plainText.length / 80) +
        (horizontalBias * 6);
  }

  static double _horizontalBias(List<TextBlock> lines) {
    final measurable = lines
        .where((line) =>
            line.width != null &&
            line.height != null &&
            line.width! > 0 &&
            line.height! > 0)
        .toList();
    if (measurable.isEmpty) return 0.0;

    final horizontal =
        measurable.where((line) => line.width! >= line.height!).length;
    return horizontal / measurable.length;
  }

  static Future<bool> isOCRAvailable() async => true;
}

/// A single recognized word with real confidence from hOCR.
class OcrWord {
  final String text;
  final double confidence; // 0.0 – 1.0
  final int? x;
  final int? y;
  final int? width;
  final int? height;

  const OcrWord({
    required this.text,
    required this.confidence,
    this.x,
    this.y,
    this.width,
    this.height,
  });
}

/// Full OCR result: parsed words + reconstructed plain text + aggregate score.
class OcrResult {
  final List<OcrWord> words;
  final List<TextBlock> lines;
  final String plainText;
  final int? imageWidth;
  final int? imageHeight;

  const OcrResult({
    required this.words,
    required this.lines,
    required this.plainText,
    this.imageWidth,
    this.imageHeight,
  });

  double get averageConfidence {
    if (words.isEmpty) return 0.0;
    return words.map((w) => w.confidence).reduce((a, b) => a + b) /
        words.length;
  }
}

/// Model for text block with confidence (used by ScanResult / UI)
class TextBlock {
  final String text;
  final double confidence;
  final int? x;
  final int? y;
  final int? width;
  final int? height;

  const TextBlock({
    required this.text,
    required this.confidence,
    this.x,
    this.y,
    this.width,
    this.height,
  });

  Map<String, dynamic> toMap() => {
        'text': text,
        'confidence': confidence,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
      };
}

class _HocrBox {
  final int left;
  final int top;
  final int width;
  final int height;

  const _HocrBox({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });
}
