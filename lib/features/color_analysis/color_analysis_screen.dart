// lib/features/color_analysis/color_analysis_screen.dart
import '../evidence/evidence_record_screen.dart';
import '../../services/evidence_storage_service.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../../models/color_analysis_result.dart';
import '../../models/test_session.dart';
import '../../services/color_analysis_service.dart';
import '../../services/image_coordinate_mapper.dart';

class ColorAnalysisScreen extends StatefulWidget {
  final TestSession testSession;

  const ColorAnalysisScreen({
    super.key,
    required this.testSession,
  });

  @override
  State<ColorAnalysisScreen> createState() => _ColorAnalysisScreenState();
}

class _ColorAnalysisScreenState extends State<ColorAnalysisScreen> {
  final ColorAnalysisService _analysisService = const ColorAnalysisService();

  bool _isAnalyzing = true;
  ColorAnalysisResult? _analysisResult;
  String? _errorMessage;

  double? _origWidth;
  double? _origHeight;

  @override
  void initState() {
    super.initState();
    _loadImageAndAnalyze();
  }

  Future<void> _loadImageAndAnalyze() async {
    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });

    final rxnRegion = widget.testSession.reactionRegion;
    final calResult = widget.testSession.calibrationResult;

    if (rxnRegion == null) {
      setState(() {
        _isAnalyzing = false;
        _errorMessage = 'Reaction Region was not selected.';
      });
      return;
    }

    if (calResult == null) {
      setState(() {
        _isAnalyzing = false;
        _errorMessage = 'Calibration data missing. Please recalibrate reference chart.';
      });
      return;
    }

    try {
      final bytes = await File(widget.testSession.capturedImagePath).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded != null) {
        _origWidth = decoded.width.toDouble();
        _origHeight = decoded.height.toDouble();
      }
    } catch (_) {}

    final result = await _analysisService.analyzeReactionRegion(
      imagePath: widget.testSession.capturedImagePath,
      reactionRegion: rxnRegion,
      calibrationResult: calResult,
    );

    if (mounted) {
      setState(() {
        _analysisResult = result;
        _isAnalyzing = false;
        if (result == null) {
          _errorMessage =
              'Could not sample reaction region pixels. Please verify the region selection.';
        }
      });
    }
  }

  bool _isSaving = false;

  Future<void> _handleSaveEvidence() async {
    if (_analysisResult == null || _isSaving) return;

    setState(() => _isSaving = true);

    final updatedSession = widget.testSession.copyWith(
      analysisResult: _analysisResult,
    );

    const storageService = EvidenceStorageService();

    // Verify file accessibility and calculate real SHA-256
    final record = await storageService.createAndSaveRecord(updatedSession);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (record == null) {
      // Error handling if original captured image file is inaccessible
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Unable to create evidence record'),
          content: const Text(
            'The original captured image could not be accessed to calculate its SHA-256 hash.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Back'),
            ),
          ],
        ),
      );
      return;
    }

    // Open Digital Evidence Record Screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EvidenceRecordScreen(record: record),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          'Colour Analysis Result',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: _isAnalyzing
            ? _buildLoadingState()
            : _analysisResult != null
                ? _buildSuccessView()
                : _buildFailureView(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Color(0xFF0284C7), strokeWidth: 3),
          SizedBox(height: 18),
          Text(
            'Analyzing reaction colour...',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Sampling median RGB & applying calibration transform',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildFailureView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 52, color: Color(0xFFEF4444)),
            const SizedBox(height: 14),
            const Text(
              'Colour Analysis Failed',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unable to sample reaction region pixels.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    child: const Text('Retake', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Adjust Regions', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    final result = _analysisResult!;
    final bool isPositive = result.isPositive;
    final bool isInconclusive = result.isInconclusive;

    Color badgeBg;
    Color badgeBorder;
    Color badgeTextColor;
    String headline;
    String subline;
    IconData badgeIcon;

    if (isPositive) {
      badgeBg = const Color(0xFFFEF2F2);
      badgeBorder = const Color(0xFFFECACA);
      badgeTextColor = const Color(0xFFB91C1C);
      headline = 'Presumptive Positive';
      subline = 'Prototype colour match: Red';
      badgeIcon = Icons.warning_amber_rounded;
    } else if (isInconclusive) {
      badgeBg = const Color(0xFFFFFBEB);
      badgeBorder = const Color(0xFFFDE68A);
      badgeTextColor = const Color(0xFFB45309);
      headline = 'Inconclusive';
      subline = 'The reaction colour did not match a supported reference colour reliably.';
      badgeIcon = Icons.help_outline_rounded;
    } else {
      badgeBg = const Color(0xFFF0FDF4);
      badgeBorder = const Color(0xFFBBF7D0);
      badgeTextColor = const Color(0xFF15803D);
      headline = 'Presumptive Negative';
      subline = 'Prototype colour match: ${result.closestReferenceColor}';
      badgeIcon = Icons.check_circle_outline_rounded;
    }

    final observedColor = Color.fromARGB(
      255,
      result.observedReactionRgb[0],
      result.observedReactionRgb[1],
      result.observedReactionRgb[2],
    );

    final calibratedColor = Color.fromARGB(
      255,
      result.calibratedReactionRgb[0],
      result.calibratedReactionRgb[1],
      result.calibratedReactionRgb[2],
    );

    final imageFile = File(widget.testSession.capturedImagePath);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Configuration Banner
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.testSession.selectedKit,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Prototype Field Test Result',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Main Classification Hero Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: badgeBorder, width: 1.5),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(badgeIcon, color: badgeTextColor, size: 28),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              headline,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: badgeTextColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subline,
                              style: TextStyle(
                                fontSize: 13,
                                color: badgeTextColor.withValues(alpha: 0.9),
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Key Measured Colour Summary Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      _buildSummaryRow(
                        label: 'Detected Colour',
                        value: result.closestReferenceColor,
                        trailingSwatch: calibratedColor,
                        isBold: true,
                      ),
                      const Divider(height: 20),
                      _buildSummaryRow(
                        label: 'Calibrated Reaction RGB',
                        value:
                            '${result.calibratedReactionRgb[0]}, ${result.calibratedReactionRgb[1]}, ${result.calibratedReactionRgb[2]}',
                      ),
                      const Divider(height: 20),
                      _buildSummaryRow(
                        label: 'Closest Reference',
                        value: result.closestReferenceColor,
                      ),
                      const Divider(height: 20),
                      _buildSummaryRow(
                        label: 'Colour Distance',
                        value: '${result.colorDistance}',
                        subtext: 'Threshold: ≤ 85.0',
                      ),
                      const Divider(height: 20),
                      _buildSummaryRow(
                        label: 'Calibration Applied',
                        value: 'Yes (OLS Matrix)',
                        valueColor: const Color(0xFF0284C7),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Photo Preview with Reaction Box Highlight
                Container(
                  height: 190,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final mapper = ImageCoordinateMapper(
                        imageWidth: _origWidth ?? 640.0,
                        imageHeight: _origHeight ?? 480.0,
                        containerWidth: constraints.maxWidth,
                        containerHeight: constraints.maxHeight,
                      );

                      final rxnDisplay = widget.testSession.reactionRegion != null
                          ? mapper.originalImageToDisplay(
                              Rect.fromLTWH(
                                widget.testSession.reactionRegion!.left,
                                widget.testSession.reactionRegion!.top,
                                widget.testSession.reactionRegion!.width,
                                widget.testSession.reactionRegion!.height,
                              ),
                            )
                          : null;

                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          Center(
                            child: kIsWeb
                                ? Image.network(widget.testSession.capturedImagePath, fit: BoxFit.contain)
                                : Image.file(imageFile, fit: BoxFit.contain),
                          ),
                          if (rxnDisplay != null)
                            Positioned.fromRect(
                              rect: rxnDisplay,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEA580C).withValues(alpha: 0.20),
                                  border: Border.all(color: const Color(0xFFEA580C), width: 2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Align(
                                  alignment: Alignment.topLeft,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    color: const Color(0xFFEA580C),
                                    child: const Text(
                                      'Reaction Sample Area',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),

                // Collapsible Analysis Details
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      initiallyExpanded: false,
                      title: const Text(
                        'Technical Analysis Details',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildDetailRow('Reference calibration', 'Completed (9 patches)'),
                              const SizedBox(height: 6),
                              _buildDetailRow('Reaction sample', '${result.sampledPixelCount} pixels (median filter)'),
                              const SizedBox(height: 6),
                              _buildDetailRow(
                                'Observed Reaction RGB',
                                '${result.observedReactionRgb[0]}, ${result.observedReactionRgb[1]}, ${result.observedReactionRgb[2]}',
                                swatchColor: observedColor,
                              ),
                              const SizedBox(height: 6),
                              _buildDetailRow(
                                'Calibrated Reaction RGB',
                                '${result.calibratedReactionRgb[0]}, ${result.calibratedReactionRgb[1]}, ${result.calibratedReactionRgb[2]}',
                                swatchColor: calibratedColor,
                              ),
                              const SizedBox(height: 6),
                              _buildDetailRow('Closest Reference', result.closestReferenceColor),
                              const SizedBox(height: 6),
                              _buildDetailRow('Colour Distance', '${result.colorDistance} (Euclidean)'),
                              const SizedBox(height: 6),
                              _buildDetailRow('Classification Rule', result.classification),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Disclaimer
                const Text(
                  '* Presumptive field test only. This is a prototype colourimetric demonstration and does not replace confirmatory forensic laboratory analysis.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ),

        // Bottom Action Bar
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                      child: const Text('Retake', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Recalibrate', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSaving ? null : _handleSaveEvidence,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'SAVE EVIDENCE RECORD',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow({
    required String label,
    required String value,
    Color? trailingSwatch,
    Color? valueColor,
    String? subtext,
    bool isBold = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              if (subtext != null)
                Text(
                  subtext,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                ),
            ],
          ),
        ),
        if (trailingSwatch != null) ...[
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: trailingSwatch,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? swatchColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
        Row(
          children: [
            if (swatchColor != null) ...[
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: swatchColor,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              value,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
            ),
          ],
        ),
      ],
    );
  }
}