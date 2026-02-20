import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:docushot/presentation/providers/settings_provider.dart';
import 'package:docushot/presentation/screens/onboarding_screen.dart';
import 'package:docushot/data/services/ocr_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildSectionHeader(context, 'Appearance'),
          ListTile(
            title: const Text('Theme'),
            subtitle: Text(
              settings.themeMode == ThemeMode.dark ? 'Dark' : (settings.themeMode == ThemeMode.light ? 'Light' : 'System'),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => SimpleDialog(
                  title: const Text('Choose Theme'),
                  children: [
                    SimpleDialogOption(
                      onPressed: () { notifier.setThemeMode(ThemeMode.light); Navigator.pop(ctx); },
                      child: const Text('Light'),
                    ),
                    SimpleDialogOption(
                      onPressed: () { notifier.setThemeMode(ThemeMode.dark); Navigator.pop(ctx); },
                      child: const Text('Dark'),
                    ),
                    SimpleDialogOption(
                      onPressed: () { notifier.setThemeMode(ThemeMode.system); Navigator.pop(ctx); },
                      child: const Text('System Default'),
                    ),
                  ],
                ),
              );
            },
          ),

          _buildSectionHeader(context, 'Camera'),
          ListTile(
            title: const Text('Image Quality'),
            subtitle: Text(settings.imageQuality),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              final next = settings.imageQuality == 'High' ? 'Medium' : 'High';
              notifier.setImageQuality(next);
            },
          ),
          SwitchListTile(
            title: const Text('Auto Crop'),
            subtitle: const Text('Automatically crop scanned documents'),
            value: settings.autoCrop,
            onChanged: (v) => notifier.setAutoCrop(v),
            activeColor: Theme.of(context).colorScheme.primary,
          ),

          _buildSectionHeader(context, 'OCR'),
          ListTile(
            title: const Text('OCR Language'),
            subtitle: Text(OcrService.supportedScripts[OcrService.scriptFromName(settings.ocrLanguage)] ?? 'English / Latin'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => SimpleDialog(
                  title: const Text('OCR Language'),
                  children: OcrService.supportedScripts.entries.map((entry) {
                    final name = OcrService.scriptToName(entry.key);
                    return SimpleDialogOption(
                      onPressed: () {
                        notifier.setOcrLanguage(name);
                        Navigator.pop(ctx);
                      },
                      child: Row(
                        children: [
                          if (settings.ocrLanguage == name)
                            Icon(Icons.check, size: 18, color: Theme.of(context).colorScheme.primary)
                          else
                            const SizedBox(width: 18),
                          const SizedBox(width: 12),
                          Text(entry.value),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),

          _buildSectionHeader(context, 'About'),
          const ListTile(
            title: Text('Version'),
            subtitle: Text('1.0.0'),
          ),
          ListTile(
            title: const Text('Show Tutorial'),
            subtitle: const Text('View the onboarding guide again'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Hive.box('settings').put('onboarding_complete', false);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                (_) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
