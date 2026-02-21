# Docushot

로컬 퍼스트 AI 문서 스캐닝 Android 앱. Flutter + Riverpod 3 + SQLite + SharedPreferences + Google ML Kit.

## 명령어

- 빌드: `flutter build apk --debug`
- 클린 빌드: `flutter clean && flutter pub get && flutter build apk --debug`
- 로컬라이제이션: `flutter gen-l10n`

## 핵심 구조

```
lib/
  core/          # 이미지 처리(Isolate), 테마
  data/
    database.dart # SQLite Helper (싱글턴, 테이블 생성)
    models/      # 순수 Dart 클래스 (toMap/fromMap)
    repositories/ # DocumentRepository (SQLite 쿼리 + StreamController)
    services/    # ScanService, OcrService, PdfService, ExportService, BackupService, IapService
  presentation/
    providers/   # Riverpod 프로바이더 + DocumentController + PremiumNotifier + IapProvider
    screens/     # 8개 화면 (Home, Detail, PageViewer, Crop, Enhance, Settings, Onboarding, Paywall)
    widgets/     # DocumentListTile, PageGridItem, SimpleSettingsDialog
  l10n/          # 국제화 (한/영/일)
```

## 세션 시작 시 필수 읽기

매 세션 시작 시 아래 문서를 반드시 읽고 현재 상태를 파악하라:

1. @docs/CURRENT_SPRINT.md — 현재 작업 목록과 블로커
2. @docs/ISSUES.md — 알려진 문제와 해결 상태
3. @docs/DEVELOPMENT_STATUS.md — 기능별 실제 완성도

## 세션 종료 시 필수 업데이트

작업 완료 후, 세션을 마치기 전에 아래 문서를 반드시 업데이트하라:

1. `docs/CURRENT_SPRINT.md` — 완료된 작업 체크, 새 블로커 추가
2. `docs/DEVELOPMENT_STATUS.md` — 변경된 기능의 완성도 갱신
3. `docs/ISSUES.md` — 해결된 문제 표시, 새 문제 추가
4. MEMORY.md — 핵심 맥락 업데이트 (현재 Phase, 마지막 작업 요약)

## 사용자 선호사항

- 한국어로 소통
- 버전 다운그레이드 금지 (최신 버전 유지 원칙)
- 상용 품질 기준 (수십만 달러 가치의 앱)
- 문서의 주장은 반드시 코드 증거와 일치해야 함
- 95%라고 쓰면 진짜 95%여야 한다

## 프로젝트 문서 체계

| 문서 | 역할 |
|------|------|
| `docs/MASTER_PLAN.md` | 비전, 로드맵, 사업 방향 |
| `docs/DEVELOPMENT_STATUS.md` | 기능별 실제 완성도 (코드 증거 포함) |
| `docs/CURRENT_SPRINT.md` | 현재 작업, 블로커, 다음 단계 |
| `docs/ISSUES.md` | 알려진 문제, 시도한 해결책 |
| `docs/ARCHITECTURE.md` | 기술 아키텍처 참조 |
