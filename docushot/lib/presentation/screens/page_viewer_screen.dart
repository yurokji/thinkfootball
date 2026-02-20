import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:docushot/data/models/page_model.dart';
import 'package:docushot/presentation/screens/perspective_crop_screen.dart';
import 'package:docushot/presentation/screens/enhance_screen.dart';

class PageViewerScreen extends StatefulWidget {
  final List<PageModel> pages;
  final int initialIndex;
  final void Function(String pageId, String newPath, {List<double>? cropCorners, int? filterType})? onPageUpdated;
  final Future<String> Function(String pageId)? onRunOcr;

  const PageViewerScreen({
    super.key,
    required this.pages,
    this.initialIndex = 0,
    this.onPageUpdated,
    this.onRunOcr,
  });

  @override
  State<PageViewerScreen> createState() => _PageViewerScreenState();
}

class _PageViewerScreenState extends State<PageViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _pageController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  PageModel get _currentPage => widget.pages[_currentIndex];

  Future<void> _openCrop() async {
    final page = _currentPage;
    final originalPath = page.originalImagePath ?? page.imagePath;

    if (!File(originalPath).existsSync()) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PerspectiveCropScreen(
          imagePath: originalPath,
          initialCorners: page.cropCorners,
        ),
      ),
    );

    if (result != null && result is Map) {
      final path = result['path'] as String;
      final corners = result['corners'] as List<double>?;
      widget.onPageUpdated?.call(page.id, path, cropCorners: corners);
      setState(() {});
    }
  }

  Future<void> _openEnhance() async {
    final page = _currentPage;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EnhanceScreen(
          imagePath: page.imagePath,
          originalPath: page.originalImagePath ?? page.imagePath,
          isManualMode: true,
          onDone: (path) {
            widget.onPageUpdated?.call(page.id, path);
            setState(() {});
          },
        ),
      ),
    );
  }

  Future<void> _showOcrText() async {
    final page = _currentPage;
    String? text = page.ocrText;

    // If no cached text, run OCR
    if ((text == null || text.isEmpty) && widget.onRunOcr != null) {
      // Show loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.white)),
      );

      text = await widget.onRunOcr!(page.id);

      if (mounted) Navigator.pop(context); // dismiss loading
    }

    if (!mounted) return;

    if (text == null || text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No text recognized on this page')),
      );
      return;
    }

    // Show bottom sheet with recognized text
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recognized Text', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.white70),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: text!));
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Text copied to clipboard')),
                        );
                      }
                    },
                  ),
                ],
              ),
              const Divider(color: Colors.white24),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: SelectableText(
                    text!,
                    style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        child: Stack(
          children: [
            // Image PageView with pinch zoom
            PageView.builder(
              controller: _pageController,
              itemCount: widget.pages.length,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemBuilder: (context, index) {
                final page = widget.pages[index];
                return InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: Image.file(
                      File(page.imagePath),
                      key: ValueKey(page.imagePath),
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              },
            ),

            // Top bar
            if (_showControls)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Spacer(),
                          Text(
                            '${_currentIndex + 1} / ${widget.pages.length}',
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          const Spacer(),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Bottom action bar
            if (_showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _ActionButton(
                            icon: Icons.crop,
                            label: 'Crop',
                            onTap: _openCrop,
                          ),
                          _ActionButton(
                            icon: Icons.auto_fix_high,
                            label: 'Enhance',
                            onTap: _openEnhance,
                          ),
                          _ActionButton(
                            icon: Icons.text_snippet,
                            label: 'OCR Text',
                            onTap: _showOcrText,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.15),
              border: Border.all(color: Colors.white30),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}
