import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:docushot/data/models/document_model.dart';
import 'package:docushot/data/repositories/document_repository.dart';
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
              final docs = documentListAsync.valueOrNull ?? [];
              final repository = ref.read(documentRepositoryProvider);
              showSearch(
                context: context,
                delegate: _DocumentSearchDelegate(
                  documents: docs,
                  repository: repository,
                  onSelect: (doc) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => DetailScreen(document: doc)),
                    );
                  },
                ),
              );
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
                   Container(
                     width: 100,
                     height: 100,
                     decoration: BoxDecoration(
                       shape: BoxShape.circle,
                       color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                     ),
                     child: Icon(Icons.document_scanner, size: 48, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
                   ),
                   const SizedBox(height: 24),
                   Text('No documents yet', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                   const SizedBox(height: 8),
                   Text('Tap the camera button to scan', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
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
      floatingActionButton: !isSelectionMode ? FloatingActionButton.extended(
        icon: const Icon(Icons.camera_alt),
        label: const Text('Scan'),
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
      ) : null,
    );
  }
}

// --- Search Delegate ---

class _DocumentSearchDelegate extends SearchDelegate<DocumentModel?> {
  final List<DocumentModel> documents;
  final DocumentRepository repository;
  final void Function(DocumentModel doc) onSelect;

  _DocumentSearchDelegate({
    required this.documents,
    required this.repository,
    required this.onSelect,
  }) : super(searchFieldLabel: 'Search documents...');

  List<DocumentModel> _filter(String query) {
    if (query.isEmpty) return documents;
    final lower = query.toLowerCase();
    return documents.where((doc) {
      // Match title
      if (doc.title.toLowerCase().contains(lower)) return true;
      // Match OCR text in pages
      final pages = repository.getPagesForDocument(doc.id);
      for (var page in pages) {
        if (page.ocrText != null && page.ocrText!.toLowerCase().contains(lower)) {
          return true;
        }
      }
      return false;
    }).toList();
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final results = _filter(query);
    if (results.isEmpty) {
      return Center(
        child: Text('No documents found', style: TextStyle(color: Colors.grey[500])),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final doc = results[index];
        final pageCount = doc.pageIds.length;
        // Find OCR match snippet
        String? ocrSnippet;
        if (query.isNotEmpty) {
          final lower = query.toLowerCase();
          final pages = repository.getPagesForDocument(doc.id);
          for (var page in pages) {
            if (page.ocrText != null && page.ocrText!.toLowerCase().contains(lower)) {
              final idx = page.ocrText!.toLowerCase().indexOf(lower);
              final start = (idx - 30).clamp(0, page.ocrText!.length);
              final end = (idx + query.length + 30).clamp(0, page.ocrText!.length);
              ocrSnippet = '...${page.ocrText!.substring(start, end)}...';
              break;
            }
          }
        }
        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 48,
              height: 48,
              child: doc.thumbnailPath != null && File(doc.thumbnailPath!).existsSync()
                  ? Image.file(File(doc.thumbnailPath!), fit: BoxFit.cover)
                  : Container(color: Colors.grey[300], child: const Icon(Icons.description, color: Colors.grey)),
            ),
          ),
          title: Text(doc.title),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$pageCount page${pageCount == 1 ? '' : 's'}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              if (ocrSnippet != null)
                Text(
                  ocrSnippet,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: Colors.blue[300], fontStyle: FontStyle.italic),
                ),
            ],
          ),
          onTap: () {
            close(context, doc);
            onSelect(doc);
          },
        );
      },
    );
  }
}
