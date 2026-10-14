// lib/models/evidence_record.dart
import 'dart:convert';
import 'image_region.dart';

class EvidenceRecord {
  final String evidenceId;
  final String testId;
  final String testKit;
  final DateTime timestamp;
  final String location;
  final String operator;
  final String imagePath;
  final String imageSha256;
  final String imageFileSize;
  final int imageWidth;
  final int imageHeight;
  final ImageRegion? referenceRegion;
  final ImageRegion? reactionRegion;
  final String calibrationStatus;
  final double calibrationError;
  final List<int> observedReactionRgb;
  final List<int> calibratedReactionRgb;
  final String closestReferenceColor;
  final double colorDistance;
  final String classification;

  const EvidenceRecord({
    required this.evidenceId,
    required this.testId,
    required this.testKit,
    required this.timestamp,
    required this.location,
    required this.operator,
    required this.imagePath,
    required this.imageSha256,
    required this.imageFileSize,
    required this.imageWidth,
    required this.imageHeight,
    this.referenceRegion,
    this.reactionRegion,
    required this.calibrationStatus,
    required this.calibrationError,
    required this.observedReactionRgb,
    required this.calibratedReactionRgb,
    required this.closestReferenceColor,
    required this.colorDistance,
    required this.classification,
  });

  String get formattedDateTime {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final day = timestamp.day;
    final month = months[timestamp.month - 1];
    final year = timestamp.year;
    final hour24 = timestamp.hour;
    final hour12 = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24);
    final period = hour24 >= 12 ? 'PM' : 'AM';
    final minute = timestamp.minute.toString().padLeft(2, '0');

    return '$day $month $year, $hour12:$minute $period';
  }

  Map<String, dynamic> toMap() => {
        'evidenceId': evidenceId,
        'testId': testId,
        'testKit': testKit,
        'timestamp': timestamp.toIso8601String(),
        'location': location,
        'operator': operator,
        'imagePath': imagePath,
        'imageSha256': imageSha256,
        'imageFileSize': imageFileSize,
        'imageWidth': imageWidth,
        'imageHeight': imageHeight,
        'referenceRegion': referenceRegion?.toJson(),
        'reactionRegion': reactionRegion?.toJson(),
        'calibrationStatus': calibrationStatus,
        'calibrationError': calibrationError,
        'observedReactionRgb': observedReactionRgb,
        'calibratedReactionRgb': calibratedReactionRgb,
        'closestReferenceColor': closestReferenceColor,
        'colorDistance': colorDistance,
        'classification': classification,
      };

  factory EvidenceRecord.fromMap(Map<String, dynamic> map) {
    return EvidenceRecord(
      evidenceId: map['evidenceId'] as String,
      testId: map['testId'] as String,
      testKit: map['testKit'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      location: map['location'] as String,
      operator: map['operator'] as String,
      imagePath: map['imagePath'] as String,
      imageSha256: map['imageSha256'] as String,
      imageFileSize: map['imageFileSize'] as String,
      imageWidth: (map['imageWidth'] as num).toInt(),
      imageHeight: (map['imageHeight'] as num).toInt(),
      referenceRegion: map['referenceRegion'] != null
          ? ImageRegion(
              left: (map['referenceRegion']['left'] as num).toDouble(),
              top: (map['referenceRegion']['top'] as num).toDouble(),
              width: (map['referenceRegion']['width'] as num).toDouble(),
              height: (map['referenceRegion']['height'] as num).toDouble(),
              label: map['referenceRegion']['label'] as String,
            )
          : null,
      reactionRegion: map['reactionRegion'] != null
          ? ImageRegion(
              left: (map['reactionRegion']['left'] as num).toDouble(),
              top: (map['reactionRegion']['top'] as num).toDouble(),
              width: (map['reactionRegion']['width'] as num).toDouble(),
              height: (map['reactionRegion']['height'] as num).toDouble(),
              label: map['reactionRegion']['label'] as String,
            )
          : null,
      calibrationStatus: map['calibrationStatus'] as String,
      calibrationError: (map['calibrationError'] as num).toDouble(),
      observedReactionRgb: List<int>.from(map['observedReactionRgb'] as List),
      calibratedReactionRgb: List<int>.from(map['calibratedReactionRgb'] as List),
      closestReferenceColor: map['closestReferenceColor'] as String,
      colorDistance: (map['colorDistance'] as num).toDouble(),
      classification: map['classification'] as String,
    );
  }

  String toJson() => jsonEncode(toMap());
  factory EvidenceRecord.fromJson(String source) =>
      EvidenceRecord.fromMap(jsonDecode(source) as Map<String, dynamic>);
}