import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:docushot/core/image/image_processor.dart';
import 'package:docushot/presentation/providers/premium_provider.dart';
import 'package:docushot/presentation/screens/paywall_screen.dart';
import 'package:docushot/l10n/app_localizations.dart';

class EnhanceScreen extends ConsumerStatefulWidget {
  final String imagePath;
  final String originalPath;
  final bool isManualMode;
  final Function(String) onDone;
  final Function(int)? onApplyToAll;
  final int initialFilter;

  const EnhanceScreen({
    super.key,
    required this.imagePath,
    required this.originalPath,
    required this.isManualMode,
    required this.onDone,
    this.onApplyToAll,
    this.initialFilter = 0,
  });

  @override
  ConsumerState<EnhanceScreen> createState() => _EnhanceScreenState();
}

class _EnhanceScreenState extends ConsumerState<EnhanceScreen> {
  late String _currentDisplayPath;
  late String _filterBasePath; // Path after filter, before manual adjustments
  int _selectedFilter = 0; // 0=Original, 1=Magic, 2=B/W, 3=Lighten
  bool _isProcessing = false;
  double _brightness = 1.0;
  double _contrast = 1.0;
  bool _showSliders = false;

  @override
  void initState() {
    super.initState();
    _currentDisplayPath = widget.imagePath;
    _filterBasePath = widget.imagePath;
    // Auto-apply recommended filter from document type config
    if (widget.initialFilter > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _applyFilter(widget.initialFilter);
      });
    }
  }

  Future<void> _applyFilter(int filterType) async {
    if (filterType == 0) {
      setState(() {
        _selectedFilter = 0;
        _currentDisplayPath = widget.imagePath;
        _filterBasePath = widget.imagePath;
        _brightness = 1.0;
        _contrast = 1.0;
      });
      return;
    }

    // Premium filters: Magic Color (1) and Lighten (3). B&W (2) is free.
    if (filterType == 1 || filterType == 3) {
      final premium = ref.read(premiumProvider);
      if (!premium.hasAllFilters) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen()));
        return;
      }
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
          _filterBasePath = newPath;
          _brightness = 1.0;
          _contrast = 1.0;
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.filterError(e.toString()))),
        );
      }
    }
  }

  Future<void> _applyManualAdjustments() async {
    if (_brightness == 1.0 && _contrast == 1.0) return;

    setState(() => _isProcessing = true);

    try {
      final newPath = await ImageProcessor.applyAdjustments(
        _filterBasePath,
        brightness: _brightness,
        contrast: _contrast,
      );
      if (mounted) {
        setState(() {
          _currentDisplayPath = newPath;
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.adjustmentError(e.toString()))),
        );
      }
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
          title: Text(AppLocalizations.of(context)!.enhanceTitle, style: const TextStyle(color: Colors.white, fontSize: 16, letterSpacing: 1.2)),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: Icon(
                Icons.tune,
                color: _showSliders ? Colors.cyanAccent : Colors.white70,
              ),
              onPressed: () => setState(() => _showSliders = !_showSliders),
            ),
            TextButton(
              onPressed: _onDone,
              child: Text(AppLocalizations.of(context)!.done, style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
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

            // 2. Manual Adjustments (expandable)
            if (_showSliders)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                color: const Color(0xFF2A2A2A),
                child: Column(
                  children: [
                    _buildSlider(
                      label: AppLocalizations.of(context)!.brightness,
                      icon: Icons.brightness_6,
                      value: _brightness,
                      min: 0.5,
                      max: 2.0,
                      onChanged: (v) => setState(() => _brightness = v),
                      onChangeEnd: (_) => _applyManualAdjustments(),
                    ),
                    _buildSlider(
                      label: AppLocalizations.of(context)!.contrast,
                      icon: Icons.contrast,
                      value: _contrast,
                      min: 0.5,
                      max: 2.0,
                      onChanged: (v) => setState(() => _contrast = v),
                      onChangeEnd: (_) => _applyManualAdjustments(),
                    ),
                  ],
                ),
              ),

            // 3. Filter Carousel
            Container(
              height: 140,
              padding: const EdgeInsets.symmetric(vertical: 20),
              color: const Color(0xFF1E1E1E),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                   _buildFilterItem(0, AppLocalizations.of(context)!.original, Icons.image, false),
                   const SizedBox(width: 20),
                   _buildFilterItem(1, AppLocalizations.of(context)!.magicColor, Icons.auto_fix_high, !ref.watch(premiumProvider).hasAllFilters),
                   const SizedBox(width: 20),
                   _buildFilterItem(2, AppLocalizations.of(context)!.bw, Icons.contrast, false),
                   const SizedBox(width: 20),
                   _buildFilterItem(3, AppLocalizations.of(context)!.lighten, Icons.light_mode, !ref.watch(premiumProvider).hasAllFilters),
                ],
              ),
            ),
          ],
        ));
  }

  Widget _buildSlider({
    required String label,
    required IconData icon,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required ValueChanged<double> onChangeEnd,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 18),
        const SizedBox(width: 8),
        SizedBox(
          width: 60,
          child: Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: Colors.cyanAccent,
              inactiveTrackColor: Colors.grey[700],
              thumbColor: Colors.cyanAccent,
              overlayColor: Colors.cyanAccent.withValues(alpha: 0.2),
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
              onChangeEnd: onChangeEnd,
            ),
          ),
        ),
        SizedBox(
          width: 36,
          child: Text(
            value.toStringAsFixed(1),
            style: const TextStyle(color: Colors.white54, fontSize: 11),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterItem(int type, String label, IconData icon, bool locked) {
    final bool isSelected = _selectedFilter == type;
    return GestureDetector(
      onTap: () => _applyFilter(type),
      child: Column(
        children: [
          Stack(
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
              if (locked)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.amber),
                    child: const Icon(Icons.lock, size: 12, color: Colors.black),
                  ),
                ),
            ],
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
