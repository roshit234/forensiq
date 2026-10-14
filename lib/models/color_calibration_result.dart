// lib/models/color_calibration_result.dart

class PatchColorData {
  final String name;
  final List<int> expectedRgb; // [R, G, B]
  final List<int> observedRgb; // [R, G, B]
  final List<int> calibratedRgb; // [R, G, B]

  const PatchColorData({
    required this.name,
    required this.expectedRgb,
    required this.observedRgb,
    required this.calibratedRgb,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'expected': expectedRgb,
        'observed': observedRgb,
        'calibrated': calibratedRgb,
      };
}

class ColorCalibrationResult {
  final List<PatchColorData> patches;
  final double maeError;
  final String calibrationMethod;

  // Linear transformation parameters per channel: Calibrated = (Observed * gain) + offset
  final double gainR;
  final double offsetR;
  final double gainG;
  final double offsetG;
  final double gainB;
  final double offsetB;

  const ColorCalibrationResult({
    required this.patches,
    required this.maeError,
    required this.calibrationMethod,
    required this.gainR,
    required this.offsetR,
    required this.gainG,
    required this.offsetG,
    required this.gainB,
    required this.offsetB,
  });

  /// Calibrates an arbitrary [r, g, b] triplet using the calculated matrix
  List<int> applyCalibration(int r, int g, int b) {
    final int calR = ((r * gainR) + offsetR).round().clamp(0, 255);
    final int calG = ((g * gainG) + offsetG).round().clamp(0, 255);
    final int calB = ((b * gainB) + offsetB).round().clamp(0, 255);
    return [calR, calG, calB];
  }
}