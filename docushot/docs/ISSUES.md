# 알려진 문제 및 해결 상태

> 최종 수정: 2026-02-22

---

## 미해결 (OPEN)

### ISSUE-001: ML Kit Document Scanner 디바이스 동작 미검증
- **심각도**: 높음 (앱의 핵심 기능)
- **상태**: 코드 수정 완료, 디바이스 테스트 필요
- **증상**: 스캔 버튼 누르면 아무 반응 없음 (이전 세션)
- **시도한 해결책**:
  1. FlutterActivity → FlutterFragmentActivity 전환 (MainActivity.kt)
  2. 런타임 카메라 권한 요청 추가 (permission_handler)
  3. 에러 전파 개선 (silently return [] → rethrow)
- **남은 작업**: 실제 디바이스에서 테스트

### ISSUE-004: google_mlkit_document_scanner Android 전용
- **심각도**: 중간 (iOS 로드맵에 영향)
- **상태**: 설계 필요
- **영향**: iOS 버전에서는 VisionKit 별도 구현 필요 (2-3주)

### ISSUE-005: "완전 오프라인" 주장의 부정확성
- **심각도**: 낮음 (마케팅 메시지 수정 필요)
- **상태**: 인지됨, 사업제안서에 반영
- **원인**: ML Kit Document Scanner는 Google Play Services 의존, 첫 사용 시 모델 다운로드 필요
- **해결**: "로컬 퍼스트"로 표현 변경 (사업제안서 수정 완료)

### ISSUE-008: 테스트 스위트 미정비
- **심각도**: 중간
- **상태**: 인지됨
- **증상**: 모델/시그니처 변경 이후 테스트 미동기화
- **해결 방향**: 테스트 재작성 또는 삭제 후 재구성

### ISSUE-009: IAP 실제 결제 테스트 미완료
- **심각도**: 중간 (코드는 완성)
- **상태**: Play Console 상품 등록 후 테스트 필요
- **증상**: 코드 작성 완료, 실제 스토어 상품 없이는 E2E 검증 불가
- **해결 방향**: Google Play Console에서 premium_monthly/premium_annual 상품 등록 → 테스트 계정으로 검증

### ISSUE-010: 릴리스 키 미생성
- **심각도**: 중간 (출시 전 필수)
- **상태**: build.gradle.kts 설정 완료, keystore 파일 미생성
- **해결 방향**: `keytool` 명령으로 keystore 생성, key.properties 작성

---

## 해결됨 (CLOSED)

### ISSUE-C23: 인앱 결제 미연동 (ISSUE-006)
- **이전**: 페이월에서 "Coming Soon" 다이얼로그 표시, 결제 불가
- **해결**: `in_app_purchase` 패키지 연동, IapService 생성, PaywallScreen 실제 구매 연동
- **세부**: iap_service.dart (상품 조회/구매/복원/스트림), iap_provider.dart (lazy 초기화), paywall_screen.dart 리팩터링

### ISSUE-C24: applicationId가 com.example.docushot
- **이전**: Play Store 등록 불가능한 기본 applicationId
- **해결**: `com.docushot.app`으로 변경 (build.gradle.kts, MainActivity.kt 패키지 이동)

### ISSUE-C25: 릴리스 빌드가 debug 키 사용
- **이전**: signingConfig = signingConfigs.getByName("debug")
- **해결**: key.properties 기반 조건부 릴리스 서명 설정, ProGuard/R8 활성화

### ISSUE-C09: 문서 삭제에 확인 다이얼로그 없음 (A-1)
- **이전**: delete_forever 아이콘 누르면 확인 없이 즉시 문서 삭제
- **해결**: AlertDialog 확인 추가 (`detail_screen.dart:202`)

### ISSUE-C10: 문서/페이지 삭제 시 이미지 파일 미삭제 (D-1)
- **이전**: Hive 레코드만 삭제, 디스크 이미지 파일 누적
- **해결**: `_deletePageFiles()`, `_tryDeleteFile()` 추가 (`document_repository.dart`)

### ISSUE-C11: autoCrop/imageQuality 설정이 로직에 미연결 (B-2/B-3)
- **이전**: 설정 토글이 존재하지만 어디에서도 참조되지 않음 (거짓 UI)
- **해결**: 설정 화면에서 해당 항목 제거 (`settings_screen.dart`)

### ISSUE-C12: 크롭/필터/보정 에러 시 사용자 피드백 없음 (A-2)
- **이전**: catch → debugPrint만, 사용자에게 아무 표시 안 됨
- **해결**: SnackBar 에러 메시지 추가 (`perspective_crop_screen.dart`, `enhance_screen.dart`)

