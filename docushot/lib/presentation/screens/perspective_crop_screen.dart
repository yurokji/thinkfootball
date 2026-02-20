import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:docushot/core/image/image_processor.dart';

class PerspectiveCropScreen extends StatefulWidget {
  final String imagePath;
  final List<double>? initialCorners;

  const PerspectiveCropScreen({super.key, required this.imagePath, this.initialCorners});

  @override
  State<PerspectiveCropScreen> createState() => _PerspectiveCropScreenState();
}

class _PerspectiveCropScreenState extends State<PerspectiveCropScreen> {
  late List<Offset> _corners;
  int? _dragIndex;
  double _imageWidth = 1;
  double _imageHeight = 1;
  Rect? _imageRect;

  /// Rotation in 90-degree steps: 0, 1, 2, 3
  int _rotationSteps = 0;

  @override
  void initState() {
    super.initState();
    _initCorners();
    _loadImageInfo();
  }

  void _initCorners() {
    if (widget.initialCorners != null && widget.initialCorners!.length == 8) {
      _corners = [];
      for (int i = 0; i < 8; i += 2) {
        _corners.add(Offset(widget.initialCorners![i], widget.initialCorners![i + 1]));
      }
    } else {
      _corners = [
        const Offset(0.05, 0.05),
        const Offset(0.95, 0.05),
        const Offset(0.95, 0.95),
        const Offset(0.05, 0.95),
      ];
    }
  }

  Future<void> _loadImageInfo() async {
    final decoded = await decodeImageFromList(File(widget.imagePath).readAsBytesSync());
    if (mounted) {
      setState(() {
        _imageWidth = decoded.width.toDouble();
        _imageHeight = decoded.height.toDouble();
      });
    }
  }

  Rect _calculateImageRect(Size containerSize) {
    // Account for rotation: swap aspect ratio for 90/270 degrees
    final bool isRotated = _rotationSteps % 2 == 1;
    final double imgW = isRotated ? _imageHeight : _imageWidth;
    final double imgH = isRotated ? _imageWidth : _imageHeight;
    final double imgRatio = imgW / imgH;
    final double containerRatio = containerSize.width / containerSize.height;

    double w, h, dx, dy;
    if (containerRatio > imgRatio) {
      h = containerSize.height;
      w = h * imgRatio;
      dx = (containerSize.width - w) / 2;
      dy = 0;
    } else {
      w = containerSize.width;
      h = w / imgRatio;
      dx = 0;
      dy = (containerSize.height - h) / 2;
    }
    return Rect.fromLTWH(dx, dy, w, h);
  }

  void _rotateClockwise() {
    setState(() {
      _rotationSteps = (_rotationSteps + 1) % 4;
      // Rotate corners: (x, y) -> (1-y, x) for 90-degree clockwise
      _corners = _corners.map((c) => Offset(1.0 - c.dy, c.dx)).toList();
    });
  }

