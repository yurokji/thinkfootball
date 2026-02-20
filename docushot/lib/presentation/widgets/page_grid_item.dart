import 'package:flutter/material.dart';
import 'package:docushot/data/models/page_model.dart';
import 'dart:io'; // NEW

class PageGridItem extends StatelessWidget {
  final PageModel page;
  final int index; // Restored
  final VoidCallback onTap; // Restored
  final bool isSelected; // Restored
  final bool isSelectionMode; // Restored
  final VoidCallback? onSelectionToggle;

  const PageGridItem({
    super.key,
    required this.page,
    required this.index,
    required this.onTap,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.onSelectionToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Page Number (Outside, Top-Left)
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            '${index + 1}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // Image & Checkbox Stack
        Expanded(
          child: GestureDetector(
            onTap: onTap, // Tap image to view
            // Long press handled by ReorderableGridView wrapper usually, 
            // but we can pass it up if needed. 
            // The ReorderableGridView uses a Listener on LongPress.
            child: Stack(
              children: [
                Hero(
                  tag: 'page_${page.id}',
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                          : Border.all(color: Colors.transparent, width: 0),
                      boxShadow: isSelected
                          ? [BoxShadow(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3), blurRadius: 8)]
                          : null,
                      image: File(page.imagePath).existsSync()
                          ? DecorationImage(
                              image: FileImage(File(page.imagePath)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: !File(page.imagePath).existsSync()
                        ? const Center(child: Icon(Icons.broken_image, color: Colors.grey))
                        : null,
                  ),
                ),
                // Checkbox Overlay (Inside, Top-Left)
                Positioned(
                  top: 0,
                  left: 0,
                  child: GestureDetector(
                    onTap: onSelectionToggle, // Tap checkbox to toggle
                    behavior: HitTestBehavior.opaque, // Ensure large hit area
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.black54,
                          borderRadius: BorderRadius.circular(4), // Square-ish checkbox
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, size: 16, color: Colors.black)
                            : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