### ISSUE-C13: 공유/내보내기 실패 시 사용자 피드백 없음 (A-3)
- **이전**: ExportService가 에러를 삼킴 (catch → debugPrint)
- **해결**: 에러 rethrow + detail_screen에서 catch/SnackBar 표시

### ISSUE-C14: restorePurchase 거짓 피드백 (B-8)
- **이전**: 빈 함수 호출 후 "복원 확인 완료" SnackBar 표시
- **해결**: "아직 지원되지 않음" 메시지로 변경 → IAP 연동 후 실제 복원 구현

### ISSUE-C15: 중간 이미지 파일 누적 (D-2/D-3)
- **이전**: 필터/크롭/회전 시 새 파일만 생성, 이전 파일 미삭제
- **해결**: `updatePageImage`에서 이전 중간 파일 삭제 (원본 보존), 회전 임시 파일 삭제

### ISSUE-C16: PDF 내보내기/갤러리 임포트 피드백 없음 (B-6/B-7)
- **이전**: 내보내기 완료/이미지 추가 시 사용자에게 알림 없음
- **해결**: "PDF 내보내기 완료", "N장 추가됨" SnackBar 추가

### ISSUE-C01: TextRecognitionScript.devanagari 오타
- **해결**: `devanagari` → `devanagiri` (라이브러리 스펠링)

### ISSUE-C02: share_plus 빌드 에러
- **해결**: AGP 8.11.1 → 8.12.1 업그레이드

### ISSUE-C03: Riverpod 2.x → 3.x 마이그레이션
- **해결**: StateNotifier → Notifier, .valueOrNull → .value

### ISSUE-C04: OpenCV edge_detection 사용
- **해결**: ML Kit Document Scanner로 전환, edge_detection 삭제

### ISSUE-C05: Repository O(n) 조회
- **해결**: firstWhere() → box.get(id), add() → put(id, obj)

### ISSUE-C06: 프리미엄 기능 잠금 미구현
- **이전**: 모든 기능이 무료로 사용 가능 (premium check 코드 0줄)
- **해결**: 6/6 기능에 Controller + UI 이중 가드 구현
- **세부**: consumeOcr(), requirePremium(), PremiumRequiredException, 잠금 아이콘, PaywallScreen 연결

### ISSUE-C07: 국제화 미연결
- **이전**: 번역 파일(90+ 키) 존재하지만 어떤 화면에서도 사용 안 함
- **해결**: 모든 화면의 사용자 대면 문자열을 AppLocalizations로 교체
- **검증**: 하드코딩 문자열 0개 확인

### ISSUE-C08: 죽은 코드 존재
- **이전**: flutter_slidable, document_type.dart, scan_result.dart 미사용
- **해결**: 전부 삭제, 빌드 검증 통과

### ISSUE-C17: Hive box corruption 위험 (A-5)
- **이전**: Hive는 저널링이 약해서 앱 강제 종료 시 DB 파일 손상 가능
- **해결**: SQLite(sqflite)로 전면 마이그레이션. WAL 저널링으로 자동 복구 지원
- **세부**: 13개 파일 수정, database.dart 신규, .g.dart 삭제, hive/build_runner 제거

### ISSUE-C18: 감사 항목 E-1 필터 프리미엄 체크 가독성
- **이전**: `filterType != 2` — 의미 불명확
- **해결**: `filterType == 1 || filterType == 3`으로 명시적 변경

### ISSUE-C19: 감사 항목 E-2 문서 정렬 기준
- **이전**: createdAt 기준 정렬 (새 페이지 추가해도 순서 불변)
- **해결**: updatedAt 기준 정렬 (최근 수정 문서가 상위)

### ISSUE-C20: 백업 복원 UI 미연결 (B-1)
- **이전**: 설정 화면에서 백업 생성만 가능, 복원 버튼 없음
- **해결**: 설정 화면에 복원 ListTile 추가, 로컬 백업 목록 + 선택 + 진행 다이얼로그

### ISSUE-C21: 페이지 뷰어에서 삭제 불가 (B-5)
- **이전**: 페이지 뷰어에서 크롭/보정/OCR만 가능, 삭제 없음
- **해결**: 하단 액션 바에 삭제 버튼 추가, 확인 다이얼로그, 마지막 페이지 보호

### ISSUE-C22: OCR 남은 횟수 미표시 (C-3)
- **이전**: 무료 사용자가 OCR 남은 횟수를 알 수 없음
- **해결**: 페이지 뷰어 OCR 버튼 옆에 남은 횟수 표시 (프리미엄은 미표시)
