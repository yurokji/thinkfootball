import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:docushot/core/theme.dart';
import 'package:docushot/presentation/providers/settings_provider.dart';
import 'package:docushot/presentation/screens/home_screen.dart';
import 'package:docushot/presentation/screens/onboarding_screen.dart';

class DocushotApp extends ConsumerWidget {
  const DocushotApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final onboardingDone = Hive.box('settings').get('onboarding_complete', defaultValue: false) as bool;

    return MaterialApp(
      title: 'Docushot',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      home: onboardingDone ? const HomeScreen() : const OnboardingScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
