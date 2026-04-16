import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'package:path_provider/path_provider.dart';
import 'package:fadocx/core/utils/logger.dart';

/// Detected document corners (4 points in order: TL, TR, BR, BL)
class DocumentCorners {
  final List<cv.Point> points; // 4 corners
  final double confidence; // 0.0–1.0 how confident we are this is a document

  DocumentCorners({required this.points, required this.confidence});
}

class ImageProcessingService {
  // ─── PUBLIC API ─────────────────────────────────────────────────────────────

  /// Prepare an OCR-friendly document image.
  ///
  /// For document OCR, the highest-value preprocessing step is not heavy
  /// filtering but reliable page normalization: crop the document if a strong
  /// quadrilateral boundary exists, then add a small border so Tesseract does
  /// not drop edge text.
  static Future<String?> processImageFile(String inputPath) async {
    try {
      final mat = cv.imread(inputPath, flags: cv.IMREAD_COLOR);
      if (mat.isEmpty) {
        log.e('Failed to decode image: $inputPath');
        return null;
      }
      log.i('Image loaded: ${mat.cols}x${mat.rows}');

      var working = _resizeMat(mat, 1600);
      mat.dispose();

      final corners = _findDocumentCorners(working);
      if (corners != null && corners.confidence >= 0.55) {
        log.i(
            'Document crop accepted: conf=${corners.confidence.toStringAsFixed(2)}');
        final warped = _warpPerspective(working, corners.points);
        working.dispose();
        working = warped;
      } else {
        log.i('Document crop skipped: no confident boundary');
      }

      final bordered = _addWhiteBorder(working, 10);
      working.dispose();

      final baseDir = await getApplicationDocumentsDirectory();
      final scanPath = '${baseDir.path}/fadocx_docs/Scans';
      await Directory(scanPath).create(recursive: true);
      final outPath =
          '$scanPath/${DateTime.now().millisecondsSinceEpoch}_processed.png';
      cv.imwrite(outPath, bordered);
      log.i(
          'Processed image saved: $outPath (${bordered.cols}x${bordered.rows})');
      bordered.dispose();
      return outPath;
    } catch (e, st) {
      log.e('processImageFile error', e, st);
      return null;
    }
  }

  /// Full binary pipeline (for edge-detection preview, not OCR).
  static Future<img.Image?> detectDocumentEdges(img.Image image) async {
    try {
      log.i('OpenCV edge pipeline: start (${image.width}x${image.height})');

      final pngBytes = img.encodePng(image);
      final mat = cv.imdecode(Uint8List.fromList(pngBytes), cv.IMREAD_COLOR);
      final resized = _resizeMat(mat, 2048);
      final gray = cv.cvtColor(resized, cv.COLOR_BGR2GRAY);
      final blurred = cv.gaussianBlur(gray, (5, 5), 0);
      final binary = cv.adaptiveThreshold(
        blurred,
        255,
        cv.ADAPTIVE_THRESH_GAUSSIAN_C,
        cv.THRESH_BINARY,
        11,
        2,
      );
      final kernel = cv.getStructuringElement(cv.MORPH_RECT, (3, 3));
      final closed = cv.morphologyEx(binary, cv.MORPH_CLOSE, kernel);
      final deskewed = _deskewHough(closed, resized);

      final (_, finalBytes) = cv.imencode('.png', deskewed);
      final result = img.decodeImage(finalBytes);

      log.i('OpenCV edge pipeline complete');
      mat.dispose();
      resized.dispose();
      gray.dispose();
      blurred.dispose();
      binary.dispose();
      closed.dispose();
      kernel.dispose();
      deskewed.dispose();

      return result;
    } catch (e, st) {
      log.e('OpenCV pipeline error: $e', e, st);
      return null;
    }
  }

