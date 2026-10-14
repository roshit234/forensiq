// lib/services/color_calibration_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../models/color_calibration_result.dart';
import '../models/image_region.dart';

class ReferenceColorTarget {
  final String name;
  final int row;
  final int col;
  final List<int> rgb; // [R, G, B]

  const ReferenceColorTarget({
    required this.name,
    required this.row,
    required this.col,
    required this.rgb,
  });
}

class ColorCalibrationService {
  const ColorCalibrationService();

  // The 9 standardized ForensIQ prototype reference colours in 3x3 order
  static const List<ReferenceColorTarget> standardTargets = [
    // Row 1
    ReferenceColorTarget(name: 'White', row: 0, col: 0, rgb: [255, 255, 255]),
    ReferenceColorTarget(name: 'Light Gray', row: 0, col: 1, rgb: [192, 192, 192]),
    ReferenceColorTarget(name: 'Dark Gray', row: 0, col: 2, rgb: [96, 96, 96]),
    // Row 2
    ReferenceColorTarget(name: 'Red', row: 1, col: 0, rgb: [230, 30, 30]),
    ReferenceColorTarget(name: 'Yellow', row: 1, col: 1, rgb: [255, 210, 0]),
    ReferenceColorTarget(name: 'Green', row: 1, col: 2, rgb: [0, 150, 75]),
    // Row 3
    ReferenceColorTarget(name: 'Blue', row: 2, col: 0, rgb: [20, 95, 200]),
    ReferenceColorTarget(name: 'Purple', row: 2, col: 1, rgb: [130, 50, 170]),
    ReferenceColorTarget(name: 'Black', row: 2, col: 2, rgb: [0, 0, 0]),
  ];

