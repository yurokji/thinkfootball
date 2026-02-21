import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:docushot/presentation/providers/settings_provider.dart';
import 'package:docushot/presentation/screens/settings_screen.dart';
import 'package:docushot/l10n/app_localizations.dart';

class SimpleSettingsDialog extends ConsumerWidget {
  const SimpleSettingsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Dialog(
      backgroundColor: Colors.black.withValues(alpha: 0.8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.quickSettings,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Dark Mode Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.dark_mode, color: Colors.white70, size: 20),
                    const SizedBox(width: 12),
                    Text(l.darkMode, style: const TextStyle(color: Colors.white70)),
                  ],
                ),
                Switch(
                  value: settings.themeMode == ThemeMode.dark,
                  onChanged: (v) {
                    notifier.setThemeMode(v ? ThemeMode.dark : ThemeMode.light);
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Auto Crop Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.crop, color: Colors.white70, size: 20),
                    const SizedBox(width: 12),
                    Text(l.autoCrop, style: const TextStyle(color: Colors.white70)),
                  ],
                ),
                Switch(
                  value: settings.autoCrop,
                  onChanged: (v) => notifier.setAutoCrop(v),
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(color: Colors.white24),
            const SizedBox(height: 10),

            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.settings, color: Colors.cyanAccent),
                label: Text(l.advancedSettings, style: const TextStyle(color: Colors.cyanAccent)),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