  /// Perspective correction (img.Image API — used by legacy callers).
  static Future<img.Image?> correctPerspective(img.Image image) async {
    try {
      final pngBytes = img.encodePng(image);
      final mat = cv.imdecode(Uint8List.fromList(pngBytes), cv.IMREAD_COLOR);

      final corners = _findDocumentCorners(mat);
      img.Image result;

      if (corners != null && corners.confidence >= 0.85) {
        log.i(
            'Perspective correction: quad found (conf=${corners.confidence.toStringAsFixed(2)})');
        final warped = _warpPerspective(mat, corners.points);
        final (_, warpedBytes) = cv.imencode('.png', warped);
        result = img.decodeImage(warpedBytes) ?? image;
        warped.dispose();
      } else {
        log.i('Perspective correction: low confidence, keeping original');
        result = image;
      }

      mat.dispose();
      return result;
    } catch (e, st) {
      log.e('Perspective correction error: $e', e, st);
      return null;
    }
  }

  /// Detect document corners from a Mat (for live preview).
  static DocumentCorners? detectCornersFromMat(cv.Mat mat) {
    try {
      return _findDocumentCorners(mat);
    } catch (e) {
      return null;
    }
  }

  // ─── PRIVATE HELPERS ────────────────────────────────────────────────────────

  /// Resize mat so the longest side ≤ maxDim (preserves aspect ratio).
  static cv.Mat _resizeMat(cv.Mat mat, int maxDim) {
    final w = mat.cols;
    final h = mat.rows;
    if (w <= maxDim && h <= maxDim) return mat.clone();
    final scale = maxDim / max(w, h);
    return cv.resize(mat, ((w * scale).toInt(), (h * scale).toInt()));
  }

  /// Add a white border around the image.
  /// Tesseract has a known issue where text touching the image edge is dropped.
  static cv.Mat _addWhiteBorder(cv.Mat mat, int borderSize) {
    try {
      return cv.copyMakeBorder(
        mat,
        borderSize,
        borderSize,
        borderSize,
        borderSize,
        cv.BORDER_CONSTANT,
        value: cv.Scalar(255, 255, 255, 255),
      );
    } catch (e) {
      log.w('_addWhiteBorder failed: $e');
      return mat.clone();
    }
  }

  /// Deskew using Hough probabilistic lines — used only for edge detection
  /// preview pipeline, not for OCR preprocessing.
  static cv.Mat _deskewHough(cv.Mat binaryMat, cv.Mat inputMat) {
    try {
      final edges = cv.canny(binaryMat, 50, 150);
      final lines = cv.HoughLinesP(edges, 1, pi / 180, 80,
          minLineLength: 100, maxLineGap: 10);

      if (lines.rows == 0) {
        edges.dispose();
        lines.dispose();
        return inputMat.clone();
      }

      final angles = <double>[];
      for (int i = 0; i < lines.rows; i++) {
        final x1 = lines.at<int>(i, 0);
        final y1 = lines.at<int>(i, 1);
        final x2 = lines.at<int>(i, 2);
        final y2 = lines.at<int>(i, 3);
        final angle =
            atan2((y2 - y1).toDouble(), (x2 - x1).toDouble()) * 180.0 / pi;
        if (angle.abs() < 45) angles.add(angle);
      }

      edges.dispose();
      lines.dispose();

      if (angles.isEmpty) return inputMat.clone();

      angles.sort();
      final medianAngle = angles[angles.length ~/ 2];

      if (medianAngle.abs() < 0.5 || medianAngle.abs() > 45) {
        return inputMat.clone();
      }

      final center = cv.Point2f(inputMat.cols / 2.0, inputMat.rows / 2.0);
      final rotMat = cv.getRotationMatrix2D(center, -medianAngle, 1.0);
      final rotated = cv.warpAffine(
        inputMat,
        rotMat,
        (inputMat.cols, inputMat.rows),
        borderMode: cv.BORDER_REPLICATE,
      );
      rotMat.dispose();
      return rotated;
    } catch (e) {
      log.w('Deskew (Hough) failed: $e');
      return inputMat.clone();
    }
  }

