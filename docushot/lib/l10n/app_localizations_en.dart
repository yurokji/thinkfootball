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

  @override
  String scannerError(String error) {
    return 'Scanner error: $error';
  }

  @override
  String get ocrLimitReached =>
      'Daily OCR limit reached. Upgrade to Premium for unlimited OCR.';

  @override
  String ocrError(String error) {
    return 'OCR error: $error';
  }

  @override
  String get premiumLabel => 'Premium';

  @override
  String get premiumActive => 'Premium Active';

  @override
  String get youArePremium => 'You are Premium!';

  @override
  String expiresOn(String date) {
    return 'Expires: $date';
  }

  @override
  String get upgradeToPremium => 'Upgrade to Premium';

  @override
  String get unlockAllFeatures =>
      'Unlock all features for professional scanning';

  @override
  String get allFeaturesUnlocked => 'All features unlocked';

  @override
  String get featureUnlimitedDocs => 'Unlimited Documents';

  @override
  String get featureUnlimitedDocsDesc => 'Create as many documents as you need';

  @override
  String get featureAllFilters => 'All Filters & Adjustments';

  @override
  String get featureAllFiltersDesc => 'Magic Color, B&W, brightness, contrast';

  @override
  String get featureOcr => 'OCR Text Recognition';

  @override
  String get featureOcrDesc => 'Extract text in 5 languages';

  @override
  String get featureBatchScan => 'Batch Scanning';

  @override
  String get featureBatchScanDesc => 'Scan multiple pages in one session';

  @override
  String get featureZipExport => 'ZIP Export';

  @override
  String get featureZipExportDesc => 'Export documents as ZIP archives';

  @override
  String get featureBackup => 'Cloud Backup';

  @override
  String get featureBackupDesc => 'Never lose your documents';

  @override
  String get comingSoon => 'Coming Soon';

  @override
  String get purchaseComingSoon =>
      'In-app purchase will be available once the app is published to the store.';

  @override
  String get ok => 'OK';

  @override
  String get annual => 'Annual';

  @override
  String get monthly => 'Monthly';

  @override
  String get annualPrice => '\$29.99/year';

  @override
  String get monthlyPrice => '\$4.99/month';

  @override
  String get save50 => 'Save 50%';

  @override
  String get restorePurchase => 'Restore Purchase';

  @override
  String get purchaseRestoreChecked => 'Purchase restore checked';

  @override
  String get subscription => 'Subscription';

  @override
  String get language => 'Language';

  @override
  String get backupSection => 'Backup';

  @override
  String get createBackup => 'Create Backup';

  @override
  String get createBackupDesc => 'Export all documents as a ZIP file';

  @override
  String get creatingBackup => 'Creating backup...';

  @override
  String get backupCreated => 'Backup created and shared';

  @override
  String get backupFailed => 'Backup failed';

  @override
  String get mergeSelected => 'Merge Selected';

  @override
  String get enhanceTitle => 'ENHANCE';

  @override
  String get cropRotate => 'CROP / ROTATE';

  @override
  String get rotate90 => 'Rotate 90°';

  @override
  String get dragCornersHint => 'Drag corners to adjust • Tap rotate to turn';

  @override
  String errorGeneric(String error) {
    return 'Error: $error';
  }

  @override
  String get deleteDocument => 'Delete Document';

  @override
  String get deleteDocumentConfirm =>
      'Delete this document? This action cannot be undone.';

  @override
  String cropError(String error) {
    return 'Crop failed: $error';
  }

  @override
  String filterError(String error) {
    return 'Filter failed: $error';
  }

  @override
  String adjustmentError(String error) {
    return 'Adjustment failed: $error';
  }

  @override
  String shareError(String error) {
    return 'Sharing failed: $error';
  }

  @override
  String get exportPdfSuccess => 'PDF exported';

  @override
  String imagesAdded(int count) {
    return '$count image(s) added';
  }

  @override
  String get restoreNotAvailable => 'Purchase restore is not yet available';

  @override
  String get restoreBackup => 'Restore Backup';

  @override
  String get restoreBackupDesc => 'Restore documents from a backup file';

  @override
  String get restoringBackup => 'Restoring backup...';

  @override
  String get backupRestored => 'Backup restored successfully';

  @override
  String get backupRestoreFailed => 'Backup restore failed';

  @override
  String get selectBackupFile => 'Select a backup ZIP file to restore';

  @override
  String get deletePageSingle => 'Delete this page?';

  @override
  String ocrRemainingCount(int remaining, int total) {
    return '$remaining/$total';
  }

  @override
  String get ocrUnlimited => '∞';

  @override
  String get noBackupsFound => 'No backups found';

  @override
  String backupDate(String date) {
    return 'Backup: $date';
  }

  @override
  String backupSize(String size) {
    return '$size MB';
  }

  @override
  String get lastPage =>
      'This is the last page. Delete the document from the detail screen.';

  @override
  String get purchaseInProgress => 'Processing purchase...';

  @override
  String get purchaseSuccess => 'Purchase successful! Premium activated.';

  @override
  String purchaseFailed(String error) {
    return 'Purchase failed: $error';
  }

  @override
  String get purchaseRestored => 'Purchase restored successfully';

  @override
  String get purchaseRestoreNone => 'No previous purchases found';

  @override
  String get loadingProducts => 'Loading...';

  @override
  String get storeUnavailable => 'Store is not available';
}
