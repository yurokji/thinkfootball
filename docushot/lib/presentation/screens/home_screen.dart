import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:docushot/data/models/document_model.dart';
import 'package:docushot/presentation/providers/document_provider.dart';
import 'package:docushot/presentation/screens/detail_screen.dart';
import 'package:docushot/presentation/screens/custom_camera_screen.dart';
import 'package:docushot/presentation/widgets/document_list_tile.dart';
import 'package:docushot/presentation/widgets/simple_settings_dialog.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool isSelectionMode = false;
  final Set<String> selectedDocIds = {};

  void _toggleSelection(String id) {
    setState(() {
      if (selectedDocIds.contains(id)) {
        selectedDocIds.remove(id);
      } else {
        selectedDocIds.add(id);
      }
      
      if (selectedDocIds.isEmpty) {
        isSelectionMode = false;
      }
    });
  }

  void _showRenameDialog(String docId, String currentTitle) {
    final textController = TextEditingController(text: currentTitle);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Document'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'New Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (textController.text.isNotEmpty) {
                 ref.read(documentControllerProvider).renameDocument(docId, textController.text);
                 Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch document list
    final documentListAsync = ref.watch(documentListProvider);
    final documentController = ref.read(documentControllerProvider);

    // Action State Logic
    final int selectedCount = selectedDocIds.length;
    final bool canExport = selectedCount >= 1;
    final bool canMerge = selectedCount >= 2;
    final bool canDelete = selectedCount >= 1;

    return Scaffold(
      appBar: AppBar(
        title: isSelectionMode 
          ? Text(
              '$selectedCount Selected',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            )
          : Image.asset(
              'assets/images/logo.png',
              height: 28, // Adjust height as needed
              fit: BoxFit.contain,
            ),
        leading: isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    isSelectionMode = false;
                    selectedDocIds.clear();
                  });
                },
              )
            : null,
        actions: [
          // PDF Export Action (Enabled if >= 1 selected)
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            color: canExport ? Theme.of(context).colorScheme.primary : Colors.grey.withValues(alpha: 0.3),
            onPressed: !canExport ? null : () async {
              await documentController.exportMultiplePdfs(selectedDocIds.toList());
              setState(() { isSelectionMode = false; selectedDocIds.clear(); });
            },
          ),
          
          // Merge Action (Enabled if >= 2 selected)
          IconButton(
            icon: const Icon(Icons.merge_type),
            color: canMerge ? Theme.of(context).colorScheme.primary : Colors.grey.withValues(alpha: 0.3),
            tooltip: 'Merge Selected',
            onPressed: !canMerge ? null : () async {
                  await documentController.mergeDocuments(selectedDocIds.toList());
                  setState(() { isSelectionMode = false; selectedDocIds.clear(); });
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Documents merged')));
                  }
              },
          ),

          // Delete Action (Enabled if >= 1 selected) - User mentioned this logic
          // Usually delete is 1+, but if they meant "folder delete" for ANY folder, then context matters.
          // Assuming "Delete selected folders". 
          IconButton(
            icon: const Icon(Icons.delete),
            color: canDelete ? Theme.of(context).colorScheme.error : Colors.grey.withValues(alpha: 0.3), 
            onPressed: !canDelete ? null : () async {
              // Confirmation Dialog
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Documents'),
                  content: Text('Delete ${selectedDocIds.length} document(s)?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                  ],
                ),
              );

              if (confirm == true) {
                final idsToDelete = selectedDocIds.toList();
                for (var id in idsToDelete) {
                  await documentController.deleteDocument(id);
                }
                setState(() { isSelectionMode = false; selectedDocIds.clear(); });
              }
            },
          ),
          
          // Divider or Spacing
          const SizedBox(width: 8),

          // Search
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Placeholder Search
            },
          ),

          // Settings
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              showDialog(
                context: context,
                barrierColor: Colors.transparent, 
                builder: (_) => const SimpleSettingsDialog(),
              );
            },
          ),
        ],
      ),
      body: documentListAsync.when(
        data: (documents) {
          if (documents.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   const Icon(Icons.folder_open, size: 60, color: Colors.grey),
                   const SizedBox(height: 16),
                   Text('No documents yet', style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            );
          }
           return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: documents.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = documents[index];
              final isSelected = selectedDocIds.contains(doc.id);
              return DocumentListTile(
                document: doc,
                index: index, // NEW: Pass index
                isSelectionMode: true, // Always allow selection via checkbox
                isSelected: isSelected,
                onSelectionChanged: (_) => _toggleSelection(doc.id),
                onLongPress: () {
                   // Long press ALWAYS renames now (as checkbox handles selection)
                   _showRenameDialog(doc.id, doc.title);
                },
                onTap: () {
                   // Tap always opens detail (CheckBox handles selection)
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailScreen(document: doc),
                      ),
                    );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: !isSelectionMode ? FloatingActionButton(
        onPressed: () async {
          // Launch Custom Camera
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CustomCameraScreen()),
          );

          if (result != null && result is List && result.isNotEmpty) {
            final newDoc = await documentController.createDocument(initialImages: result);
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailScreen(document: newDoc),
                ),
              );
            }
          }
        },
        child: const Icon(Icons.camera_alt),
      ) : null,
    );
  }
}
