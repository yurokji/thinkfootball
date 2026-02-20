import 'dart:io';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:docushot/presentation/providers/document_provider.dart';
import 'package:docushot/presentation/screens/perspective_crop_screen.dart';
import 'package:docushot/presentation/screens/enhance_screen.dart';
import 'package:docushot/core/image/image_processor.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:edge_detection/edge_detection.dart';
import 'package:image/image.dart' as img;
import 'package:docushot/core/models/document_type.dart';

class CustomCameraScreen extends ConsumerStatefulWidget {
  const CustomCameraScreen({super.key});

  @override
  ConsumerState<CustomCameraScreen> createState() => _CustomCameraScreenState();
}

class _CustomCameraScreenState extends ConsumerState<CustomCameraScreen> with SingleTickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  
  // Modes: 0 = Manual, 1 = Batch
  int _currentMode = 0;
  // Doc Type: 0 = Document, 1 = Book, 2 = ID Card
  int _docType = 0; 
  
  FlashMode _flashMode = FlashMode.off;
  
  // Animation for "AI Breathing" effect
  late AnimationController _animController;
  late Animation<double> _animValue;

  final List<Map<String, dynamic>> _capturedImages = [];
  bool _isTakingPicture = false;

  // Auto-Capture Variables
  bool _isAutoCapture = false;
  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  Timer? _stabilityTimer;
  double _lastX = 0, _lastY = 0, _lastZ = 0;
  bool _isStable = false;

  // Edge Detection Preview
  List<Offset>? _previewCorners; // Normalized 0..1 corners for overlay
  Timer? _edgeDetectTimer;
  bool _isDetectingEdges = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    
    // Setup Pulse Animation
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _animValue = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _animController.dispose();
    _stopAutoCaptureLoop();
    _stopEdgeDetectLoop();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        final backCamera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras!.first,
        );
        
        _controller = CameraController(
          backCamera, 
          ResolutionPreset.high, 
          enableAudio: false,
          imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.jpeg : ImageFormatGroup.bgra8888,
        );

        await _controller!.initialize();
        if (mounted) {
          setState(() {});
          _startEdgeDetectLoop();
        }
      }
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  void _startEdgeDetectLoop() {
    _edgeDetectTimer?.cancel();
    _edgeDetectTimer = Timer.periodic(const Duration(milliseconds: 1000), (_) {
      _detectEdgesPreview();
    });
  }

  void _stopEdgeDetectLoop() {
    _edgeDetectTimer?.cancel();
  }

  Future<void> _detectEdgesPreview() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_isDetectingEdges || _isTakingPicture) return;

    _isDetectingEdges = true;
    String? tempPath;

    try {
      // Take a quick snapshot for edge detection
      final XFile preview = await _controller!.takePicture();
      final dir = await getTemporaryDirectory();
      tempPath = '${dir.path}/_edge_preview.jpg';
      await preview.saveTo(tempPath);

      final corners = await EdgeDetection.detectEdgesNoUI(tempPath);

      if (mounted) {
        if (corners != null && corners.length == 4) {
          // Corners are pixel coordinates - normalize to 0..1
          final decoded = await decodeImageFromList(File(tempPath).readAsBytesSync());
          final w = decoded.width.toDouble();
          final h = decoded.height.toDouble();
          setState(() {
            _previewCorners = corners.map((o) => Offset(
              (o.dx / w).clamp(0.0, 1.0),
              (o.dy / h).clamp(0.0, 1.0),
            )).toList();
          });
        } else {
          setState(() => _previewCorners = null);
        }
      }
    } catch (e) {
      debugPrint('Edge preview error: $e');
      if (mounted) setState(() => _previewCorners = null);
    } finally {
      _isDetectingEdges = false;
      // Clean up temp file
      if (tempPath != null) {
        try { File(tempPath).deleteSync(); } catch (_) {}
      }
    }
  }

  Future<void> _toggleFlash() async {
    if (_controller == null) return;
    
    FlashMode newMode;
    switch (_flashMode) {
      case FlashMode.off: newMode = FlashMode.auto; break;
      case FlashMode.auto: newMode = FlashMode.always; break;
      case FlashMode.always: newMode = FlashMode.off; break;
      default: newMode = FlashMode.off;
    }
    
    await _controller!.setFlashMode(newMode);
    setState(() { _flashMode = newMode; });
  }

  // --- LOGIC SECTION ---

  void _startAutoCaptureLoop() {
    // Start listening to accelerometer
    _accelSubscription?.cancel();
    _accelSubscription = accelerometerEventStream().listen((event) {
      if (!_isAutoCapture || _isTakingPicture || !mounted) return;
      
      double delta = (event.x - _lastX).abs() + (event.y - _lastY).abs() + (event.z - _lastZ).abs();
      _lastX = event.x;
      _lastY = event.y;
      _lastZ = event.z;

      if (delta < 0.5) { // Threshold for "Stable"
        if (!_isStable) {
           _isStable = true;
           // Start Stability Timer
           _stabilityTimer?.cancel();
           _stabilityTimer = Timer(const Duration(milliseconds: 1200), () {
             if (_isStable && _isAutoCapture && !_isTakingPicture && mounted) {
                debugPrint("Auto-Capture Triggered!");
                _takePicture();
             }
           });
        }
      } else {
        // Moving
        _isStable = false;
        _stabilityTimer?.cancel();
      }
    });
  }

  void _stopAutoCaptureLoop() {
    _accelSubscription?.cancel();
    _stabilityTimer?.cancel();
  }

  void _toggleAutoCapture() {
    setState(() {
      _isAutoCapture = !_isAutoCapture;
    });
    if (_isAutoCapture) {
      _startAutoCaptureLoop();
    } else {
      _stopAutoCaptureLoop();
    }
  }

  // Helper to open Step 2 (Enhance)
  Future<Map<String, String>?> _processStep2(String croppedPath, String originalPath) async {
    String? enhancedPath;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EnhanceScreen(
          imagePath: croppedPath,
          originalPath: originalPath,
          isManualMode: _currentMode == 0,
          onDone: (path) => enhancedPath = path,
          onApplyToAll: (type) async {
            for (var item in _capturedImages) {
              final croppedPath = item['path'] as String;
              final newP = await ImageProcessor.applyFilter(croppedPath, type);
              item['path'] = newP;
            }
          },
        ),
      ),
    );
    return enhancedPath != null ? {'path': enhancedPath!, 'originalPath': originalPath} : null;
  }

  Future<Map<String, dynamic>?> _cropImage(String sourcePath, {List<double>? initialCorners}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PerspectiveCropScreen(
          imagePath: sourcePath,
          initialCorners: initialCorners,
        ),
      ),
    );
    if (result != null && result is Map<String, dynamic>) {
        return result;
    }
    return null;
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isTakingPicture) return;

    _stopEdgeDetectLoop();
    setState(() { _isTakingPicture = true; _previewCorners = null; });

    try {
      final XFile image = await _controller!.takePicture();
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String fileName = '${const Uuid().v4()}.jpg';
      final String savedPath = '${appDir.path}/$fileName';
      await image.saveTo(savedPath);

      // Processing Logic (Custom UI Flow)
      if (_currentMode == 0) {
         // Manual: Capture -> Crop -> Enhance -> Return
         
         // 1. Auto-Detect Edges (Headless)
         List<double>? normalizedCorners;
         try {
             final corners = await EdgeDetection.detectEdgesNoUI(savedPath);
             if (corners != null && corners.length == 4) {
                 final decoded = await decodeImageFromList(File(savedPath).readAsBytesSync());
                 final w = decoded.width.toDouble();
                 final h = decoded.height.toDouble();
                 
                 normalizedCorners = [];
                 for (var c in corners) {
                     normalizedCorners!.add((c.dx / w).clamp(0.0, 1.0));
                     normalizedCorners!.add((c.dy / h).clamp(0.0, 1.0));
                 }
             }
         } catch (e) {
             debugPrint("Auto-detect failed: $e");
         }
         
         // 2. Open Crop Screen with detected corners
         final cropResult = await _cropImage(savedPath, initialCorners: normalizedCorners);
         
         if (cropResult != null) {
            final croppedPath = cropResult['path'] as String;
            final corners = cropResult['corners'] as List<double>?;
            
            // 2. Open Enhance Screen
            final resultItem = await _processStep2(croppedPath, savedPath);
            
            if (resultItem != null) {
               if (mounted) Navigator.pop(context, [resultItem]);
            } else {
               // Canceled Enhance -> Keep Cropped Version
               if (mounted) {
                 setState(() {
                   _capturedImages.add({
                     'path': croppedPath,
                     'originalPath': savedPath,
                     'corners': corners,
                     'docType': _docType,
                   });
                 });
               }
            }
         } else {
            // Canceled Crop -> Keep Raw (or Retake? User pressed Check on Crop usually)
            // If user pressed BACK on crop, it returns null.
            // Let's assume Back = Retake (Don't add to list).
            // But for safety, let's keep it as raw?
            // "Just bare camera screen" complaint implies they want to see the UI.
            // If they cancel crop, they probably want to retry.
            // Let's NOT add to list if crop is canceled.
         }
      } else {
         // Batch: Capture + Auto-Detect Edges, defer crop/enhance to _finish()
         List<double>? normalizedCorners;
         try {
           final corners = await EdgeDetection.detectEdgesNoUI(savedPath);
           if (corners != null && corners.length == 4) {
             final decoded = await decodeImageFromList(File(savedPath).readAsBytesSync());
             final w = decoded.width.toDouble();
             final h = decoded.height.toDouble();
             normalizedCorners = [];
             for (var c in corners) {
               normalizedCorners!.add((c.dx / w).clamp(0.0, 1.0));
               normalizedCorners!.add((c.dy / h).clamp(0.0, 1.0));
             }
           }
         } catch (e) {
           debugPrint("Batch auto-detect failed: $e");
         }

         if (mounted) {
           setState(() {
             _capturedImages.add({
               'path': savedPath,
               'originalPath': savedPath,
               'corners': normalizedCorners,
               'docType': _docType,
             });
           });
         }
         await Future.delayed(const Duration(milliseconds: 500));
      }

    } catch (e) {
      debugPrint('Capture error: $e');
    } finally {
      if (mounted) {
        setState(() { _isTakingPicture = false; });
        _startEdgeDetectLoop();
      }
    }
  }

  Future<void> _finish() async {
    if (_currentMode == 1 && _capturedImages.isNotEmpty) {
      // Batch: Auto-crop all images using detected corners
      for (var item in _capturedImages) {
        final corners = item['corners'] as List<double>?;
        final rawPath = item['originalPath'] as String;
        if (corners != null && corners.length == 8) {
          final cropResult = await ImageProcessor.perspectiveCrop(
            rawPath,
            _cornersToPoints(corners, rawPath),
          );
          item['path'] = cropResult;
        }
      }

      // Open enhance for the first image; onApplyToAll applies to all cropped images
      final firstItem = _capturedImages.first;
      final config = getDocTypeConfig(docTypeFromIndex(_docType));
      String? enhancedPath;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EnhanceScreen(
            imagePath: firstItem['path'] as String,
            originalPath: firstItem['originalPath'] as String,
            isManualMode: false,
            initialFilter: config.defaultFilter,
            onDone: (path) => enhancedPath = path,
            onApplyToAll: (type) async {
              for (var item in _capturedImages) {
                final croppedPath = item['path'] as String;
                final newP = await ImageProcessor.applyFilter(croppedPath, type);
                item['path'] = newP;
              }
            },
          ),
        ),
      );

      // Apply first image's enhance result back
      if (enhancedPath != null) {
        firstItem['path'] = enhancedPath!;
      }
    }
    if (mounted) Navigator.pop(context, _capturedImages);
  }

  /// Convert normalized corner list [x1,y1,...x4,y4] to img.Point list
  Future<List<img.Point>> _cornersToPointsAsync(List<double> corners, String imagePath) async {
    final decoded = await decodeImageFromList(File(imagePath).readAsBytesSync());
    final w = decoded.width.toDouble();
    final h = decoded.height.toDouble();
    final points = <img.Point>[];
    for (int i = 0; i < 8; i += 2) {
      points.add(img.Point((corners[i] * w).toInt(), (corners[i + 1] * h).toInt()));
    }
    return points;
  }

  List<img.Point> _cornersToPoints(List<double> corners, String imagePath) {
    // Sync version: read image dimensions
    final bytes = File(imagePath).readAsBytesSync();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return [];
    final w = decoded.width.toDouble();
    final h = decoded.height.toDouble();
    final points = <img.Point>[];
    for (int i = 0; i < 8; i += 2) {
      points.add(img.Point((corners[i] * w).toInt(), (corners[i + 1] * h).toInt()));
    }
    return points;
  }
  
  Future<void> _editLast() async {
    if (_capturedImages.isEmpty) return;
    final lastItem = _capturedImages.last;
    final originalPath = lastItem['originalPath'] as String; 
    final currentCorners = lastItem['corners'] as List<double>?;
    
    final cropResult = await _cropImage(originalPath, initialCorners: currentCorners);
    if (cropResult != null) {
       final croppedPath = cropResult['path'] as String;
       final corners = cropResult['corners'] as List<double>?;
       lastItem['corners'] = corners;
       final resultItem = await _processStep2(croppedPath, originalPath);
       
       setState(() {
         if (resultItem != null) {
           lastItem['path'] = resultItem['path'];
         } else {
           lastItem['path'] = croppedPath; 
         }
       });
    }
  }

  Future<void> _undoLast() async {
    if (_capturedImages.isNotEmpty) {
      setState(() => _capturedImages.removeLast());
    }
  }

  // --- UI BUILDING ---

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera Preview
          SizedBox.expand(child: CameraPreview(_controller!)),
          
          // 2. AI Overlay (Pulsing brackets)
          Positioned.fill(
             child: AnimatedBuilder(
               animation: _animValue,
               builder: (context, child) {
                 return CustomPaint(
                   painter: _AIOverlayPainter(_animValue.value),
                 );
               },
             ),
          ),

          // 2b. Edge Detection Overlay (detected document polygon)
          if (_previewCorners != null && _previewCorners!.length == 4)
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return CustomPaint(
                    painter: _EdgeOverlayPainter(
                      corners: _previewCorners!,
                      previewSize: Size(constraints.maxWidth, constraints.maxHeight),
                    ),
                  );
                },
              ),
            ),

          // 3. Top Bar
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(child: _buildTopBar()),
          ),

          // 4. Bottom Controls Complex
          Positioned(
             bottom: 0, left: 0, right: 0,
             child: _buildBottomUI(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.black26, 
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
            onPressed: () => Navigator.pop(context, _capturedImages),
          ),
          IconButton(
            icon: Icon(
              _flashMode == FlashMode.off ? Icons.flash_off : 
              _flashMode == FlashMode.auto ? Icons.flash_auto : Icons.flash_on, 
              color: _flashMode == FlashMode.off ? Colors.white : Colors.yellow,
            ),
            onPressed: _toggleFlash,
          ),
          Container(
             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
             decoration: BoxDecoration(
               border: Border.all(color: Colors.white),
               borderRadius: BorderRadius.circular(4),
             ),
             child: const Text('HD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {}, 
          ),
        ],
      ),
    );
  }

  Widget _buildBottomUI() {
    final hasImages = _capturedImages.isNotEmpty;
    
    return Container(
      padding: const EdgeInsets.only(bottom: 30, top: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.9)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // LEVEL 1: OVERLAY SLIDER (Manual / Batch)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 20),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildModePill('Manual', 0),
                _buildModePill('Batch', 1),
              ],
            ),
          ),
          
          // LEVEL 2: TYPE SELECTOR
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 20),
                _buildTypeItem('Document', 0),
                const SizedBox(width: 30),
                _buildTypeItem('Book', 1),
                 const SizedBox(width: 30),
                _buildTypeItem('ID Card', 2),
                const SizedBox(width: 20),
              ],
            ),
          ),
          
          const SizedBox(height: 30),
          
          // LEVEL 3: CONTROLS
          Column(
            children: [
               // AUTO TOGGLE
               GestureDetector(
                 onTap: _toggleAutoCapture,
                 child: Container(
                   margin: const EdgeInsets.only(bottom: 20),
                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                   decoration: BoxDecoration(
                     color: _isAutoCapture ? Colors.yellowAccent : Colors.white24,
                     borderRadius: BorderRadius.circular(20),
                     border: Border.all(color: _isAutoCapture ? Colors.yellow : Colors.white54),
                   ),
                   child: Row(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       Icon(Icons.auto_awesome, size: 16, color: _isAutoCapture ? Colors.black : Colors.white),
                       const SizedBox(width: 8),
                       Text(
                         _isAutoCapture ? 'AUTO CAPTURE: ON' : 'AUTO CAPTURE: OFF',
                         style: TextStyle(
                           color: _isAutoCapture ? Colors.black : Colors.white,
                           fontWeight: FontWeight.bold,
                           fontSize: 12
                         ),
                       ),
                     ],
                   ),
                 ),
               ),
               
               Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                   // Gallery / Thumbnail
                   GestureDetector(
                    onTap: hasImages ? _editLast : () {},
                    child: Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 2),
                        borderRadius: BorderRadius.circular(8),
                        image: hasImages ? DecorationImage(
                          image: FileImage(File(_capturedImages.last['path'])),
                          fit: BoxFit.cover,
                        ) : null,
                      ),
                      child: !hasImages ? const Icon(Icons.image, color: Colors.white) : null,
                    ),
                   ),
                   
                   // Shutter
                   GestureDetector(
                     onTap: _takePicture,
                     child: Container(
                       width: 80, height: 80,
                       decoration: BoxDecoration(
                         shape: BoxShape.circle,
                         border: Border.all(color: Colors.white, width: 4),
                         color: Colors.white24,
                       ),
                       child: Container(
                         margin: const EdgeInsets.all(6),
                         decoration: const BoxDecoration(
                           shape: BoxShape.circle,
                           color: Colors.white,
                         ),
                       ),
                     ),
                   ),
                   
                   // Done
                   GestureDetector(
                     onTap: _finish,
                     child: Container(
                       width: 50, height: 50,
                       alignment: Alignment.center,
                       child: hasImages 
                         ? const Icon(Icons.check_circle, color: Colors.cyanAccent, size: 40)
                         : const SizedBox(),
                     ),
                   ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModePill(String text, int index) {
    final bool selected = _currentMode == index;
    return GestureDetector(
      onTap: () => setState(() => _currentMode = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
           color: selected ? Colors.black87 : Colors.transparent,
           borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text, style: TextStyle(
          color: selected ? Colors.yellowAccent : Colors.white60,
          fontWeight: FontWeight.bold,
        )),
      ),
    );
  }

  Widget _buildTypeItem(String text, int index) {
    final bool selected = _docType == index;
    return GestureDetector(
      onTap: () => setState(() => _docType = index),
      child: Text(text, style: TextStyle(
        color: selected ? Colors.yellowAccent : Colors.white54,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        fontSize: 14,
        letterSpacing: 1.0,
      )),
    );
  }
}

