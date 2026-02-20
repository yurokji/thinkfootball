import 'dart:io';
import 'package:flutter/material.dart';
import 'package:docushot/core/image/image_processor.dart';

class EnhanceScreen extends StatefulWidget {
  final String imagePath;
  final String originalPath;
  final bool isManualMode;
  final Function(String) onDone;
  final Function(int)? onApplyToAll;

  const EnhanceScreen({
    super.key, 
    required this.imagePath,
    required this.originalPath,
    required this.isManualMode,
    required this.onDone,
    this.onApplyToAll,
  });

  @override
  State<EnhanceScreen> createState() => _EnhanceScreenState();
}

class _EnhanceScreenState extends State<EnhanceScreen> {
  late String _currentDisplayPath;
  int _selectedFilter = 0; // 0=Original, 1=Magic, 2=B/W, 3=Lighten
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _currentDisplayPath = widget.imagePath;
  }

  Future<void> _applyFilter(int filterType) async {
    if (filterType == 0) {
      setState(() {
        _selectedFilter = 0;
        _currentDisplayPath = widget.imagePath;
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _selectedFilter = filterType;
    });

    try {
      // Apply filter to the CROPPED image (imagePath), not the raw original
      final newPath = await ImageProcessor.applyFilter(widget.imagePath, filterType);

      if (mounted) {
        setState(() {
          _currentDisplayPath = newPath;
          _isProcessing = false;
        });
      }
    } catch (e) {
      debugPrint("Filter error: $e");
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _onDone() {
    widget.onDone(_currentDisplayPath);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text('ENHANCE', style: TextStyle(color: Colors.white, fontSize: 16, letterSpacing: 1.2)),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            TextButton(
              onPressed: _onDone,
              child: const Text('DONE', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
            )
          ],
        ),
        body: Column(
          children: [
            // 1. Image Preview
            Expanded(
              child: Center(
                child: _isProcessing
                  ? const CircularProgressIndicator(color: Colors.cyanAccent)
                  : Image.file(
                      File(_currentDisplayPath),
                      key: ValueKey(_currentDisplayPath + _selectedFilter.toString()),
                      fit: BoxFit.contain,
                    ),
              ),
            ),

            // 2. Filter Carousel
            Container(
              height: 140,
              padding: const EdgeInsets.symmetric(vertical: 20),
              color: const Color(0xFF1E1E1E),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                   _buildFilterItem(0, "Original", Icons.image),
                   const SizedBox(width: 20),
                   _buildFilterItem(1, "Magic Color", Icons.auto_fix_high),
                   const SizedBox(width: 20),
                   _buildFilterItem(2, "B & W", Icons.contrast),
                   const SizedBox(width: 20),
                   _buildFilterItem(3, "Lighten", Icons.light_mode),
                ],
              ),
            ),
          ],
        ));
  }

  Widget _buildFilterItem(int type, String label, IconData icon) {
    final bool isSelected = _selectedFilter == type;
    return GestureDetector(
      onTap: () => _applyFilter(type),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.cyanAccent : Colors.grey.shade800,
                width: 2
              ),
              color: isSelected ? Colors.cyanAccent.withValues(alpha: 0.1) : Colors.transparent,
            ),
            child: Icon(icon, color: isSelected ? Colors.cyanAccent : Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(
            color: isSelected ? Colors.cyanAccent : Colors.white60,
            fontSize: 12
          ))
        ],
      ),
    );
  }
}
