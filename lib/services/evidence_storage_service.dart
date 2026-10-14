// lib/services/evidence_storage_service.dart
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/evidence_record.dart';
import '../models/test_session.dart';

class EvidenceStorageService {
  static const String _storageKey = 'forensiq_saved_evidence_records';

  const EvidenceStorageService();

  /// Calculates SHA-256 on the ACTUAL ORIGINAL camera file bytes
  Future<String?> calculateOriginalImageSha256(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('[EvidenceStorageService] Error: Image file does not exist.');
        return null;
      }

      final Uint8List rawBytes = await file.readAsBytes();
      final Digest digest = sha256.convert(rawBytes);
      return digest.toString();
    } catch (e) {
      debugPrint('[EvidenceStorageService] SHA-256 calculation failed: $e');
      return null;
    }
  }

  /// Builds a sealed EvidenceRecord from active session data and saves it locally
  Future<EvidenceRecord?> createAndSaveRecord(TestSession session) async {
    try {
      final file = File(session.capturedImagePath);
      if (!await file.exists()) return null;

      final int bytesCount = await file.length();
      final String sha256Hash = (await calculateOriginalImageSha256(session.capturedImagePath)) ?? '';

      if (sha256Hash.isEmpty) return null;

      // Read real pixel dimensions from file
      final Uint8List rawBytes = await file.readAsBytes();
      final decoded = img.decodeImage(rawBytes);
      final int width = decoded?.width ?? 0;
      final int height = decoded?.height ?? 0;

      // Unique Evidence ID: FIQ-EV-YYYYMMDD-XXXX
      final now = DateTime.now();
      final dateStr =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      final randomSuffix = (Random().nextInt(9000) + 1000).toString();
      final evidenceId = 'FIQ-EV-$dateStr-$randomSuffix';

      final record = EvidenceRecord(
        evidenceId: evidenceId,
        testId: session.testId,
        testKit: session.selectedKit,
        timestamp: session.capturedAt,
        location: session.locationDisplay,
        operator: session.operatorId,
        imagePath: session.capturedImagePath,
        imageSha256: sha256Hash,
        imageFileSize: _formatFileSize(bytesCount),
        imageWidth: width,
        imageHeight: height,
        referenceRegion: session.referenceRegion,
        reactionRegion: session.reactionRegion,
        calibrationStatus: session.calibrationResult != null ? 'Completed' : 'Unavailable',
        calibrationError: session.calibrationResult?.maeError ?? 0.0,
        observedReactionRgb: session.analysisResult?.observedReactionRgb ?? [0, 0, 0],
        calibratedReactionRgb: session.analysisResult?.calibratedReactionRgb ?? [0, 0, 0],
        closestReferenceColor: session.analysisResult?.closestReferenceColor ?? 'Unknown',
        colorDistance: session.analysisResult?.colorDistance ?? 0.0,
        classification: session.analysisResult?.classification ?? 'Inconclusive',
      );

      // Persist to local storage
      await saveRecord(record);
      return record;
    } catch (e) {
      debugPrint('[EvidenceStorageService] Failed to create evidence record: $e');
      return null;
    }
  }

  Future<void> saveRecord(EvidenceRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> recordsJson = prefs.getStringList(_storageKey) ?? [];

    // Duplicate protection: do not add duplicate records for the same testId
    recordsJson.removeWhere((item) {
      try {
        final existing = EvidenceRecord.fromJson(item);
        return existing.testId == record.testId;
      } catch (_) {
        return false;
      }
    });

    recordsJson.insert(0, record.toJson());
    await prefs.setStringList(_storageKey, recordsJson);
    debugPrint('[EvidenceStorageService] Evidence saved locally. Total records: ${recordsJson.length}');
  }

  Future<List<EvidenceRecord>> getAllRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> recordsJson = prefs.getStringList(_storageKey) ?? [];

      return recordsJson.map((item) => EvidenceRecord.fromJson(item)).toList();
    } catch (e) {
      debugPrint('[EvidenceStorageService] Failed to load records: $e');
      return [];
    }
  }

  Future<EvidenceRecord?> getRecordByTestId(String testId) async {
    final records = await getAllRecords();
    return records.cast<EvidenceRecord?>().firstWhere(
          (r) => r?.testId == testId,
          orElse: () => null,
        );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}