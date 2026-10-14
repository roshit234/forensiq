// lib/models/test_session.dart
import 'color_analysis_result.dart';
import 'color_calibration_result.dart';
import 'image_region.dart';

class TestSession {
  final String testId;
  final String selectedKit;
  final DateTime capturedAt;
  final String operatorId;
  final double? latitude;
  final double? longitude;
  final String? city;
  final String? state;
  final String capturedImagePath;
  final double? sharpnessScore;

  final ImageRegion? referenceRegion;
  final ImageRegion? reactionRegion;
  final ColorCalibrationResult? calibrationResult;

  // Analysis Result
  final ColorAnalysisResult? analysisResult;

  const TestSession({
    required this.testId,
    required this.selectedKit,
    required this.capturedAt,
    required this.operatorId,
    this.latitude,
    this.longitude,
    this.city,
    this.state,
    required this.capturedImagePath,
    this.sharpnessScore,
    this.referenceRegion,
    this.reactionRegion,
    this.calibrationResult,
    this.analysisResult,
  });

  String get formattedDateTime {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final day = capturedAt.day;
    final month = months[capturedAt.month - 1];
    final year = capturedAt.year;
    final hour24 = capturedAt.hour;
    final hour12 = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24);
    final period = hour24 >= 12 ? 'PM' : 'AM';
    final minute = capturedAt.minute.toString().padLeft(2, '0');

    return '$day $month $year, $hour12:$minute $period';
  }

  String get locationDisplay {
    if (city != null && state != null && city!.isNotEmpty && state!.isNotEmpty) {
      return '$city, $state';
    } else if (latitude != null && longitude != null) {
      return '${latitude!.toStringAsFixed(4)}°, ${longitude!.toStringAsFixed(4)}°';
    }
    return 'Location unavailable';
  }

  TestSession copyWith({
    String? testId,
    String? selectedKit,
    DateTime? capturedAt,
    String? operatorId,
    double? latitude,
    double? longitude,
    String? city,
    String? state,
    String? capturedImagePath,
    double? sharpnessScore,
    ImageRegion? referenceRegion,
    ImageRegion? reactionRegion,
    ColorCalibrationResult? calibrationResult,
    ColorAnalysisResult? analysisResult,
  }) {
    return TestSession(
      testId: testId ?? this.testId,
      selectedKit: selectedKit ?? this.selectedKit,
      capturedAt: capturedAt ?? this.capturedAt,
      operatorId: operatorId ?? this.operatorId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      city: city ?? this.city,
      state: state ?? this.state,
      capturedImagePath: capturedImagePath ?? this.capturedImagePath,
      sharpnessScore: sharpnessScore ?? this.sharpnessScore,
      referenceRegion: referenceRegion ?? this.referenceRegion,
      reactionRegion: reactionRegion ?? this.reactionRegion,
      calibrationResult: calibrationResult ?? this.calibrationResult,
      analysisResult: analysisResult ?? this.analysisResult,
    );
  }
}