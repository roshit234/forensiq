// lib/features/camera/image_quality_screen.dart
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../models/test_session.dart';
import '../../services/image_quality_service.dart';
import 'quality_verified_screen.dart';

class ImageQualityScreen extends StatefulWidget {
  final XFile imageFile;
  final TestSession testSession;

  const ImageQualityScreen({
    super.key,
    required this.imageFile,
    required this.testSession,
  });

  @override
  State<ImageQualityScreen> createState() => _ImageQualityScreenState();
}

class _ImageQualityScreenState extends State<ImageQualityScreen> {
  final ImageQualityService _qualityService = const ImageQualityService();

  QualityCheckResult? _result;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _runQualityCheck();
  }

  Future<void> _runQualityCheck() async {
    setState(() => _isChecking = true);

    final result = await _qualityService.analyzeImage(widget.imageFile);

    if (mounted) {
      setState(() {
        _result = result;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Sample Quality Inspection',
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
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                clipBehavior: Clip.antiAlias,
                child: kIsWeb
                    ? Image.network(widget.imageFile.path, fit: BoxFit.contain)
                    : Image.file(File(widget.imageFile.path), fit: BoxFit.contain),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: _isChecking ? _buildProcessingState() : _buildResultState(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Color(0xFF0284C7), strokeWidth: 3),
          SizedBox(height: 16),
          Text(
            'Checking image quality...',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Analyzing sharpness, edge acutance, and exposure',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildResultState() {
    final result = _result!;
    final bool isAcceptable = result.isAcceptable;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'IMAGE QUALITY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
                letterSpacing: 0.8,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isAcceptable ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isAcceptable ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isAcceptable ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
                    size: 14,
                    color: isAcceptable ? const Color(0xFF059669) : const Color(0xFFDC2626),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    isAcceptable ? '✓ Acceptable' : '✕ Retake Required',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isAcceptable ? const Color(0xFF065F46) : const Color(0xFFB91C1C),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (!isAcceptable)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Text(
              result.failureReason ??
                  'The image appears too blurry for reliable analysis. Please hold the phone steady and capture the test again.',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF92400E),
                height: 1.3,
              ),
            ),
          ),
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sharpness Index: ${result.sharpnessScore}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Detail Score: ${result.detailScore}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${result.width} × ${result.height} px',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 2),
                Text(
                  'Exposure: ${result.exposureStatus}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: result.exposureStatus == 'Normal'
                        ? const Color(0xFF059669)
                        : const Color(0xFFD97706),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'RETAKE',
                  style: TextStyle(
                    color: Color(0xFF334155),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            if (isAcceptable) ...[
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    // Update session with measured sharpness score before forwarding
                    final updatedSession = widget.testSession.copyWith(
                      sharpnessScore: result.sharpnessScore,
                    );

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QualityVerifiedScreen(
                          imageFile: widget.imageFile,
                          testSession: updatedSession,
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'CONTINUE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}