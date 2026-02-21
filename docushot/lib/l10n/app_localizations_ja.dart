// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Docushot';

  @override
  String get noDocuments => 'ドキュメントがありません';

  @override
  String get noDocumentsHint => 'カメラボタンをタップしてスキャン';

  @override
  String get scan => 'スキャン';

  @override
  String get noPagesYet => 'ページがありません';

  @override
  String get noPagesHint => 'カメラまたはギャラリーからページを追加';

  @override
  String selected(int count) {
    return '$count件選択中';
  }

  @override
  String get deleteDocuments => 'ドキュメント削除';

  @override
  String deleteDocumentsConfirm(int count) {
    return '$count件のドキュメントを削除しますか？';
  }

  @override
  String get deletePages => 'ページ削除';

  @override
  String deletePagesConfirm(int count) {
    return '$count件のページを削除しますか？';
  }

  @override
  String get cancel => 'キャンセル';

  @override
  String get delete => '削除';

  @override
  String get save => '保存';

  @override
  String get done => '完了';

  @override
  String get rename => '名前を変更';

  @override
  String get newName => '新しい名前';

  @override
  String get searchDocuments => 'ドキュメントを検索...';

  @override
  String get noDocumentsFound => 'ドキュメントが見つかりません';

  @override
  String pages(int count) {
    return '$countページ';
  }

  @override
  String get quickSettings => 'クイック設定';

  @override
  String get darkMode => 'ダークモード';

  @override
  String get autoCrop => '自動クロップ';

  @override
  String get advancedSettings => '詳細設定';

  @override
  String get settings => '設定';

  @override
  String get appearance => '外観';

  @override
  String get theme => 'テーマ';

  @override
  String get themeLight => 'ライト';

  @override
  String get themeDark => 'ダーク';

  @override
  String get themeSystem => 'システム';

  @override
  String get chooseTheme => 'テーマを選択';

  @override
  String get camera => 'カメラ';

  @override
  String get imageQuality => '画質';

  @override
  String get autoCropDesc => 'スキャンしたドキュメントを自動的にクロップ';

  @override
  String get ocrSection => 'OCR';

  @override
  String get ocrLanguage => 'OCR言語';

  @override
  String get about => 'バージョン情報';

  @override
  String get version => 'バージョン';

  @override
  String get showTutorial => 'チュートリアルを表示';

  @override
  String get showTutorialDesc => 'オンボーディングガイドを再表示';

  @override
  String get exportPdf => 'PDF出力';

  @override
  String get exportZip => 'ZIP出力';

  @override
  String get shareImages => '画像を共有';

  @override
  String get crop => 'クロップ';

  @override
  String get enhance => '補正';

  @override
  String get ocrText => 'OCRテキスト';

  @override
  String get recognizedText => '認識されたテキスト';

  @override
  String get noTextRecognized => 'このページではテキストが認識されませんでした';

  @override
  String get textCopied => 'テキストをクリップボードにコピーしました';

  @override
  String get brightness => '明るさ';

  @override
  String get contrast => 'コントラスト';

  @override
  String get original => 'オリジナル';

  @override
  String get magicColor => 'マジックカラー';

  @override
  String get bw => '白黒';

  @override
  String get lighten => '明るく';

  @override
  String get manual => '手動';

  @override
  String get batch => 'バッチ';

  @override
  String get document => '文書';

  @override
  String get book => '本';

  @override
  String get idCard => 'IDカード';

  @override
  String get autoCaptureOn => '自動撮影: オン';

  @override
  String get autoCaptureOff => '自動撮影: オフ';

  @override
  String get skip => 'スキップ';

  @override
  String get next => '次へ';

  @override
  String get getStarted => '始める';

  @override
  String get onboardingTitle1 => 'スマート文書スキャン';

  @override
  String get onboardingDesc1 =>
      'カメラを文書に向けると、Docushotが自動的にエッジを検出し、完璧にクロップされたスキャンをキャプチャします。';

  @override
  String get onboardingTitle2 => '補正＆フィルター';

  @override
  String get onboardingDesc2 =>
      'マジックカラー、白黒、または明るさとコントラストを調整してプロフェッショナルなスキャンを作成。';

  @override
  String get onboardingTitle3 => 'OCRテキスト認識';

  @override
  String get onboardingDesc3 => '韓国語、英語、日本語、中国語などでスキャンしたドキュメントからテキストを抽出。';

  @override
  String get onboardingTitle4 => 'どこでもエクスポート';

  @override
  String get onboardingDesc4 => 'PDF、ZIP、または画像として共有。ドキュメントを整理し、検索で即座に見つけましょう。';

  @override
  String get documentsMerged => 'ドキュメントが結合されました';

  @override
  String scannerError(String error) {
    return 'スキャナーエラー: $error';
  }

  @override
  String get ocrLimitReached =>
      '1日のOCR上限に達しました。プレミアムにアップグレードすると無制限にOCRを使用できます。';

  @override
  String ocrError(String error) {
    return 'OCRエラー: $error';
  }

  @override
  String get premiumLabel => 'プレミアム';

  @override
  String get premiumActive => 'プレミアム有効';

  @override
  String get youArePremium => 'プレミアム利用中！';

  @override
  String expiresOn(String date) {
    return '有効期限: $date';
  }

  @override
  String get upgradeToPremium => 'プレミアムにアップグレード';

  @override
  String get unlockAllFeatures => 'すべての機能をアンロック';

  @override
  String get allFeaturesUnlocked => 'すべての機能がアンロックされました';

  @override
  String get featureUnlimitedDocs => '無制限ドキュメント';

  @override
  String get featureUnlimitedDocsDesc => '必要なだけドキュメントを作成';

  @override
  String get featureAllFilters => 'すべてのフィルター＆調整';

  @override
  String get featureAllFiltersDesc => 'マジックカラー、白黒、明るさ、コントラスト';

  @override
  String get featureOcr => 'OCRテキスト認識';

  @override
  String get featureOcrDesc => '5言語でテキスト抽出';

  @override
  String get featureBatchScan => 'バッチスキャン';

  @override
  String get featureBatchScanDesc => '一度に複数ページをスキャン';

  @override
  String get featureZipExport => 'ZIP出力';

  @override
  String get featureZipExportDesc => 'ZIPアーカイブとしてドキュメントを出力';

  @override
  String get featureBackup => 'クラウドバックアップ';

  @override
  String get featureBackupDesc => 'ドキュメントを安全に保管';

  @override
  String get comingSoon => '近日公開';

  @override
  String get purchaseComingSoon => 'アプリがストアに公開されると、アプリ内購入が利用可能になります。';

  @override
  String get ok => 'OK';

  @override
  String get annual => '年間';

  @override
  String get monthly => '月間';

  @override
  String get annualPrice => '¥4,500/年';

  @override
  String get monthlyPrice => '¥750/月';

  @override
  String get save50 => '50%オフ';

  @override
  String get restorePurchase => '購入を復元';

  @override
  String get purchaseRestoreChecked => '購入復元を確認しました';

  @override
  String get subscription => 'サブスクリプション';

  @override
  String get language => '言語';

  @override
  String get backupSection => 'バックアップ';

  @override
  String get createBackup => 'バックアップ作成';

  @override
  String get createBackupDesc => 'すべてのドキュメントをZIPファイルとして出力';

  @override
  String get creatingBackup => 'バックアップ作成中...';

  @override
  String get backupCreated => 'バックアップが作成・共有されました';

  @override
  String get backupFailed => 'バックアップに失敗しました';

  @override
  String get mergeSelected => '選択を結合';

  @override
  String get enhanceTitle => '補正';

  @override
  String get cropRotate => 'クロップ / 回転';

  @override
  String get rotate90 => '90°回転';

  @override
  String get dragCornersHint => '角をドラッグして調整 • 回転ボタンで回す';

  @override
  String errorGeneric(String error) {
    return 'エラー: $error';
  }

  @override
  String get deleteDocument => 'ドキュメント削除';

  @override
  String get deleteDocumentConfirm => 'このドキュメントを削除しますか？この操作は元に戻せません。';

  @override
  String cropError(String error) {
    return 'クロップ失敗: $error';
  }

  @override
  String filterError(String error) {
    return 'フィルター適用失敗: $error';
  }

  @override
  String adjustmentError(String error) {
    return '調整失敗: $error';
  }

  @override
  String shareError(String error) {
    return '共有失敗: $error';
  }

  @override
  String get exportPdfSuccess => 'PDF出力完了';

  @override
  String imagesAdded(int count) {
    return '$count枚追加されました';
  }

  @override
  String get restoreNotAvailable => '購入の復元はまだ利用できません';

  @override
  String get restoreBackup => 'バックアップ復元';

  @override
  String get restoreBackupDesc => 'バックアップファイルからドキュメントを復元';

  @override
  String get restoringBackup => 'バックアップ復元中...';

  @override
  String get backupRestored => 'バックアップが正常に復元されました';

  @override
  String get backupRestoreFailed => 'バックアップの復元に失敗しました';

  @override
  String get selectBackupFile => '復元するバックアップZIPファイルを選択してください';

  @override
  String get deletePageSingle => 'このページを削除しますか？';

  @override
  String ocrRemainingCount(int remaining, int total) {
    return '$remaining/$total';
  }

  @override
  String get ocrUnlimited => '∞';

  @override
  String get noBackupsFound => 'バックアップが見つかりません';

  @override
  String backupDate(String date) {
    return 'バックアップ: $date';
  }

  @override
  String backupSize(String size) {
    return '$size MB';
  }

  @override
  String get lastPage => '最後のページです。ドキュメントは詳細画面から削除してください。';

  @override
  String get purchaseInProgress => '購入処理中...';

  @override
  String get purchaseSuccess => '購入完了！プレミアムが有効化されました。';

  @override
  String purchaseFailed(String error) {
    return '購入失敗: $error';
  }

  @override
  String get purchaseRestored => '購入が正常に復元されました';

  @override
  String get purchaseRestoreNone => '以前の購入が見つかりません';

  @override
  String get loadingProducts => '読み込み中...';

  @override
  String get storeUnavailable => 'ストアが利用できません';
}