  /// Find the largest quadrilateral contour (document boundary).
  static DocumentCorners? _findDocumentCorners(cv.Mat mat) {
    try {
      final scale = 800.0 / max(mat.cols, mat.rows);
      final small = scale < 1.0
          ? cv.resize(
              mat, ((mat.cols * scale).toInt(), (mat.rows * scale).toInt()))
          : mat.clone();

      final gray = small.channels == 1
          ? small.clone()
          : cv.cvtColor(small, cv.COLOR_BGR2GRAY);
      final blurred = cv.gaussianBlur(gray, (5, 5), 0);
      final edges = cv.canny(blurred, 75, 200);
      final kernel = cv.getStructuringElement(cv.MORPH_RECT, (3, 3));
      final dilated = cv.dilate(edges, kernel);

      final (contours, _) = cv.findContours(
        dilated,
        cv.RETR_LIST,
        cv.CHAIN_APPROX_SIMPLE,
      );

      gray.dispose();
      blurred.dispose();
      edges.dispose();
      kernel.dispose();
      dilated.dispose();

      final imageArea = small.cols * small.rows;
      cv.VecPoint? bestQuad;
      double bestArea = 0;

      for (final contour in contours) {
        final area = cv.contourArea(contour);
        if (area < imageArea * 0.1) continue;
        if (area > imageArea * 0.99) continue;

        final peri = cv.arcLength(contour, true);
        final approx = cv.approxPolyDP(contour, 0.02 * peri, true);

        if (approx.length == 4 && area > bestArea) {
          bestArea = area;
          bestQuad = approx;
        }
      }

      small.dispose();
      if (bestQuad == null) return null;

      final invScale = 1.0 / scale;
      final scaledPoints = bestQuad
          .map((p) => cv.Point(
                (p.x * invScale).toInt(),
                (p.y * invScale).toInt(),
              ))
          .toList();

      final confidence = (bestArea / imageArea).clamp(0.0, 1.0);
      return DocumentCorners(points: scaledPoints, confidence: confidence);
    } catch (e) {
      log.w('Corner detection failed: $e');
      return null;
    }
  }

  /// Warp perspective to straighten detected quad.
  static cv.Mat _warpPerspective(cv.Mat mat, List<cv.Point> corners) {
    final sorted = _sortCorners(corners);
    final tl = sorted[0];
    final tr = sorted[1];
    final br = sorted[2];
    final bl = sorted[3];

    final widthTop = sqrt(pow(tr.x - tl.x, 2) + pow(tr.y - tl.y, 2));
    final widthBottom = sqrt(pow(br.x - bl.x, 2) + pow(br.y - bl.y, 2));
    final maxWidth = max(widthTop, widthBottom).toInt();

    final heightLeft = sqrt(pow(bl.x - tl.x, 2) + pow(bl.y - tl.y, 2));
    final heightRight = sqrt(pow(br.x - tr.x, 2) + pow(br.y - tr.y, 2));
    final maxHeight = max(heightLeft, heightRight).toInt();

    final src = cv.VecPoint.fromList(sorted);
    final dst = cv.VecPoint.fromList([
      cv.Point(0, 0),
      cv.Point(maxWidth - 1, 0),
      cv.Point(maxWidth - 1, maxHeight - 1),
      cv.Point(0, maxHeight - 1),
    ]);

    final M = cv.getPerspectiveTransform(src, dst);
    final warped = cv.warpPerspective(mat, M, (maxWidth, maxHeight));
    M.dispose();
    return warped;
  }

  /// Sort 4 corners into TL, TR, BR, BL order.
  static List<cv.Point> _sortCorners(List<cv.Point> pts) {
    final centerX = pts.map((p) => p.x).reduce((a, b) => a + b) / pts.length;
    final centerY = pts.map((p) => p.y).reduce((a, b) => a + b) / pts.length;

    final clockwise = List<cv.Point>.from(pts)
      ..sort((a, b) {
        final angleA =
            atan2((a.y - centerY).toDouble(), (a.x - centerX).toDouble());
        final angleB =
            atan2((b.y - centerY).toDouble(), (b.x - centerX).toDouble());
        return angleA.compareTo(angleB);
      });

    final topLeftIndex = clockwise.indexWhere((p) =>
        p.x + p.y == clockwise.map((point) => point.x + point.y).reduce(min));

    final rotated = [
      ...clockwise.sublist(topLeftIndex),
      ...clockwise.sublist(0, topLeftIndex),
    ];

    final tl = rotated[0];
    final tr = rotated[1];
    final br = rotated[2];
    final bl = rotated[3];

    final cross = (tr.x - tl.x) * (bl.y - tl.y) - (tr.y - tl.y) * (bl.x - tl.x);
    if (cross < 0) {
      return [tl, bl, br, tr];
    }

    return [tl, tr, br, bl];
  }
}
