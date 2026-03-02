# **D-018: Bundle Promotion Platform Implementation**

## 1. 아키텍처 계층 다이어그램

```text
[ User Interface (CLI) ]
      ↓ (Args: --promote-bundle, --fresh-session)
[ Adapter Layer (runtime/bundle) ]
      ↓ 1. Resolve Active Bundle Root (Default or CLI specified)
      ↓ 2. Load manifest.json
      ↓ 3. Compute Sorted Map Hash (B-018 LOCK-17)
      ↓ 4. Load Pin File from storage/sessions/ (if exists)
      ↓ 5. Compare: Pin vs Resolved Active (Abort if diff without --promote-bundle)
      ↓ 6. If missing or promote: Create/Update Pin (Atomic)
      ↓
[ Core Engine (src/core) ] --- [LOCK-7: No node:fs]
      ↓ 7. computeExecutionPlanHash(Metadata: id, version, hash)
      ↓ 8. sessionStore.verify()
```

## 2. 주요 컴포넌트 및 경로 규약
* **BundleResolver 위치:** `runtime/bundle/bundle_resolver.ts` (Core 외부 위치 엄수).
* **Pin 파일 경로:** `storage/sessions/<session_id>.bundle_pin.json`.
* **Fresh Session 동작:** `--fresh-session` 호출 시 `session_state.*.json` 회전과 동일하게 `bundle_pin.*.json` 파일도 `.bak`으로 회전(Rotate)시킨다.

## 3. Drift Detection 상세 흐름
1. **Adapter 단계 (1차 검증):**
    * `manifest.json` 로드 및 **Sorted Map Hash** 계산.
    * Pin 파일의 `bundle_hash`와 계산된 해시 비교.
    * Pin 파일의 버전 정보와 현재 `Active Bundle` 비교.
    * 불일치 시 즉시 예외 발생 및 실행 중단.
2. **Core 단계 (2차 검증):**
    * 실행 메타데이터에 `bundle_id`, `bundle_version`, `bundle_hash` 포함.
    * `computeExecutionPlanHash`를 통해 실행 계획 해시 생성.
    * `sessionStore.verify()`를 통해 기존 세션의 해시 정합성 최종 확인.
