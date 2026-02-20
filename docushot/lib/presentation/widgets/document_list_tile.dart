import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:docushot/data/models/document_model.dart';
import 'dart:io'; // NEW

class DocumentListTile extends StatelessWidget {
  final DocumentModel document; // Restored
  final int index; // NEW: Display index
  final VoidCallback onTap;
  final bool isSelected;
  final bool isSelectionMode;
  final ValueChanged<bool?>? onSelectionChanged;
  final VoidCallback? onLongPress;

  const DocumentListTile({
    super.key,
    required this.document,
    required this.index, // NEW
    required this.onTap,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.onSelectionChanged,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('yyyy. MM. dd. HH:mm');

    return ListTile(
      // Main Tap: View Document
      onTap: onTap, 
      // Long Press: Rename (if provided)
      onLongPress: onLongPress,
      
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center, // Center vertically
        children: [
          // Index Number (Outside, Left)
          SizedBox(
            width: 24, // Fixed width for alignment
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: Colors.grey[400],
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Thumbnail with Checkbox Overlay -> Tap toggles selection
          GestureDetector(
            onTap: () => onSelectionChanged?.call(!isSelected),
           // Thumbnail with Checkbox Overlay
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Hero(
                tag: 'doc_thumb_${document.id}',
                child: Container(
                  width: 50,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(4),
                    border: isSelected
                        ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                        : Border.all(color: Colors.white12),
                    image: document.thumbnailPath != null && File(document.thumbnailPath!).existsSync()
                        ? DecorationImage(
                            image: FileImage(File(document.thumbnailPath!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: document.thumbnailPath == null
                      ? const Icon(Icons.description, color: Colors.white24)
                      : null,
                ),
              ),
              // Checkbox Overlay (Inside, Top-Left)
              Positioned(
                top: 2,
                left: 2,
                child: GestureDetector(
                  onTap: () => onSelectionChanged?.call(!isSelected),
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: isSelected ? Theme.of(context).colorScheme.primary : Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 14, color: Colors.black)
                        : null,
                  ),
                ),
              ),
            ],
          ),
          ),
        ],
      ),
      title: Text(
        document.title,
        style: const TextStyle(fontWeight: FontWeight.bold),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            dateFormatter.format(document.createdAt),
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12),
          ),
        ],
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter, size: 12, color: Theme.of(context).colorScheme.secondary), // Document Icon
            const SizedBox(width: 4),
            Text(
              '${document.pageIds.length}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
