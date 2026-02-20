import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:share_plus/share_plus.dart';
import 'package:docushot/presentation/providers/settings_provider.dart';
import 'package:docushot/presentation/providers/document_provider.dart';
import 'package:docushot/presentation/screens/onboarding_screen.dart';
import 'package:docushot/data/services/ocr_service.dart';
import 'package:docushot/presentation/providers/premium_provider.dart';
import 'package:docushot/presentation/screens/paywall_screen.dart';

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
            title: const Text('Language'),
            subtitle: Text(_localeDisplayName(settings.locale)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => SimpleDialog(
                  title: const Text('Language'),
                  children: [
                    _localeOption(ctx, notifier, settings.locale, 'en', 'English'),
                    _localeOption(ctx, notifier, settings.locale, 'ko', '한국어'),
                    _localeOption(ctx, notifier, settings.locale, 'ja', '日本語'),
                  ],
                ),
              );
            },
          ),
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

          _buildSectionHeader(context, 'Backup'),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('Create Backup'),
            subtitle: const Text('Export all documents as a ZIP file'),
            onTap: () async {
              final backup = ref.read(backupServiceProvider);
              // Show progress dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const AlertDialog(
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 20),
                      Text('Creating backup...'),
                    ],
                  ),
                ),
              );

              final path = await backup.createBackup();

              if (context.mounted) Navigator.pop(context); // dismiss progress

              if (path != null && context.mounted) {
                // Share the backup file
                await Share.shareXFiles([XFile(path)], subject: 'Docushot Backup');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Backup created and shared')),
                  );
                }
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Backup failed')),
                );
              }
            },
          ),

          _buildSectionHeader(context, 'Subscription'),
          ListTile(
            leading: Icon(
              ref.watch(premiumProvider).isPremium ? Icons.verified : Icons.workspace_premium,
              color: Colors.amber,
            ),
            title: Text(ref.watch(premiumProvider).isPremium ? 'Premium Active' : 'Upgrade to Premium'),
            subtitle: Text(ref.watch(premiumProvider).isPremium ? 'All features unlocked' : 'Unlock all features'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen()));
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

  String _localeDisplayName(String locale) {
    switch (locale) {
      case 'ko': return '한국어';
      case 'ja': return '日本語';
      default: return 'English';
    }
  }

  Widget _localeOption(BuildContext ctx, SettingsNotifier notifier, String current, String code, String label) {
    return SimpleDialogOption(
      onPressed: () {
        notifier.setLocale(code);
        Navigator.pop(ctx);
      },
      child: Row(
        children: [
          if (current == code)
            Icon(Icons.check, size: 18, color: Theme.of(ctx).colorScheme.primary)
          else
            const SizedBox(width: 18),
          const SizedBox(width: 12),
          Text(label),
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
