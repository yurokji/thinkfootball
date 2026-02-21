# Docushot 개발 상태

> 최종 수정: 2026-02-22
> 종합 완성도: **90%**

---

## 기능별 완성도

| 기능 | 완성도 | 증거 | 비고 |
|------|--------|------|------|
| 문서 CRUD | 97% | `document_repository.dart` (SQLite 쿼리, 파일 삭제) | 삭제 확인 다이얼로그 + 이미지 파일 정리 |
| ML Kit 문서 스캔 | 70% | `scan_service.dart` (권한+스캐너) | **디바이스 미검증** |
| 원근 크롭 | 95% | `perspective_crop_screen.dart`, `image_processor.dart` | 4점 자유 변형, 에러 피드백, 회전 파일 정리 |
| 이미지 필터/보정 | 97% | `enhance_screen.dart`, `image_processor.dart` (Isolate) | 4종 필터, 프리미엄 잠금, 에러 피드백 |
| 다국어 OCR | 95% | `ocr_service.dart` (5스크립트), `document_provider.dart:consumeOcr` | 프리미엄 3회/일 |
| PDF 내보내기 | 95% | `pdf_service.dart`, `detail_screen.dart` | A4 자동 방향, 성공 SnackBar |
| ZIP 내보내기 | 95% | `export_service.dart`, `document_provider.dart:requirePremium` | 프리미엄 잠금, 에러 전파 |
| 이미지 공유 | 95% | `export_service.dart` | share_plus, 에러 전파 |
| 백업 | 95% | `backup_service.dart`, `settings_screen.dart` | 생성+복원 UI 완성, 프리미엄 잠금 |
| 문서 검색 | 90% | `home_screen.dart` (_DocumentSearchDelegate, pagesMap) | 제목+OCR 검색 |
| 문서 병합 | 95% | `document_provider.dart:requirePremium('Merge')` | 프리미엄 잠금 |
| 일괄 작업 | 95% | `home_screen.dart`, `document_provider.dart:requirePremium` | 프리미엄 잠금 |
| **프리미엄 잠금** | **95%** | `premium_provider.dart`, 6개 화면 | 6/6 가드, IAP 연동 완료 |
| **인앱결제** | **85%** | `iap_service.dart`, `iap_provider.dart`, `paywall_screen.dart` | 코드 완성, **Play Console 상품 등록 + 실제 결제 테스트 필요** |
| **국제화** | **100%** | `l10n/app_*.arb` (107+ 키), 모든 화면 | 하드코딩 0개 |
| 온보딩 | 100% | `onboarding_screen.dart` | 4페이지 캐러셀 |
| 설정 | 95% | `settings_screen.dart`, `settings_provider.dart` | 거짓 토글 제거, 백업 잠금 |
| 페이월 UI | 95% | `paywall_screen.dart` | 실제 구매 연동, 스토어 가격 표시, 로딩/에러 처리 |
| **DB (SQLite)** | **100%** | `database.dart`, `document_repository.dart` | WAL 저널링, 자동 복구 |
| **릴리스 빌드** | **90%** | `build.gradle.kts` | applicationId 변경, ProGuard 설정, **keystore 미생성** |

## 데이터 계층 현황

| 계층 | 기술 | 파일 |
|------|------|------|
| 문서/페이지 DB | sqflite (SQLite) | `data/database.dart`, `data/repositories/document_repository.dart` |
| 설정/프리미엄 | SharedPreferences | `providers/settings_provider.dart`, `providers/premium_provider.dart` |
| 반응형 스트림 | StreamController | `document_repository.dart:changes` |
| 인앱결제 | in_app_purchase | `data/services/iap_service.dart`, `providers/iap_provider.dart` |

## 프리미엄 가드 현황

| 기능 | Controller 체크 | UI 잠금 아이콘 | 페이월 연동 |
|------|:-:|:-:|:-:|
| OCR (3회/일) | `consumeOcr()` | SnackBar 안내 | 에러 메시지 |
| ZIP 내보내기 | `requirePremium()` | 잠금 아이콘 | PaywallScreen |
| 문서 병합 | `requirePremium()` | 잠금 아이콘 | PaywallScreen |
| 일괄 내보내기 | `requirePremium()` | 잠금 아이콘 | PaywallScreen |
| 백업 | UI 직접 체크 | 잠금 아이콘 | PaywallScreen |
| 프리미엄 필터 | UI 직접 체크 | 잠금 뱃지 | PaywallScreen |

## 죽은 코드

없음. 전부 정리 완료:
- `core/models/document_type.dart` → 삭제
- `core/models/scan_result.dart` → 삭제
- `flutter_slidable` → pubspec에서 제거
- `image_processor.dart:applyFilterToAll()` → 삭제
- `hive`, `hive_flutter`, `hive_generator`, `build_runner` → 제거
- `document_model.g.dart`, `page_model.g.dart` → 삭제
- `async` 패키지 → 제거 (StreamGroup 미사용)

## 최근 완료된 작업

- [x] 인앱결제(IAP) 연동 (iap_service, iap_provider, paywall 리팩터링)
- [x] 릴리스 빌드 설정 (applicationId, 서명, ProGuard, INTERNET 권한)
- [x] Hive → SQLite 마이그레이션
- [x] B-5: 페이지 뷰어 삭제 버튼 추가
- [x] C-3: OCR 남은 횟수 표시 (페이지 뷰어)
- [x] B-1: 백업 복원 UI (설정 화면)
- [x] E-1: 필터 프리미엄 체크 조건 가독성 개선
- [x] E-2: 문서 정렬 updatedAt 기준 변경
- [x] A-5: Hive box corruption → SQLite WAL로 근본 해결
- [x] 전체 앱 플로우 감사 8개 항목 수정
- [x] 프리미엄 기능 잠금 구현 (6/6 기능)
- [x] 국제화 완전 연결 (모든 화면, 107+ 키, 3개 언어)
- [x] 데드 코드 최종 정리