class _AIOverlayPainter extends CustomPainter {
  final double pulse;
  _AIOverlayPainter(this.pulse);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final double w = size.width;
    final double h = size.height;
    
    final double bracketLen = 40.0 * pulse; 
    final double m = 50.0; 
    
    // Top Left
    canvas.drawLine(Offset(m, m + bracketLen), Offset(m, m), paint);
    canvas.drawLine(Offset(m, m), Offset(m + bracketLen, m), paint);
    
    // Top Right
    canvas.drawLine(Offset(w - m - bracketLen, m), Offset(w - m, m), paint);
    canvas.drawLine(Offset(w - m, m), Offset(w - m, m + bracketLen), paint);
    
    // Bottom Right
    canvas.drawLine(Offset(w - m, h - m - bracketLen), Offset(w - m, h - m), paint);
    canvas.drawLine(Offset(w - m, h - m), Offset(w - m - bracketLen, h - m), paint);
    
    // Bottom Left
    canvas.drawLine(Offset(m + bracketLen, h - m), Offset(m, h - m), paint);
    canvas.drawLine(Offset(m, h - m), Offset(m, h - m - bracketLen), paint);
  }

  @override
  bool shouldRepaint(covariant _AIOverlayPainter oldDelegate) => oldDelegate.pulse != pulse;
}

class _EdgeOverlayPainter extends CustomPainter {
  final List<Offset> corners; // Normalized 0..1 corners
  final Size previewSize;

  _EdgeOverlayPainter({required this.corners, required this.previewSize});

  @override
  void paint(Canvas canvas, Size size) {
    if (corners.length != 4) return;

    final paint = Paint()
      ..color = Colors.greenAccent.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = Colors.greenAccent.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    // Map normalized corners (0..1) to widget coordinates
    final mapped = corners.map((c) => Offset(c.dx * size.width, c.dy * size.height)).toList();

    final path = Path()
      ..moveTo(mapped[0].dx, mapped[0].dy)
      ..lineTo(mapped[1].dx, mapped[1].dy)
      ..lineTo(mapped[2].dx, mapped[2].dy)
      ..lineTo(mapped[3].dx, mapped[3].dy)
      ..close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, paint);

    // Draw corner dots
    final dotPaint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.fill;
    for (var p in mapped) {
      canvas.drawCircle(p, 5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _EdgeOverlayPainter oldDelegate) {
    return oldDelegate.corners != corners;
  }
}
