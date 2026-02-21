import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:docushot/data/models/document_model.dart';
import 'package:docushot/data/models/page_model.dart';
import 'package:docushot/presentation/providers/document_provider.dart';
import 'package:docushot/presentation/providers/premium_provider.dart';
import 'package:docushot/presentation/screens/detail_screen.dart';
import 'package:docushot/presentation/screens/paywall_screen.dart';
import 'package:docushot/data/services/scan_service.dart';
import 'package:docushot/presentation/widgets/document_list_tile.dart';
import 'package:docushot/presentation/widgets/simple_settings_dialog.dart';
import 'package:docushot/l10n/app_localizations.dart';

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
    final l = AppLocalizations.of(context)!;
    final textController = TextEditingController(text: currentTitle);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.rename),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: InputDecoration(labelText: l.newName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () {
              if (textController.text.isNotEmpty) {
                 ref.read(documentControllerProvider).renameDocument(docId, textController.text);
                 Navigator.pop(context);
              }
            },
            child: Text(l.save),
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

    final l = AppLocalizations.of(context)!;

    // Action State Logic
    final int selectedCount = selectedDocIds.length;
    final bool canExport = selectedCount >= 1;
    final bool canMerge = selectedCount >= 2;
    final bool canDelete = selectedCount >= 1;
    final bool isPremium = ref.watch(premiumProvider).isPremium;

    return Scaffold(
      appBar: AppBar(
        title: isSelectionMode
          ? Text(
              l.selected(selectedCount),
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
          // PDF Export Action (Enabled if >= 1 selected, premium only for batch)
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.picture_as_pdf),
                if (!isPremium)
                  const Positioned(right: -4, top: -4, child: Icon(Icons.lock, size: 12, color: Colors.amber)),
              ],
            ),
            color: canExport ? Theme.of(context).colorScheme.primary : Colors.grey.withValues(alpha: 0.3),
            onPressed: !canExport ? null : () async {
              try {
                await documentController.exportMultiplePdfs(selectedDocIds.toList());
                setState(() { isSelectionMode = false; selectedDocIds.clear(); });
              } on PremiumRequiredException {
                if (context.mounted) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen()));
                }
              }
            },
          ),

          // Merge Action (Enabled if >= 2 selected, premium only)
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.merge_type),
                if (!isPremium)
                  const Positioned(right: -4, top: -4, child: Icon(Icons.lock, size: 12, color: Colors.amber)),
              ],
            ),
            color: canMerge ? Theme.of(context).colorScheme.primary : Colors.grey.withValues(alpha: 0.3),
            tooltip: l.mergeSelected,
            onPressed: !canMerge ? null : () async {
                  try {
                    await documentController.mergeDocuments(selectedDocIds.toList());
                    setState(() { isSelectionMode = false; selectedDocIds.clear(); });
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.documentsMerged)));
                    }
                  } on PremiumRequiredException {
                    if (context.mounted) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen()));
                    }
                  }
              },
          ),

          // Delete Action (Enabled if >= 1 selected)
          IconButton(
            icon: const Icon(Icons.delete),
            color: canDelete ? Theme.of(context).colorScheme.error : Colors.grey.withValues(alpha: 0.3),
            onPressed: !canDelete ? null : () async {
              // Confirmation Dialog
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(l.deleteDocuments),
                  content: Text(l.deleteDocumentsConfirm(selectedDocIds.length)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.delete, style: const TextStyle(color: Colors.red))),
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
            onPressed: () async {
              final docs = documentListAsync.value ?? [];
              final repository = ref.read(documentRepositoryProvider);
              // Pre-load all pages for search (async → sync lookup)
              final pagesMap = <String, List<PageModel>>{};
              for (final doc in docs) {
                pagesMap[doc.id] = await repository.getPagesForDocumentAsync(doc.id);
              }
              if (!mounted) return;
              showSearch(
                context: context,
                delegate: _DocumentSearchDelegate(
                  documents: docs,
                  pagesMap: pagesMap,
                  searchLabel: l.searchDocuments,
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
                   Text(l.noDocuments, style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                   const SizedBox(height: 8),
                   Text(l.noDocumentsHint, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
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
                index: index,
                isSelectionMode: true,
                isSelected: isSelected,
                onSelectionChanged: (_) => _toggleSelection(doc.id),
                onLongPress: () {
                   _showRenameDialog(doc.id, doc.title);
                },
                onTap: () {
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
        error: (err, stack) => Center(child: Text(l.errorGeneric(err.toString()))),
      ),
      floatingActionButton: !isSelectionMode ? FloatingActionButton.extended(
        icon: const Icon(Icons.camera_alt),
        label: Text(l.scan),
        onPressed: () async {
          // Launch ML Kit Document Scanner
          try {
            final scanService = ref.read(scanServiceProvider);
            final images = await scanService.scanDocuments();

            if (images.isNotEmpty) {
              final newDoc = await documentController.createDocument(initialImages: images);
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetailScreen(document: newDoc),
                  ),
                );
              }
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l.scannerError(e.toString()))),
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
  final Map<String, List<PageModel>> pagesMap;
  final void Function(DocumentModel doc) onSelect;

  _DocumentSearchDelegate({
    required this.documents,
    required this.pagesMap,
    required String searchLabel,
    required this.onSelect,
  }) : super(searchFieldLabel: searchLabel);

  List<DocumentModel> _filter(String query) {
    if (query.isEmpty) return documents;
    final lower = query.toLowerCase();
    return documents.where((doc) {
      // Match title
      if (doc.title.toLowerCase().contains(lower)) return true;
      // Match OCR text in pages
      final pages = pagesMap[doc.id] ?? [];
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
        child: Text(AppLocalizations.of(context)!.noDocumentsFound, style: TextStyle(color: Colors.grey[500])),
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
          final pages = pagesMap[doc.id] ?? [];
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
              Text(AppLocalizations.of(context)!.pages(pageCount), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
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