  Future<ColorCalibrationResult?> calibrateReferenceChart({
    required String imagePath,
    required ImageRegion referenceRegion,
  }) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        debugPrint('[ColorCalibrationService] Error: Image file missing.');
        return null;
      }

      final bytes = await file.readAsBytes();
      final img.Image? fullImage = img.decodeImage(bytes);

      if (fullImage == null) {
        debugPrint('[ColorCalibrationService] Error: Failed to decode original image.');
        return null;
      }

      final int origW = fullImage.width;
      final int origH = fullImage.height;

      // Extract reference region bounds in original image pixels
      final double refL = referenceRegion.left.clamp(0.0, origW.toDouble() - 1);
      final double refT = referenceRegion.top.clamp(0.0, origH.toDouble() - 1);
      final double refW = referenceRegion.width.clamp(10.0, origW.toDouble() - refL);
      final double refH = referenceRegion.height.clamp(10.0, origH.toDouble() - refT);

      if (refW < 30 || refH < 30) {
        debugPrint('[ColorCalibrationService] Error: Reference region too small.');
        return null;
      }

      final double cellW = refW / 3.0;
      final double cellH = refH / 3.0;

      final List<List<int>> observedList = [];
      final List<List<int>> expectedList = [];

      // 1. Sample central 65% of each of the 9 cells
      for (final target in standardTargets) {
        final double cellLeft = refL + (target.col * cellW);
        final double cellTop = refT + (target.row * cellH);

        // Sample center 65%
        const double sampleRatio = 0.65;
        final double sampleW = cellW * sampleRatio;
        final double sampleH = cellH * sampleRatio;
        final double sampleLeft = cellLeft + ((cellW - sampleW) / 2.0);
        final double sampleTop = cellTop + ((cellH - sampleH) / 2.0);

        final List<int> medianRgb = _sampleMedianRgb(
          image: fullImage,
          left: sampleLeft.toInt(),
          top: sampleTop.toInt(),
          width: sampleW.toInt(),
          height: sampleH.toInt(),
        );

        observedList.add(medianRgb);
        expectedList.add(target.rgb);
      }

      // 2. Perform per-channel OLS Linear Regression: Expected = (Observed * m) + b
      final _LinearCoeffs coeffR = _fitLinearRegression(
        observedList.map((c) => c[0].toDouble()).toList(),
        expectedList.map((c) => c[0].toDouble()).toList(),
      );

      final _LinearCoeffs coeffG = _fitLinearRegression(
        observedList.map((c) => c[1].toDouble()).toList(),
        expectedList.map((c) => c[1].toDouble()).toList(),
      );

      final _LinearCoeffs coeffB = _fitLinearRegression(
        observedList.map((c) => c[2].toDouble()).toList(),
        expectedList.map((c) => c[2].toDouble()).toList(),
      );

      // 3. Compute Calibrated RGB and Total Absolute Errors
      double totalAbsError = 0.0;
      final List<PatchColorData> patchResults = [];

      for (int i = 0; i < standardTargets.length; i++) {
        final target = standardTargets[i];
        final observed = observedList[i];
        final expected = expectedList[i];

        final int calR = ((observed[0] * coeffR.m) + coeffR.b).round().clamp(0, 255);
        final int calG = ((observed[1] * coeffG.m) + coeffG.b).round().clamp(0, 255);
        final int calB = ((observed[2] * coeffB.m) + coeffB.b).round().clamp(0, 255);

        totalAbsError += (calR - expected[0]).abs();
        totalAbsError += (calG - expected[1]).abs();
        totalAbsError += (calB - expected[2]).abs();

        patchResults.add(
          PatchColorData(
            name: target.name,
            expectedRgb: expected,
            observedRgb: observed,
            calibratedRgb: [calR, calG, calB],
          ),
        );
      }

      // Mean Absolute Error across all 9 patches and 3 channels
      final double mae = double.parse((totalAbsError / (9.0 * 3.0)).toStringAsFixed(1));

      debugPrint('[ColorCalibrationService] Calibration Complete. MAE: $mae');
      debugPrint('[ColorCalibrationService] Transforms: '
          'R: ${coeffR.m.toStringAsFixed(2)}x + ${coeffR.b.toStringAsFixed(1)} | '
          'G: ${coeffG.m.toStringAsFixed(2)}x + ${coeffG.b.toStringAsFixed(1)} | '
          'B: ${coeffB.m.toStringAsFixed(2)}x + ${coeffB.b.toStringAsFixed(1)}');

      return ColorCalibrationResult(
        patches: patchResults,
        maeError: mae,
        calibrationMethod: 'Per-Channel Linear Regression (OLS)',
        gainR: coeffR.m,
        offsetR: coeffR.b,
        gainG: coeffG.m,
        offsetG: coeffG.b,
        gainB: coeffB.m,
        offsetB: coeffB.b,
      );
    } catch (e) {
      debugPrint('[ColorCalibrationService] Exception during calibration: $e');
      return null;
    }
  }

  /// Calculates median RGB from the central window to discard noise and glare
  List<int> _sampleMedianRgb({
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

    if (rValues.isEmpty) return [128, 128, 128];

    rValues.sort();
    gValues.sort();
    bValues.sort();

    final int mid = rValues.length ~/ 2;
    return [rValues[mid], gValues[mid], bValues[mid]];
  }

  /// Ordinary Least Squares: fits y = m * x + b
  _LinearCoeffs _fitLinearRegression(List<double> x, List<double> y) {
    final int n = x.length;
    double sumX = 0;
    double sumY = 0;
    double sumXY = 0;
    double sumX2 = 0;

    for (int i = 0; i < n; i++) {
      sumX += x[i];
      sumY += y[i];
      sumXY += x[i] * y[i];
      sumX2 += x[i] * x[i];
    }

    final double denominator = (n * sumX2) - (sumX * sumX);
    if (denominator.abs() < 1e-6) {
      return const _LinearCoeffs(m: 1.0, b: 0.0);
    }

    final double m = ((n * sumXY) - (sumX * sumY)) / denominator;
    final double b = (sumY - (m * sumX)) / n;

    return _LinearCoeffs(m: m, b: b);
  }
}

class _LinearCoeffs {
  final double m;
  final double b;
  const _LinearCoeffs({required this.m, required this.b});
}