// lib/models/color_analysis_result.dart

class ColorAnalysisResult {
  final List<int> observedReactionRgb;   // [R, G, B]
  final List<int> calibratedReactionRgb; // [R, G, B]
  final String closestReferenceColor;
  final double colorDistance;
  final String classification;           // "Positive", "Negative", "Inconclusive"
  final bool calibrationApplied;
  final int sampledPixelCount;

  const ColorAnalysisResult({
    required this.observedReactionRgb,
    required this.calibratedReactionRgb,
    required this.closestReferenceColor,
    required this.colorDistance,
    required this.classification,
    required this.calibrationApplied,
    required this.sampledPixelCount,
  });

  bool get isPositive => classification == 'Positive';
  bool get isNegative => classification == 'Negative';
  bool get isInconclusive => classification == 'Inconclusive';

  Map<String, dynamic> toJson() => {
        'observedReactionRgb': observedReactionRgb,
        'calibratedReactionRgb': calibratedReactionRgb,
        'closestReferenceColor': closestReferenceColor,
        'colorDistance': colorDistance,
        'classification': classification,
        'calibrationApplied': calibrationApplied,
        'sampledPixelCount': sampledPixelCount,
      };
}