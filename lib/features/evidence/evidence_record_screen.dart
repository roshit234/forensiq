// lib/features/evidence/evidence_record_screen.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/evidence_record.dart';

class EvidenceRecordScreen extends StatelessWidget {
  final EvidenceRecord record;

  const EvidenceRecordScreen({
    super.key,
    required this.record,
  });

  void _copyHash(BuildContext context) {
    Clipboard.setData(ClipboardData(text: record.imageSha256));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('SHA-256 hash copied to clipboard.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isPositive = record.classification == 'Positive';
    final bool isInconclusive = record.classification == 'Inconclusive';

    Color badgeBg;
    Color badgeBorder;
    Color badgeText;
    String resultTitle;

    if (isPositive) {
      badgeBg = const Color(0xFFFEF2F2);
      badgeBorder = const Color(0xFFFECACA);
      badgeText = const Color(0xFFB91C1C);
      resultTitle = 'Presumptive Positive';
    } else if (isInconclusive) {
      badgeBg = const Color(0xFFFFFBEB);
      badgeBorder = const Color(0xFFFDE68A);
      badgeText = const Color(0xFFB45309);
      resultTitle = 'Inconclusive';
    } else {
      badgeBg = const Color(0xFFF0FDF4);
      badgeBorder = const Color(0xFFBBF7D0);
      badgeText = const Color(0xFF15803D);
      resultTitle = 'Presumptive Negative';
    }

    final observedColor = Color.fromARGB(
      255,
      record.observedReactionRgb[0],
      record.observedReactionRgb[1],
      record.observedReactionRgb[2],
    );

    final calibratedColor = Color.fromARGB(
      255,
      record.calibratedReactionRgb[0],
      record.calibratedReactionRgb[1],
      record.calibratedReactionRgb[2],
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Digital Evidence Record',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Result Header Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: badgeBorder, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isPositive
                                ? Icons.warning_amber_rounded
                                : isInconclusive
                                    ? Icons.help_outline_rounded
                                    : Icons.check_circle_outline_rounded,
                            color: badgeText,
                            size: 26,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  resultTitle,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: badgeText,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Matched: ${record.closestReferenceColor} (Dist: ${record.colorDistance})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: badgeText.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // SECTION 1: TEST INFORMATION
                    _buildSectionHeader('TEST INFORMATION'),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          _buildRow('Evidence ID', record.evidenceId, isBold: true),
                          const Divider(height: 18),
                          _buildRow('Test ID', record.testId),
                          const Divider(height: 18),
                          _buildRow('Test Kit', record.testKit),
                          const Divider(height: 18),
                          _buildRow('Date & Time', record.formattedDateTime),
                          const Divider(height: 18),
                          _buildRow('Location', record.location),
                          const Divider(height: 18),
                          _buildRow('Operator', 'Officer ${record.operator}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // SECTION 2: IMAGE INFORMATION & SHA-256 HASH
                    _buildSectionHeader('IMAGE INFORMATION'),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Photo Preview
                          Container(
                            height: 160,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: kIsWeb
                                ? Image.network(record.imagePath, fit: BoxFit.contain)
                                : Image.file(File(record.imagePath), fit: BoxFit.contain),
                          ),
                          const SizedBox(height: 12),
                          _buildRow('Image Resolution', '${record.imageWidth} × ${record.imageHeight} px'),
                          const Divider(height: 18),
                          _buildRow('File Size', record.imageFileSize),
                          const Divider(height: 18),

                          // Cryptographic Hash Box
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'SHA-256 Image Hash',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => _copyHash(context),
                                icon: const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF0284C7)),
                                label: const Text(
                                  'Copy Hash',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF0284C7)),
                                ),
                                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: SelectableText(
                              record.imageSha256,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                color: Color(0xFF334155),
                                height: 1.3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Image Integrity Box
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.security_rounded, size: 16, color: Color(0xFF1D4ED8)),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Image Integrity',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E3A8A),
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'SHA-256 hash generated from the original captured image. Binds unedited sensor data to this test session.',
                                        style: TextStyle(fontSize: 10, color: Color(0xFF1E40AF)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // SECTION 3: ANALYSIS
                    _buildSectionHeader('ANALYSIS & CALIBRATION'),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          _buildRow('Reference Calibration', record.calibrationStatus),
                          const Divider(height: 18),
                          _buildRow('Calibration Error (MAE)', '${record.calibrationError}'),
                          const Divider(height: 18),
                          _buildRow(
                            'Observed Reaction RGB',
                            '${record.observedReactionRgb[0]}, ${record.observedReactionRgb[1]}, ${record.observedReactionRgb[2]}',
                            swatch: observedColor,
                          ),
                          const Divider(height: 18),
                          _buildRow(
                            'Calibrated Reaction RGB',
                            '${record.calibratedReactionRgb[0]}, ${record.calibratedReactionRgb[1]}, ${record.calibratedReactionRgb[2]}',
                            swatch: calibratedColor,
                          ),
                          const Divider(height: 18),
                          _buildRow('Closest Reference Colour', record.closestReferenceColor),
                          const Divider(height: 18),
                          _buildRow('Colour Distance', '${record.colorDistance}'),
                          const Divider(height: 18),
                          _buildRow('Prototype Result', resultTitle, isBold: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    const Text(
                      '* Presumptive field test result only. This digital record and SHA-256 digest establish preliminary evidentiary integrity and require laboratory confirmation.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Actions
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _copyHash(context),
                      child: const Text(
                        'Copy Hash',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        // Return cleanly to the main dashboard
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                      child: const Text(
                        'Return to Dashboard',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, left: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF64748B),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false, Color? swatch}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        Row(
          children: [
            if (swatch != null) ...[
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: swatch,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ],
    );
  }
}