// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Docushot';

  @override
  String get noDocuments => 'No documents yet';

  @override
  String get noDocumentsHint => 'Tap the camera button to scan';

  @override
  String get scan => 'Scan';

  @override
  String get noPagesYet => 'No pages yet';

  @override
  String get noPagesHint => 'Use camera or gallery to add pages';

  @override
  String selected(int count) {
    return '$count Selected';
  }

  @override
  String get deleteDocuments => 'Delete Documents';

  @override
  String deleteDocumentsConfirm(int count) {
    return 'Delete $count document(s)?';
  }

  @override
  String get deletePages => 'Delete Pages';

  @override
  String deletePagesConfirm(int count) {
    return 'Delete $count page(s)?';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get done => 'Done';

  @override
  String get rename => 'Rename Document';

  @override
  String get newName => 'New Name';

  @override
  String get searchDocuments => 'Search documents...';

  @override
  String get noDocumentsFound => 'No documents found';

  @override
  String pages(int count) {
    return '$count page(s)';
  }

  @override
  String get quickSettings => 'Quick Settings';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get autoCrop => 'Auto Crop';

  @override
  String get advancedSettings => 'Advanced Settings';

  @override
  String get settings => 'Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System Default';

  @override
  String get chooseTheme => 'Choose Theme';

  @override
  String get camera => 'Camera';

  @override
  String get imageQuality => 'Image Quality';

  @override
  String get autoCropDesc => 'Automatically crop scanned documents';

  @override
  String get ocrSection => 'OCR';

  @override
  String get ocrLanguage => 'OCR Language';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get showTutorial => 'Show Tutorial';

  @override
  String get showTutorialDesc => 'View the onboarding guide again';

  @override
  String get exportPdf => 'Export PDF';

  @override
  String get exportZip => 'Export ZIP';

  @override
  String get shareImages => 'Share Images';

  @override
  String get crop => 'Crop';

  @override
  String get enhance => 'Enhance';

  @override
  String get ocrText => 'OCR Text';

  @override
  String get recognizedText => 'Recognized Text';

  @override
  String get noTextRecognized => 'No text recognized on this page';

  @override
  String get textCopied => 'Text copied to clipboard';

  @override
  String get brightness => 'Brightness';

  @override
  String get contrast => 'Contrast';

  @override
  String get original => 'Original';

  @override
  String get magicColor => 'Magic Color';

  @override
  String get bw => 'B & W';

  @override
  String get lighten => 'Lighten';

  @override
  String get manual => 'Manual';

  @override
  String get batch => 'Batch';

  @override
  String get document => 'Document';

  @override
  String get book => 'Book';

  @override
  String get idCard => 'ID Card';

  @override
  String get autoCaptureOn => 'AUTO CAPTURE: ON';

  @override
  String get autoCaptureOff => 'AUTO CAPTURE: OFF';

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get getStarted => 'Get Started';

  @override
  String get onboardingTitle1 => 'Smart Document Scanning';

  @override
  String get onboardingDesc1 =>
      'Point your camera at any document. Docushot automatically detects edges and captures a perfectly cropped scan.';

  @override
  String get onboardingTitle2 => 'Enhance & Filter';

  @override
  String get onboardingDesc2 =>
      'Apply Magic Color, B&W, or adjust brightness and contrast to make your scans look professional.';

  @override
  String get onboardingTitle3 => 'OCR Text Recognition';

  @override
  String get onboardingDesc3 =>
      'Extract text from scanned documents in Korean, English, Japanese, Chinese, and more.';

  @override
  String get onboardingTitle4 => 'Export Anywhere';

  @override
  String get onboardingDesc4 =>
      'Share as PDF, ZIP, or images. Organize your documents and find them instantly with search.';

  @override
  String get documentsMerged => 'Documents merged';
}