  void _onPanStart(DragStartDetails details, BoxConstraints constraints) {
    if (_imageRect == null) return;
    final pos = details.localPosition;

    for (int i = 0; i < 4; i++) {
      final cx = _imageRect!.left + (_corners[i].dx * _imageRect!.width);
      final cy = _imageRect!.top + (_corners[i].dy * _imageRect!.height);
      if ((Offset(cx, cy) - pos).distance < 40) {
        setState(() => _dragIndex = i);
        break;
      }
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_dragIndex == null || _imageRect == null) return;

    setState(() {
      final dx = details.delta.dx / _imageRect!.width;
      final dy = details.delta.dy / _imageRect!.height;
      double newX = (_corners[_dragIndex!].dx + dx).clamp(0.0, 1.0);
      double newY = (_corners[_dragIndex!].dy + dy).clamp(0.0, 1.0);
      _corners[_dragIndex!] = Offset(newX, newY);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() => _dragIndex = null);
  }

  /// Un-rotate corners back to original image coordinates before cropping
  List<Offset> _getOriginalCorners() {
    var result = List<Offset>.from(_corners);
    // Reverse rotation: apply counter-clockwise rotation _rotationSteps times
    for (int i = 0; i < _rotationSteps; i++) {
      result = result.map((c) => Offset(c.dy, 1.0 - c.dx)).toList();
    }
    return result;
  }

  Future<void> _processCrop() async {
    final originalCorners = _getOriginalCorners();

    List<double> savedCorners = [];
    for (var c in originalCorners) {
      savedCorners.add(c.dx);
      savedCorners.add(c.dy);
    }

    List<img.Point> points = originalCorners.map((c) {
      return img.Point((c.dx * _imageWidth).toInt(), (c.dy * _imageHeight).toInt());
    }).toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      String resultPath = widget.imagePath;

      // Apply rotation first if needed
      if (_rotationSteps > 0) {
        resultPath = await _applyRotation(resultPath, _rotationSteps);
        // After rotation, points are already in rotated space, recalculate
        final rotatedDecoded = await decodeImageFromList(File(resultPath).readAsBytesSync());
        final rw = rotatedDecoded.width.toDouble();
        final rh = rotatedDecoded.height.toDouble();
        points = _corners.map((c) {
          return img.Point((c.dx * rw).toInt(), (c.dy * rh).toInt());
        }).toList();
      }

      final croppedPath = await ImageProcessor.perspectiveCrop(resultPath, points);
      if (mounted) {
        Navigator.pop(context); // Pop loader
        Navigator.pop(context, {'path': croppedPath, 'corners': savedCorners});
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint('Crop error: $e');
    }
  }

  Future<String> _applyRotation(String path, int steps) async {
    final bytes = await File(path).readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return path;

    for (int i = 0; i < steps; i++) {
      image = img.copyRotate(image!, angle: 90);
    }

    final ts = DateTime.now().millisecondsSinceEpoch;
    final newPath = path.replaceAll('.jpg', '_rot$ts.jpg');
    final encoded = img.encodeJpg(image!, quality: 90);
    await File(newPath).writeAsBytes(encoded);
    return newPath;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('CROP / ROTATE', style: TextStyle(color: Colors.white, fontSize: 16, letterSpacing: 1.2)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.rotate_right, color: Colors.white),
            tooltip: 'Rotate 90°',
            onPressed: _rotateClockwise,
          ),
          IconButton(
            icon: const Icon(Icons.check, color: Colors.cyanAccent),
            onPressed: _processCrop,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (ctx, constraints) {
                  _imageRect = _calculateImageRect(Size(constraints.maxWidth, constraints.maxHeight));

                  return GestureDetector(
                    onPanStart: (d) => _onPanStart(d, constraints),
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    child: Stack(
                      children: [
                        Center(
                          child: Transform.rotate(
                            angle: _rotationSteps * math.pi / 2,
                            child: Image.file(
                              File(widget.imagePath),
                              fit: BoxFit.contain,
                              width: constraints.maxWidth,
                              height: constraints.maxHeight,
                            ),
                          ),
                        ),
                        if (_imageRect != null)
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _CropOverlayPainter(_corners, _imageRect!),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Container(
              height: 60,
              color: Colors.black,
              child: const Center(
                child: Text('Drag corners to adjust • Tap rotate to turn',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CropOverlayPainter extends CustomPainter {
  final List<Offset> corners;
  final Rect imageRect;

  _CropOverlayPainter(this.corners, this.imageRect);

  @override
  void paint(Canvas canvas, Size size) {
    final points = corners.map((c) {
      return Offset(
        imageRect.left + (c.dx * imageRect.width),
        imageRect.top + (c.dy * imageRect.height),
      );
    }).toList();

    // Draw shaded area outside crop region
    final cropPath = Path()
      ..moveTo(points[0].dx, points[0].dy)
      ..lineTo(points[1].dx, points[1].dy)
      ..lineTo(points[2].dx, points[2].dy)
      ..lineTo(points[3].dx, points[3].dy)
      ..close();

    final fullPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final shadePath = Path.combine(PathOperation.difference, fullPath, cropPath);

    canvas.drawPath(
      shadePath,
      Paint()..color = Colors.black.withValues(alpha: 0.5),
    );

    // Draw crop border
    canvas.drawPath(
      cropPath,
      Paint()
        ..color = Colors.cyanAccent
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    // Draw edge midpoint lines for better alignment
    for (int i = 0; i < 4; i++) {
      final next = (i + 1) % 4;
      final mid = Offset(
        (points[i].dx + points[next].dx) / 2,
        (points[i].dy + points[next].dy) / 2,
      );
      canvas.drawCircle(mid, 4, Paint()..color = Colors.cyanAccent.withValues(alpha: 0.5));
    }

    // Draw corner handles
    for (var p in points) {
      canvas.drawCircle(p, 12, Paint()..color = Colors.white);
      canvas.drawCircle(p, 7, Paint()..color = Colors.cyan);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
