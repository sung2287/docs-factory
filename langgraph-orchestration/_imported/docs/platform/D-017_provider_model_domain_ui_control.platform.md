# D-017: Provider / Model / Domain UI Control Platform

## 1. Overview
이 기능의 구현은 Web Adapter 계층과 실행 요청 래퍼에 국한되며, 시스템의 코어 로직은 보존됩니다.

## 2. Affected Components & Files

### 2.1 Web Runtime Adapter
- **Path**: `src/adapters/web/web.runtime_adapter.ts`
- **Role**: HTTP 요청에서 오버라이드 파라미터를 추출하여 런타임 실행 함수로 전달. `freshSession` 플래그 확인 시 세션 생성 로직 트리거.

### 2.2 Run Request Wrapper
- **Path**: `runtime/orchestrator/run_request.ts`
- **Role**: 전달받은 `provider`, `model`, `currentDomain`을 실행 컨텍스트에 포함시켜 `ExecutionPlan` 생성 시 해시에 반영되도록 함.

## 3. Infrastructure Constraints (LOCKED)
- **Core-Zero-Mod**: `src/core/**` 내부의 어떤 파일도 수정하지 않음.
- **No Schema Change**: `session_state.json` 및 관련 TypeScript 인터페이스 수정 금지.
- **No Persistence**: SQLite(`Decision Evidence DB`)에 UI 오버라이드 값을 기록하지 않음.
- **No Policy Change**: `PolicyInterpreter` 로직을 수정하여 도메인 규칙을 강제하지 않음 (도메인은 오직 실행 컨텍스트로만 전달됨).
- **"unset" Isolation**:
    - `"unset"`은 Hash 계산 입력에 포함되지 않는다.
    - `"unset"`은 Domain Allowlist 검증 대상이 아니다.
    - `"unset"` 처리 로직은 Adapter 계층에서만 수행한다.
    - Core 및 Orchestrator는 `"unset"`을 인지하지 않는다.

### Explicit Rotation Trigger (LOCK)
<!-- PRD-017 Reinforcement Patch -->
Session rotation MUST occur only when:
- `freshSession: true` is explicitly sent, OR
- No sessionId is provided.
Mismatch MUST NOT automatically rotate session. Rotation must be tied to explicit user intent.

## 4. Interaction Flow
1. **Web UI**가 `localStorage`의 기본값과 현재 세션 ID를 포함하여 `POST /api/chat` 호출.
2. **Web Runtime Adapter**가 페이로드에서 오버라이드 값을 확인.

### Explicit Rotation Guarantee (LOCK)
<!-- PRD-017 Reinforcement Patch -->

- Web Adapter는 `freshSession` 값을 그대로 `runRuntimeOnce`에 전달해야 한다.
- Adapter는 `freshSession` 값을 재정의하거나 강제 false로 설정해서는 안 된다.
- Session rotation은 오직 다음 경우에만 발생한다:
  1) `freshSession: true`
  2) `sessionId` 미제공
- PLAN_HASH_MISMATCH는 자동 회전 트리거가 아니다.

3. **Explicit Session Rotation Logic (LOCK)**
<!-- PRD-017 Reinforcement Patch -->

Session rotation MUST follow this exact logic:

- If `freshSession: true` is explicitly provided:
  - Adapter MUST create a new session.
- Else if no `sessionId` is provided:
  - Adapter MUST create a new session.
- Else:
  - Adapter MUST execute against the provided `sessionId`.
  - If PLAN_HASH_MISMATCH occurs:
      - Adapter MUST return mismatch response.
      - Adapter MUST NOT auto-rotate.
      - Rotation requires explicit user action.

Automatic rotation on mismatch is strictly forbidden.
4. **Orchestrator**(`run_request.ts`)가 오버라이드 값을 기반으로 계획을 요청하고, 이 과정에서 해시가 자연스럽게 변경됨.
5. 실행 완료 후 결과만 반환하며, 오버라이드 설정은 소멸함.

## 5. Governance (LOCK)
<!-- PRD-017 Reinforcement Patch -->
- No implicit Phase → Domain inference is permitted.
- Domain changes MUST always originate from explicit UI selection.
- Runtime MUST NOT derive Domain from Phase or Mode.

- **Core-Zero-Mod**: 보존됨.
- **No Session Expansion**: 보존됨.
- **No Implicit Domain Inference**: 보존됨 (도메인은 항상 명시적 요청 또는 시스템 기본값에 의함).
