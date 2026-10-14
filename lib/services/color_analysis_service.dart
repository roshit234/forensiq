// lib/services/color_analysis_service.dart
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../models/color_analysis_result.dart';
import '../models/color_calibration_result.dart';
import '../models/image_region.dart';

class ColorAnalysisConfig {
  /// Prototype parameter: Euclidean colour distances greater than this threshold
  /// indicate that the reaction colour does not match any reference swatch reliably.
  /// NOTE: This is a prototype parameter and requires validation with real forensic kit data.
  static const double maxColorDistance = 85.0;

  /// Central sampling window ratio (60% to avoid boundaries, borders, text, and edge shadows)
  static const double sampleRatio = 0.60;
}

class ColorAnalysisService {
  const ColorAnalysisService();

  Future<ColorAnalysisResult?> analyzeReactionRegion({
    required String imagePath,
    required ImageRegion reactionRegion,
    required ColorCalibrationResult calibrationResult,
  }) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        debugPrint('[ColorAnalysisService] Error: Image file not found.');
        return null;
      }

      final bytes = await file.readAsBytes();
      final img.Image? fullImage = img.decodeImage(bytes);

      if (fullImage == null) {
        debugPrint('[ColorAnalysisService] Error: Failed to decode image.');
        return null;
      }

      final int origW = fullImage.width;
      final int origH = fullImage.height;

      // Extract reaction region bounds in original image pixels
      final double rxnL = reactionRegion.left.clamp(0.0, origW.toDouble() - 1);
      final double rxnT = reactionRegion.top.clamp(0.0, origH.toDouble() - 1);
      final double rxnW = reactionRegion.width.clamp(10.0, origW.toDouble() - rxnL);
      final double rxnH = reactionRegion.height.clamp(10.0, origH.toDouble() - rxnT);

      if (rxnW < 15 || rxnH < 15) {
        debugPrint('[ColorAnalysisService] Error: Reaction region too small.');
        return null;
      }

      // Sample central 60% of the reaction area
      final double sampleW = rxnW * ColorAnalysisConfig.sampleRatio;
      final double sampleH = rxnH * ColorAnalysisConfig.sampleRatio;
      final double sampleLeft = rxnL + ((rxnW - sampleW) / 2.0);
      final double sampleTop = rxnT + ((rxnH - sampleH) / 2.0);

      final _SamplingOutput sampling = _sampleMedianRgb(
        image: fullImage,
        left: sampleLeft.toInt(),
        top: sampleTop.toInt(),
        width: sampleW.toInt(),
        height: sampleH.toInt(),
      );

      final List<int> observedRgb = sampling.medianRgb;
      final int sampleCount = sampling.pixelCount;

      // Apply calibration matrix from the current test session
      final List<int> calibratedRgb = calibrationResult.applyCalibration(
        observedRgb[0],
        observedRgb[1],
        observedRgb[2],
      );

      // Compare calibrated reaction RGB against the calibrated reference patches
      double minDistance = double.infinity;
      String closestColorName = 'Unknown';

      for (final patch in calibrationResult.patches) {
        final double dist = _calculateEuclideanDistance(
          calibratedRgb,
          patch.calibratedRgb,
        );

        if (dist < minDistance) {
          minDistance = dist;
          closestColorName = patch.name;
        }
      }

      final double finalDistance = double.parse(minDistance.toStringAsFixed(1));

      // Apply Prototype Classification Rule:
      // Red = Positive, other reference colours = Negative, distance > max = Inconclusive
      String classification;
      if (finalDistance > ColorAnalysisConfig.maxColorDistance) {
        classification = 'Inconclusive';
      } else if (closestColorName.toLowerCase() == 'red') {
        classification = 'Positive';
      } else {
        classification = 'Negative';
      }

      debugPrint('[ColorAnalysisService] Analysis Complete:');
      debugPrint(' -> Observed: $observedRgb');
      debugPrint(' -> Calibrated: $calibratedRgb');
      debugPrint(' -> Closest Reference: $closestColorName (Distance: $finalDistance)');
      debugPrint(' -> Classification: $classification');

      return ColorAnalysisResult(
        observedReactionRgb: observedRgb,
        calibratedReactionRgb: calibratedRgb,
        closestReferenceColor: closestColorName,
        colorDistance: finalDistance,
        classification: classification,
        calibrationApplied: true,
        sampledPixelCount: sampleCount,
      );
    } catch (e) {
      debugPrint('[ColorAnalysisService] Exception: $e');
      return null;
    }
  }

  _SamplingOutput _sampleMedianRgb({
    required img.Image image,
    required int left,
    required int top,
    required int width,
    required int height,
  }) {
    final List<int> rValues = [];
    final List<int> gValues = [];
    final List<int> bValues = [];

    final int startX = left.clamp(0, image.width - 1);
    final int startY = top.clamp(0, image.height - 1);
    final int endX = (left + width).clamp(0, image.width);
    final int endY = (top + height).clamp(0, image.height);

    for (int y = startY; y < endY; y++) {
      for (int x = startX; x < endX; x++) {
        final pixel = image.getPixel(x, y);
        rValues.add(pixel.r.toInt());
        gValues.add(pixel.g.toInt());
        bValues.add(pixel.b.toInt());
      }
    }

    if (rValues.isEmpty) {
      return const _SamplingOutput(medianRgb: [128, 128, 128], pixelCount: 0);
    }

    rValues.sort();
    gValues.sort();
    bValues.sort();

    final int mid = rValues.length ~/ 2;
    return _SamplingOutput(
      medianRgb: [rValues[mid], gValues[mid], bValues[mid]],
      pixelCount: rValues.length,
    );
  }

  double _calculateEuclideanDistance(List<int> c1, List<int> c2) {
    final double dr = (c1[0] - c2[0]).toDouble();
    final double dg = (c1[1] - c2[1]).toDouble();
    final double db = (c1[2] - c2[2]).toDouble();
    return sqrt((dr * dr) + (dg * dg) + (db * db));
  }
}

class _SamplingOutput {
  final List<int> medianRgb;
  final int pixelCount;

  const _SamplingOutput({
    required this.medianRgb,
    required this.pixelCount,
  });
}