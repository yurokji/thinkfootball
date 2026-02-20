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
}
