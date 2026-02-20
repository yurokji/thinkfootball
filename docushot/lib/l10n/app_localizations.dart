import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ko')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Docushot'**
  String get appTitle;

  /// No description provided for @noDocuments.
  ///
  /// In en, this message translates to:
  /// **'No documents yet'**
  String get noDocuments;

  /// No description provided for @noDocumentsHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the camera button to scan'**
  String get noDocumentsHint;

  /// No description provided for @scan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scan;

  /// No description provided for @noPagesYet.
  ///
  /// In en, this message translates to:
  /// **'No pages yet'**
  String get noPagesYet;

  /// No description provided for @noPagesHint.
  ///
  /// In en, this message translates to:
  /// **'Use camera or gallery to add pages'**
  String get noPagesHint;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'{count} Selected'**
  String selected(int count);

  /// No description provided for @deleteDocuments.
  ///
  /// In en, this message translates to:
  /// **'Delete Documents'**
  String get deleteDocuments;

  /// No description provided for @deleteDocumentsConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} document(s)?'**
  String deleteDocumentsConfirm(int count);

  /// No description provided for @deletePages.
  ///
  /// In en, this message translates to:
  /// **'Delete Pages'**
  String get deletePages;

  /// No description provided for @deletePagesConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} page(s)?'**
  String deletePagesConfirm(int count);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename Document'**
  String get rename;

  /// No description provided for @newName.
  ///
  /// In en, this message translates to:
  /// **'New Name'**
  String get newName;

  /// No description provided for @searchDocuments.
  ///
  /// In en, this message translates to:
  /// **'Search documents...'**
  String get searchDocuments;

  /// No description provided for @noDocumentsFound.
  ///
  /// In en, this message translates to:
  /// **'No documents found'**
  String get noDocumentsFound;

  /// No description provided for @pages.
  ///
  /// In en, this message translates to:
  /// **'{count} page(s)'**
  String pages(int count);

  /// No description provided for @quickSettings.
  ///
  /// In en, this message translates to:
  /// **'Quick Settings'**
  String get quickSettings;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @autoCrop.
  ///
  /// In en, this message translates to:
  /// **'Auto Crop'**
  String get autoCrop;

  /// No description provided for @advancedSettings.
  ///
  /// In en, this message translates to:
  /// **'Advanced Settings'**
  String get advancedSettings;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get themeSystem;

  /// No description provided for @chooseTheme.
  ///
  /// In en, this message translates to:
  /// **'Choose Theme'**
  String get chooseTheme;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @imageQuality.
  ///
  /// In en, this message translates to:
  /// **'Image Quality'**
  String get imageQuality;

  /// No description provided for @autoCropDesc.
  ///
  /// In en, this message translates to:
  /// **'Automatically crop scanned documents'**
  String get autoCropDesc;

  /// No description provided for @ocrSection.
  ///
  /// In en, this message translates to:
  /// **'OCR'**
  String get ocrSection;

  /// No description provided for @ocrLanguage.
  ///
  /// In en, this message translates to:
  /// **'OCR Language'**
  String get ocrLanguage;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @showTutorial.
  ///
  /// In en, this message translates to:
  /// **'Show Tutorial'**
  String get showTutorial;

  /// No description provided for @showTutorialDesc.
  ///
  /// In en, this message translates to:
  /// **'View the onboarding guide again'**
  String get showTutorialDesc;

  /// No description provided for @exportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get exportPdf;

  /// No description provided for @exportZip.
  ///
  /// In en, this message translates to:
  /// **'Export ZIP'**
  String get exportZip;

  /// No description provided for @shareImages.
  ///
  /// In en, this message translates to:
  /// **'Share Images'**
  String get shareImages;

  /// No description provided for @crop.
  ///
  /// In en, this message translates to:
  /// **'Crop'**
  String get crop;

  /// No description provided for @enhance.
  ///
  /// In en, this message translates to:
  /// **'Enhance'**
  String get enhance;

  /// No description provided for @ocrText.
  ///
  /// In en, this message translates to:
  /// **'OCR Text'**
  String get ocrText;

  /// No description provided for @recognizedText.
  ///
  /// In en, this message translates to:
  /// **'Recognized Text'**
  String get recognizedText;

  /// No description provided for @noTextRecognized.
  ///
  /// In en, this message translates to:
  /// **'No text recognized on this page'**
  String get noTextRecognized;

  /// No description provided for @textCopied.
  ///
  /// In en, this message translates to:
  /// **'Text copied to clipboard'**
  String get textCopied;

  /// No description provided for @brightness.
  ///
  /// In en, this message translates to:
  /// **'Brightness'**
  String get brightness;

  /// No description provided for @contrast.
  ///
  /// In en, this message translates to:
  /// **'Contrast'**
  String get contrast;

  /// No description provided for @original.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get original;

  /// No description provided for @magicColor.
  ///
  /// In en, this message translates to:
  /// **'Magic Color'**
  String get magicColor;

  /// No description provided for @bw.
  ///
  /// In en, this message translates to:
  /// **'B & W'**
  String get bw;

  /// No description provided for @lighten.
  ///
  /// In en, this message translates to:
  /// **'Lighten'**
  String get lighten;

  /// No description provided for @manual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get manual;

  /// No description provided for @batch.
  ///
  /// In en, this message translates to:
  /// **'Batch'**
  String get batch;

  /// No description provided for @document.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get document;

  /// No description provided for @book.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get book;

  /// No description provided for @idCard.
  ///
  /// In en, this message translates to:
  /// **'ID Card'**
  String get idCard;

  /// No description provided for @autoCaptureOn.
  ///
  /// In en, this message translates to:
  /// **'AUTO CAPTURE: ON'**
  String get autoCaptureOn;

  /// No description provided for @autoCaptureOff.
  ///
  /// In en, this message translates to:
  /// **'AUTO CAPTURE: OFF'**
  String get autoCaptureOff;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Smart Document Scanning'**
  String get onboardingTitle1;

  /// No description provided for @onboardingDesc1.
  ///
  /// In en, this message translates to:
  /// **'Point your camera at any document. Docushot automatically detects edges and captures a perfectly cropped scan.'**
  String get onboardingDesc1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Enhance & Filter'**
  String get onboardingTitle2;

  /// No description provided for @onboardingDesc2.
  ///
  /// In en, this message translates to:
  /// **'Apply Magic Color, B&W, or adjust brightness and contrast to make your scans look professional.'**
  String get onboardingDesc2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'OCR Text Recognition'**
  String get onboardingTitle3;

  /// No description provided for @onboardingDesc3.
  ///
  /// In en, this message translates to:
  /// **'Extract text from scanned documents in Korean, English, Japanese, Chinese, and more.'**
  String get onboardingDesc3;

  /// No description provided for @onboardingTitle4.
  ///
  /// In en, this message translates to:
  /// **'Export Anywhere'**
  String get onboardingTitle4;

  /// No description provided for @onboardingDesc4.
  ///
  /// In en, this message translates to:
  /// **'Share as PDF, ZIP, or images. Organize your documents and find them instantly with search.'**
  String get onboardingDesc4;

  /// No description provided for @documentsMerged.
  ///
  /// In en, this message translates to:
  /// **'Documents merged'**
  String get documentsMerged;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
