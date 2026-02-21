import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:docushot/data/models/document_model.dart';
import 'package:docushot/data/models/page_model.dart';
import 'package:docushot/presentation/providers/document_provider.dart';
import 'package:docushot/presentation/providers/premium_provider.dart';
import 'package:docushot/presentation/widgets/page_grid_item.dart';
import 'package:docushot/presentation/screens/perspective_crop_screen.dart';
import 'package:docushot/presentation/screens/page_viewer_screen.dart';
import 'package:docushot/presentation/screens/paywall_screen.dart';
import 'package:docushot/l10n/app_localizations.dart';
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
    final l = AppLocalizations.of(context)!;
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
                final allPages = ref.read(documentPagesProvider(widget.document.id)).value ?? [];
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
                    title: Text(l.deletePages),
                    content: Text(l.deletePagesConfirm(selectedPageIds.length)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.delete, style: const TextStyle(color: Colors.red))),
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
                final count = await controller.importImagesFromGallery(widget.document.id);
                if (count > 0 && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.imagesAdded(count))),
                  );
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.add_a_photo), // Camera
              onPressed: () async {
                  try {
                    final scanService = ref.read(scanServiceProvider);
                    final images = await scanService.scanDocuments();
                    if (images.isNotEmpty) {
                      await controller.addPagesToDocument(widget.document.id, images);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l.scannerError(e.toString()))),
                      );
                    }
                  }
              },
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.share),
              onSelected: (value) async {
                try {
                  switch (value) {
                    case 'pdf':
                      await controller.exportPdf(widget.document.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l.exportPdfSuccess)),
                        );
                      }
                      break;
                    case 'zip':
                      await controller.exportZip(widget.document.id);
                      break;
                    case 'images':
                      final pages = ref.read(documentPagesProvider(widget.document.id)).value ?? [];
                      if (pages.isNotEmpty) {
                        await controller.shareImages(pages.map((p) => p.imagePath).toList());
                      }
                      break;
                  }
                } on PremiumRequiredException {
                  if (context.mounted) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen()));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l.shareError(e.toString()))),
                    );
                  }
                }
              },
              itemBuilder: (ctx) {
                final isPremium = ref.read(premiumProvider).isPremium;
                return [
                  PopupMenuItem(value: 'pdf', child: ListTile(leading: const Icon(Icons.picture_as_pdf), title: Text(l.exportPdf), dense: true)),
                  PopupMenuItem(value: 'zip', child: ListTile(
                    leading: const Icon(Icons.folder_zip),
                    title: Text(l.exportZip),
                    trailing: isPremium ? null : const Icon(Icons.lock, size: 16, color: Colors.amber),
                    dense: true,
                  )),
                  PopupMenuItem(value: 'images', child: ListTile(leading: const Icon(Icons.image), title: Text(l.shareImages), dense: true)),
                ];
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(l.deleteDocument),
                    content: Text(l.deleteDocumentConfirm),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.delete, style: const TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                if (confirm == true) {
                  await controller.deleteDocument(widget.document.id);
                  if (context.mounted) Navigator.pop(context);
                }
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
                child: Text(l.selected(selectedPageIds.length)),
              ),
             ),
          Expanded(
            child: pagesAsync.when(
              data: (pages) {
                if (pages.isEmpty) {
                   return Center(
                     child: Column(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         Icon(Icons.note_add, size: 48, color: Colors.grey[600]),
                         const SizedBox(height: 16),
                         Text(l.noPagesYet, style: TextStyle(color: Colors.grey[500], fontSize: 15)),
                         const SizedBox(height: 6),
                         Text(l.noPagesHint, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                       ],
                     ),
                   );
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
                                  onRunOcr: (pageId) => controller.runOcr(pageId),
                                  onDeletePage: (pageId) => controller.deletePage(widget.document.id, pageId),
                                  ocrRemaining: ref.read(premiumProvider).ocrRemaining,
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
              error: (err, stack) => Center(child: Text(l.errorGeneric(err.toString()))),
            ),
          ),
        ],
      ),
    );
  }
}
