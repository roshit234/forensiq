// lib/services/image_quality_service.dart
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Configurable prototype thresholds for quality validation.
class ImageQualityConfig {
  /// Minimum Gated Laplacian Variance required for acceptable sharpness.
  /// Clearly blurred / motion-smeared photos score 90 - 160.
  /// Sharp, in-focus test photographs score 280 - 1500+.
  static const double minSharpnessScore = 220.0;

  /// Minimum Sobel Edge Acutance required (steepness of the best edges).
  /// Smeared motion blur transitions rarely exceed 65-70.
  /// In-focus edges and text reach 90 - 200+.
  static const double minDetailScore = 85.0;

  /// Exposure bounds (0 - 255 scale)
  static const double minBrightness = 35.0;
  static const double maxBrightness = 225.0;
  static const double maxOverexposedRatio = 0.35; // 35% pure white pixels
}

/// Structured inspection result
class QualityCheckResult {
  final bool isAcceptable;
  final double sharpnessScore;
  final double detailScore;
  final double brightnessScore;
  final String exposureStatus; // "Normal", "Too Dark", "Overexposed"
  final int width;
  final int height;
  final String? failureReason;

  const QualityCheckResult({
    required this.isAcceptable,
    required this.sharpnessScore,
    required this.detailScore,
    required this.brightnessScore,
    required this.exposureStatus,
    required this.width,
    required this.height,
    this.failureReason,
  });
}

class ImageQualityService {
  const ImageQualityService();

  /// Analyzes the raw photo and returns an objective multi-metric evaluation
  Future<QualityCheckResult> analyzeImage(XFile file) async {
    try {
      final Uint8List bytes = await file.readAsBytes();

      if (bytes.isEmpty) {
        return _buildFailureResult(
          reason: 'Captured image file is empty or corrupted.',
          width: 0,
          height: 0,
        );
      }

      // 1. Decode Image
      final img.Image? decoded = img.decodeImage(bytes);
      if (decoded == null) {
        return _buildFailureResult(
          reason: 'Unable to decode image format.',
          width: 0,
          height: 0,
        );
      }

      final int originalWidth = decoded.width;
      final int originalHeight = decoded.height;

      // 2. Validate Dimensions
      if (originalWidth < 300 || originalHeight < 300) {
        return _buildFailureResult(
          reason: 'Image resolution is too low ($originalWidth × $originalHeight px).',
          width: originalWidth,
          height: originalHeight,
        );
      }

      // 3. Normalize resolution to a standard 640px width for consistent scale
      final img.Image normalized = img.copyResize(decoded, width: 640);
      final img.Image grayscale = img.grayscale(normalized);

      // 4. Exposure & Brightness Analysis
      final exposureInfo = _evaluateExposure(grayscale);
      final double brightness = exposureInfo['brightness']!;
      final double overexposedRatio = exposureInfo['overexposedRatio']!;

      String exposureStatus = 'Normal';
      if (brightness < ImageQualityConfig.minBrightness) {
        exposureStatus = 'Too Dark';
        return QualityCheckResult(
          isAcceptable: false,
          sharpnessScore: 0.0,
          detailScore: 0.0,
          brightnessScore: double.parse(brightness.toStringAsFixed(1)),
          exposureStatus: exposureStatus,
          width: originalWidth,
          height: originalHeight,
          failureReason: 'The image is too dark. Please ensure adequate lighting and retake.',
        );
      } else if (brightness > ImageQualityConfig.maxBrightness ||
          overexposedRatio > ImageQualityConfig.maxOverexposedRatio) {
        exposureStatus = 'Overexposed';
        return QualityCheckResult(
          isAcceptable: false,
          sharpnessScore: 0.0,
          detailScore: 0.0,
          brightnessScore: double.parse(brightness.toStringAsFixed(1)),
          exposureStatus: exposureStatus,
          width: originalWidth,
          height: originalHeight,
          failureReason: 'The image is overexposed with heavy glare. Please adjust lighting and retake.',
        );
      }

      // 5. Metric 1: Noise-Gated Laplacian Variance
      final double sharpness = _computeGatedLaplacianVariance(grayscale);

      // 6. Metric 2: Sobel Edge Acutance (Steepest edge transitions)
      final double detail = _computeSobelAcutance(grayscale);

      // 7. Strict Decision Logic:
      // An image is blurry if Sharpness is under 220.0 OR Detail is under 85.0.
      final bool isBlurry = (sharpness < ImageQualityConfig.minSharpnessScore) ||
          (detail < ImageQualityConfig.minDetailScore);

      final bool isAcceptable = !isBlurry;

      final result = QualityCheckResult(
        isAcceptable: isAcceptable,
        sharpnessScore: double.parse(sharpness.toStringAsFixed(1)),
        detailScore: double.parse(detail.toStringAsFixed(1)),
        brightnessScore: double.parse(brightness.toStringAsFixed(1)),
        exposureStatus: exposureStatus,
        width: originalWidth,
        height: originalHeight,
        failureReason: isAcceptable
            ? null
            : 'The image appears too blurry for reliable analysis. Please hold the phone steady and capture the test again.',
      );

      debugPrint(
        '[ForensIQ Quality Check] Sharpness: ${result.sharpnessScore} (Min: ${ImageQualityConfig.minSharpnessScore}) | '
        'Detail: ${result.detailScore} (Min: ${ImageQualityConfig.minDetailScore}) | '
        'Result: ${isAcceptable ? "PASS" : "REJECT (Blurry)"}',
      );

      return result;
    } catch (e) {
      return _buildFailureResult(
        reason: 'Image inspection error: $e',
        width: 0,
        height: 0,
      );
    }
  }

