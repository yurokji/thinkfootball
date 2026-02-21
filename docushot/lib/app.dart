import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:docushot/core/theme.dart';
import 'package:docushot/presentation/providers/settings_provider.dart';
import 'package:docushot/presentation/screens/home_screen.dart';
import 'package:docushot/presentation/screens/onboarding_screen.dart';
import 'package:docushot/l10n/app_localizations.dart';

class DocushotApp extends ConsumerWidget {
  const DocushotApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final prefs = ref.watch(sharedPreferencesProvider);
    final onboardingDone = prefs.getBool('onboarding_complete') ?? false;

    return MaterialApp(
      title: 'Docushot',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      locale: Locale(settings.locale),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: onboardingDone ? const HomeScreen() : const OnboardingScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
