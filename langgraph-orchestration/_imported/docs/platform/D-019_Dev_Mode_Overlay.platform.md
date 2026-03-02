# D-019: Dev Mode Overlay Platform Spec

## 1. File-level Change Map
- `src/dev/overlay/`: React 기반 오버레이 UI 컴포넌트 셋.
- `src/dev/local_secret_manager.ts`: 로컬 파일/키체인 연동 시크릿 관리 로직.
- `src/runtime/telemetry/telemetry_emitter.ts`: 전송 전 `structuredClone()` 또는 `lodash.cloneDeep()`을 통한 스냅샷 생성 로직 강제.
- `src/runtime/safety/override_guard.ts` (New): Override 상태 감지 시 `Promote`/`Pin` 요청을 가로채어 거절하는 가드 로직.
- **`override_guard` 적용 범위**: 다음 모든 진입 경로에서 강제 적용되어야 한다.
    - `runtime/orchestrator/run_request.ts` (API/Web 호출)
    - `CLI promote`/`pin` command handlers (CLI 도구)
    - `state:cycle`, `prd:close` 스크립트 진입부 (상태 전이 자동화)
- `src/server/routes/dev_telemetry.route.ts`: SSE/WebSocket 엔드포인트 정의 (Dev 모드 전용).
- `src/types/telemetry.ts`: 텔레메트리 메시지 스키마 정의.

---

## 2. Dependency Graph (Hardened)

### Before
```text
Runtime Core -> Local/Env Secrets
             -> No Telemetry Channels
```

### After
```text
Runtime Core -> [TelemetryEmitter] -> Deep-copy Snapshot -> [SSE/WebSocket] -> Dev Overlay
             -> [OverrideGuard] -> Blocking (Promote/Pin/Cycle/Close)
             -> [LocalSecretStore] -> In-memory only (Interceptor for PRD-004)
```

---

## 3. State Machine Diagram

```text
[ IDLE ] -- Toggle Click --> [ OVERLAY_ACTIVE ]
    |                              |
    |-- SSE Event Received --------|--> [ SNAPSHOT_UPDATE_HUD ]
    |                              |
    |-- Secret Input --------------> [ ENCRYPT_SAVE_LOCAL ] (Vault Interceptor)
    |                              |
    |-- Override Trigger ----------> [ APPLY_TEMP_CONTEXT ] 
    |                              |       + [ ACTIVATE_REPRODUCIBILITY_LOCK ]
    |                              |       + [ SHOW_NON_REPRODUCIBLE_WATERMARK ]
```

---

## 4. Hash Watch Flow
1. **Core**: `ExecutionPlan` 생성 시 해시 계산.
2. **Emitter**: 현재 세션의 `bundle_pin_hash`와 `current_plan_hash`를 스냅샷으로 전송.
3. Diff Comparison Specification

- 단순 JSON diff는 허용되지 않는다.
- 구조 비교는 다음 단위로 수행되어야 한다:
    - Step execution order
    - Step type chain
    - Validator / PostValidator sequence
    - Retrieval source signature (Decision/Evidence ID set)
    - Bundle pin hash vs current plan hash
- 의미 없는 필드 차이는 표시하지 않는다 (timestamp, UI-only metadata 제외).

---

## 5. Migration Notes
- **Legacy Compatibility**: 구버전 세션에는 텔레메트리 데이터가 없을 수 있으므로 클라이언트에서 옵셔널 처리.
- **Tree-shaking**: 운영 환경 빌드 시 `src/dev` 디렉토리가 최종 번들에 포함되지 않도록 빌드 스크립트(webpack/vite) 조정 필수.
