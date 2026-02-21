# 현재 스프린트

> 최종 수정: 2026-02-22

---

## 현재 Phase: 출시 준비

### 완료된 작업

- [x] **Phase 1**: 프리미엄 기능 잠금 구현
  - premium_provider.dart: consumeOcr(), requirePremium(), PremiumRequiredException
  - DocumentController: OCR, ZIP, Merge, Batch Export 프리미엄 체크
  - 6개 화면: 잠금 아이콘 + PaywallScreen 연결
  - 감사 검증: 6/6 기능 가드 + 6/6 UI 잠금 표시

- [x] **Phase 2**: 국제화 실제 연결
  - ARB 파일 3개 (en, ko, ja) 각 90+ 키
  - 모든 화면 AppLocalizations 연결 완료
  - 하드코딩 문자열 0개
  - `flutter gen-l10n` + `flutter build apk --debug` 검증 통과

- [x] **Phase 3**: 죽은 코드 정리
  - flutter_slidable 제거 (pubspec.yaml)
  - document_type.dart 삭제
  - scan_result.dart 삭제
  - applyFilterToAll() 삭제
  - 빌드 검증 통과

- [x] **Phase 4**: 감사 문서 재작성
  - docushot_기술감사서.md: 정직한 현재 상태 반영
  - docushot_사업제안서.md: 현실적 수치, 가격 통일
  - docushot_audit_개발자.md: 해결/미해결 명시
  - docushot_audit_투자자.md: 조건부 진행 유지

- [x] **프로젝트 문서 하네스 구축**
  - CLAUDE.md, MEMORY.md, docs/ 5개 문서, 에이전트 2개, 규칙 2개, 훅 2개

- [x] **Phase 5**: 전체 앱 플로우 감사 → 문제점 수정
  - 26+ 파일 감사, 15개 문제점 발견, 8개 수정 완료:
  - A-1: 문서 삭제 확인 다이얼로그 (`detail_screen.dart`)
  - D-1: 문서/페이지 삭제 시 이미지 파일도 삭제 (`document_repository.dart`)
  - B-2/B-3: 미연결 설정(autoCrop, imageQuality) UI에서 제거 (`settings_screen.dart`)
  - A-2: 크롭/필터/보정 에러 SnackBar 피드백 (`perspective_crop_screen.dart`, `enhance_screen.dart`)
  - A-3: 내보내기 에러 전파 + catch 피드백 (`export_service.dart`, `detail_screen.dart`)
  - B-8: restorePurchase 정직한 메시지 (`paywall_screen.dart`)
  - D-2/D-3: 중간 이미지 파일 정리 (원본 보존) (`document_repository.dart`, `perspective_crop_screen.dart`)
  - B-6/B-7: PDF 내보내기/갤러리 임포트 성공 피드백 (`detail_screen.dart`)

- [x] **감사 추가 수정**
  - E-1: 필터 프리미엄 체크 조건 가독성 개선 (`enhance_screen.dart`)
  - E-2: 문서 정렬 updatedAt 기준 변경 (`document_repository.dart`)
  - B-5: 페이지 뷰어 삭제 버튼 (`page_viewer_screen.dart`)
  - C-3: OCR 남은 횟수 표시 (`page_viewer_screen.dart`, `detail_screen.dart`)
  - B-1: 백업 복원 UI (`settings_screen.dart`)

- [x] **Hive → SQLite 마이그레이션**
  - sqflite + shared_preferences 도입, hive/hive_flutter/hive_generator/build_runner 제거
  - `database.dart` 신규 생성 (SQLite Helper, documents/pages 테이블)
  - 모델: HiveObject/어노테이션 제거 → 순수 Dart 클래스 + toMap/fromMap
  - Repository: Box → SQL 쿼리 + StreamController 반응형
  - Provider: box.watch() → repository.changes Stream 구독
  - Settings/Premium: Hive.box('settings') → SharedPreferences
  - BackupService: Box → SQL 쿼리
  - main.dart: ProviderScope overrides로 DB/SharedPreferences 주입
  - 검색 SearchDelegate: 미리 로드한 pagesMap으로 동기 검색 유지
  - .g.dart 삭제, async 패키지 제거
  - `flutter build apk --debug` 빌드 검증 통과

- [x] **인앱결제(IAP) 연동**
  - `in_app_purchase: ^3.2.0` 의존성 추가
  - `iap_service.dart` 신규: InAppPurchase 래핑, 상품 조회/구매/복원/스트림 처리
  - `iap_provider.dart` 신규: iapServiceProvider (lazy 초기화), iapProductsProvider, iapStateProvider
  - `paywall_screen.dart` 리팩터링: "Coming Soon" 제거 → 실제 구매 연동
  - 스토어 가격 표시 (ProductDetails.price), 로딩/에러/복원 상태 처리
  - ARB 3개 파일에 IAP 문자열 7개 추가 (en/ko/ja)
  - `premium_provider.dart`: restorePurchase() TODO 제거

- [x] **릴리스 빌드 설정**
  - applicationId: `com.example.docushot` → `com.docushot.app`
  - MainActivity.kt 패키지 이동 (com/example/docushot → com/docushot/app)
  - 릴리스 서명: key.properties 기반 조건부 서명 설정
  - ProGuard/R8: Flutter, Google Play Billing, ML Kit keep 규칙
  - INTERNET 권한 추가
  - .gitignore: key.properties, *.jks, *.keystore 제외
  - 앱 라벨: "docushot" → "Docushot"
  - `flutter build apk --debug` 빌드 검증 통과

### 남은 작업 (출시 전)

- [ ] **Phase 0**: 스캔 버튼 디바이스 검증
  - 상태: 대기 (디바이스 ADB 연결 필요)
  - scan_service.dart 코드 완성, 실동작 미확인

- [ ] **릴리스 키 생성** (사용자 수동)
  - `keytool` 명령으로 keystore 생성
  - `android/key.properties` 파일 작성
  - `flutter build apk --release` 검증

- [ ] **Play Store 등록 준비**
  - 개인정보 처리방침
  - 스토어 설명 (한/영/일)
  - 스크린샷
  - Google Play Console에 상품 등록 (premium_monthly, premium_annual)

### 감사 미수정 항목 (선택/판단 필요)

- [x] A-4: 병합 후 원본 문서 유지 (현행 유지 결정)
- [x] A-5: ~~Hive box corruption~~ → SQLite WAL 저널링으로 해결
- [x] B-5: 페이지 뷰어에서 삭제 기능 추가 (완료)
- [x] C-3: OCR 남은 횟수 표시 (완료)
- [x] B-1: 백업 복원 UI 추가 (완료)
- [x] E-1: 필터 프리미엄 체크 조건 가독성 개선 (완료)
- [x] E-2: documentListProvider 정렬 updatedAt 기준 (완료)

## 블로커

| 블로커 | 심각도 | 해결 방법 |
|--------|--------|----------|
| 스캔 디바이스 미검증 | 높음 | ADB 연결 후 테스트 |
| 릴리스 키 미생성 | 중간 | keytool 명령 실행 (사용자 수동) |
| Play Console 상품 미등록 | 중간 | 콘솔에서 premium_monthly/premium_annual 생성 |