  /// Calculates Laplacian Variance while ignoring sensor ISO noise (|L| <= 10)
  double _computeGatedLaplacianVariance(img.Image gray) {
    final int w = gray.width;
    final int h = gray.height;

    double sum = 0.0;
    double sumSquared = 0.0;
    int count = 0;

    const double noiseFloor = 10.0;

    for (int y = 1; y < h - 1; y++) {
      for (int x = 1; x < w - 1; x++) {
        final num center = gray.getPixel(x, y).r;
        final num up = gray.getPixel(x, y - 1).r;
        final num down = gray.getPixel(x, y + 1).r;
        final num left = gray.getPixel(x - 1, y).r;
        final num right = gray.getPixel(x + 1, y).r;

        double lap = ((up + down + left + right) - (4 * center)).toDouble();

        // Suppress microscopic sensor noise
        if (lap.abs() <= noiseFloor) {
          lap = 0.0;
        }

        sum += lap;
        sumSquared += lap * lap;
        count++;
      }
    }

    if (count == 0) return 0.0;
    final double mean = sum / count;
    final double variance = (sumSquared / count) - (mean * mean);
    return variance > 0 ? variance : 0.0;
  }

  /// Computes the steepness of true in-focus edges using Sobel operators
  double _computeSobelAcutance(img.Image gray) {
    final int w = gray.width;
    final int h = gray.height;
    final List<double> strongGradients = [];

    for (int y = 1; y < h - 1; y += 2) {
      for (int x = 1; x < w - 1; x += 2) {
        final num p00 = gray.getPixel(x - 1, y - 1).r;
        final num p01 = gray.getPixel(x, y - 1).r;
        final num p02 = gray.getPixel(x + 1, y - 1).r;
        final num p10 = gray.getPixel(x - 1, y).r;
        final num p12 = gray.getPixel(x + 1, y).r;
        final num p20 = gray.getPixel(x - 1, y + 1).r;
        final num p21 = gray.getPixel(x, y + 1).r;
        final num p22 = gray.getPixel(x + 1, y + 1).r;

        final double gx = ((p02 + 2 * p12 + p22) - (p00 + 2 * p10 + p20)).toDouble();
        final double gy = ((p20 + 2 * p21 + p22) - (p00 + 2 * p01 + p02)).toDouble();
        final double magnitude = sqrt(gx * gx + gy * gy) / 4.0;

        if (magnitude > 20.0) {
          strongGradients.add(magnitude);
        }
      }
    }

    if (strongGradients.isEmpty) return 0.0;
    strongGradients.sort((a, b) => b.compareTo(a));

    // Average the top 5% steepest edge transitions
    final int topK = max(1, (strongGradients.length * 0.05).toInt());
    final double topMean =
        strongGradients.take(topK).reduce((a, b) => a + b) / topK;

    return topMean;
  }

  Map<String, double> _evaluateExposure(img.Image gray) {
    double totalLum = 0.0;
    int overexposedCount = 0;
    final int totalPixels = gray.width * gray.height;

    for (final pixel in gray) {
      final num lum = pixel.r;
      totalLum += lum.toDouble();
      if (lum >= 250) {
        overexposedCount++;
      }
    }

    return {
      'brightness': totalLum / totalPixels,
      'overexposedRatio': overexposedCount / totalPixels,
    };
  }

  QualityCheckResult _buildFailureResult({
    required String reason,
    required int width,
    required int height,
  }) {
    return QualityCheckResult(
      isAcceptable: false,
      sharpnessScore: 0.0,
      detailScore: 0.0,
      brightnessScore: 0.0,
      exposureStatus: 'Unknown',
      width: width,
      height: height,
      failureReason: reason,
    );
  }
}