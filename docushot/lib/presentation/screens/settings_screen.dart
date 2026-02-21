import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:docushot/presentation/providers/settings_provider.dart';
import 'package:docushot/presentation/providers/document_provider.dart';
import 'package:docushot/presentation/screens/onboarding_screen.dart';
import 'package:docushot/data/services/ocr_service.dart';
import 'package:docushot/presentation/providers/premium_provider.dart';
import 'package:docushot/presentation/screens/paywall_screen.dart';
import 'package:docushot/l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.settings),
      ),
      body: ListView(
        children: [
          _buildSectionHeader(context, l.appearance),
          ListTile(
            title: Text(l.language),
            subtitle: Text(_localeDisplayName(settings.locale)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => SimpleDialog(
                  title: Text(l.language),
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
            title: Text(l.theme),
            subtitle: Text(
              settings.themeMode == ThemeMode.dark ? l.themeDark : (settings.themeMode == ThemeMode.light ? l.themeLight : l.themeSystem),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => SimpleDialog(
                  title: Text(l.chooseTheme),
                  children: [
                    SimpleDialogOption(
                      onPressed: () { notifier.setThemeMode(ThemeMode.light); Navigator.pop(ctx); },
                      child: Text(l.themeLight),
                    ),
                    SimpleDialogOption(
                      onPressed: () { notifier.setThemeMode(ThemeMode.dark); Navigator.pop(ctx); },
                      child: Text(l.themeDark),
                    ),
                    SimpleDialogOption(
                      onPressed: () { notifier.setThemeMode(ThemeMode.system); Navigator.pop(ctx); },
                      child: Text(l.themeSystem),
                    ),
                  ],
                ),
              );
            },
          ),

          _buildSectionHeader(context, l.ocrSection),
          ListTile(
            title: Text(l.ocrLanguage),
            subtitle: Text(OcrService.supportedScripts[OcrService.scriptFromName(settings.ocrLanguage)] ?? 'English / Latin'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => SimpleDialog(
                  title: Text(l.ocrLanguage),
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

          _buildSectionHeader(context, l.backupSection),
          ListTile(
            leading: const Icon(Icons.backup),
            title: Text(l.createBackup),
            subtitle: Text(l.createBackupDesc),
            trailing: ref.watch(premiumProvider).hasBackup
                ? null
                : const Icon(Icons.lock, size: 16, color: Colors.amber),
            onTap: () async {
              if (!ref.read(premiumProvider).hasBackup) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen()));
                return;
              }
              final backup = ref.read(backupServiceProvider);
              // Show progress dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => AlertDialog(
                  content: Row(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(width: 20),
                      Text(l.creatingBackup),
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
                    SnackBar(content: Text(l.backupCreated)),
                  );
                }
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l.backupFailed)),
                );
              }
            },
          ),

          ListTile(
            leading: const Icon(Icons.restore),
            title: Text(l.restoreBackup),
            subtitle: Text(l.restoreBackupDesc),
            trailing: ref.watch(premiumProvider).hasBackup
                ? null
                : const Icon(Icons.lock, size: 16, color: Colors.amber),
            onTap: () async {
              if (!ref.read(premiumProvider).hasBackup) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen()));
                return;
              }
              final backup = ref.read(backupServiceProvider);
              final backups = await backup.listLocalBackups();

              if (backups.isEmpty) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.noBackupsFound)),
                  );
                }
                return;
              }

              if (!context.mounted) return;

              // Show backup selection dialog
              final selectedPath = await showDialog<String>(
                context: context,
                builder: (ctx) => SimpleDialog(
                  title: Text(l.restoreBackup),
                  children: backups.map((file) {
                    final name = file.path.split('/').last;
                    final stat = file.statSync();
                    final sizeMb = (stat.size / 1024 / 1024).toStringAsFixed(1);
                    return SimpleDialogOption(
                      onPressed: () => Navigator.pop(ctx, file.path),
                      child: ListTile(
                        leading: const Icon(Icons.archive),
                        title: Text(name, overflow: TextOverflow.ellipsis),
                        subtitle: Text('$sizeMb MB'),
                        dense: true,
                      ),
                    );
                  }).toList(),
                ),
              );

              if (selectedPath == null || !context.mounted) return;

              // Show progress
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => AlertDialog(
                  content: Row(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(width: 20),
                      Text(l.restoringBackup),
                    ],
                  ),
                ),
              );

              final success = await backup.restoreBackup(selectedPath);

              if (context.mounted) Navigator.pop(context); // dismiss progress

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? l.backupRestored : l.backupRestoreFailed)),
                );
              }
            },
          ),

          _buildSectionHeader(context, l.subscription),
          ListTile(
            leading: Icon(
              ref.watch(premiumProvider).isPremium ? Icons.verified : Icons.workspace_premium,
              color: Colors.amber,
            ),
            title: Text(ref.watch(premiumProvider).isPremium ? l.premiumActive : l.upgradeToPremium),
            subtitle: Text(ref.watch(premiumProvider).isPremium ? l.allFeaturesUnlocked : l.unlockAllFeatures),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen()));
            },
          ),

          _buildSectionHeader(context, l.about),
          ListTile(
            title: Text(l.version),
            subtitle: const Text('1.0.0'),
          ),
          ListTile(
            title: Text(l.showTutorial),
            subtitle: Text(l.showTutorialDesc),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              ref.read(sharedPreferencesProvider).setBool('onboarding_complete', false);
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
