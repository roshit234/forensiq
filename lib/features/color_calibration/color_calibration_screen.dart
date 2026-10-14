// lib/features/color_calibration/color_calibration_screen.dart
import '../color_analysis/color_analysis_screen.dart';
import 'package:flutter/material.dart';
import '../../models/color_calibration_result.dart';
import '../../models/test_session.dart';
import '../../services/color_calibration_service.dart';

class ColorCalibrationScreen extends StatefulWidget {
  final TestSession testSession;

  const ColorCalibrationScreen({
    super.key,
    required this.testSession,
  });

  @override
  State<ColorCalibrationScreen> createState() => _ColorCalibrationScreenState();
}

class _ColorCalibrationScreenState extends State<ColorCalibrationScreen> {
  final ColorCalibrationService _calibrationService =
      const ColorCalibrationService();

  bool _isProcessing = true;
  ColorCalibrationResult? _calibrationResult;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _runCalibration();
  }

  Future<void> _runCalibration() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    final refRegion = widget.testSession.referenceRegion;
    if (refRegion == null) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Reference Colour Card region was not specified.';
      });
      return;
    }

    final result = await _calibrationService.calibrateReferenceChart(
      imagePath: widget.testSession.capturedImagePath,
      referenceRegion: refRegion,
    );

    if (mounted) {
      setState(() {
        _calibrationResult = result;
        _isProcessing = false;
        if (result == null) {
          _errorMessage =
              'Could not sample the 3×3 colour grid reliably. Please verify that the reference rectangle surrounds the complete 9-patch chart.';
        }
      });
    }
  }

  void _handleContinue() {
    if (_calibrationResult == null) return;

    final updatedSession = widget.testSession.copyWith(
      calibrationResult: _calibrationResult,
    );

    debugPrint('[ForensIQ] Calibration confirmed. Navigating to Colour Analysis for session: ${updatedSession.testId}');

    // Navigate to the new Colour Analysis & Classification stage
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ColorAnalysisScreen(
          testSession: updatedSession,
        ),
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
          'Reference Colour Calibration',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: _isProcessing
            ? _buildLoadingState()
            : _calibrationResult != null
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
            'Analyzing reference colours...',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Sampling 3×3 patch array & computing linear transform',
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
            const Icon(Icons.warning_amber_rounded, size: 52, color: Color(0xFFEF4444)),
            const SizedBox(height: 14),
            const Text(
              'Calibration Failed',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unable to sample reference patches from the selected region.',
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
                      // Pop back to camera to retake photo
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
    final result = _calibrationResult!;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Summary Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Calibration Complete',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFA7F3D0)),
                            ),
                            child: const Text(
                              '9 Patches Analyzed',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF065F46),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Calibration Error (MAE): ${result.maeError}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Model: Per-Channel OLS Linear Regression. Offsets ambient lighting and camera sensor cast.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 9 Reference Patches Breakdown
                const Text(
                  'REFERENCE COLOUR PATCHES (3×3)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),

                ...result.patches.map((patch) => _buildPatchRow(patch)),
              ],
            ),
          ),
        ),

        // Bottom Continue Bar
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _handleContinue,
            child: const Text(
              'CONTINUE TO COLOUR ANALYSIS',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPatchRow(PatchColorData patch) {
    final expectedColor = Color.fromARGB(255, patch.expectedRgb[0], patch.expectedRgb[1], patch.expectedRgb[2]);
    final calibratedColor = Color.fromARGB(255, patch.calibratedRgb[0], patch.calibratedRgb[1], patch.calibratedRgb[2]);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          // Visual Color Comparison Swatches
          Column(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: expectedColor,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
              ),
              const SizedBox(height: 2),
              const Text('Target', style: TextStyle(fontSize: 9, color: Color(0xFF64748B))),
            ],
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: calibratedColor,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
              ),
              const SizedBox(height: 2),
              const Text('Calibrated', style: TextStyle(fontSize: 9, color: Color(0xFF64748B))),
            ],
          ),
          const SizedBox(width: 14),

          // Numerical Values
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patch.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Expected:   ${patch.expectedRgb[0]}, ${patch.expectedRgb[1]}, ${patch.expectedRgb[2]}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                ),
                Text(
                  'Observed:  ${patch.observedRgb[0]}, ${patch.observedRgb[1]}, ${patch.observedRgb[2]}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                Text(
                  'Calibrated: ${patch.calibratedRgb[0]}, ${patch.calibratedRgb[1]}, ${patch.calibratedRgb[2]}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0284C7)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}