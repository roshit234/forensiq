// lib/features/camera/camera_screen.dart
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../models/test_session.dart';
import '../../services/location_service.dart';
import 'image_quality_screen.dart';

class CameraScreen extends StatefulWidget {
  final String officerId;
  final String selectedKit;

  const CameraScreen({
    super.key,
    required this.officerId,
    required this.selectedKit, // <-- Mark required
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitializing = true;
  bool _permissionDenied = false;
  bool _permanentlyDenied = false;
  String _errorMessage = '';
  FlashMode _currentFlashMode = FlashMode.off;
  bool _isCapturing = false;

  // Metadata session fields
  late final String _testId;
  final LocationService _locationService = const LocationService();
  LocationDataResult _location = const LocationDataResult.unavailable();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _testId = _generateTestId();
    _fetchBackgroundLocation();
    _checkPermissionAndInit();
  }

  /// Generates clean unique ID: FIQ-YYYYMMDD-XXX
  String _generateTestId() {
    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final randomSuffix = (Random().nextInt(900) + 100).toString();
    return 'FIQ-$dateStr-$randomSuffix';
  }

  Future<void> _fetchBackgroundLocation() async {
    final result = await _locationService.getCurrentLocation();
    if (mounted) {
      setState(() => _location = result);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _checkPermissionAndInit() async {
    setState(() {
      _isInitializing = true;
      _permissionDenied = false;
      _permanentlyDenied = false;
      _errorMessage = '';
    });

    if (kIsWeb) {
      await _initCamera();
      return;
    }

    final status = await Permission.camera.request();

    if (status.isGranted) {
      await _initCamera();
    } else if (status.isPermanentlyDenied) {
      setState(() {
        _isInitializing = false;
        _permanentlyDenied = true;
      });
    } else {
      setState(() {
        _isInitializing = false;
        _permissionDenied = true;
      });
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _isInitializing = false;
          _permissionDenied = true;
          _errorMessage = 'No camera sensors detected on this device.';
        });
        return;
      }

      final selectedCamera = _cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      final controller = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller.initialize();

      if (!kIsWeb) {
        try {
          await controller.setFlashMode(FlashMode.off);
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _controller = controller;
          _isInitializing = false;
          _currentFlashMode = FlashMode.off;
        });
      }
    } on CameraException catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          if (e.code == 'CameraAccessDenied' ||
              e.code == 'CameraAccessDeniedAtOs' ||
              e.code == 'cameraPermission') {
            _permissionDenied = true;
          } else {
            _errorMessage = e.description ?? e.code;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _toggleFlash() async {
    if (kIsWeb || _controller == null || !_controller!.value.isInitialized) return;

    FlashMode nextMode;
    switch (_currentFlashMode) {
      case FlashMode.off:
        nextMode = FlashMode.torch;
        break;
      case FlashMode.torch:
        nextMode = FlashMode.auto;
        break;
      default:
        nextMode = FlashMode.off;
        break;
    }

    try {
      await _controller!.setFlashMode(nextMode);
      setState(() {
        _currentFlashMode = nextMode;
      });
    } catch (_) {}
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) {
      return;
    }

    try {
      setState(() => _isCapturing = true);

      final XFile imageFile = await _controller!.takePicture();
      final DateTime captureTime = DateTime.now();

      // Create session instance tied to this physical photo event
      final session = TestSession(
        testId: _testId,
        selectedKit: widget.selectedKit, // <-- Pass the selected kit here
        capturedAt: captureTime,
        operatorId: widget.officerId,
        latitude: _location.latitude,
        longitude: _location.longitude,
        city: _location.city,
        state: _location.state,
        capturedImagePath: imageFile.path,
      );

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageQualityScreen(
            imageFile: imageFile,
            testSession: session,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture sample: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isInitializing) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF38BDF8)),
            SizedBox(height: 16),
            Text(
              'Initializing Camera Sensor...',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_permissionDenied || _permanentlyDenied) {
      return _buildPermissionFallback();
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.amber, size: 48),
              const SizedBox(height: 12),
              Text(
                'Camera Error: $_errorMessage',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _checkPermissionAndInit,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(
        child: Text(
          'Unable to initialize camera sensor.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: CameraPreview(_controller!),
        ),
        Center(
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.6),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.8),
                ),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: const Text(
                  'Capture Sample Image',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              if (!kIsWeb)
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.8),
                  ),
                  icon: Icon(
                    _currentFlashMode == FlashMode.torch
                        ? Icons.flash_on_rounded
                        : _currentFlashMode == FlashMode.auto
                            ? Icons.flash_auto_rounded
                            : Icons.flash_off_rounded,
                    color: _currentFlashMode != FlashMode.off
                        ? const Color(0xFF38BDF8)
                        : Colors.white,
                  ),
                  onPressed: _toggleFlash,
                )
              else
                const SizedBox(width: 48),
            ],
          ),
        ),
        Positioned(
          bottom: 28,
          left: 0,
          right: 0,
          child: Column(
            children: [
              const Text(
                'Center kit reaction zone inside framing guide',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _isCapturing ? null : _takePicture,
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isCapturing ? const Color(0xFF64748B) : Colors.white,
                    ),
                    child: _isCapturing
                        ? const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionFallback() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.no_photography_outlined,
              size: 56,
              color: Color(0xFF94A3B8),
            ),
            const SizedBox(height: 18),
            const Text(
              'Camera Access Required',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'ForensIQ requires the camera sensor to photograph test reagents.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              onPressed: _checkPermissionAndInit,
              child: const Text('Retry Camera Access', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Return to Dashboard', style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
      ),
    );
  }
}