// lib/features/manual_region_selection/manual_region_selection_screen.dart
import '../color_calibration/color_calibration_screen.dart';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../../models/image_region.dart';
import '../../models/test_session.dart';
import '../../services/image_coordinate_mapper.dart';

class ManualRegionSelectionScreen extends StatefulWidget {
  final TestSession testSession;

  const ManualRegionSelectionScreen({
    super.key,
    required this.testSession,
  });

  @override
  State<ManualRegionSelectionScreen> createState() =>
      _ManualRegionSelectionScreenState();
}

enum SelectionStage { reference, reaction, review }

enum DragMode {
  none,
  create,
  move,
  resizeTopLeft,
  resizeTopRight,
  resizeBottomLeft,
  resizeBottomRight,
}

class _ManualRegionSelectionScreenState
    extends State<ManualRegionSelectionScreen> {
  SelectionStage _currentStage = SelectionStage.reference;

  // Single source of truth: stored in ORIGINAL camera image coordinates
  Rect? _originalRefRect;
  Rect? _originalRxnRect;

  // Temporary screen rect used ONLY while user's finger is actively on the glass
  Rect? _activeDragDisplayRect;

  double? _origWidth;
  double? _origHeight;
  bool _isLoadingImage = true;

  DragMode _dragMode = DragMode.none;
  Offset? _dragStart;
  Rect? _initialDisplayRect;

  @override
  void initState() {
    super.initState();
    _loadImageDimensions();
  }

  Future<void> _loadImageDimensions() async {
    try {
      final bytes = await File(widget.testSession.capturedImagePath).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded != null && mounted) {
        setState(() {
          _origWidth = decoded.width.toDouble();
          _origHeight = decoded.height.toDouble();
          _isLoadingImage = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingImage = false);
    }
  }

  void _onPanStart(DragStartDetails details, ImageCoordinateMapper mapper) {
    if (_currentStage == SelectionStage.review) return;

    final touchPoint = mapper.clampToRenderedBounds(details.localPosition);
    final currentOrigRect = _currentStage == SelectionStage.reference
        ? _originalRefRect
        : _originalRxnRect;

    final currentDisplayRect = currentOrigRect != null
        ? mapper.originalImageToDisplay(currentOrigRect)
        : null;

    const handleRadius = 26.0;

    if (currentDisplayRect != null) {
      if ((touchPoint - currentDisplayRect.topLeft).distance <= handleRadius) {
        _dragMode = DragMode.resizeTopLeft;
      } else if ((touchPoint - currentDisplayRect.topRight).distance <= handleRadius) {
        _dragMode = DragMode.resizeTopRight;
      } else if ((touchPoint - currentDisplayRect.bottomLeft).distance <= handleRadius) {
        _dragMode = DragMode.resizeBottomLeft;
      } else if ((touchPoint - currentDisplayRect.bottomRight).distance <= handleRadius) {
        _dragMode = DragMode.resizeBottomRight;
      } else if (currentDisplayRect.contains(touchPoint)) {
        _dragMode = DragMode.move;
      } else {
        _dragMode = DragMode.create;
        _activeDragDisplayRect = Rect.fromPoints(touchPoint, touchPoint);
      }
      _initialDisplayRect = currentDisplayRect;
    } else {
      _dragMode = DragMode.create;
      _activeDragDisplayRect = Rect.fromPoints(touchPoint, touchPoint);
      _initialDisplayRect = _activeDragDisplayRect;
    }

    _dragStart = touchPoint;
    setState(() {});
  }

  void _onPanUpdate(DragUpdateDetails details, ImageCoordinateMapper mapper) {
    if (_currentStage == SelectionStage.review || _dragStart == null) return;

    final currentTouch = mapper.clampToRenderedBounds(details.localPosition);
    final initial = _initialDisplayRect;

    if (_dragMode == DragMode.create) {
      _activeDragDisplayRect = Rect.fromPoints(_dragStart!, currentTouch);
    } else if (_dragMode == DragMode.move && initial != null) {
      final delta = currentTouch - _dragStart!;
      final newLeft = (initial.left + delta.dx).clamp(
        mapper.renderedImageRect.left,
        mapper.renderedImageRect.right - initial.width,
      );
      final newTop = (initial.top + delta.dy).clamp(
        mapper.renderedImageRect.top,
        mapper.renderedImageRect.bottom - initial.height,
      );
      _activeDragDisplayRect = Rect.fromLTWH(newLeft, newTop, initial.width, initial.height);
    } else if (initial != null) {
      double l = initial.left;
      double t = initial.top;
      double r = initial.right;
      double b = initial.bottom;

      switch (_dragMode) {
        case DragMode.resizeTopLeft:
          l = min(currentTouch.dx, r - 20);
          t = min(currentTouch.dy, b - 20);
          break;
        case DragMode.resizeTopRight:
          r = max(currentTouch.dx, l + 20);
          t = min(currentTouch.dy, b - 20);
          break;
        case DragMode.resizeBottomLeft:
          l = min(currentTouch.dx, r - 20);
          b = max(currentTouch.dy, t + 20);
          break;
        case DragMode.resizeBottomRight:
          r = max(currentTouch.dx, l + 20);
          b = max(currentTouch.dy, t + 20);
          break;
        default:
          break;
      }
      _activeDragDisplayRect = Rect.fromLTRB(l, t, r, b);
    }

    setState(() {});
  }

  void _onPanEnd(DragEndDetails details, ImageCoordinateMapper mapper) {
    if (_activeDragDisplayRect != null) {
      // Normalize rect in case user dragged from bottom-right to top-left
      final normalized = Rect.fromLTRB(
        min(_activeDragDisplayRect!.left, _activeDragDisplayRect!.right),
        min(_activeDragDisplayRect!.top, _activeDragDisplayRect!.bottom),
        max(_activeDragDisplayRect!.left, _activeDragDisplayRect!.right),
        max(_activeDragDisplayRect!.top, _activeDragDisplayRect!.bottom),
      );

      if (normalized.width >= 20 && normalized.height >= 20) {
        // Convert and store in original image coordinates
        final origRect = mapper.displayToOriginalImage(normalized);
        if (_currentStage == SelectionStage.reference) {
          _originalRefRect = origRect;
        } else if (_currentStage == SelectionStage.reaction) {
          _originalRxnRect = origRect;
        }
      }
    }

    _activeDragDisplayRect = null;
    _dragMode = DragMode.none;
    _dragStart = null;
    _initialDisplayRect = null;
    setState(() {});
  }

  void _handleContinue() {
    if (_originalRefRect == null || _originalRxnRect == null) return;

    final refRegion = ImageRegion(
      label: 'Reference Colour Card',
      left: _originalRefRect!.left,
      top: _originalRefRect!.top,
      width: _originalRefRect!.width,
      height: _originalRefRect!.height,
      confidence: 1.0,
    );

    final rxnRegion = ImageRegion(
      label: 'Test / Reaction Region',
      left: _originalRxnRect!.left,
      top: _originalRxnRect!.top,
      width: _originalRxnRect!.width,
      height: _originalRxnRect!.height,
      confidence: 1.0,
    );

    final updatedSession = widget.testSession.copyWith(
      referenceRegion: refRegion,
      reactionRegion: rxnRegion,
    );

    // Route into the Reference Colour Calibration stage
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ColorCalibrationScreen(
          testSession: updatedSession,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageFile = File(widget.testSession.capturedImagePath);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () {
            if (_currentStage == SelectionStage.review) {
              setState(() => _currentStage = SelectionStage.reaction);
            } else if (_currentStage == SelectionStage.reaction) {
              setState(() => _currentStage = SelectionStage.reference);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          _currentStage == SelectionStage.review
              ? 'Review Selected Regions'
              : 'Select Test Regions',
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: _isLoadingImage
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)))
            : Column(
                children: [
                  // Interactive Canvas
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF1E293B)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Mapper recalculated dynamically based on the exact active canvas size
                          final mapper = ImageCoordinateMapper(
                            imageWidth: _origWidth ?? 640.0,
                            imageHeight: _origHeight ?? 480.0,
                            containerWidth: constraints.maxWidth,
                            containerHeight: constraints.maxHeight,
                          );

                          // Calculate screen rects dynamically from original coordinates
                          Rect? displayRef;
                          if (_currentStage == SelectionStage.reference && _activeDragDisplayRect != null) {
                            displayRef = _activeDragDisplayRect;
                          } else if (_originalRefRect != null) {
                            displayRef = mapper.originalImageToDisplay(_originalRefRect!);
                          }

                          Rect? displayRxn;
                          if (_currentStage == SelectionStage.reaction && _activeDragDisplayRect != null) {
                            displayRxn = _activeDragDisplayRect;
                          } else if (_originalRxnRect != null) {
                            displayRxn = mapper.originalImageToDisplay(_originalRxnRect!);
                          }

                          return GestureDetector(
                            onPanStart: (d) => _onPanStart(d, mapper),
                            onPanUpdate: (d) => _onPanUpdate(d, mapper),
                            onPanEnd: (d) => _onPanEnd(d, mapper),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Center(
                                  child: kIsWeb
                                      ? Image.network(widget.testSession.capturedImagePath, fit: BoxFit.contain)
                                      : Image.file(imageFile, fit: BoxFit.contain),
                                ),

                                // Reference Box (Cyan)
                                if (displayRef != null)
                                  Positioned.fromRect(
                                    rect: displayRef,
                                    child: _buildRegionBox(
                                      label: 'Reference',
                                      borderColor: const Color(0xFF0284C7),
                                      fillColor: const Color(0xFF0284C7).withValues(alpha: 0.18),
                                      isEditable: _currentStage == SelectionStage.reference,
                                    ),
                                  ),

                                // Reaction Box (Orange)
                                if (displayRxn != null)
                                  Positioned.fromRect(
                                    rect: displayRxn,
                                    child: _buildRegionBox(
                                      label: 'Reaction',
                                      borderColor: const Color(0xFFEA580C),
                                      fillColor: const Color(0xFFEA580C).withValues(alpha: 0.18),
                                      isEditable: _currentStage == SelectionStage.reaction,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Bottom Controls Panel
                  Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: _buildControlPanel(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildRegionBox({
    required String label,
    required Color borderColor,
    required Color fillColor,
    required bool isEditable,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: fillColor,
        border: Border.all(color: borderColor, width: 2.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(3),
                  bottomRight: Radius.circular(6),
                ),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (isEditable) ...[
            _buildCornerHandle(Alignment.topLeft, borderColor),
            _buildCornerHandle(Alignment.topRight, borderColor),
            _buildCornerHandle(Alignment.bottomLeft, borderColor),
            _buildCornerHandle(Alignment.bottomRight, borderColor),
          ],
        ],
      ),
    );
  }

  Widget _buildCornerHandle(Alignment alignment, Color color) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2.5),
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    if (_currentStage == SelectionStage.reference) {
      return _buildReferenceStepPanel();
    } else if (_currentStage == SelectionStage.reaction) {
      return _buildReactionStepPanel();
    } else {
      return _buildReviewPanel();
    }
  }

  Widget _buildReferenceStepPanel() {
    final bool hasSelection = _originalRefRect != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'STEP 1 OF 2',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0284C7),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Select the Reference Colour Card',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 4),
        const Text(
          'Drag over the complete 3×3 reference colour chart. Drag inside to move; drag corners to resize.',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: hasSelection ? () => setState(() => _originalRefRect = null) : null,
                child: const Text('Reset', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: hasSelection ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: hasSelection
                    ? () => setState(() => _currentStage = SelectionStage.reaction)
                    : null,
                child: const Text('Confirm Reference', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReactionStepPanel() {
    final bool hasSelection = _originalRxnRect != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'STEP 2 OF 2',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFFEA580C),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Select the Reaction Region',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 4),
        const Text(
          'Drag over the test/reaction colour area. Drag inside to move; drag corners to resize.',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => setState(() => _currentStage = SelectionStage.reference),
                child: const Text('Back', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: hasSelection ? () => setState(() => _originalRxnRect = null) : null,
                child: const Text('Reset', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: hasSelection ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: hasSelection
                    ? () => setState(() => _currentStage = SelectionStage.review)
                    : null,
                child: const Text('Confirm Reaction', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReviewPanel() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CONFIRMATION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.testSession.selectedKit,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: const Text(
                'Regions Verified',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF065F46)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Column(
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: Color(0xFF0284C7)),
                  SizedBox(width: 8),
                  Text(
                    'Reference region selected',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: Color(0xFFEA580C)),
                  SizedBox(width: 8),
                  Text(
                    'Reaction region selected',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Retake', style: TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.bold)),
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
                onPressed: () {
                  setState(() => _currentStage = SelectionStage.reference);
                },
                child: const Text('Adjust Regions', style: TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF0F172A),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _handleContinue,
          child: const Text(
            'CONTINUE',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
        ),
      ],
    );
  }
}