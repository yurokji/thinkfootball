import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:docushot/data/models/document_model.dart';
import 'package:docushot/data/models/page_model.dart';
import 'package:docushot/presentation/providers/document_provider.dart';
import 'package:docushot/presentation/widgets/page_grid_item.dart'; // Restored
import 'package:docushot/presentation/screens/custom_camera_screen.dart'; 
import 'package:docushot/presentation/screens/perspective_crop_screen.dart';
import 'package:docushot/presentation/screens/page_viewer_screen.dart';
import 'dart:io';

class DetailScreen extends ConsumerStatefulWidget {
  final DocumentModel document;

  const DetailScreen({super.key, required this.document});

  @override
  ConsumerState<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends ConsumerState<DetailScreen> {
  bool isSelectionMode = false;
  Set<String> selectedPageIds = {};

  void _onReorder(int oldIndex, int newIndex) {
     ref.read(documentControllerProvider).reorderPages(widget.document.id, oldIndex, newIndex);
  }

  void _toggleSelection(String pageId) {
    setState(() {
      if (selectedPageIds.contains(pageId)) {
        selectedPageIds.remove(pageId);
        if (selectedPageIds.isEmpty) isSelectionMode = false;
      } else {
        selectedPageIds.add(pageId);
        isSelectionMode = true;
      }
    });
  }

  Future<void> _cropImage(PageModel page) async {
    final originalPath = page.originalImagePath ?? page.imagePath;
    
    // Check if file exists to avoid crashes
    if (!File(originalPath).existsSync()) {
       // Warn user?
       return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PerspectiveCropScreen(
          imagePath: originalPath,
          initialCorners: page.cropCorners, // Pass saved corners
        ),
      ),
    );

    if (result != null && result is Map) {
      final path = result['path'] as String;
      final corners = result['corners'] as List<double>?;
      
      ref.read(documentControllerProvider).updatePageImage(
        page.id, 
        path,
        cropCorners: corners,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pagesAsync = ref.watch(documentPagesProvider(widget.document.id));
    final controller = ref.read(documentControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.document.title),
        actions: [
          if (isSelectionMode) ...[
             // ... existing selection actions ...
             IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: () {
                // Export selected pages
                controller.exportPdf(widget.document.id, pageIds: selectedPageIds.toList());
                // Exit selection mode
                setState(() {
                  isSelectionMode = false;
                  selectedPageIds.clear();
                });
              },
            ),
             IconButton(
              icon: const Icon(Icons.share),
              onPressed: () async {
                final allPages = ref.read(documentPagesProvider(widget.document.id)).valueOrNull ?? [];
                final selectedPages = allPages.where((p) => selectedPageIds.contains(p.id)).toList();
                if (selectedPages.isNotEmpty) {
                  final paths = selectedPages.map((p) => p.imagePath).toList();
                  await controller.shareImages(paths);
                }
                setState(() {
                  isSelectionMode = false;
                  selectedPageIds.clear();
                });
              },
            ),
             IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Pages'),
                    content: Text('Delete ${selectedPageIds.length} page(s)?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                if (confirm == true) {
                  for (var pageId in selectedPageIds.toList()) {
                    await controller.deletePage(widget.document.id, pageId);
                  }
                  setState(() {
                    isSelectionMode = false;
                    selectedPageIds.clear();
                  });
                }
              },
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.image), // Import
              onPressed: () async {
                 await controller.importImagesFromGallery(widget.document.id);
              },
            ),
            IconButton(
              icon: const Icon(Icons.add_a_photo), // Camera
              onPressed: () async {
                  // Launch Custom Camera
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CustomCameraScreen()),
                  );
                  if (result != null && result is List && result.isNotEmpty) {
                    await controller.addPagesToDocument(widget.document.id, result);
                  }
              },
            ),
            // ... other actions ...
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: () {
                // Export ALL pages
                controller.exportPdf(widget.document.id);
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
              onPressed: () {
                controller.deleteDocument(widget.document.id).then((_) {
                  Navigator.pop(context);
                });
              },
            ),
          ]
        ],
      ),
      body: Column(
        children: [
          if (isSelectionMode)
             Container(
              color: Colors.black12,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Text('${selectedPageIds.length} Selected'),
              ),
             ),
          Expanded(
            child: pagesAsync.when(
              data: (pages) {
                if (pages.isEmpty) {
                   return Center(child: Text('No pages yet. Tap + to add.', style: TextStyle(color: Colors.grey[500])));
                }
                return ReorderableGridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  padding: const EdgeInsets.all(16),
                  // Disable reorder when in selection mode to avoid conflicts
                  onReorder: isSelectionMode ? (_, __) {} : _onReorder,
                  children: pages.map((page) {
                    return Container(
                      key: ValueKey(page.id),
                      child: GestureDetector(
                        onDoubleTap: () => _cropImage(page), // Double tap to Re-edit
                        child: PageGridItem(
                          page: page,
                          index: pages.indexOf(page),
                          isSelected: selectedPageIds.contains(page.id),
                          isSelectionMode: isSelectionMode,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PageViewerScreen(
                                  pages: pages,
                                  initialIndex: pages.indexOf(page),
                                  onPageUpdated: (pageId, newPath, {cropCorners, filterType}) {
                                    controller.updatePageImage(pageId, newPath, cropCorners: cropCorners, filterType: filterType);
                                  },
                                ),
                              ),
                            );
                          },
                          onSelectionToggle: () => _toggleSelection(page.id),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
