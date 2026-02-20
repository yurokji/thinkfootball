import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:docushot/app.dart';
import 'package:docushot/data/models/document_model.dart';
import 'package:docushot/data/models/page_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Adapters
  Hive.registerAdapter(DocumentModelAdapter());
  Hive.registerAdapter(PageModelAdapter());

  // Open Boxes
  await Hive.openBox<DocumentModel>('documents');
  await Hive.openBox<PageModel>('pages');
  await Hive.openBox('settings');

  runApp(
    const ProviderScope(
      child: DocushotApp(),
    ),
  );
}
