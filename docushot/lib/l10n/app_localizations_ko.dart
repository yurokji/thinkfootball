// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'Docushot';

  @override
  String get noDocuments => '문서가 없습니다';

  @override
  String get noDocumentsHint => '카메라 버튼을 눌러 스캔하세요';

  @override
  String get scan => '스캔';

  @override
  String get noPagesYet => '페이지가 없습니다';

  @override
  String get noPagesHint => '카메라 또는 갤러리에서 페이지를 추가하세요';

  @override
  String selected(int count) {
    return '$count개 선택됨';
  }

  @override
  String get deleteDocuments => '문서 삭제';

  @override
  String deleteDocumentsConfirm(int count) {
    return '$count개 문서를 삭제하시겠습니까?';
  }

  @override
  String get deletePages => '페이지 삭제';

  @override
  String deletePagesConfirm(int count) {
    return '$count개 페이지를 삭제하시겠습니까?';
  }

  @override
  String get cancel => '취소';

  @override
  String get delete => '삭제';

  @override
  String get save => '저장';

  @override
  String get done => '완료';

  @override
  String get rename => '문서 이름 변경';

  @override
  String get newName => '새 이름';

  @override
  String get searchDocuments => '문서 검색...';

  @override
  String get noDocumentsFound => '검색 결과가 없습니다';

  @override
  String pages(int count) {
    return '$count페이지';
  }

  @override
  String get quickSettings => '빠른 설정';

  @override
  String get darkMode => '다크 모드';

  @override
  String get autoCrop => '자동 크롭';

  @override
  String get advancedSettings => '상세 설정';

  @override
  String get settings => '설정';

  @override
  String get appearance => '외관';

  @override
  String get theme => '테마';

  @override
  String get themeLight => '라이트';

  @override
  String get themeDark => '다크';

  @override
  String get themeSystem => '시스템 기본값';

  @override
  String get chooseTheme => '테마 선택';

  @override
  String get camera => '카메라';

  @override
  String get imageQuality => '이미지 품질';

  @override
  String get autoCropDesc => '스캔한 문서를 자동으로 크롭합니다';

  @override
  String get ocrSection => 'OCR';

  @override
  String get ocrLanguage => 'OCR 언어';

  @override
  String get about => '정보';

  @override
  String get version => '버전';

  @override
  String get showTutorial => '튜토리얼 보기';

  @override
  String get showTutorialDesc => '온보딩 가이드를 다시 봅니다';

  @override
  String get exportPdf => 'PDF 내보내기';

  @override
  String get exportZip => 'ZIP 내보내기';

  @override
  String get shareImages => '이미지 공유';

  @override
  String get crop => '크롭';

  @override
  String get enhance => '보정';

  @override
  String get ocrText => 'OCR 텍스트';

  @override
  String get recognizedText => '인식된 텍스트';

  @override
  String get noTextRecognized => '이 페이지에서 텍스트를 인식하지 못했습니다';

  @override
  String get textCopied => '텍스트가 클립보드에 복사되었습니다';

  @override
  String get brightness => '밝기';

  @override
  String get contrast => '대비';

  @override
  String get original => '원본';

  @override
  String get magicColor => '매직 컬러';

  @override
  String get bw => '흑백';

  @override
  String get lighten => '밝게';

  @override
  String get manual => '수동';

  @override
  String get batch => '배치';

  @override
  String get document => '문서';

  @override
  String get book => '책';

  @override
  String get idCard => '신분증';

  @override
  String get autoCaptureOn => '자동 촬영: 켜짐';

  @override
  String get autoCaptureOff => '자동 촬영: 꺼짐';

  @override
  String get skip => '건너뛰기';

  @override
  String get next => '다음';

  @override
  String get getStarted => '시작하기';

  @override
  String get onboardingTitle1 => '스마트 문서 스캔';

  @override
  String get onboardingDesc1 =>
      '카메라를 문서에 대면 Docushot이 자동으로 가장자리를 감지하고 완벽하게 크롭된 스캔을 캡처합니다.';

  @override
  String get onboardingTitle2 => '보정 & 필터';

  @override
  String get onboardingDesc2 => '매직 컬러, 흑백 또는 밝기와 대비를 조절하여 전문적인 스캔을 만드세요.';

  @override
  String get onboardingTitle3 => 'OCR 텍스트 인식';

  @override
  String get onboardingDesc3 => '한국어, 영어, 일본어, 중국어 등 스캔한 문서에서 텍스트를 추출합니다.';

  @override
  String get onboardingTitle4 => '어디서나 내보내기';

  @override
  String get onboardingDesc4 =>
      'PDF, ZIP 또는 이미지로 공유하세요. 문서를 정리하고 검색으로 즉시 찾으세요.';

  @override
  String get documentsMerged => '문서가 병합되었습니다';
}
